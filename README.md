# eq-experimental

Experimental scripts and launchers for the EveryQuery paper.

## Setup

Clone this repo onto the cluster and `sbatch` from its root — logs write to `logs/` here (gitignored).

Python is pinned to 3.11 via `.python-version`; deps are locked in `uv.lock`. To create a reproducible venv:

```bash
uv sync --frozen
source .venv/bin/activate
```

`--frozen` installs exactly what's in `uv.lock` and fails if the lockfile is stale (instead of silently re-resolving). To update deps, edit `pyproject.toml`, run `uv lock`, and commit the new `uv.lock`.

The `EQ_*` console scripts must be on `PATH` separately — install EveryQuery into the same venv however your workflow prefers (e.g. `uv pip install EveryQuery` or `uv pip install -e /path/to/EveryQuery`). It is intentionally not a dependency of this repo so the lock stays standalone.

## How to use a script

Each `scripts/run_*.sh` is a self-contained SLURM job script. The workflow is always the same:

**1. Open the script and edit the `# === Edit these ===` block** at the top to set paths and any defaults for your run:

```bash
# === Edit these for your run ===
export OUTPUT_DIR=/users/you/eq-experimental/outputs
export TASK_DIR=/users/you/eq-experimental/tasks
...
# ================================
```

**2. Submit with `sbatch`**, optionally passing Hydra overrides as extra args:

```bash
# Use the defaults you set in the script
sbatch scripts/run_train.sh

# Or override specific Hydra knobs inline without editing the file
sbatch scripts/run_train.sh lightning_module.optimizer.lr=2e-5 trainer.max_steps=40000
```

Extra args are forwarded directly to the underlying `EQ_*` CLI, which uses [Hydra](https://hydra.cc/) — overrides follow `key=value` syntax.

## Pipeline stages

The stages run in this order:

```
EQ_process_data
    ↓
EQ_generate_training_tasks   EQ_generate_evaluation_tasks
    ↓                                   ↓
EQ_train  ←─────────────────────────────┘
    ↓
EQ_predict
    ↓
EQ_evaluate
```

### `scripts/run_process_data.sh`

Tensorizes the raw MEDS cohort. Run once; output feeds every downstream stage.

- **Exports to set:** `PROJECT_DIR` (raw data root), `INTERMEDIATE`, `FINAL_DATA_DIR` (output)
- **Partition:** cpu

### `scripts/run_generate_training_tasks.sh`

Samples training tasks across all input shards as a SLURM job array (`--array=0-291%20`). Each array task covers one shard and runs 16 task-shards as a Hydra multirun internally.

- **Exports to set:** `INTERMEDIATE`, `PROCESSED`, `TASK_DIR`
- **Partition:** cpu

### `scripts/run_generate_evaluation_tasks.sh`

Same structure as training-task gen but for eval. Output goes to `$TASK_DIR/eval/held_out/`.

- **Exports to set:** `INTERMEDIATE`, `PROCESSED`, `TASK_DIR`
- **Partition:** cpu
- **To use a sampled codes YAML** (from `sample_eval_task_codes.py` or `make_code_split.py`) instead of the full vocab:
  ```bash
  sbatch scripts/run_generate_evaluation_tasks.sh codes=/path/to/eval_codes.yaml
  ```

### Producing a coordinated train / eval code split

`make_code_split.py` produces a single seeded split directory with all
artifacts needed to run a held-out-codes experiment:

```
eval_codes/split__seed42__pool{H1}__ood{H2}__id{H3}/
  manifest.yaml          # seed, source parquet, sizes, hashes, ID/OOD membership
  train_codes.yaml       # full vocab − 100 OOD codes (point training task gen here)
  ood_eval_codes.yaml    # 100 codes held out from training
  id_eval_codes.yaml     # 100 codes sampled from the train pool
  eval_codes.yaml        # combined 200 codes (OOD ∪ ID), flat list
```

Wire the split into the pipeline:

```bash
# Train sees only the train pool
sbatch scripts/run_generate_training_tasks.sh codes=/.../split__.../train_codes.yaml

# Eval task gen on the combined 200-code eval set
sbatch scripts/run_generate_evaluation_tasks.sh codes=/.../split__.../eval_codes.yaml
```

The ID/OOD breakdown for the combined eval lives in `manifest.yaml` —
use it to compute per-split metrics downstream.

### `scripts/run_train.sh`

Trains the model. Wraps the CLI in `srun` — required for Lightning DDP to work correctly.

- **Exports to set:** `PROJECT_DIR`, `OUTPUT_DIR`, `TASK_DIR`, `FINAL_DATA_DIR`, `WANDB_ENTITY`
- **Partition:** gpu (1 GPU, 256G RAM, 300h)

### `scripts/run_predict.sh`

Generates predictions from a trained checkpoint against eval tasks.

- **Exports to set:** `MODEL_RUN_DIR` (path to a training run dir containing `checkpoints/`), `TASKS_DIR`, `OUTPUT_PARQUET`
- **Partition:** gpu
- `TASKS_DIR` must point to the eval subdirectory, e.g. `$TASK_DIR/eval/held_out` — **not** `$TASK_DIR/held_out`.
- `split=train` is rejected (the train loader shuffles, which breaks row alignment).

### `scripts/run_evaluate.sh`

Computes per-`(query, duration_days)` metrics from the prediction parquet.

- **Exports to set:** `PREDICTIONS_PARQUET`, `METRICS_PARQUET`
- **Partition:** cpu
