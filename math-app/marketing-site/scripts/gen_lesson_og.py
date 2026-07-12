#!/usr/bin/env python3
"""Generate per-subject OG images for HocVui marketing site.
92 images (one per active subject+grade cell), 1200x630 PNG.

Layout mimics a real screenshot of the Flutter lesson list for that
(subject, grade) — left side has subject hero (icon + name + count),
right side has a "lesson card" previewing 4 actual lesson titles from
lessons.json. Higher CTR than the abstract version.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "public" / "og-lessons"
LESSONS_JSON = ROOT / "src" / "data" / "lessons.json"
OUT.mkdir(parents=True, exist_ok=True)

# Brand palette (mirrors app_colors.dart)
PINK = (255, 107, 157, 255)
PINK_DARK = (192, 38, 107, 255)
PINK_SOFT = (255, 224, 236, 255)
PINK_BG = (255, 245, 250, 255)
DEEP_PURPLE = (45, 27, 78, 255)
MUTED_PURPLE = (107, 91, 149, 255)
CREAM = (255, 248, 225, 255)
WHITE = (255, 255, 255, 255)
LIGHT_BORDER = (240, 232, 240, 255)
PROGRESS_FILL = (134, 239, 172, 255)
PROGRESS_BG = (243, 232, 243, 255)

SUBJECT_CELLS = {
    "numbers": [(g, 50) for g in range(1, 13)],
    "geometry": [(g, 50) for g in range(1, 13)],
    "measurement": [(g, 50) for g in range(1, 13)],
    "logic": [(g, 50) for g in range(1, 13)],
    "algebra": [(g, 50) for g in range(2, 13)],
    "trigonometry": [(g, 50) for g in range(3, 13)],
    "statistics": [(g, 50) for g in range(4, 13)],
    "arithmetic_2digit": [(2, 50)],
    "arithmetic_3digit": [(3, 50)],
    "multiplication": [(2, 50), (3, 50)],
    "division": [(3, 50)],
    "fractions": [(3, 50)],
    "decimals": [(3, 50)],
    "perimeter": [(2, 50)],
    "area": [(3, 50)],
    "angles": [(3, 50)],
    "time_money": [(2, 50)],
    "volume": [(3, 50)],
    "speed": [(3, 50)],
    "word_problems": [(2, 50)],
}

SUBJECTS = {
    "numbers": ("Số học", "Numbers", "🔢"),
    "geometry": ("Hình học", "Geometry", "📐"),
    "measurement": ("Đo lường", "Measurement", "📏"),
    "logic": ("Tư duy", "Logic", "🧠"),
    "algebra": ("Đại số", "Algebra", "➕"),
    "trigonometry": ("Lượng giác", "Trigonometry", "📊"),
    "statistics": ("Thống kê", "Statistics", "📈"),
    "arithmetic_2digit": ("Cộng trừ 2 chữ số", "2-digit arithmetic", "🧮"),
    "arithmetic_3digit": ("Cộng trừ 3 chữ số", "3-digit arithmetic", "🧮"),
    "multiplication": ("Bảng cửu chương", "Times table", "✖️"),
    "division": ("Phép chia", "Division", "➗"),
    "fractions": ("Phân số", "Fractions", "½"),
    "decimals": ("Số thập phân", "Decimals", "🧮"),
    "perimeter": ("Chu vi", "Perimeter", "📏"),
    "area": ("Diện tích", "Area", "⬛"),
    "angles": ("Góc", "Angles", "📐"),
    "time_money": ("Thời gian & Tiền", "Time & Money", "⏰"),
    "volume": ("Thể tích", "Volume", "🧊"),
    "speed": ("Tốc độ", "Speed", "🏃"),
    "word_problems": ("Bài toán có lời văn", "Word problems", "📝"),
}

FONT_REGULAR = "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf"
FONT_BOLD = "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf"
FONT_BLACK = "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf"


def font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(
        {"regular": FONT_REGULAR, "bold": FONT_BOLD, "black": FONT_BLACK}[weight], size
    )


def draw_gradient_bg(img: Image.Image, top_color: tuple, bot_color: tuple) -> None:
    W, H = img.size
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        c = (
            int(top_color[0] * (1 - t) + bot_color[0] * t),
            int(top_color[1] * (1 - t) + bot_color[1] * t),
            int(top_color[2] * (1 - t) + bot_color[2] * t),
        )
        d.line([(0, y), (W, y)], fill=c)


def truncate(s: str, max_chars: int) -> str:
    if len(s) <= max_chars:
        return s
    return s[: max_chars - 1].rstrip() + "…"


def draw_lesson_card(
    d: ImageDraw.ImageDraw,
    x: int,
    y: int,
    w: int,
    h: int,
    titles: list[str],
    progress: int,
) -> None:
    d.rounded_rectangle([x, y, x + w, y + h], radius=20, fill=WHITE, outline=LIGHT_BORDER, width=2)
    # Card header: 🐸 HocVui (small) + "Lớp N" (right)
    d.text((x + 24, y + 22), "🐸  HocVui", font=font(20, "black"), fill=DEEP_PURPLE)
    # Progress bar
    pb_x, pb_y, pb_w, pb_h = x + 24, y + 56, w - 48, 10
    d.rounded_rectangle([pb_x, pb_y, pb_x + pb_w, pb_y + pb_h], radius=5, fill=PROGRESS_BG)
    fill_w = max(8, int(pb_w * (progress / 50)))
    d.rounded_rectangle(
        [pb_x, pb_y, pb_x + fill_w, pb_y + pb_h], radius=5, fill=PROGRESS_FILL
    )
    d.text(
        (pb_x + pb_w, pb_y - 22),
        f"{progress}/50 bài",
        font=font(13, "bold"),
        fill=MUTED_PURPLE,
        anchor="ra",
    )
    # 4 lesson rows
    row_h = 56
    row_y = y + 90
    for i, title in enumerate(titles[:4]):
        # Numbered circle
        d.ellipse(
            [x + 24, row_y, x + 24 + 36, row_y + 36],
            fill=PINK_SOFT,
        )
        d.text(
            (x + 24 + 18, row_y + 18),
            str(i + 1),
            font=font(18, "bold"),
            fill=PINK_DARK,
            anchor="mm",
        )
        # Title
        d.text(
            (x + 70, row_y + 8),
            truncate(title, 32),
            font=font(17, "bold"),
            fill=DEEP_PURPLE,
        )
        # Subtitle (mock): "Tương tác • 5 phút"
        d.text(
            (x + 70, row_y + 30),
            "Tương tác  ·  5 phút",
            font=font(12, "regular"),
            fill=MUTED_PURPLE,
        )
        # Checkmark (right)
        d.ellipse(
            [x + w - 50, row_y + 4, x + w - 18, row_y + 36],
            fill=PROGRESS_FILL,
        )
        d.text(
            (x + w - 34, row_y + 20),
            "✓",
            font=font(16, "bold"),
            fill=WHITE,
            anchor="mm",
        )
        row_y += row_h


def render_og(
    name_vi: str,
    name_en: str,
    emoji: str,
    subject_color: tuple,
    grade: int,
    n_lessons: int,
    titles: list[str],
) -> Path:
    W, H = 1200, 630
    img = Image.new("RGB", (W, H), (255, 245, 250))
    d = ImageDraw.Draw(img)
    draw_gradient_bg(img, (255, 232, 244), (255, 224, 236))

    # --- LEFT: subject hero (40% width) ---
    left_w = 460
    # Subject icon
    cx, cy = 230, H // 2 - 30
    r = 160
    d.ellipse([cx - r - 5, cy - r - 5, cx + r + 5, cy + r + 5], fill=PINK_DARK)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=PINK)
    d.text((cx, cy), emoji, font=font(140, "black"), anchor="mm")
    # "LỚP {grade}" badge
    f_badge = font(22, "bold")
    badge_text = f"LỚP {grade}"
    bbox = d.textbbox((0, 0), badge_text, font=f_badge)
    badge_w = bbox[2] - bbox[0] + 24
    badge_h = bbox[3] - bbox[1] + 14
    bx = cx - badge_w // 2
    by = cy + r + 18
    d.rounded_rectangle([bx, by, bx + badge_w, by + badge_h], radius=20, fill=DEEP_PURPLE)
    d.text((bx + 12, by + 7), badge_text, font=f_badge, fill=WHITE)
    # Subject name (VI)
    f_name = font(54, "black")
    name_bbox = d.textbbox((0, 0), name_vi, font=f_name)
    name_w = name_bbox[2] - name_bbox[0]
    d.text((cx - name_w // 2, by + badge_h + 24), name_vi, font=f_name, fill=DEEP_PURPLE)
    # Subject name (EN) smaller
    f_name_en = font(28, "regular")
    d.text((cx, by + badge_h + 92), name_en, font=f_name_en, fill=MUTED_PURPLE, anchor="mm")

    # --- RIGHT: lesson list card (60% width) ---
    card_x = 480
    card_y = 60
    card_w = W - card_x - 60
    card_h = H - 120
    draw_lesson_card(d, card_x, card_y, card_w, card_h, titles, progress=12)

    # --- BOTTOM: brand bar ---
    f_brand = font(28, "black")
    d.text((60, H - 50), "🐸  HocVui", font=f_brand, fill=DEEP_PURPLE)
    f_url = font(18, "regular")
    d.text(
        (60, H - 22),
        "Học vui mỗi ngày  ·  sekklings.com",
        font=f_url,
        fill=MUTED_PURPLE,
    )

    slug = f"og-{re.sub(r'[^a-z0-9]+', '-', name_en.lower()).strip('-')}-grade-{grade}.png"
    out = OUT / slug
    img.save(out, format="PNG", optimize=True)
    return out


def main() -> None:
    if not LESSONS_JSON.exists():
        print(f"✗ lessons.json not found at {LESSONS_JSON}", file=sys.stderr)
        sys.exit(1)
    try:
        lessons_data = json.loads(LESSONS_JSON.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"✗ lessons.json: invalid JSON — {e}", file=sys.stderr)
        sys.exit(1)

    written = 0
    for subject_id, (name_vi, name_en, emoji) in SUBJECTS.items():
        for grade, _n_lessons in SUBJECT_CELLS[subject_id]:
            cell = lessons_data.get(f"{subject_id}|{grade}", {})
            titles = cell.get("sample_titles_vi", []) or []
            p = render_og(name_vi, name_en, emoji, (255, 232, 240), grade, 50, titles)
            written += 1
    print(f"✓ Wrote {written} per-lesson OG images to {OUT.relative_to(ROOT)}/")


if __name__ == "__main__":
    import sys
    main()
