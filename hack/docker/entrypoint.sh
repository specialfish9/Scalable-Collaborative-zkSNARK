#!/bin/sh
# usage: run-bench.sh <server_id> <log_n> <l> [bench_name]
set -e
ulimit -n 65536 2>/dev/null || true
export RUST_BACKTRACE=1

server_id="$1"
n="$2"
l="$3"
bench="${4:-bench_hyperplonk}"

echo "Running benchmark '$bench' with server_id=$server_id, n=$n, l=$l"

exec /usr/bin/time -v "/app/$bench" \
    --file "/shared/ips.txt" \
    --l "$l" --n "$n" --id "$server_id"
