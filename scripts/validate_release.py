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
    previous_min_score = -1
    for group in config["spawn"]["score_tiers"]:
        tiers_in_group = group["tiers"]
        weights = group["weights"]
        if sum(weights) != 100:
            fail("every spawn tier weight group must total 100")
        if len(tiers_in_group) != len(weights):
            fail("every spawn tier group must have one weight per tier")
        if any(weight <= 0 for weight in weights):
            fail("spawn tier weights must be positive")
        if any(tier not in range(1, config["merge"]["max_tier"] + 1) for tier in tiers_in_group):
            fail("spawn tier groups may only reference configured tiers")
        min_score = group["min_score"]
        if min_score < previous_min_score:
            fail("spawn tier groups must be sorted by min_score")
        previous_min_score = min_score

    en_keys = read_csv_keys(ROOT / "translations/en.csv")
    # Паритет ключей: каждый translations/*.csv должен совпадать с en.csv.
    for csv_path in sorted((ROOT / "translations").glob("*.csv")):
        if csv_path == (ROOT / "translations/en.csv"):
            continue
        loc_keys = read_csv_keys(csv_path)
        if loc_keys != en_keys:
            fail(f"translation key parity differs between en.csv and {csv_path.name}")

    presets = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    if presets.count("permissions/internet=true") != 2:
        fail("both Android presets must enable INTERNET for release services")
    if 'package/unique_name="com.akarakuts.tiltmerge"' not in presets:
        fail("Android package name is missing")

    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    version_marker = 'config/version="'
    version_start = project.find(version_marker)
    if version_start == -1:
        fail("project version is missing")
    version_start += len(version_marker)
    version_end = project.find('"', version_start)
    version = project[version_start:version_end]
    if f'version/name="{version}"' not in presets:
        fail("Android version name must match project version")
    if 'version/code=' not in presets:
        fail("Android version code is missing")

    print("Release configuration validation passed")


if __name__ == "__main__":
    main()
