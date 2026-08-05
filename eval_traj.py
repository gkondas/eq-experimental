import logging
import sys
from pathlib import Path
from datetime import timedelta

import polars as pl

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    stream=sys.stdout,
    force=True,
)
logger = logging.getLogger("eval_traj")

# NOTE: adjust this import to match your package/module layout.
# From your description, this should be correct:
from MEDS_trajectory_evaluation.temporal_AUC_evaluation.trajectory_AUC import (
    temporal_auc_from_trajectory_files,
)

# ----------------------------
# FILL THESE IN
# ----------------------------
MEDS_PARQUET = Path(
    "/groups/mm6677_gp/gbk2114/columbia-meds/intermediate/data/held_out"
)  # reference MEDS dataframe
TRAJ_ROOT = Path(
    "/users/gbk2114/eic_stuff/columbia-eic/rebuttle-trajectories/medium_seq_1024/merged"
)  # dir OR single parquet file

# yaml defining which codes/tasks to eval
PREDICATES_YAML = Path(
    "/users/gbk2114/columbia-eq/code-split/split__seed42__poolc75b328e959b__ooda7759bfdd359__id71dda1371215/ar-eval-predicate-codes-w-clinical.yaml"
)

OUT_PARQUET = Path(
    "/users/gbk2114/eic_stuff/columbia-eic/rebuttle-trajectories/results/temporal-auc-results-final.parquet"
)

# Optional knobs
DURATION_GRID = [
    timedelta(days=30),
    timedelta(days=90),
    timedelta(days=180),
    timedelta(days=365),
    timedelta(731),
    timedelta(1096),
    timedelta(1461),
    timedelta(1826),
]
# DURATION_GRID = [timedelta(days=2), timedelta(days=4), timedelta(days=10), timedelta(days=12), timedelta(days=18), timedelta(days=19), timedelta(days=39), timedelta(days=64), timedelta(days=70), timedelta(days=99), timedelta(days=148), timedelta(days=151), timedelta(days=165), timedelta(days=170), timedelta(days=178), timedelta(days=227), timedelta(days=235), timedelta(days=288), timedelta(days=361), timedelta(days=451)]
AUC_DIST_APPROX = -1  # -1 means "no approximation" (per your defaults)
SEED = 42
OFFSET = timedelta(0)  # e.g. timedelta(hours=1)
EXCLUDE_HISTORY = False  # or True, or ["task_name_1", "task_name_2"]


def main() -> None:
    logger.info("reading meds_df from %s", MEDS_PARQUET)
    meds_df = pl.read_parquet(MEDS_PARQUET, use_pyarrow=True)
    logger.info("loaded meds_df: shape=%s", meds_df.shape)

    logger.info("starting temporal_auc_from_trajectory_files()")
    out = temporal_auc_from_trajectory_files(
        MEDS_df=meds_df,
        trajectories=TRAJ_ROOT,
        predicates=PREDICATES_YAML,
        duration_grid=DURATION_GRID,
        AUC_dist_approx=AUC_DIST_APPROX,
        seed=SEED,
        offset=OFFSET,
        exclude_history=EXCLUDE_HISTORY,
    )

    logger.info("result:\n%s", out)
    OUT_PARQUET.parent.mkdir(parents=True, exist_ok=True)
    out.write_parquet(OUT_PARQUET)
    logger.info("wrote results to %s", OUT_PARQUET)


if __name__ == "__main__":
    main()
