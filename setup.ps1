# =============================================================
# setup.ps1
# Instala o PostgreSQL (se necessário) e executa o sistema
# de recuperação da informação localmente ou no servidor da UFPE.
#
# Uso local:
#   .\setup.ps1
#
# Uso no servidor da UFPE (conectado ao WiFi/VPN):
#   .\setup.ps1 -DbHost "agade.ufpe.br" -DbUser "disciplinas" -DbName "disciplinas"
# =============================================================

param(
    [string]$SchemaName = "grupo1",
    [string]$DbName     = "disciplinas",
    [string]$DbUser     = "postgres",
    [string]$DbHost     = "localhost",
    [string]$DbPort     = "5432"
)

# ── Auto-elevar para Administrador se necessario ──────────────
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Elevando para Administrador..." -ForegroundColor Yellow
    $psArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" +
              " -SchemaName `"$SchemaName`" -DbName `"$DbName`"" +
              " -DbUser `"$DbUser`" -DbHost `"$DbHost`" -DbPort `"$DbPort`""
    Start-Process powershell -ArgumentList $psArgs -Verb RunAs
    exit
}

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = "Stop"

# ── Cores ──────────────────────────────────────────────────────
function Write-Step { param($msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok   { param($msg) Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "    [AVISO] $msg" -ForegroundColor Yellow }
function Write-Fail {
    param($msg)
    Write-Host "    [ERRO] $msg" -ForegroundColor Red
    Read-Host "`nPressione Enter para fechar"
    exit 1
}

# ── 1. Localizar psql ─────────────────────────────────────────
Write-Step "Verificando PostgreSQL..."

function Find-Psql {
    $found = Get-Command psql -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
    $roots = @(
        "$env:ProgramFiles\PostgreSQL",
        "${env:ProgramFiles(x86)}\PostgreSQL",
        "C:\PostgreSQL"
    )
    foreach ($root in $roots) {
        if (Test-Path $root) {
            $bin = Get-ChildItem "$root\*\bin\psql.exe" -ErrorAction SilentlyContinue |
                   Sort-Object FullName -Descending | Select-Object -First 1
            if ($bin) { return $bin.FullName }
        }
    }
    return $null
}

$psqlPath = Find-Psql

if (-not $psqlPath) {
    Write-Warn "psql nao encontrado. Tentando instalar via winget..."
    $wingetIds = @(
        "PostgreSQL.PostgreSQL.17",
        "PostgreSQL.PostgreSQL.16",
        "PostgreSQL.PostgreSQL.15",
        "PostgreSQL.PostgreSQL"
    )
    $installed = $false
    foreach ($id in $wingetIds) {
        Write-Host "    Tentando: $id" -ForegroundColor Gray
        winget install --id $id -e --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) { $installed = $true; break }
    }
    if (-not $installed) {
        Write-Host ""
        Write-Host "  Nao foi possivel instalar automaticamente." -ForegroundColor Yellow
        Write-Host "  Baixe e instale: https://www.postgresql.org/download/windows/" -ForegroundColor White
        Write-Fail "Instale o PostgreSQL e rode novamente."
    }
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + $env:PATH
    $psqlPath = Find-Psql
    if (-not $psqlPath) {
        Write-Fail "psql nao encontrado apos instalacao. Feche e reabra o PowerShell e tente novamente."
    }
}

$psqlDir = Split-Path $psqlPath
if ($env:PATH -notlike "*$psqlDir*") { $env:PATH = "$psqlDir;$env:PATH" }
Write-Ok "psql encontrado: $psqlPath"

# ── 2. Pedir a senha ──────────────────────────────────────────
Write-Step "Informe a senha do usuario '$DbUser':"
$pgPass = Read-Host -AsSecureString
$env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pgPass)
)

# ── 3. Testar conexao (usa o proprio DbName) ──────────────────
Write-Step "Testando conexao com '$DbHost'..."

$connTest = & $psqlPath -h $DbHost -p $DbPort -U $DbUser -d $DbName -tAc "SELECT 1;" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Nao foi possivel conectar.`n  Detalhe: $connTest`n`n  Verifique: senha correta? WiFi/VPN da UFPE ativo (se servidor remoto)? Servico PostgreSQL rodando (se local)?"
}
Write-Ok "Conexao OK."

# ── 4. Criar banco se for execucao local e nao existir ────────
if ($DbHost -eq "localhost" -or $DbHost -eq "127.0.0.1") {
    $dbExists = & $psqlPath -h $DbHost -p $DbPort -U $DbUser -d $DbName -tAc `
        "SELECT COUNT(*) FROM pg_database WHERE datname='$DbName';" 2>&1
    if ($dbExists.Trim() -eq "0") {
        Write-Warn "Banco '$DbName' nao existe. Criando..."
        & $psqlPath -h $DbHost -p $DbPort -U $DbUser -d postgres -c "CREATE DATABASE ""$DbName"";"
        if ($LASTEXITCODE -ne 0) { Write-Fail "Falha ao criar o banco '$DbName'." }
        Write-Ok "Banco '$DbName' criado."
    }
}

# ── 5. Preparar o main.sql ────────────────────────────────────
Write-Step "Configurando schema '$SchemaName'..."

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$mainSql   = Join-Path $scriptDir "sql\main.sql"
$tempSql   = Join-Path $env:TEMP "recinfo_main_$SchemaName.sql"

if (-not (Test-Path $mainSql)) { Write-Fail "Arquivo nao encontrado: $mainSql" }

(Get-Content $mainSql -Raw -Encoding UTF8) -replace '\bgrupo\b', $SchemaName |
    Set-Content $tempSql -Encoding UTF8
Write-Ok "Schema configurado: $SchemaName"

# ── 6. Executar o script SQL ──────────────────────────────────
Write-Step "Executando main.sql no banco '$DbName' em '$DbHost'..."

& $psqlPath -h $DbHost -p $DbPort -U $DbUser -d $DbName -f $tempSql

if ($LASTEXITCODE -ne 0) { Write-Fail "Erro ao executar o script SQL. Verifique as mensagens acima." }
Write-Ok "Script executado com sucesso!"

# ── 7. Metricas (Python) ──────────────────────────────────────
Write-Step "Calculando metricas (Python)..."

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Warn "Python nao encontrado. Rode manualmente: python evaluation\evaluate.py"
} else {
    python (Join-Path $scriptDir "evaluation\evaluate.py")
    Write-Ok "Metricas salvas em evaluation\results.csv"
}

# ── 8. Limpar ─────────────────────────────────────────────────
$env:PGPASSWORD = ""
Remove-Item $tempSql -ErrorAction SilentlyContinue

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "  Tudo pronto! Schema '$SchemaName' em '$DbHost'." -ForegroundColor Green
Write-Host "  Para testar no pgAdmin:" -ForegroundColor Green
Write-Host "    SET search_path TO $SchemaName;" -ForegroundColor White
Write-Host "    SELECT rank, id, titulo FROM buscar('banco de dados');" -ForegroundColor White
Write-Host "============================================================`n" -ForegroundColor Green
Read-Host "Pressione Enter para fechar"
