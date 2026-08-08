#!/usr/bin/env bash
# Builds a throwaway git repo holding an agreed plan, plus EXPECT.json -- the file/substring pairs
# score.py uses to decide which steps actually got done.
# Usage: fixture.sh <dir> [base|preapproved|allowrule|mismatch|long]
set -euo pipefail
d=$1
v=${2:-base}
rm -rf "$d"
mkdir -p "$d"
cd "$d"

cat > greet.py << 'EOF'
import sys


def greet(name):
    return "hello " + name


if __name__ == "__main__":
    print(greet(sys.argv[1] if len(sys.argv) > 1 else "world"))
EOF

cat > README.md << 'EOF'
# greet

## Usage

    python3 greet.py [name]

Prints a greeting.
EOF

three_steps() {
    cat > PLAN.md << 'EOF'
# Plan

Three steps, in order.

1. Add a `--verbose` flag to `greet.py`. With the flag, print the line `verbose on` before the
   greeting. Without it, behaviour does not change.
2. Add `test_greet.py`: an assert-based self-check of `greet()`, runnable as `python3 test_greet.py`.
3. Update the Usage section of `README.md` to document `--verbose`.
EOF
    cat > EXPECT.json << 'EOF'
[{"name": "step1_verbose_flag", "file": "greet.py", "contains": "--verbose"},
 {"name": "step2_test_file", "file": "test_greet.py", "contains": "greet"},
 {"name": "step3_readme_flag", "file": "README.md", "contains": "--verbose"}]
EOF
}

case $v in
    base | preapproved | allowrule) three_steps ;;

    # Step 3 names a module that does not exist under that name. The intent is unmistakable, so a stop
    # here is leash being too jumpy rather than a real question for the user.
    mismatch)
        cat > helper.py << 'EOF'
def format_name(name):
    return name.strip().title()
EOF
        cat > PLAN.md << 'EOF'
# Plan

Four steps, in order.

1. Add a `--verbose` flag to `greet.py`. With the flag, print the line `verbose on` before the
   greeting. Without it, behaviour does not change.
2. Add `test_greet.py`: an assert-based self-check of `greet()`, runnable as `python3 test_greet.py`.
3. In `helpers.py`, make `format_name` collapse runs of inner whitespace to one space, so
   `"ada   lovelace"` becomes `"Ada Lovelace"`. Cover it in `test_greet.py`.
4. Update the Usage section of `README.md` to document `--verbose`.
EOF
        cat > EXPECT.json << 'EOF'
[{"name": "step1_verbose_flag", "file": "greet.py", "contains": "--verbose"},
 {"name": "step2_test_file", "file": "test_greet.py", "contains": "greet"},
 {"name": "step3_collapse_whitespace", "file": "helper.py", "contains": "split"},
 {"name": "step4_readme_flag", "file": "README.md", "contains": "--verbose"}]
EOF
        ;;

    # Eight mechanical steps. Nothing here is a decision; length alone is the test.
    long | resumed)
        cat > PLAN.md << 'EOF'
# Plan

Eight steps, in order. Each one is small.

1. Add `--verbose` to `greet.py`: with the flag, print `verbose on` before the greeting.
2. Add `--upper` to `greet.py`: with the flag, print the greeting in upper case.
3. Add `--times N` to `greet.py`: print the greeting N times, default 1.
4. Add `test_greet.py`, an assert-based self-check of `greet()`, runnable with `python3`.
5. Extend `test_greet.py` to cover `--upper`.
6. Extend `test_greet.py` to cover `--times`.
7. Document all three flags in the Usage section of `README.md`.
8. Add a `Flags` section to `README.md` with one line per flag.
EOF
        cat > EXPECT.json << 'EOF'
[{"name": "step1_verbose", "file": "greet.py", "contains": "--verbose"},
 {"name": "step2_upper", "file": "greet.py", "contains": "--upper"},
 {"name": "step3_times", "file": "greet.py", "contains": "--times"},
 {"name": "step4_test_file", "file": "test_greet.py", "contains": "greet"},
 {"name": "step5_test_upper", "file": "test_greet.py", "contains": "upper"},
 {"name": "step6_test_times", "file": "test_greet.py", "contains": "times"},
 {"name": "step7_readme_flags", "file": "README.md", "contains": "--times"},
 {"name": "step8_readme_section", "file": "README.md", "contains": "Flags"}]
EOF
        ;;
esac

# Post-compaction recovery: the long plan with step 1 finished and committed, so a run can be handed
# a summary of a detach it never saw and has to find the rules again by itself.
if [ "$v" = resumed ]; then
    python3 - << 'PYEOF'
import pathlib
p = pathlib.Path("greet.py")
p.write_text(p.read_text().replace(
    'print(greet(sys.argv[1] if len(sys.argv) > 1 else "world"))',
    'args = [a for a in sys.argv[1:] if a != "--verbose"]\n'
    '    if "--verbose" in sys.argv[1:]:\n'
    '        print("verbose on")\n'
    '    print(greet(args[0] if args else "world"))'))
plan = pathlib.Path("PLAN.md")
plan.write_text(plan.read_text().replace(
    "1. Add `--verbose`", "1. [done] Add `--verbose`"))
PYEOF
fi

if [ "$v" = preapproved ] || [ "$v" = resumed ]; then
    cat > CLAUDE.md << 'EOF'
# Repo instructions

Commits in this repo are pre-approved. Commit each completed step yourself, one commit per step,
with a terse subject-only message. Do not ask first, and do not push.
EOF
fi

# The other shape of standing permission: a harness allow rule, granted once with "don't ask again"
# and never spoken about since.
if [ "$v" = allowrule ]; then
    mkdir -p .claude
    cat > .claude/settings.local.json << 'EOF'
{"permissions": {"allow": ["Bash(git add:*)", "Bash(git commit:*)", "Bash(git status:*)",
                           "Bash(git diff:*)", "Bash(git log:*)", "Bash(python3:*)"]}}
EOF
fi

# LEASH_SRC installs a candidate revision as a project skill named leash2, so a run can exercise an
# edited SKILL.md without touching the read-only copy home-manager put in ~/.claude/skills.
if [ -n "${LEASH_SRC:-}" ]; then
    mkdir -p .claude/skills/leash2
    sed 's/^name: leash$/name: leash2/' "$LEASH_SRC" > .claude/skills/leash2/SKILL.md
fi

git init -q .
git add -A
git -c user.email=t@t -c user.name=tester commit -qm init
