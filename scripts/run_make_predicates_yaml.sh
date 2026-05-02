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

INPUT=TODO_INPUT_PATH
OUTPUT=TODO_OUTPUT_PATH

uv run python make_predicates_yaml.py \
    --input "$INPUT" \
    --output "$OUTPUT"

echo "Finished at $(date)"
