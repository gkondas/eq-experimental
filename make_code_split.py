import datetime as dt
import hashlib
import os
import random
from pathlib import Path

import polars as pl
import yaml


def stable_hash_list(items: list[str]) -> str:
    h = hashlib.sha256()
    for x in items:
        h.update(x.encode("utf-8"))
        h.update(b"\n")
    return h.hexdigest()[:12]


PARQUET_PATH = "/groups/mm6677_gp/gbk2114/columbia-meds/processed/metadata/codes.parquet"
N_OOD = 100
N_ID = 100
SEED = 42
OUT_ROOT = Path("/users/gbk2114/columbia-eq/eval_codes")


def write_codes_yaml(path: Path, codes: list[str]) -> None:
    with open(path, "x") as f:
        yaml.safe_dump({"codes": codes}, f)


if __name__ == "__main__":
    rng = random.Random(SEED)

    parquet = Path(PARQUET_PATH)
    df = pl.read_parquet(parquet)
    all_codes = df["code"].unique().sort().to_list()
    filtered = sorted(c for c in all_codes if "TIME" not in c)

    ood = sorted(rng.sample(filtered, N_OOD))
    train_pool = sorted(set(filtered) - set(ood))
    id_eval = sorted(rng.sample(train_pool, N_ID))
    combined = sorted(set(ood) | set(id_eval))

    assert not (set(ood) & set(train_pool)), "OOD codes leaked into train pool"
    assert set(id_eval) <= set(train_pool), "ID eval codes must be subset of train pool"
    assert len(ood) == N_OOD
    assert len(id_eval) == N_ID
    assert len(combined) == N_OOD + N_ID

    pool_hash = stable_hash_list(train_pool)
    ood_hash = stable_hash_list(ood)
    id_hash = stable_hash_list(id_eval)

    split_dir = OUT_ROOT / f"split__seed{SEED}__pool{pool_hash}__ood{ood_hash}__id{id_hash}"
    os.makedirs(split_dir, exist_ok=False)

    write_codes_yaml(split_dir / "train_codes.yaml", train_pool)
    write_codes_yaml(split_dir / "ood_eval_codes.yaml", ood)
    write_codes_yaml(split_dir / "id_eval_codes.yaml", id_eval)
    write_codes_yaml(split_dir / "eval_codes.yaml", combined)

    parquet_stat = parquet.stat()
    manifest = {
        "seed": SEED,
        "source_parquet": str(parquet),
        "source_parquet_mtime": dt.datetime.fromtimestamp(parquet_stat.st_mtime).isoformat(),
        "source_parquet_size_bytes": parquet_stat.st_size,
        "vocab_size_total": len(all_codes),
        "vocab_size_filtered": len(filtered),
        "filter": "exclude codes containing 'TIME'",
        "n_train_pool": len(train_pool),
        "n_ood": N_OOD,
        "n_id_eval": N_ID,
        "n_combined_eval": len(combined),
        "hashes": {
            "train_pool": pool_hash,
            "ood": ood_hash,
            "id_eval": id_hash,
            "combined_eval": stable_hash_list(combined),
        },
        "files": {
            "train_codes": "train_codes.yaml",
            "ood_eval_codes": "ood_eval_codes.yaml",
            "id_eval_codes": "id_eval_codes.yaml",
            "eval_codes": "eval_codes.yaml",
        },
        "eval_membership": {
            "in_distribution": id_eval,
            "out_of_distribution": ood,
        },
        "created_at": dt.datetime.now().isoformat(),
    }
    with open(split_dir / "manifest.yaml", "x") as f:
        yaml.safe_dump(manifest, f, sort_keys=False)

    print(f"Written split to {split_dir}")
