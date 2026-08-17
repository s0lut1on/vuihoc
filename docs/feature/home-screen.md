# Home Screen

The home screen is the main dashboard for signed-in children. It shows progress stats, a continue card, the subject grid, and quick navigation to achievements, leaderboard, and profile.

## Files

- `math-app/frontend/lib/screens/home_screen.dart`
- `math-app/frontend/lib/widgets/subject_tile.dart`
- `math-app/frontend/lib/widgets/pricing_banner.dart`
- `math-app/frontend/lib/widgets/streak_badge.dart`
- `math-app/frontend/lib/widgets/kid_nav_bar.dart`
- `math-app/frontend/lib/providers/app_providers.dart`

## Layout

- **Nav bar**: mascot branding, "Chủ đề" label, streak badge, achievements/leaderboard/profile icons.
- **Pricing banner**: dismissible banner shown when free users hit the daily 50-lesson cap.
- **Review card**: shown when the user has recorded wrong answers.
- **Continue card**: prompts the child to keep learning (currently hard-coded to `/subject/numbers`).
- **Stats row**: streak days, total stars, and placeholder trophies/gems/time stats.
- **Subject grid**: responsive grid (2–4 columns) of subject tiles.
- **Build footer**: `🐸 HocVui <git-sha>` so users can verify the deployed build.

## Data Sources

- `userProvider` — name, grade, total stars.
- `streakProvider` — current streak from `/api/progress/streak/:userId`.
- `subjectsProvider(grade)` — math subjects with `lesson_count` from `content-service`.
- `languageSubjectsProvider(grade)` — Vietnamese/English subjects from `language-service`.
- `ReviewApi.getWrongAnswerCount(userId)` — wrong answer count from `question_bank-service`.

## Responsive Behavior

- Width > 900: continue card + streak/stars cards in a horizontal row.
- Width > 1100: 4-column subject grid.
- Width 700–1100: 3-column grid.
- Below 700: 2-column grid.
