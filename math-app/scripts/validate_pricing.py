#!/usr/bin/env python3
"""Validate math-app/pricing.json against the schema.

Used by:
  - marketing-site prebuild hook
  - math-app/Makefile deploy target
  - manual sanity check

Exit 0 = valid, Exit 1 = invalid. Prints human-readable errors to stderr.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent  # math-app/
PRICING_JSON = REPO_ROOT / "pricing.json"
KNOWN_VERSIONS = {1}
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def fail(errors: list[str]) -> None:
    print(f"✗ pricing.json has {len(errors)} error(s):", file=sys.stderr)
    for e in errors:
        print(f"  - {e}", file=sys.stderr)
    sys.exit(1)


def validate(data: dict) -> list[str]:
    errs: list[str] = []

    # Top-level fields
    version = data.get("version")
    if not isinstance(version, int):
        errs.append(f"version must be int, got {type(version).__name__}")
    elif version not in KNOWN_VERSIONS:
        errs.append(f"version {version} not in known versions {KNOWN_VERSIONS} (migration needed)")

    for field in ("currency", "contact_email", "tiers", "compare_rows"):
        if field not in data:
            errs.append(f"missing top-level field: {field}")

    if data.get("currency") != "VND":
        errs.append(f"currency must be 'VND', got {data.get('currency')!r}")

    email = data.get("contact_email", "")
    if not EMAIL_RE.match(email):
        errs.append(f"contact_email invalid: {email!r}")

    tiers = data.get("tiers", [])
    if not isinstance(tiers, list) or len(tiers) < 2:
        errs.append("tiers must be a list of at least 2 (Free + Premium)")
        return errs

    # Each tier
    seen_ids: set[str] = set()
    defaults: list[str] = []
    for i, t in enumerate(tiers):
        prefix = f"tiers[{i}]"
        if not isinstance(t, dict):
            errs.append(f"{prefix} must be object")
            continue
        for field in ("id", "name_vi", "name_en", "price", "price_period_vi", "price_period_en", "features"):
            if field not in t:
                errs.append(f"{prefix} missing field: {field}")
        tid_raw = t.get("id")
        tid = str(tid_raw) if tid_raw is not None else ""
        if tid in seen_ids:
            errs.append(f"{prefix} duplicate tier id: {tid!r}")
        seen_ids.add(tid)
        if t.get("is_default") is True:
            defaults.append(tid)
        price = t.get("price")
        if price is not None and (not isinstance(price, int) or price < 0):
            errs.append(f"{prefix} price must be int >= 0, got {price!r}")
        feats = t.get("features", [])
        if not isinstance(feats, list):
            errs.append(f"{prefix} features must be a list")
        else:
            for j, f in enumerate(feats):
                fprefix = f"{prefix}.features[{j}]"
                if not isinstance(f, dict):
                    errs.append(f"{fprefix} must be object")
                    continue
                for field in ("id", "text_vi", "text_en"):
                    if field not in f:
                        errs.append(f"{fprefix} missing field: {field}")
                if f.get("text_vi", "").strip() == "":
                    errs.append(f"{fprefix} text_vi is empty")
                if f.get("text_en", "").strip() == "":
                    errs.append(f"{fprefix} text_en is empty")

    if len(defaults) != 1:
        errs.append(f"exactly one tier must have is_default=true, found {defaults}")

    # Free tier sanity
    free_tiers = [t for t in tiers if t.get("price") == 0]
    if not free_tiers:
        errs.append("no Free tier (price=0) found")
    elif not any(t.get("is_default") for t in free_tiers):
        errs.append("Free tier (price=0) must be is_default")

    # Compare rows
    rows = data.get("compare_rows", [])
    for j, r in enumerate(rows):
        rprefix = f"compare_rows[{j}]"
        if not isinstance(r, dict):
            errs.append(f"{rprefix} must be object")
            continue
        for field in ("id", "label_vi", "label_en", "free", "premium"):
            if field not in r:
                errs.append(f"{rprefix} missing field: {field}")
        if r.get("label_vi", "").strip() == "":
            errs.append(f"{rprefix} label_vi is empty")
        if r.get("label_en", "").strip() == "":
            errs.append(f"{rprefix} label_en is empty")

    return errs


def main() -> None:
    if not PRICING_JSON.exists():
        print(f"✗ pricing.json not found at {PRICING_JSON}", file=sys.stderr)
        sys.exit(1)
    try:
        data = json.loads(PRICING_JSON.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"✗ pricing.json: invalid JSON — {e}", file=sys.stderr)
        sys.exit(1)
    errs = validate(data)
    if errs:
        fail(errs)
    n_tiers = len(data.get("tiers", []))
    n_features = sum(len(t.get("features", [])) for t in data.get("tiers", []))
    n_rows = len(data.get("compare_rows", []))
    print(f"✓ pricing.json v{data.get('version')}: {n_tiers} tiers, {n_features} features, {n_rows} compare rows")


if __name__ == "__main__":
    main()
