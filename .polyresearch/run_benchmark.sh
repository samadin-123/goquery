#!/bin/bash
# Benchmark harness for goquery
# Runs all benchmarks and computes a geometric mean of ops/sec

set -e

# Run benchmarks with consistent parameters
# -benchtime=1s: run each benchmark for 1 second
# -count=3: run each benchmark 3 times for stability
# -run=^$: skip all tests, only run benchmarks
BENCH_OUTPUT=$(go test -bench=. -benchtime=1s -count=1 -run=^$ 2>&1)

# Extract ops/sec from benchmark results
# Format: BenchmarkName-8   1234567   123.4 ns/op
# We need to calculate ops/sec from ns/op

OPS_PER_SEC=()

while IFS= read -r line; do
    # Match lines like: BenchmarkFind-8         1234567              123.4 ns/op
    if [[ "$line" =~ ^Benchmark.*[[:space:]]+([0-9]+)[[:space:]]+([0-9.]+)[[:space:]]+(ns|µs|ms)/op ]]; then
        ITERS="${BASH_REMATCH[1]}"
        TIME="${BASH_REMATCH[2]}"
        UNIT="${BASH_REMATCH[3]}"

        # Convert time to nanoseconds
        case "$UNIT" in
            "ns")
                TIME_NS="$TIME"
                ;;
            "µs")
                TIME_NS=$(echo "$TIME * 1000" | bc -l)
                ;;
            "ms")
                TIME_NS=$(echo "$TIME * 1000000" | bc -l)
                ;;
        esac

        # Calculate ops/sec: 1,000,000,000 / ns_per_op
        OPS=$(echo "scale=2; 1000000000 / $TIME_NS" | bc -l)
        OPS_PER_SEC+=("$OPS")
    fi
done <<< "$BENCH_OUTPUT"

# Calculate geometric mean of all ops/sec values
if [ ${#OPS_PER_SEC[@]} -eq 0 ]; then
    echo "ERROR: No benchmark results found" >&2
    exit 1
fi

# Geometric mean = (product of all values)^(1/n)
PRODUCT=1
COUNT=0
for ops in "${OPS_PER_SEC[@]}"; do
    PRODUCT=$(echo "$PRODUCT * $ops" | bc -l)
    COUNT=$((COUNT + 1))
done

GEOMEAN=$(echo "scale=2; e(l($PRODUCT)/$COUNT)" | bc -l)

echo "METRIC=$GEOMEAN"
echo "# Benchmarks run: $COUNT" >&2
echo "# Geometric mean ops/sec: $GEOMEAN" >&2
