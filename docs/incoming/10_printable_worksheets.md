# Plan: Printable Worksheets

## Problem
Parents and teachers want offline practice materials. Vietnamese parents commonly print exercises for kids to solve with pen and paper. No download/print option exists — kids can only practice on-screen.

## Goal
Add a "Tải phiếu bài tập" (Download Worksheet) button to every lesson. Generates a print-ready A4 PDF with:
- 5-10 exercises from the lesson (or similar difficulty)
- Kid-friendly layout with large fonts, emoji visuals
- Space to write answers
- Answer key on page 2
- Vietnamese title + instructions

## Scope

### MVP — Backend (2-3 days)

**Worksheet generation service** (new Rust microservice or extend content-service):

Option A (recommended — simpler): **New HTML-to-print endpoint** on content-service
- `GET /api/content/lesson/:id/worksheet` → returns HTML styled for A4 print
- Renders 5-10 exercises from the lesson in a grid layout
- Large fonts (min 16pt), emoji support, answer spaces
- Answer key in a collapsible section or separate page
- Frontend opens this in a new tab → user presses Ctrl+P or Cmd+P

Option B: **Dedicated `worksheet-service`** with real PDF generation
- Rust service using `printpdf` or `genpdf` crate
- Same endpoint but returns `application/pdf` bytes
- More control over layout but adds dependencies

**MVP uses Option A** (HTML print) — faster, no new service, leverages browser's print engine.

**Worksheet endpoint** on content-service:
```rust
// In content-service main.rs
.route("/api/content/lesson/:id/worksheet", get(handlers::worksheet))
```

**Worksheet handler**:
- Fetch lesson + exercises from DB (same as `get_lesson`)
- Render HTML template with exercises in A4-friendly format
- Include answer key after page break
- Set `Content-Type: text/html; charset=utf-8`
- Add print-specific CSS (`@media print` rules)

**Worksheet HTML template** (`minijinja` template, already in deps):
```
Phiếu bài tập: {{ title_vi }}
Lớp {{ grade }} — {{ subject_vi }}

Họ và tên: _____________  Ngày: _____________

Hướng dẫn: Khoanh tròn vào đáp án đúng.

1. {{ question_vi }}
   ☐ {{ option_1 }}
   ☐ {{ option_2 }}
   ☐ {{ option_3 }}

...

--- Trang đáp án (dành cho phụ huynh) ---
1. {{ correct_answer_1 }}
2. {{ correct_answer_2 }}
...
```

**Static content seeder** — generate 500+ printable-only exercises per subject for variety (not tied to lesson progression):
- Simple arithmetic: `{{a}} + {{b}} = ?` with auto-generated params
- Shape identification: "Hình nào là hình tròn?"
- Number patterns: "Số tiếp theo: {{a}}, {{b}}, {{c}}, ...?"
- Uses the existing question_bank `engine/generator.rs` to render stems

### MVP — Frontend (1 day)

**Worksheet button** on `LessonScreen` + `SubjectScreen`:
- "📄 Tải phiếu bài tập" button in the header area
- Opens `GET /api/content/lesson/:id/worksheet` in new tab
- Browser's native print dialog fires automatically

**Worksheet button** on home screen:
- "📄 Phiếu bài tập" card in the 4-up stat row (replacing a static stat)
- Shows "10+ phiếu mới mỗi tuần" badge
- Links to a curated list of popular worksheets

### V2
- Parametric worksheet generator: parent picks subject, topic, difficulty, number of questions
- Answers sheet separate (page 2 or QR code to reveal)
- Vietnamese math competition prep worksheets (Violympic-style)
- Email worksheet PDF as attachment (feeds into parent email report)

## Affected Files

### Backend
- `math-app/backend/content/src/handlers.rs` — add `worksheet()` handler
- `math-app/backend/content/src/main.rs` — add route
- `math-app/backend/content/src/worksheet_template.html` — new, Minijinja template
- `math-app/backend/question_bank/src/engine/generator.rs` — reuse param sampling for seeder

### Frontend
- `math-app/frontend/lib/screens/lesson_screen.dart` — add "Tải phiếu" button
- `math-app/frontend/lib/screens/subject_screen.dart` — add "Tải phiếu" button
- `math-app/frontend/lib/screens/home_screen.dart` — add worksheet card
- `math-app/frontend/lib/services/content_api.dart` — add `getWorksheetUrl()` 

### Docs
- `docs/incoming/10_printable_worksheets.md` — this plan

## Effort Estimate
- **Backend**: 2-3 days (HTML template, endpoint, parametric content seeder)
- **Frontend**: 1 day (buttons, routing)
- **Testing**: 0.5 day
- **Total**: ~4 days

## Viral Loop
This is the key growth driver:
1. Parent prints worksheet → kid solves on paper
2. Parent takes photo, posts to Facebook/Zalo group: "Con tôi học Toán trên HocVui"
3. Friends see the worksheet → visit site → sign up
4. **Add watermark** on each worksheet: `HocVui — Toán vui cho bé 5-7 tuổi | https://sekklings.com`

## Risks
- Print layouts look different across browsers. Use test suite (Playwright PDF snapshots).
- Answer key must be easy for parents to find but not for kids to peek.
- Worksheet content must match curriculum — regenerate when lessons change.

## Success Criteria
- [ ] Every lesson has a "Tải phiếu bài tập" button
- [ ] Clicking opens a print-ready A4 page with 5-10 exercises
- [ ] Exercises use large fonts (min 16pt) with emoji
- [ ] Answer key on page 2
- [ ] Watermark with HocVui branding + URL
- [ ] Browser print dialog opens automatically (optional, user can cancel)
- [ ] Parametric content generates limitless unique worksheets per subject
