"""Collapse eq eval-tasks parquets to one row per (subject_id, prediction_time).

eq's ``EQ_generate_evaluation_tasks`` writes the dense
``subjects x sampled_times x codes x durations`` grid — every prediction time is
duplicated ``|codes| * |durations|`` times.  MEDS_EIC_AR's
``MEDSPytorchDataset`` materialises one base item per row in the labels parquet,
so pointing it at the raw eq output would generate that many redundant
trajectories per subject/time.

This script reads each ``<input_dir>/<split>/<shard>.parquet`` and writes a
deduped copy to ``<output_dir>/<split>/<shard>.parquet`` — one row per
``(subject_id, prediction_time)``, keeping just the columns MEDS_EIC_AR needs.

Usage:
    python dedupe_eval_tasks_for_trajectories.py \\
        --input-dir  /path/to/tasks/eval \\
        --output-dir /path/to/tasks/eval_unique \\
        [--split held_out]
"""

import argparse
from pathlib import Path

import polars as pl

# MEDS_EIC_AR's MEDSPytorchDataset reads (subject_id, prediction_time) for each
# generation start.  boolean_value is retained because LabelSchema requires the
# column to exist; its value is meaningless after dedup (it was the label for
# one arbitrary (query, duration) pair) and unused at generation time.


def dedupe_parquet(src: Path, dst: Path) -> tuple[int, int]:
    df = pl.read_parquet(src)
    before = df.height
    out = (
        df.unique(subset=["subject_id", "prediction_time"])
        .select(["subject_id", "prediction_time"])
        .sort(["subject_id", "prediction_time"])
    )
    dst.parent.mkdir(parents=True, exist_ok=True)
    out.write_parquet(dst)
    return before, out.height


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--input-dir", type=Path, required=True, help="e.g. $TASK_DIR/eval")
    p.add_argument("--output-dir", type=Path, required=True)
    p.add_argument(
        "--split",
        default=None,
        help="Restrict to one split subdirectory (e.g. held_out). Default: all splits.",
    )
    args = p.parse_args()

    split_dirs = (
        [args.input_dir / args.split]
        if args.split
        else [d for d in args.input_dir.iterdir() if d.is_dir()]
    )

    for split_dir in split_dirs:
        if not split_dir.is_dir():
            raise FileNotFoundError(f"Not a directory: {split_dir}")
        shards = sorted(split_dir.glob("*.parquet"))
        if not shards:
            print(f"[{split_dir.name}] no parquets found, skipping")
            continue
        for src in shards:
            dst = args.output_dir / split_dir.name / src.name
            before, after = dedupe_parquet(src, dst)
            print(f"[{split_dir.name}/{src.name}] {before} -> {after} rows")


if __name__ == "__main__":
    main()
