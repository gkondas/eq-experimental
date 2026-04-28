#!/bin/bash
#SBATCH --job-name=eq-gen-train
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --mail-user=gbk2114@cumc.columbia.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --array=0-291%20
#
# Each array task = one input shard; 16 task_shards run as a Hydra multirun within each array task.
# To restrict training to a sampled codes YAML (e.g. train_codes.yaml from make_code_split.py):
#   sbatch scripts/run_generate_training_tasks.sh codes=/path/to/train_codes.yaml
# Usage: sbatch scripts/run_generate_training_tasks.sh [hydra overrides...]

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
EQ_generate_training_tasks -m \
    split=train \
    input_shard="${SLURM_ARRAY_TASK_ID}" \
    task_shard='range(0,16)' \
    "$@"

echo "Finished at $(date)"
