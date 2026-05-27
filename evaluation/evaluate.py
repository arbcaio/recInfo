"""
evaluate.py
-----------
Computes Precision, Recall (Cobertura), and F-measure for each
query defined in evaluation/relevance.json.

Usage:
    python evaluation/evaluate.py

Output:
    - Formatted table printed to stdout
    - evaluation/results.csv written with the same data
"""

import json
import csv
import os

# -- Load relevance judgments ----------------------------------

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RELEVANCE_FILE = os.path.join(SCRIPT_DIR, "relevance.json")
OUTPUT_CSV     = os.path.join(SCRIPT_DIR, "results.csv")

with open(RELEVANCE_FILE, encoding="utf-8") as f:
    data = json.load(f)


# -- Metric functions ------------------------------------------

def precision(relevant: set, retrieved: list) -> float:
    """P = |relevant ∩ retrieved| / |retrieved|"""
    if not retrieved:
        return 0.0
    return len(relevant & set(retrieved)) / len(retrieved)


def recall(relevant: set, retrieved: list) -> float:
    """R = |relevant ∩ retrieved| / |relevant|"""
    if not relevant:
        return 0.0
    return len(relevant & set(retrieved)) / len(relevant)


def f_measure(p: float, r: float) -> float:
    """F = 2PR / (P + R)"""
    if p + r == 0:
        return 0.0
    return 2 * p * r / (p + r)


# -- Compute metrics -------------------------------------------

rows = []

for q in data["queries"]:
    rel = set(q["relevant"])
    ret = q["retrieved"]

    p  = precision(rel, ret)
    r  = recall(rel, ret)
    f  = f_measure(p, r)

    tp = len(rel & set(ret))   # true  positives
    fp = len(set(ret) - rel)   # false positives
    fn = len(rel - set(ret))   # false negatives

    rows.append({
        "id":         q["id"],
        "query":      q["query"],
        "relevant":   sorted(rel),
        "retrieved":  ret,
        "TP": tp, "FP": fp, "FN": fn,
        "precision":  round(p, 2),
        "recall":     round(r, 2),
        "f_measure":  round(f, 2),
    })


# -- Print formatted table -------------------------------------

HEADER = (
    f"{'#':>2}  {'Query':<28}  "
    f"{'Relev':>5}  {'Retr':>4}  {'TP':>2}  {'FP':>2}  {'FN':>2}  "
    f"{'Prec':>5}  {'Rec':>5}  {'F':>5}"
)
SEP = "-" * len(HEADER)

print(SEP)
print(HEADER)
print(SEP)

for row in rows:
    print(
        f"{row['id']:>2}  {row['query']:<28}  "
        f"{len(row['relevant']):>5}  {len(row['retrieved']):>4}  "
        f"{row['TP']:>2}  {row['FP']:>2}  {row['FN']:>2}  "
        f"{row['precision']:>5.2f}  {row['recall']:>5.2f}  {row['f_measure']:>5.2f}"
    )

print(SEP)

avg_p = sum(r["precision"] for r in rows) / len(rows)
avg_r = sum(r["recall"]    for r in rows) / len(rows)
avg_f = sum(r["f_measure"] for r in rows) / len(rows)

print(
    f"{'':>2}  {'AVERAGE':<28}  "
    f"{'':>5}  {'':>4}  {'':>2}  {'':>2}  {'':>2}  "
    f"{avg_p:>5.2f}  {avg_r:>5.2f}  {avg_f:>5.2f}"
)
print(SEP)


# -- Write CSV -------------------------------------------------

with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as csvfile:
    fieldnames = [
        "id", "query",
        "n_relevant", "n_retrieved",
        "TP", "FP", "FN",
        "precision", "recall", "f_measure",
        "notes",
    ]
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()

    for row, q in zip(rows, data["queries"]):
        writer.writerow({
            "id":          row["id"],
            "query":       row["query"],
            "n_relevant":  len(row["relevant"]),
            "n_retrieved": len(row["retrieved"]),
            "TP":          row["TP"],
            "FP":          row["FP"],
            "FN":          row["FN"],
            "precision":   row["precision"],
            "recall":      row["recall"],
            "f_measure":   row["f_measure"],
            "notes":       q.get("notes", ""),
        })

print(f"\nResults saved to: {OUTPUT_CSV}")
