#!/bin/bash
#SBATCH --job-name=eq-gen-eval
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --mail-user=gbk2114@cumc.columbia.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --array=0-291%20   # <-- edit upper bound to match your shard count
#
# Each array task = one input shard.
# To use a sampled codes YAML instead of the full vocab:
#   sbatch scripts/run_generate_evaluation_tasks.sh codes=/path/to/eval_codes.yaml
# Output lands in $TASK_DIR/eval/held_out/ (not $TASK_DIR/held_out/).
# Usage: sbatch scripts/run_generate_evaluation_tasks.sh [hydra overrides...]

set -euo pipefail
export PYTHONNOUSERSITE=1
export HYDRA_FULL_ERROR=1

cd "${SLURM_SUBMIT_DIR:-$PWD}"
mkdir -p logs

# === Edit these for your run ===
export INTERMEDIATE=/users/gbk2114/data/MIMIC_MEDS/MEDS_cohort/intermediate
export PROCESSED=/users/gbk2114/data/MIMIC_MEDS/MEDS_cohort/processed
export TASK_DIR=/users/gbk2114/eq-experimental/tasks
# ================================

echo "Starting job on $(hostname) at $(date) [array task ${SLURM_ARRAY_TASK_ID}]"

# Note: input_shard is parsed as a string — keep it quoted.
EQ_generate_evaluation_tasks \
    split=held_out \
    input_shard="${SLURM_ARRAY_TASK_ID}" \
    "$@"

echo "Finished at $(date)"
