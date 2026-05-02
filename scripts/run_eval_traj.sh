#!/bin/bash
#SBATCH --job-name=eval-traj
#SBATCH --output=logs/%x_%j.out
#SBATCH --mail-user=gbk2114@cumc.columbia.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=15:00
#
# Usage: sbatch scripts/run_eval_traj.sh

set -euo pipefail
export PYTHONNOUSERSITE=1

cd "${SLURM_SUBMIT_DIR:-$PWD}"
mkdir -p logs

echo "Starting job on $(hostname) at $(date)"

uv run eval_traj.py

echo "Finished at $(date)"
