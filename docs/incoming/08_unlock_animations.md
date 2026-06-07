# Plan: Subject-Specific Unlock Animations

## Problem
Unlocking a new sub-subject is functional but emotionally flat. A celebration moment increases dopamine and retention in young learners.

## Goal
Play a short, subject-themed animation when a user unlocks a new sub-subject (reaches 80% completion of previous).

## Scope

### MVP (1-2 days)
- **Frontend**: Define 5 animation themes matching sub-subjects:
  1. "Space" — rocket launch, stars (for a math/geometry sub-subject)
  2. "Jungle" — monkey swinging, tropical leaves (for counting sub-subject)
  3. "Ocean" — bubbles, fish swimming (for logic/patterns)
  4. "Castle" — drawbridge opening, flag raising (for advanced sub-subject)
  5. "Farm" — tractor driving, barn doors (for measurement)
- **Frontend**: Use Rive or Lottie for animations (preferred: Rive for Flutter web performance).
- **Frontend**: Add `UnlockAnimationOverlay` widget:
  - Full-screen overlay on `SubjectScreen` when `is_unlocked` transitions from `false` to `true`.
  - Auto-dismiss after 3 seconds or tap.
  - Plays sound effect (optional, muted by default, toggle in settings).
- **Frontend**: Store animation assets in `assets/animations/` (`.riv` or `.json`).

### V2
- Haptic feedback on mobile (vibration burst on unlock).
- Confetti particle effect layered on top of Rive animation.
- Parent can disable animations in `ParentDashboardScreen` settings (reduce overstimulation).

## Affected Files

### Frontend
- `math-app/frontend/lib/widgets/unlock_animation_overlay.dart` — new
- `math-app/frontend/lib/screens/subject_screen.dart` — detect unlock transition, trigger overlay
- `math-app/frontend/lib/models/subject.dart` — add `animation_theme` field (optional)
- `math-app/frontend/pubspec.yaml` — add `rive` or `lottie` dependency
- `math-app/frontend/assets/animations/` — add 5 `.riv` files

### Backend
- Optional: Add `animation_theme` column to `sub_subjects` table so themes are data-driven, not hardcoded.

## Effort Estimate
- **Frontend**: 1 day (widget + Rive integration + 5 placeholder animations)
- **Asset creation**: 1-2 days (if outsourced to designer; or use free Lottie files from lottiefiles.com)
- **Testing**: 0.5 day

## Risks
- Asset size: Rive files are small (~20KB each), but 5 × 20KB = 100KB extra initial load. Lazy-load per subject.
- Flutter web + Rive compatibility: test on mobile Safari and Chrome.
- Overstimulation: some kids (especially neurodivergent) may find full-screen animations distressing. Add global disable toggle.

## Success Criteria
- [ ] When a sub-subject unlocks, a full-screen themed animation plays for 3 seconds.
- [ ] Animation matches the sub-subject's theme (e.g., Space for geometry).
- [ ] User can tap to dismiss early.
- [ ] Parent can disable all animations from dashboard settings.
