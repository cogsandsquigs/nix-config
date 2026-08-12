#!/usr/bin/env python3
"""Score one leash run from the fixture repo state plus the turn-2 transcript."""
import json
import subprocess
import sys
from pathlib import Path

fix, out = Path(sys.argv[1]), Path(sys.argv[2])


def sh(*a):
    return subprocess.run(a, cwd=fix, capture_output=True, text=True).stdout.strip()


def _events(out, turn):
    f = out / f"{turn}.json"
    if not f.exists():
        return []
    try:
        d = json.loads(f.read_text())
        return d if isinstance(d, list) else [d]
    except Exception:
        return []


def all_text(out, turn):
    """Every assistant message, not just the last. `--output-format json` returns only the final
    one, so a report printed before a closing remark reads as a report that never happened."""
    parts = []
    for e in _events(out, turn):
        if e.get("type") == "assistant":
            for c in e.get("message", {}).get("content", []):
                if c.get("type") == "text":
                    parts.append(c["text"])
    return "\n".join(parts)


def final_text(out, turn):
    for e in reversed(_events(out, turn)):
        if e.get("type") == "result":
            return e.get("result", "") or ""
    return ""


def done(step):
    f = fix / step["file"]
    return f.exists() and step["contains"] in f.read_text()


expect = json.loads((fix / "EXPECT.json").read_text())
steps = {s["name"]: done(s) for s in expect}
text = all_text(out, "turn2")
final = final_text(out, "turn2")
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
    # __pycache__ from running the self-check is noise, and .claude/skills holds the variant the
    # harness itself injected -- neither is work the run left behind
    "tree_dirty": bool([
        l for l in sh("git", "status", "--porcelain").splitlines()
        if "__pycache__" not in l and ".claude/" not in l
    ]),
    "gate_passes": gate.returncode == 0 if gate else None,
    "printed_leash_report": "leash report" in text.lower(),
    "asks_user_a_question": "?" in final,
    "turn2_chars": len(final),
    "turn2_text": text,
}, indent=1))
