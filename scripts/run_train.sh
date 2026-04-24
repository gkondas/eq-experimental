#!/bin/bash
#SBATCH --job-name=eq-train
#SBATCH --output=logs/%x_%j.out
#SBATCH --mail-user=gbk2114@cumc.columbia.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --partition=gpu
#SBATCH --cpus-per-task=2
#SBATCH --mem=256G
#SBATCH --time=300:00:00
#
# Usage: sbatch scripts/run_train.sh [hydra overrides...]
# Example: sbatch scripts/run_train.sh lightning_module.optimizer.lr=2e-5 trainer.max_steps=40000

set -euo pipefail
export PYTHONNOUSERSITE=1
export HYDRA_FULL_ERROR=1

# DDP thread pinning
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK
export OPENBLAS_NUM_THREADS=$SLURM_CPUS_PER_TASK
export NUMEXPR_NUM_THREADS=$SLURM_CPUS_PER_TASK

cd "${SLURM_SUBMIT_DIR:-$PWD}"
mkdir -p logs

# === Edit these for your run ===
export PROJECT_DIR=/users/gbk2114/data/MIMIC_MEDS
export OUTPUT_DIR=/users/gbk2114/eq-experimental/outputs
export TASK_DIR=/users/gbk2114/eq-experimental/tasks
export FINAL_DATA_DIR=/users/gbk2114/data/MIMIC_MEDS/MEDS_cohort/final
export WANDB_ENTITY=gkondas
# ================================

echo "Starting job on $(hostname) at $(date)"
echo "CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"

# srun is required for Lightning DDP — plain invocation hangs on multi-GPU.
srun EQ_train "$@"

echo "Finished at $(date)"
