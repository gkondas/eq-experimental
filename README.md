# eq-experimental

Experimental scripts and launchers for the EveryQuery paper.

## Setup

Install EveryQuery into your environment so the `EQ_*` console scripts are on `PATH`:

```bash
pip install -e /path/to/EveryQuery
which EQ_train  # should resolve
```

## Running pipeline stages

Each `scripts/run_*.sh` is a self-contained SLURM sbatch script. Edit the `# === Edit these ===` block at the top of whichever script you want to run, then submit:

```bash
sbatch scripts/run_process_data.sh
sbatch scripts/run_generate_training_tasks.sh
sbatch scripts/run_generate_evaluation_tasks.sh codes=/path/to/eval_codes.yaml
sbatch scripts/run_train.sh
sbatch scripts/run_predict.sh
sbatch scripts/run_evaluate.sh
```

Pass ad-hoc Hydra overrides as positional args — they are forwarded directly to the CLI:

```bash
sbatch scripts/run_train.sh lightning_module.optimizer.lr=2e-5 trainer.max_steps=40000
```

Logs land in `logs/` (gitignored).

## Pipeline order

```
EQ_process_data → EQ_generate_training_tasks + EQ_generate_evaluation_tasks → EQ_train → EQ_predict → EQ_evaluate
```

Key path dependencies:
- `EQ_train` reads from `$FINAL_DATA_DIR` (process_data output) and `$TASK_DIR` (training task output).
- `EQ_predict tasks_dir` must point to the eval subdir: `$TASK_DIR/eval/held_out` (not `$TASK_DIR/held_out`).
- `EQ_evaluate` consumes the parquet written by `EQ_predict`.
