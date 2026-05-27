# =============================================================
# setup.ps1
# Instala o PostgreSQL (se necessário) e executa o sistema
# de recuperação da informação localmente.
#
# Como usar:
#   1. Abra o PowerShell como Administrador
#   2. Execute:  .\setup.ps1
#   3. Quando pedido, informe a senha do postgres
# =============================================================

param(
    [string]$SchemaName = "grupo1",
    [string]$DbName     = "disciplinas",
    [string]$DbUser     = "postgres",
    [string]$DbHost     = "localhost",
    [string]$DbPort     = "5432"
)

$ErrorActionPreference = "Stop"

# ── Cores ──────────────────────────────────────────────────────
function Write-Step  { param($msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok    { param($msg) Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "    [AVISO] $msg" -ForegroundColor Yellow }
function Write-Fail  { param($msg) Write-Host "    [ERRO] $msg" -ForegroundColor Red; exit 1 }

# ── 1. Verificar / instalar PostgreSQL ────────────────────────
Write-Step "Verificando PostgreSQL..."

$psql = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psql) {
    Write-Warn "psql nao encontrado. Tentando instalar via winget..."
    winget install --id PostgreSQL.PostgreSQL -e --accept-source-agreements --accept-package-agreements
    # Atualiza o PATH para encontrar o psql recém-instalado
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + $env:PATH
    $psql = Get-Command psql -ErrorAction SilentlyContinue
    if (-not $psql) {
        Write-Fail "psql ainda nao encontrado. Adicione a pasta bin do PostgreSQL ao PATH e rode novamente."
    }
}
Write-Ok "psql encontrado: $($psql.Source)"

# ── 2. Pedir a senha do postgres ──────────────────────────────
Write-Step "Informe a senha do usuario '$DbUser' (definida na instalacao do PostgreSQL):"
$pgPass = Read-Host -AsSecureString
$env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pgPass)
)

# ── 3. Criar banco de dados se nao existir ────────────────────
Write-Step "Verificando banco de dados '$DbName'..."

$exists = psql -h $DbHost -p $DbPort -U $DbUser -tAc `
    "SELECT 1 FROM pg_database WHERE datname='$DbName';" 2>&1

if ($exists -notmatch "1") {
    Write-Warn "Banco '$DbName' nao existe. Criando..."
    psql -h $DbHost -p $DbPort -U $DbUser -c "CREATE DATABASE $DbName;" postgres
    Write-Ok "Banco '$DbName' criado."
} else {
    Write-Ok "Banco '$DbName' ja existe."
}

# ── 4. Preparar o main.sql com o schema correto ───────────────
Write-Step "Configurando schema '$SchemaName' no script SQL..."

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$mainSql    = Join-Path $scriptDir "sql\main.sql"
$tempSql    = Join-Path $env:TEMP "recinfo_main_$SchemaName.sql"

if (-not (Test-Path $mainSql)) {
    Write-Fail "Arquivo nao encontrado: $mainSql"
}

(Get-Content $mainSql -Raw) -replace '\bgrupo\b', $SchemaName | Set-Content $tempSql -Encoding UTF8
Write-Ok "Script temporario criado em: $tempSql"

# ── 5. Executar o script SQL ──────────────────────────────────
Write-Step "Executando main.sql no banco '$DbName'..."

psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -f $tempSql

if ($LASTEXITCODE -ne 0) {
    Write-Fail "Erro ao executar o script SQL. Verifique as mensagens acima."
}
Write-Ok "Script executado com sucesso!"

# ── 6. Calcular metricas (Python) ─────────────────────────────
Write-Step "Calculando metricas de avaliacao (Python)..."

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Warn "Python nao encontrado. Pule esta etapa ou instale em python.org/downloads"
} else {
    $evalScript = Join-Path $scriptDir "evaluation\evaluate.py"
    python $evalScript
    Write-Ok "Metricas calculadas. Resultados em evaluation\results.csv"
}

# ── 7. Limpar senha da memoria ────────────────────────────────
$env:PGPASSWORD = ""
Remove-Item $tempSql -ErrorAction SilentlyContinue

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "  Tudo pronto! Sistema executado no schema '$SchemaName'." -ForegroundColor Green
Write-Host "  Para testar no pgAdmin, execute:" -ForegroundColor Green
Write-Host "    SET search_path TO $SchemaName;" -ForegroundColor White
Write-Host "    SELECT rank, id, titulo FROM buscar('banco de dados');" -ForegroundColor White
Write-Host "============================================================`n" -ForegroundColor Green
