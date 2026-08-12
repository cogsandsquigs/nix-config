#!/usr/bin/env python3
"""Roll every score.json under a run dir into a compliance-vs-size table."""
import json
import sys
from collections import defaultdict
from pathlib import Path

run = Path(sys.argv[1])
sizes = {p.stem: p.stat().st_size for p in Path(sys.argv[2]).glob("*.md")} if len(sys.argv) > 2 else {}

by_variant = defaultdict(lambda: defaultdict(list))  # variant -> scenario -> [score.json]
fails = defaultdict(list)

for s in sorted(run.glob("*/rep*/*/score.json")):
    variant, _, sc = s.parts[-4], s.parts[-3], s.parts[-2]
    d = json.loads(s.read_text())
    by_variant[variant][sc].append(d)
    for k, v in d["checks"].items():
        if not v:
            fails[variant].append(f"{sc}/{k}")

print("# sudo compression benchmark\n")
print("| variant | bytes | pass | rate | failed checks |")
print("|---|---|---|---|---|")
for variant in sorted(by_variant):
    runs = [d for scs in by_variant[variant].values() for d in scs]
    p = sum(d["passed"] for d in runs)
    t = sum(d["total"] for d in runs)
    b = sizes.get(variant, "")
    print(f"| {variant} | {b} | {p}/{t} | {p / t:.0%} | {', '.join(sorted(set(fails[variant]))) or '--'} |")

print("\n## per scenario\n")
scenarios = sorted({sc for v in by_variant.values() for sc in v})
print("| variant | " + " | ".join(scenarios) + " |")
print("|---" * (len(scenarios) + 1) + "|")
for variant in sorted(by_variant):
    cells = []
    for sc in scenarios:
        ds = by_variant[variant].get(sc, [])
        cells.append("/".join(f"{d['passed']}-{d['total']}" for d in ds) or "-")
    print(f"| {variant} | " + " | ".join(cells) + " |")
