#!/bin/bash
#SBATCH --job-name=eq-predict
#SBATCH --output=logs/%x_%j.out
#SBATCH --mail-user=gbk2114@cumc.columbia.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#
# Note: TASKS_DIR must point to the eval subdirectory, e.g. $TASK_DIR/eval/held_out
# Note: split=train is rejected by EQ_predict (train loader shuffles, breaks row alignment).
# Usage: sbatch scripts/run_predict.sh [hydra overrides...]

set -euo pipefail
export PYTHONNOUSERSITE=1
export HYDRA_FULL_ERROR=1

cd "${SLURM_SUBMIT_DIR:-$PWD}"
mkdir -p logs

# === Edit these for your run ===
export MODEL_RUN_DIR=/users/gbk2114/eq-experimental/outputs/<run_id>
export TASKS_DIR=/users/gbk2114/eq-experimental/tasks/eval/held_out
export OUTPUT_PARQUET=/users/gbk2114/eq-experimental/outputs/predictions.parquet
# ================================

echo "Starting job on $(hostname) at $(date)"

EQ_predict \
    model_run_dir="${MODEL_RUN_DIR}" \
    tasks_dir="${TASKS_DIR}" \
    output_parquet="${OUTPUT_PARQUET}" \
    "$@"

echo "Finished at $(date)"
