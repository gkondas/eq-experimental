#!/bin/bash
#SBATCH --job-name=eq-process-data
#SBATCH --output=logs/%x_%j.out
#SBATCH --mail-user=gbk2114@cumc.columbia.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=24:00:00

set -euo pipefail
export PYTHONNOUSERSITE=1
export HYDRA_FULL_ERROR=1

cd "${SLURM_SUBMIT_DIR:-$PWD}"
mkdir -p logs

# === Edit these for your run ===
export PROJECT_DIR=/users/gbk2114/data/MIMIC_MEDS
export INTERMEDIATE=/users/gbk2114/data/MIMIC_MEDS/MEDS_cohort/intermediate
export FINAL_DATA_DIR=/users/gbk2114/data/MIMIC_MEDS/MEDS_cohort/final
# ================================

echo "Starting job on $(hostname) at $(date)"

EQ_process_data \
    input_dir="${PROJECT_DIR}/raw" \
    intermediate_dir="${INTERMEDIATE}" \
    output_dir="${FINAL_DATA_DIR}" \
    "$@"

echo "Finished at $(date)"
