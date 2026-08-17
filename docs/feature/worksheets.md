# Printable Worksheets

Each math lesson can generate a printable worksheet so children can practice offline with paper and pencil.

## Files

- `math-app/backend/content/src/handlers.rs` (`worksheet` handler)
- `math-app/backend/content/worksheet_template.html`
- `math-app/frontend/lib/screens/lesson_screen.dart`

## Endpoint

- `GET /api/content/lesson/:id/worksheet` returns an HTML page with the lesson exercises formatted for printing.

## Frontend Trigger

- `LessonScreen` shows a 📄 button in the header.
- Tapping it opens the worksheet URL in an external browser tab via `url_launcher`.

## Template

- Uses `minijinja` to render `worksheet_template.html`.
- Includes lesson title, question list, and visual assets in a print-friendly layout.
