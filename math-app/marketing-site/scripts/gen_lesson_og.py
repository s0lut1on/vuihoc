#!/usr/bin/env python3
"""Generate per-subject OG images for HocVui marketing site.
20 images, one per subject, 1200x630 PNG with subject name, lesson count,
and brand gradient.
"""
from __future__ import annotations

import json
import os
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "public" / "og-lessons"
OUT.mkdir(parents=True, exist_ok=True)

# Brand palette (mirrors app_colors.dart)
PINK = (255, 107, 157, 255)
PINK_DARK = (192, 38, 107, 255)
PINK_SOFT = (255, 224, 236, 255)
PINK_BG = (255, 245, 250, 255)
DEEP_PURPLE = (45, 27, 78, 255)
CREAM = (255, 248, 225, 255)
WHITE = (255, 255, 255, 255)

# Subject -> per-cell lesson count mapping (from the live data)
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

# Subject metadata
SUBJECTS = {
    "numbers": ("Số học", "Numbers", "🔢", (255, 232, 240)),
    "geometry": ("Hình học", "Geometry", "📐", (224, 242, 254)),
    "measurement": ("Đo lường", "Measurement", "📏", (255, 243, 224)),
    "logic": ("Tư duy", "Logic", "🧠", (243, 229, 245)),
    "algebra": ("Đại số", "Algebra", "➕", (220, 252, 231)),
    "trigonometry": ("Lượng giác", "Trigonometry", "📊", (255, 224, 236)),
    "statistics": ("Thống kê", "Statistics", "📈", (232, 245, 233)),
    "arithmetic_2digit": ("Cộng trừ 2 chữ số", "2-digit arithmetic", "🧮", (255, 248, 225)),
    "arithmetic_3digit": ("Cộng trừ 3 chữ số", "3-digit arithmetic", "🧮", (255, 248, 225)),
    "multiplication": ("Bảng cửu chương", "Times table", "✖️", (255, 248, 225)),
    "division": ("Phép chia", "Division", "➗", (255, 248, 225)),
    "fractions": ("Phân số", "Fractions", "½", (255, 224, 236)),
    "decimals": ("Số thập phân", "Decimals", "0.5", (224, 242, 254)),
    "perimeter": ("Chu vi", "Perimeter", "📏", (224, 242, 254)),
    "area": ("Diện tích", "Area", "⬛", (224, 242, 254)),
    "angles": ("Góc", "Angles", "📐", (224, 242, 254)),
    "time_money": ("Thời gian & Tiền", "Time & Money", "⏰", (255, 243, 224)),
    "volume": ("Thể tích", "Volume", "🧊", (255, 243, 224)),
    "speed": ("Tốc độ", "Speed", "🏃", (255, 243, 224)),
    "word_problems": ("Bài toán có lời văn", "Word problems", "📝", (243, 229, 245)),
}

FONT_REGULAR = "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf"
FONT_BOLD = "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf"
FONT_BLACK = "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf"


def font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    return ImageFont.truetype({"regular": FONT_REGULAR, "bold": FONT_BOLD, "black": FONT_BLACK}[weight], size)


def draw_gradient_bg(img: Image.Image, top_color: tuple, bot_color: tuple) -> None:
    """Vertical gradient background."""
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


def render_og(name_vi: str, name_en: str, emoji: str, subject_color: tuple, grade: int, n_lessons: int) -> Path:
    W, H = 1200, 630
    img = Image.new("RGB", (W, H), (255, 245, 250))
    d = ImageDraw.Draw(img)
    # Gradient
    draw_gradient_bg(img, (255, 232, 244), (255, 224, 236))
    # Big subject color circle (left)
    cx, cy = 280, H // 2
    r = 200
    # Outer dark ring
    d.ellipse([cx - r - 6, cy - r - 6, cx + r + 6, cy + r + 6], fill=PINK_DARK)
    # Inner pink
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=PINK)
    # Subject icon (emoji)
    f_emoji = font(180, "black")
    d.text((cx, cy), emoji, font=f_emoji, anchor="mm")
    # Right side: text
    text_x = 540
    # "Lớp {grade}" badge
    f_badge = font(28, "bold")
    badge_text = f"LỚP {grade}"
    bbox = d.textbbox((0, 0), badge_text, font=f_badge)
    badge_w = bbox[2] - bbox[0] + 24
    badge_h = bbox[3] - bbox[1] + 16
    d.rounded_rectangle([text_x, 100, text_x + badge_w, 100 + badge_h], radius=20, fill=DEEP_PURPLE)
    d.text((text_x + 12, 100 + 8), badge_text, font=f_badge, fill=WHITE)
    # Subject name (VI)
    f_name = font(80, "black")
    d.text((text_x, 160), name_vi, font=f_name, fill=DEEP_PURPLE)
    # Subject name (EN) - smaller
    f_name_en = font(40, "regular")
    d.text((text_x, 250), name_en, font=f_name_en, fill=(107, 91, 149))
    # Lesson count
    f_count = font(36, "bold")
    count_text = f"{n_lessons} bài học tương tác"
    d.text((text_x, 340), count_text, font=f_count, fill=PINK_DARK)
    f_desc = font(28, "regular")
    d.text((text_x, 390), "Song ngữ Việt–Anh • Tương tác thực hành", font=f_desc, fill=(107, 91, 149))
    # Brand badge bottom
    f_brand = font(32, "black")
    d.text((text_x, H - 80), "🐸 HocVui", font=f_brand, fill=DEEP_PURPLE)
    f_url = font(20, "regular")
    d.text((text_x, H - 40), "sekklings.com", font=f_url, fill=(107, 91, 149))
    # Decorative shapes
    import random
    random.seed(hash((name_vi, grade)) & 0xFFFFFFFF)
    for _ in range(8):
        sx = random.randint(0, W - 30)
        sy = random.randint(0, H - 30)
        color = random.choice([(253, 224, 71), (134, 239, 172), (167, 139, 250), (252, 165, 165)])
        size_r = random.randint(8, 24)
        d.ellipse([sx, sy, sx + size_r, sy + size_r], fill=color)

    slug = f"og-{re.sub(r'[^a-z0-9]+', '-', name_en.lower()).strip('-')}-grade-{grade}.png"
    out = OUT / slug
    img.save(out, format="PNG", optimize=True)
    return out


def main() -> None:
    written = 0
    for subject_id, (name_vi, name_en, emoji, subj_color) in SUBJECTS.items():
        for grade, n_lessons in SUBJECT_CELLS[subject_id]:
            p = render_og(name_vi, name_en, emoji, subj_color, grade, n_lessons)
            print(f"  ✓ {p.name} ({p.stat().st_size // 1024} KB)")
            written += 1
    print(f"\nWrote {written} per-lesson OG images to {OUT.relative_to(ROOT)}/")


if __name__ == "__main__":
    main()
