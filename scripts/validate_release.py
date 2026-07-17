#!/usr/bin/env python3
"""Fail-fast validation for release-critical repository configuration."""

from __future__ import annotations

import csv
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_csv_keys(path: Path) -> set[str]:
    with path.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.reader(handle))
    if not rows or rows[0][:2] != ["key", path.stem]:
        fail(f"{path.relative_to(ROOT)} has an invalid header")
    keys = [row[0] for row in rows[1:] if row]
    if len(keys) != len(set(keys)):
        fail(f"{path.relative_to(ROOT)} contains duplicate keys")
    return set(keys)


def main() -> None:
    config = json.loads((ROOT / "data/config.json").read_text(encoding="utf-8"))
    tiers = config["cube"]["tiers"]
    if [tier["tier"] for tier in tiers] != list(range(1, config["merge"]["max_tier"] + 1)):
        fail("cube tiers must be continuous and end at merge.max_tier")
    if any(sum(group["weights"]) != 100 for group in config["spawn"]["score_tiers"]):
        fail("every spawn tier weight group must total 100")

    en_keys = read_csv_keys(ROOT / "translations/en.csv")
    ru_keys = read_csv_keys(ROOT / "translations/ru.csv")
    if en_keys != ru_keys:
        fail("translation key parity differs between en.csv and ru.csv")

    presets = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    if presets.count("permissions/internet=true") != 2:
        fail("both Android presets must enable INTERNET for release services")
    if 'package/unique_name="com.akarakuts.tiltmerge"' not in presets:
        fail("Android package name is missing")

    print("Release configuration validation passed")


if __name__ == "__main__":
    main()
