#!/usr/bin/env python3
"""Generate HocVui brand assets (PNGs + ICO + SVGs).

Reads nothing. Produces:
  - public/brand/logo.svg, logo-mark.svg, logo-wordmark.svg
  - public/brand/favicon.ico
  - public/brand/favicon-32.png, favicon-180.png
  - public/brand/icon-192.png, icon-512.png
  - public/brand/icon-maskable-192.png, icon-maskable-512.png
  - public/brand/apple-touch-icon.png (180x180)
  - public/brand/og-image.png, og-image-vi.png, og-image-en.png
  - public/brand/twitter-card.png

Brand:
  - Mascot: pink circle (#FF6B9D) with frog emoji (matches app BigMascot)
  - Wordmark: "HocVui" in Noto Sans Bold
  - Tagline (vi): "Toán vui cho bé 5-7 tuổi"
  - Tagline (en): "Fun math for kids 5-7"
"""
from __future__ import annotations

import os
import struct
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

# === Brand palette (sourced from math-app/frontend/lib/core/app_colors.dart) ===
PINK = (255, 107, 157, 255)        # #FF6B9D
PINK_DARK = (192, 38, 107, 255)    # #C0266B
PINK_SOFT = (255, 224, 236, 255)   # #FFE0EC
PINK_BG = (255, 245, 250, 255)     # #FFF5FA
DEEP_PURPLE = (45, 27, 78, 255)    # #2D1B4E
CREAM = (255, 248, 225, 255)       # #FFF8E1
WHITE = (255, 255, 255, 255)
SHADOW = (0, 0, 0, 50)

# === Font (Noto Sans has full Vietnamese + Latin coverage) ===
FONT_DIR = Path("/usr/share/fonts/truetype/noto")
FONT_REGULAR = str(FONT_DIR / "NotoSans-Regular.ttf")
FONT_BOLD = str(FONT_DIR / "NotoSans-Bold.ttf")
FONT_BLACK = str(FONT_DIR / "NotoSans-Black.ttf") if (FONT_DIR / "NotoSans-Black.ttf").exists() else FONT_BOLD

# === Output dir ===
OUT = Path(__file__).resolve().parent.parent / "public" / "brand"
OUT.mkdir(parents=True, exist_ok=True)


def font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    path = {
        "regular": FONT_REGULAR,
        "bold": FONT_BOLD,
        "black": FONT_BLACK,
    }[weight]
    return ImageFont.truetype(path, size)


