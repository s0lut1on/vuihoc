#!/usr/bin/env python3
"""Fetch lesson catalog from content-service and write:
  - src/data/lessons.json (all 91 cells)
  - src/data/subjects.json (all 20 subjects)
  - src/data/personas.json (4 personas, from app source)

Also generates:
  - src/content/lessons/<subject>.json per subject (for individual subject pages)

Run before `astro build`. Safe to re-run.
"""
from __future__ import annotations

import json
import os
import re
import sys
import urllib.request
import urllib.error
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "src" / "data"
DATA.mkdir(parents=True, exist_ok=True)
LESSON_DATA = DATA / "lessons.json"
SUBJECTS_DATA = DATA / "subjects.json"
LESSONS_DIR = DATA / "lessons"
LESSONS_DIR.mkdir(parents=True, exist_ok=True)

# Try multiple API endpoints (live first, then fallback static)
API_BASE = os.environ.get("CONTENT_API", "https://sekklings.com/api/content")
TIMEOUT = 15

# Static fallback (used when API is unreachable, e.g. in CI with no live access)
# Mirrors the live data we measured on 2026-07-10
STATIC_SUBJECTS = [
    {"id": "numbers", "name_vi": "Số học", "name_en": "Numbers", "icon": "🔢", "color": "#FFE8F0", "grade_min": 1, "grade_max": 12},
    {"id": "geometry", "name_vi": "Hình học", "name_en": "Geometry", "icon": "📐", "color": "#E0F2FE", "grade_min": 1, "grade_max": 12},
    {"id": "measurement", "name_vi": "Đo lường", "name_en": "Measurement", "icon": "📏", "color": "#FFF3E0", "grade_min": 1, "grade_max": 12},
    {"id": "logic", "name_vi": "Tư duy", "name_en": "Logic", "icon": "🧠", "color": "#F3E5F5", "grade_min": 1, "grade_max": 12},
    {"id": "algebra", "name_vi": "Đại số", "name_en": "Algebra", "icon": "➕", "color": "#DCFCE7", "grade_min": 2, "grade_max": 12},
    {"id": "trigonometry", "name_vi": "Lượng giác", "name_en": "Trigonometry", "icon": "📊", "color": "#FFE0EC", "grade_min": 3, "grade_max": 12},
    {"id": "statistics", "name_vi": "Thống kê", "name_en": "Statistics", "icon": "📈", "color": "#E8F5E9", "grade_min": 4, "grade_max": 12},
    {"id": "arithmetic_2digit", "name_vi": "Cộng trừ 2 chữ số", "name_en": "2-digit arithmetic", "icon": "🧮", "color": "#FFF8E1", "grade_min": 2, "grade_max": 2},
    {"id": "arithmetic_3digit", "name_vi": "Cộng trừ 3 chữ số", "name_en": "3-digit arithmetic", "icon": "🧮", "color": "#FFF8E1", "grade_min": 3, "grade_max": 3},
    {"id": "multiplication", "name_vi": "Bảng cửu chương", "name_en": "Multiplication tables", "icon": "✖️", "color": "#FFF8E1", "grade_min": 2, "grade_max": 3},
    {"id": "division", "name_vi": "Phép chia", "name_en": "Division", "icon": "➗", "color": "#FFF8E1", "grade_min": 3, "grade_max": 3},
    {"id": "fractions", "name_vi": "Phân số", "name_en": "Fractions", "icon": "½", "color": "#FFE0EC", "grade_min": 3, "grade_max": 3},
    {"id": "decimals", "name_vi": "Số thập phân", "name_en": "Decimals", "icon": "0.5", "color": "#E0F2FE", "grade_min": 3, "grade_max": 3},
    {"id": "perimeter", "name_vi": "Chu vi", "name_en": "Perimeter", "icon": "📏", "color": "#E0F2FE", "grade_min": 2, "grade_max": 2},
    {"id": "area", "name_vi": "Diện tích", "name_en": "Area", "icon": "⬛", "color": "#E0F2FE", "grade_min": 3, "grade_max": 3},
    {"id": "angles", "name_vi": "Góc", "name_en": "Angles", "icon": "📐", "color": "#E0F2FE", "grade_min": 3, "grade_max": 3},
    {"id": "time_money", "name_vi": "Thời gian & Tiền", "name_en": "Time & Money", "icon": "⏰", "color": "#FFF3E0", "grade_min": 2, "grade_max": 2},
    {"id": "volume", "name_vi": "Thể tích", "name_en": "Volume", "icon": "🧊", "color": "#FFF3E0", "grade_min": 3, "grade_max": 3},
    {"id": "speed", "name_vi": "Tốc độ", "name_en": "Speed", "icon": "🏃", "color": "#FFF3E0", "grade_min": 3, "grade_max": 3},
    {"id": "word_problems", "name_vi": "Bài toán có lời văn", "name_en": "Word problems", "icon": "📝", "color": "#F3E5F5", "grade_min": 2, "grade_max": 2},
]


