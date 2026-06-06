# Facebook Page Assets Design Guide

**Brand:** Math Learning Fun (Bé Học Toán)  
**Style:** Playful, pastel, children-friendly, adaptive personas  
**Base Dimensions:** Cover 820 × 312 px / Avatar 1080 × 1080 px  
**Output:** Text-free `.png` files ready for import into Canva, Facebook, Meta Business Suite

---

## 1. Color Palette (Exact Hex Codes from App)

| Role | Hex | Usage |
|------|-----|-------|
| **Deep Purple** | `#2D1B4E` | Primary text, borders, dark UI elements |
| **Hot Pink** | `#FF6B9D` | CTA buttons, accents, highlights, frog cheek blush |
| **Soft Pink BG** | `#FFE8F0` | Hero background, page atmosphere |
| **Cream** | `#FFF8E1` | Secondary background (assessment screen tone) |
| **White** | `#FFFFFF` | Cards, text bases, clean spaces |
| **Muted Purple** | `#6B5B95` | Secondary text, subtle details |
| **Achiever Orange** | `#E65100` | Persona accent card 1 |
| **Gamer Green** | `#2E7D32` | Persona accent card 2 |
| **Struggler Blue** | `#1565C0` | Persona accent card 3 |
| **Silent Purple** | `#7B1FA2` | Persona accent card 4 |

All persona accent colors should appear as small floating decorative shapes (circles, stars, numbers) to keep the brand language consistent.

---

## 2. Facebook Cover Layout (Horizontal)

### Canvas Size
- **Desktop display:** 820 × 312 px
- **Mobile cropping:** Facebook crops the top and bottom on mobile. The **safe zone** is effectively **820 × 220 px**, vertically centered.
- **Recommended export:** Create a 1640 × 624 px canvas (2x) and export at 2x for crisp retina screens.

### Composition Rules
1. **Background**
   - Base fill: **Soft Pink `#FFE8F0`**
   - Add 2–3 large semi-transparent white blobs (`#FFFFFF` at 20–35% opacity) as background layers to create depth without clutter.

2. **Focal Point — Mascot (Frog)**
   - Place the frog mascot in the **center** of the safe zone.
   - Size: roughly **240–280 px** tall in the 820 px wide canvas.
   - Pose: Waving hello, sitting upright, wearing a tiny graduation cap (consistent with app iconography).
   - Must be fully inside the **safe zone** (vertically centered) so its face is never cropped on mobile.

3. **Floating Decorative Elements (No Text)**
   - **3D-style pastel numbers:** `1`, `2`, `3`, `+`, `=` scattered gently around the mascot.
   - **Geometric shapes:** Circles, triangles, squares in persona accent colors (Orange, Green, Blue, Purple) at low opacity or soft drop shadows (color: `#2D1B4E`, opacity 8%, blur 12 px).
   - **Sparkles / Stars:** Tiny 4-point stars in Hot Pink `#FF6B9D` placed sparsely.
   - **Rule:** Keep all critical decorative elements within the safe zone. Edges can have faint pink dots that are allowed to be cropped.

4. **Bottom Edge Band (Optional Brand Stamp)**
   - A very subtle horizontal band at the bottom 60 px of the cover, colored **Cream `#FFF8E1`**.
   - This zone is *safe to be cropped on mobile* but adds warmth on desktop.
   - Do NOT place the mascot here.

5. **Layering Order (Bottom to Top)**
   1. Solid `#FFE8F0` background
   2. Large semi-transparent white blobs
   3. Cream bottom band (if used)
   4. Floating geometric shapes & numbers
   5. Frog mascot (main focal layer)
   6. Hot pink sparkles & tiny accent stars (topmost)

### Output File Requirements
- **Filename:** `facebook_cover.png`
- **Format:** PNG (transparent elements allowed if needed, but flat PNG is safer for Facebook)
- **Resolution:** 1640 × 624 px (2x), then let Facebook downscale.
- **Safe Zone Overlay:** Before exporting, temporarily draw a rectangle **820 × 220 px** inside your 1640 × 624 px canvas (centered vertically). Ensure the mascot’s face and the main character are fully inside this rectangle. Delete the rectangle before export.

