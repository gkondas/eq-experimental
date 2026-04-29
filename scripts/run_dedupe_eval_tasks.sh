#!/bin/bash
#SBATCH --job-name=eq-dedupe-eval
#SBATCH --output=logs/%x_%j.out
#SBATCH --mail-user=gbk2114@cumc.columbia.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#
# Collapse eq eval-tasks parquets to one row per (subject_id, prediction_time)
# before feeding them to MEDS_EIC_AR trajectory generation.  The raw eq output
# is the dense (subjects x times x codes x durations) grid — generating
# trajectories on it directly produces |codes|*|durations| duplicate
# trajectories per (subject, prediction_time).
#
# Usage:
#   sbatch scripts/run_dedupe_eval_tasks.sh [--split held_out] [extra args...]

set -euo pipefail
export PYTHONNOUSERSITE=1

cd "${SLURM_SUBMIT_DIR:-$PWD}"
mkdir -p logs

# === Edit these for your run ===
INPUT_DIR=/groups/mm6677_gp/gbk2114/columbia-meds/task_sampler_5_years/eval
OUTPUT_DIR=/groups/mm6677_gp/gbk2114/columbia-meds/task_sampler_5_years/eval_unique_index
# ================================

echo "Starting job on $(hostname) at $(date)"

uv run python dedupe_eval_tasks_for_trajectories.py \
    --input-dir  "${INPUT_DIR}" \
    --output-dir "${OUTPUT_DIR}" \
    --split "held_out"
    "$@"

echo "Finished at $(date)"