def render_mascot(size: int, *, shadow: bool = True, circle_radius: float = 0.45) -> Image.Image:
    """Pink circle with frog emoji, matches the app's BigMascot visual."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = size / 2, size / 2
    r = size * circle_radius
    # Drop shadow
    if shadow:
        d.ellipse(
            [cx - r, cy - r + size * 0.05, cx + r, cy + r + size * 0.05],
            fill=SHADOW,
        )
    # Main circle (radial-ish: solid pink with darker ring for the app's chunky look)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=PINK)
    # Outer dark ring (3D chunky effect from app's pinkDark border)
    ring = size * 0.04
    d.ellipse(
        [cx - r - ring, cy - r - ring, cx + r + ring, cy + r + ring],
        outline=PINK_DARK,
        width=int(size * 0.025),
    )
    # Frog emoji (uses the system emoji font; PIL's default font can render color emoji on Linux
    # only if we use a CBDT/CBLC emoji font. Fallback: render 🐸 as text in Noto Sans — it'll
    # look monochrome but the brand mark is the pink circle, not the emoji itself).
    emoji_font = font(int(size * 0.55), "black")
    d.text(
        (cx, cy),
        "🐸",
        font=emoji_font,
        anchor="mm",
        fill=DEEP_PURPLE,
    )
    return img


def write_png(img: Image.Image, name: str) -> Path:
    out = OUT / name
    img.save(out, format="PNG", optimize=True)
    return out


def write_ico(img: Image.Image, name: str, sizes: tuple[int, ...] = (16, 32, 48)) -> Path:
    """Save multi-size .ico from a single source."""
    out = OUT / name
    img.save(out, format="ICO", sizes=[(s, s) for s in sizes])
    return out


def write_ico_from_sizes(sizes_to_imgs: dict[int, Image.Image], name: str) -> Path:
    out = OUT / name
    out.parent.mkdir(parents=True, exist_ok=True)
    # Save a primary PNG (largest), then .ico with all sizes
    primary = max(sizes_to_imgs.keys())
    primary_img = sizes_to_imgs[primary]
    primary_img.save(out, format="ICO", sizes=[(s, s) for s in sizes_to_imgs.keys()])
    return out


def svg_mascot(size: int = 200) -> str:
    """Return SVG markup for the pink-circle frog mascot (vector)."""
    cx = cy = size / 2
    r = size * 0.45
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" width="{size}" height="{size}">
  <defs>
    <radialGradient id="g" cx="0.3" cy="0.3" r="0.8">
      <stop offset="0%" stop-color="#FFC1DA"/>
      <stop offset="100%" stop-color="#FF6B9D"/>
    </radialGradient>
  </defs>
  <circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#g)" stroke="#C0266B" stroke-width="{size*0.025:.2f}"/>
  <text x="{cx}" y="{cy}" text-anchor="middle" dominant-baseline="central"
        font-size="{size*0.55:.0f}" font-family="Noto Color Emoji, Apple Color Emoji, Segoe UI Emoji, sans-serif">🐸</text>
</svg>'''


def svg_logo(size: int = 400) -> str:
    """Logo = mascot + wordmark beside it."""
    mascot_size = int(size * 0.4)
    mascot_x = size * 0.04
    mascot_y = (size - mascot_size) / 2
    text_x = size * 0.05 + mascot_size + size * 0.04
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size * 0.3}" width="{size}" height="{size * 0.3}">
  <defs>
    <radialGradient id="g" cx="0.3" cy="0.3" r="0.8">
      <stop offset="0%" stop-color="#FFC1DA"/>
      <stop offset="100%" stop-color="#FF6B9D"/>
    </radialGradient>
  </defs>
  <circle cx="{mascot_x + mascot_size/2}" cy="{mascot_y + mascot_size/2}" r="{mascot_size*0.45}" fill="url(#g)" stroke="#C0266B" stroke-width="{mascot_size*0.025:.2f}"/>
  <text x="{mascot_x + mascot_size/2}" y="{mascot_y + mascot_size/2}" text-anchor="middle" dominant-baseline="central"
        font-size="{mascot_size*0.55:.0f}" font-family="Noto Color Emoji, Apple Color Emoji, Segoe UI Emoji, sans-serif">🐸</text>
  <text x="{text_x}" y="{size * 0.15}" dominant-baseline="central"
        font-family="Noto Sans, Inter, system-ui, sans-serif" font-weight="900"
        font-size="{size * 0.18}" fill="#2D1B4E">HocVui</text>
</svg>'''


def render_og_image(*, lang: str = "vi", out_name: str = "og-image.png") -> Path:
    """1200x630 Open Graph image. lang=vi|en."""
    W, H = 1200, 630
    img = Image.new("RGB", (W, H), PINK_BG[:3])
    d = ImageDraw.Draw(img)
    # Background gradient (pink soft → pink)
    for y in range(H):
        t = y / H
        c = (
            int(PINK_SOFT[0] * (1 - t) + PINK[0] * t),
            int(PINK_SOFT[1] * (1 - t) + PINK[1] * t),
            int(PINK_SOFT[2] * (1 - t) + PINK[2] * t),
        )
        d.line([(0, y), (W, y)], fill=c)
    # Bottom curved purple band (decorative)
    band_h = 120
    d.rectangle([(0, H - band_h), (W, H)], fill=DEEP_PURPLE[:3])

    # Mascot (large, left side)
    mascot_img = render_mascot(380, circle_radius=0.45)
    mascot_x, mascot_y = 80, 100
    img.paste(mascot_img, (mascot_x, mascot_y), mascot_img)

    # Wordmark
    word_x = 540
    word_y = 130
    f_word = font(150, "black")
    d.text((word_x, word_y), "HocVui", font=f_word, fill=DEEP_PURPLE[:3])

    # Tagline
    if lang == "vi":
        line1 = "Toán vui cho bé 5–7 tuổi"
        line2 = "Hơn 6,000 bài học • Miễn phí"
        line3 = "Học toán không khóc, không nản"
    else:
        line1 = "Fun math for kids 5–7"
        line2 = "6,000+ lessons • Free forever"
        line3 = "Learn math with confidence and joy"
    f_tag1 = font(46, "bold")
    f_tag2 = font(34, "regular")
    d.text((word_x, 320), line1, font=f_tag1, fill=DEEP_PURPLE[:3])
    d.text((word_x, 390), line2, font=f_tag2, fill=PINK_DARK[:3])
    d.text((word_x, 440), line3, font=f_tag2, fill=(80, 80, 100, 255))

    # URL footer
    f_url = font(28, "regular")
    d.text((word_x, H - 80), "sekklings.com", font=f_url, fill=WHITE[:3])

    # Decorative stars
    import random
    random.seed(42)
    star_font = font(28, "regular")
    for _ in range(15):
        sx = random.randint(0, W - 30)
        sy = random.randint(0, H - 30)
        d.text((sx, sy), random.choice(["✨", "⭐", "💖", "🌟"]), font=star_font, fill=DEEP_PURPLE[:3])

    return write_png(img, out_name)


def main() -> None:
    print(f"Writing to {OUT}")

    # SVG sources
    (OUT / "logo-mark.svg").write_text(svg_mascot(200))
    (OUT / "logo.svg").write_text(svg_logo(400))
    print("  ✓ logo.svg, logo-mark.svg")

    # Favicons
    sizes = [16, 32, 48, 64, 180, 192, 512]
    mascots = {s: render_mascot(s) for s in sizes}
    # favicon.ico (16, 32, 48)
    write_ico_from_sizes({s: mascots[s] for s in (16, 32, 48)}, "favicon.ico")
    # Standard PNG sizes
    write_png(mascots[32], "favicon-32.png")
    write_png(mascots[180], "apple-touch-icon.png")  # iOS
    write_png(mascots[192], "icon-192.png")
    write_png(mascots[512], "icon-512.png")
    # Maskable (logo centered in safe zone = inner 80% of canvas)
    for s in (192, 512):
        bg = Image.new("RGBA", (s, s), PINK)
        m = render_mascot(int(s * 0.6), circle_radius=0.45)
        off = (s - int(s * 0.6)) // 2
        bg.paste(m, (off, off), m)
        write_png(bg, f"icon-maskable-{s}.png")
    print("  ✓ favicon.ico, favicon-32.png, apple-touch-icon.png, icon-{192,512}.png, icon-maskable-{192,512}.png")

    # OG images
    render_og_image(lang="vi", out_name="og-image-vi.png")
    render_og_image(lang="en", out_name="og-image-en.png")
    # Default = vi
    (OUT / "og-image.png").write_bytes((OUT / "og-image-vi.png").read_bytes())
    # Twitter card = same as OG (1.91:1 ratio)
    (OUT / "twitter-card.png").write_bytes((OUT / "og-image-vi.png").read_bytes())
    print("  ✓ og-image{,-vi,-en}.png, twitter-card.png")

    # Print sizes
    for f in sorted(OUT.iterdir()):
        print(f"  {f.name}: {f.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()
