import argparse
import hashlib
import re
from pathlib import Path

import yaml


KEY_PREFIX_LEN = 24
KEY_HASH_LEN = 10
_NON_KEY_CHAR = re.compile(r"[^A-Za-z0-9_]")


def make_key(code: str) -> str:
    sanitized = _NON_KEY_CHAR.sub("_", code.replace("//", "_"))
    prefix = sanitized[:KEY_PREFIX_LEN]
    suffix = hashlib.sha256(code.encode("utf-8")).hexdigest()[:KEY_HASH_LEN]
    return f"{prefix}__{suffix}"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert an eval_codes.yaml ({codes: [...]}) into a predicates YAML "
        "({predicates: {<key>: {code: <code>}}})."
    )
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    with open(args.input) as f:
        data = yaml.safe_load(f)
    codes = data["codes"]

    predicates: dict[str, dict[str, str]] = {}
    for code in codes:
        key = make_key(code)
        if key in predicates:
            raise ValueError(f"Duplicate predicate key {key!r} (collision on code {code!r})")
        predicates[key] = {"code": code}

    with open(args.output, "x") as f:
        yaml.safe_dump({"predicates": predicates}, f, sort_keys=False)

    print(f"Wrote {len(predicates)} predicates to {args.output}")


if __name__ == "__main__":
    main()
