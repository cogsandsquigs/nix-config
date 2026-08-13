#!/usr/bin/env bash
# Every scenario against every variant, N at a time.
# Usage: all.sh <run-dir> <reps> <variant.md>...
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
run=$1 reps=$2
shift 2
mkdir -p "$run"

jobs=$run/jobs.txt
: > "$jobs"
for v in "$@"; do
    name=$(basename "$v" .md)
    for r in $(seq 1 "$reps"); do
        for sc in A B C D F G mode resume; do
            echo "$sc|$v|$run/$name/rep$r/$sc|$run/fixtures/$name-r$r-$sc" >> "$jobs"
        done
    done
done

xargs -a "$jobs" -d '\n' -P "${PAR:-8}" -I{} bash -c '
  IFS="|" read -r sc v out fix <<< "{}"
  here='"$here"'
  case $sc in
    mode)   LEASH_SKILL="$v" bash "$here/run-mode.sh" "$out" "$fix" >/dev/null 2>&1 ;;
    resume) LEASH_SKILL_PATH="$v" bash "$here/run-resume.sh" "$out" "$fix" >/dev/null 2>&1 ;;
    *)      LEASH_SKILL="$v" bash "$here/run.sh" "$sc" with_skill "$out" "$fix" >/dev/null 2>&1 ;;
  esac
  [ -f "$out/score.json" ] && python3 "$here/checks.py" "$sc" "$out/score.json" > "$out/checks.json"
  echo "done $out"
'
python3 "$here/aggregate.py" "$run" "$(dirname "$1")" > "$run/benchmark.md"
cat "$run/benchmark.md"
