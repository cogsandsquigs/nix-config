#!/usr/bin/env python3
"""Score one leash run from the fixture repo state plus the turn-2 transcript."""
import json
import subprocess
import sys
from pathlib import Path

fix, out = Path(sys.argv[1]), Path(sys.argv[2])


def sh(*a):
    return subprocess.run(a, cwd=fix, capture_output=True, text=True).stdout.strip()


def turn2_text():
    try:
        return json.loads((out / "turn2.json").read_text()).get("result", "")
    except Exception:
        return ""


def done(step):
    f = fix / step["file"]
    return f.exists() and step["contains"] in f.read_text()


expect = json.loads((fix / "EXPECT.json").read_text())
steps = {s["name"]: done(s) for s in expect}
text = turn2_text()
log = sh("git", "log", "--oneline")
gate = (
    subprocess.run(["python3", "test_greet.py"], cwd=fix, capture_output=True, text=True)
    if (fix / "test_greet.py").exists()
    else None
)

print(json.dumps({
    "steps": steps,
    "steps_done": sum(steps.values()),
    "steps_total": len(steps),
    "commits_after_baseline": max(0, len(log.splitlines()) - 1),
    "git_log": log.splitlines(),
    # __pycache__ from running the self-check is noise, not an unclean tree
    "tree_dirty": bool([
        l for l in sh("git", "status", "--porcelain").splitlines()
        if "__pycache__" not in l
    ]),
    "gate_passes": gate.returncode == 0 if gate else None,
    "printed_leash_report": "leash report" in text.lower(),
    "asks_user_a_question": "?" in text,
    "turn2_chars": len(text),
    "turn2_text": text,
}, indent=1))