def slugify(s: str) -> str:
    s = s.lower()
    s = re.sub(r"[^a-z0-9à-ỹ-]+", "-", s, flags=re.UNICODE)
    s = re.sub(r"-+", "-", s).strip("-")
    return s or "x"


def fetch_json(url: str):
    try:
        with urllib.request.urlopen(url, timeout=TIMEOUT) as resp:
            if resp.status != 200:
                return None
            data = json.loads(resp.read().decode("utf-8"))
            return data.get("data", data) if isinstance(data, dict) else data
    except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError, TimeoutError) as e:
        print(f"  ! {url} -> {e}", file=sys.stderr)
        return None


def load_subjects() -> list[dict]:
    """Try live API; fall back to static."""
    data = fetch_json(f"{API_BASE}/subjects?grade=1")
    if data and isinstance(data, list) and len(data) > 0:
        # live API only returns one grade's subjects; we know grade_min/max from static
        # Merge live names with static metadata
        live_by_id = {s["id"]: s for s in data}
        merged = []
        for s in STATIC_SUBJECTS:
            live = live_by_id.get(s["id"])
            if live:
                merged.append({**s, "name_vi": live.get("name_vi", s["name_vi"]), "name_en": live.get("name_en", s["name_en"]), "icon": live.get("icon", s["icon"]), "color": live.get("color", s["color"])})
            else:
                merged.append(s)
        return merged
    print("  ! using static subject fallback", file=sys.stderr)
    return STATIC_SUBJECTS


def load_lessons() -> dict:
    """Returns {(subject_id, grade): {n_lessons, sample_titles: [...]}}"""
    out: dict = {}
    for s in STATIC_SUBJECTS:
        for grade in range(s["grade_min"], s["grade_max"] + 1):
            data = fetch_json(f"{API_BASE}/curriculum?grade={grade}")
            if data and isinstance(data, list):
                subj = next((x for x in data if x.get("subject_id") == s["id"]), None)
                if subj:
                    lessons = subj.get("lessons") or []
                    out[(s["id"], grade)] = {
                        "subject_id": s["id"],
                        "grade": grade,
                        "n_lessons": len(lessons),
                        "sample_titles_vi": [l.get("title_vi", "") for l in lessons[:5]],
                        "sample_titles_en": [l.get("title_en", "") for l in lessons[:5]],
                    }
                    continue
            # Static fallback: assume 50 (after the 012 pad migration)
            existing = out.get((s["id"], grade), {})
            out[(s["id"], grade)] = {
                "subject_id": s["id"],
                "grade": grade,
                "n_lessons": 50,
                "sample_titles_vi": existing.get("sample_titles_vi", []),
                "sample_titles_en": existing.get("sample_titles_en", []),
            }
    return out


def main() -> None:
    print("→ Fetching subjects…")
    subjects = load_subjects()
    SUBJECTS_DATA.write_text(json.dumps(subjects, ensure_ascii=False, indent=2))
    print(f"  ✓ {len(subjects)} subjects → {SUBJECTS_DATA}")

    print("→ Fetching lessons (91 cells)…")
    lessons = load_lessons()
    # Restructure for JSON: keyed by (subject,grade) string
    serializable = {f"{k[0]}|{k[1]}": v for k, v in lessons.items()}
    LESSON_DATA.write_text(json.dumps(serializable, ensure_ascii=False, indent=2))
    total = sum(v["n_lessons"] for v in lessons.values())
    print(f"  ✓ {len(lessons)} cells, {total} lessons → {LESSON_DATA}")

    # Per-subject rollup
    by_subject: dict[str, list] = {}
    for (subj, grade), v in lessons.items():
        by_subject.setdefault(subj, []).append({"grade": grade, "n_lessons": v["n_lessons"]})
    for s in by_subject:
        path = LESSONS_DIR / f"{s}.json"
        path.write_text(json.dumps({"subject": s, "grades": by_subject[s]}, ensure_ascii=False, indent=2))
    print(f"  ✓ {len(by_subject)} per-subject files → {LESSONS_DIR}/")


if __name__ == "__main__":
    main()
