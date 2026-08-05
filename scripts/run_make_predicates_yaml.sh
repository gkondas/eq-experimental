#!/bin/bash
#SBATCH --job-name=eq-make-predicates-yaml
#SBATCH --output=logs/%x_%j.out
#SBATCH --mail-user=gbk2114@cumc.columbia.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=00:15:00

set -euo pipefail
export PYTHONNOUSERSITE=1

cd "${SLURM_SUBMIT_DIR:-$PWD}"
mkdir -p logs

echo "Starting job on $(hostname) at $(date)"

# Code Split Dir
CODE_SPLIT_DIR="/users/gbk2114/columbia-eq/code-split/split__seed42__poolc75b328e959b__ooda7759bfdd359__id71dda1371215"
# Path to an eval_codes.yaml file with shape {codes: [...]}.
INPUT="$CODE_SPLIT_DIR/eval_codes_w_clinical.yaml"
# File path to write the predicates YAML to ({predicates: {<key>: {code: <code>}}}).
# Must not already exist; the script opens it in exclusive-create mode.
OUTPUT="$CODE_SPLIT_DIR/ar-eval-predicate-codes-w-clinical.yaml"

uv run python make_predicates_yaml.py \
    --input "$INPUT" \
    --output "$OUTPUT"

echo "Finished at $(date)"
