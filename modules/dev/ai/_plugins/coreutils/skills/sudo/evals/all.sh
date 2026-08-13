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
        for sc in A B C D E F G; do
            echo "$sc|$v|$run/$name/rep$r/$sc|$run/fixtures/$name-r$r-$sc" >> "$jobs"
        done
    done
done

xargs -a "$jobs" -d '\n' -P "${PAR:-7}" -I{} bash -c '
  IFS="|" read -r sc v out fix <<< "{}"
  bash '"$here"'/run.sh "$sc" "$v" "$out" "$fix" > /dev/null 2>&1
  echo "done $out"
'
python3 "$here/aggregate.py" "$run" "$(dirname "$1")" > "$run/benchmark.md"
cat "$run/benchmark.md"