---

## 3. Facebook Avatar / Page Profile Picture

### Canvas Size
- **Recommended:** 1080 × 1080 px (Facebook crops to a circle, so design in a square).
- **Minimum:** 600 × 600 px.

### Composition Rules
1. **Background**
   - Base: Radial gradient from **White `#FFFFFF`** (center) to **Soft Pink `#FFE8F0`** (edges).
   - Alternative solid: **Soft Pink `#FFE8F0`** with a subtle circular highlight in the center.

2. **Focal Point — Frog Mascot**
   - Centered, large, friendly, occupying ~60–70% of the square.
   - Pose: Facing forward, holding a small pink pencil (`#FF6B9D`) or waving.
   - Expression: Big smile, wide eyes.

3. **Frame / Container**
   - A thick circular border in **Hot Pink `#FF6B9D`** (stroke width ~24 px at 1080 px scale).
   - OR a soft circular shadow behind the frog (`#2D1B4E` at 10% opacity, blur 30 px) to make it pop against white Facebook backgrounds.

4. **No extra floating elements** — keep it clean; it will be rendered very small in comments.

### Output File Requirements
- **Filename:** `facebook_avatar.png`
- **Format:** PNG
- **Resolution:** 1080 × 1080 px
- **Safe for Circle Crop:** Place a circle mask overlay (diameter ~1000 px, centered) before exporting. Ensure the frog’s ears/head do not get cut by the circle.

---

## 4. Canva Import Workflow

1. **Create new design**
   - Cover: Use custom size **1640 × 624 px**.
   - Avatar: Use custom size **1080 × 1080 px**.

2. **Upload your base mascot**
   - If you generated the frog in Midjourney/DALL-E, upload it as a `.png` with a transparent background.

3. **Apply the color palette**
   - Add the hex codes above into Canva’s color palette manager so you can pick them quickly.

4. **Build using the layout rules above**
   - Use Canva’s circular frame shapes for the white background blobs.
   - Use star and circle shapes for the floating accent elements.
   - Apply the exact hex codes to each shape.

5. **Safe zone check**
   - Temporarily draw a rectangle: width = full canvas, height = ~72% of canvas, vertically centered. This mimics the Facebook mobile crop. Make sure the mascot is inside it. Delete before export.

6. **Export**
   - Download as PNG, **not JPG**, to preserve clean edges and sparkles.
   - Recommended: transparent background OFF (flat) for the cover to avoid white-fringe issues on Facebook’s dark mode.

---

## 5. Text Placement (If Adding Overlay in Canva Later)

Since these images are **text-free**, text should be added *within Canva* as a separate layer so it remains editable.

| Element | Placement | Recommended Canva Font | Color |
|---------|-----------|------------------------|-------|
| **Page Name** | Lower-left quadrant, inside safe zone | Fredoka One / Nunito (Bold) | `#2D1B4E` or `#FF6B9D` |
| **Tagline** | Below page name, smaller | Quicksand (Medium) | `#6B5B95` |

**Rule:** Do NOT bake text into the exported PNG. Facebook compresses covers, and baked text becomes blurry. Editable Canva text stays crisp.

---

## 6. Quick Reference Checklist

- [ ] Cover is 820 × 312 px (or 2x: 1640 × 624 px)
- [ ] Avatar is 1080 × 1080 px
- [ ] Mascot is centered and inside mobile-safe zone
- [ ] No baked-in text in the PNGs
- [ ] Colors match the app palette exactly
- [ ] Floating elements use persona accent colors
- [ ] Exported as PNG, flat background (not transparent on cover)
- [ ] File names: `facebook_cover.png`, `facebook_avatar.png`

---

*This guide is based on the existing `web-design.pen` and `web-design-preview.html` color system and mascot identity.*
