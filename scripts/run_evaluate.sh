#!/bin/bash
#SBATCH --job-name=eq-evaluate
#SBATCH --output=logs/%x_%j.out
#SBATCH --mail-user=gbk2114@cumc.columbia.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#
# Usage: sbatch scripts/run_evaluate.sh [hydra overrides...]

set -euo pipefail
export PYTHONNOUSERSITE=1
export HYDRA_FULL_ERROR=1

cd "${SLURM_SUBMIT_DIR:-$PWD}"
mkdir -p logs

# === Edit these for your run ===
export PREDICTIONS_PARQUET=/users/gbk2114/eq-experimental/outputs/predictions.parquet
export METRICS_PARQUET=/users/gbk2114/eq-experimental/outputs/metrics.parquet
# ================================

echo "Starting job on $(hostname) at $(date)"

EQ_evaluate \
    predictions_parquet="${PREDICTIONS_PARQUET}" \
    metrics_parquet="${METRICS_PARQUET}" \
    "$@"

echo "Finished at $(date)"
