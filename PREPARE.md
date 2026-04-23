# Evaluation Setup

This file is outside the editable surface. It defines how results are judged. Agents cannot modify the evaluator or the scoring logic — the evaluation is the trust boundary.

Consider defining more than one evaluation criterion. Optimizing for a single number makes it easy to overfit and silently break other things. A secondary metric or sanity check helps keep the process honest.

eval_cores: 1
eval_memory_gb: 1.0
prereq_command: go mod download

## Setup

Install dependencies and prepare the evaluation environment.

```bash
# Ensure Go 1.25+ is installed (required by goquery v1.12.0)
go version

# Download dependencies
go mod download

# Verify tests pass
go test -v
```

The prereq_command above downloads Go dependencies before each benchmark run.

## Run command

```bash
bash .polyresearch/run_benchmark.sh
```

This script:
1. Runs all Go benchmarks (`go test -bench=.`)
2. Extracts ops/sec from each benchmark (converts from ns/op)
3. Computes geometric mean across all benchmarks
4. Outputs `METRIC=<geomean_ops_per_sec>`

## Output format

The benchmark must print `METRIC=<number>` to stdout.

## Metric parsing

The CLI looks for `METRIC=<number>` or `ops_per_sec=<number>` in the output.

## Ground truth

The baseline metric is the geometric mean of operations per second across all goquery benchmarks:
- BenchmarkFind, BenchmarkChildren, BenchmarkFilter, BenchmarkParent, etc.
- Each benchmark measures DOM traversal, selection, filtering, or manipulation operations
- Geometric mean is used because benchmark performance spans several orders of magnitude
- Higher values indicate better performance
- Baseline measured on clean repository at commit c92c451 (v1.12.0)
