# Clock Face Visuals

The app can render an analog clock face for time-telling exercises. This is implemented with a Flutter `CustomPaint` widget rather than an image asset, so the hands can be set to any hour and minute.

## Files

- `math-app/frontend/lib/widgets/clock_face.dart`

## Format

The visual asset string must match:

```
clock|hour|minute
```

Example: `clock|3|15` renders a clock showing 3:15.

## Rendering

- White circular face with a dark border.
- Hour markers (ticks) for 1–12.
- Hour numbers 1–12.
- Hour hand length = 50% of radius; minute hand length = 75% of radius.
- Center dot.

## Usage

`LessonScreen._buildVisualAsset()` calls `ClockFace.tryParse(asset)`. If it matches, the widget is returned; otherwise the raw asset string is displayed as emoji/text.
