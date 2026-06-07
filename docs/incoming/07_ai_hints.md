# Plan: AI-Generated Hints (Controlled)

## Problem
When a child gets stuck on an exercise, they have no help except guessing. Giving the full answer defeats the learning purpose.

## Goal
Use Claude (Anthropic) to generate contextual, gentle hints when a user gets 2 wrong answers in a row — never the full answer.

## Scope

### MVP (1-2 days)
- **Backend**: Extend `question-bank-service` (already has `ANTHROPIC_API_KEY` env var):
  - New endpoint `POST /api/qb/hint`:
    - Input: `exercise_id`, `exercise_type`, `prompt_text`, `user_answer_history: ["3", "7"]`
    - Build prompt:
      ```
      You are a friendly Vietnamese math tutor for 6-year-olds.
      Exercise: "What is 5 + 3?"
      Child answered: 3, then 7.
      Give ONE short hint in Vietnamese (max 20 words). Do NOT give the answer.
      ```
    - Call Anthropic API (`claude-sonnet-4-20250514` or cheapest model).
    - Cache response in Redis for 24h (key: `hint:{exercise_id}:{hash_of_history}`).
    - Return `{ "hint": "...", "hint_en": "..." }`.
- **Backend**: Rate limit: max 3 hints per exercise per session (Redis counter `hint_count:{user_id}:{exercise_id}`).
- **Frontend**: Show hint as a speech bubble in `LanguageLessonScreen` after 2 wrong attempts.
  - "Need a hint?" button appears; tapping reveals hint.
  - Dismissible. No auto-display (child might not want it).

### V2
- Pre-generate hints for all exercises at build time (batch job) to reduce API cost.
- A/B test: auto-show hint vs. user-requested hint.

## Affected Files

### Backend
- `math-app/backend/question-bank/src/main.rs` — add `/hint` route
- `math-app/backend/question-bank/src/hint.rs` — new, Anthropic API client + prompt builder
- `math-app/backend/question-bank/src/cache.rs` — Redis hint cache + rate limiter

### Frontend
- `math-app/frontend/lib/screens/language_lesson_screen.dart` — add "Need a hint?" button + speech bubble
- `math-app/frontend/lib/services/question_bank_api.dart` — add `getHint()`
- `math-app/frontend/lib/widgets/hint_bubble.dart` — new reusable widget

## Effort Estimate
- **Backend**: 1 day (prompt engineering + API client + cache)
- **Frontend**: 0.5 day (button + bubble UI)
- **Testing**: 0.5 day (prompt safety: ensure no direct answers leak)

## Risks
- API cost: Anthropic calls cost ~$0.003 per hint. With caching, ~$1/day at 300 active users.
- Prompt injection: a crafted exercise prompt could trick the LLM into revealing the answer. Use strict system prompt + output validation (regex check that answer text is not in hint).
- Privacy: do NOT send user_id or PII to Anthropic; only send exercise content.

## Success Criteria
- [ ] After 2 wrong answers, "Need a hint?" button appears.
- [ ] Hint is in Vietnamese, ≤ 20 words, does not contain the correct answer.
- [ ] Same hint returned for same exercise + wrong answers within 24h (cache hit).
- [ ] Rate limit enforced: 4th hint request returns 429.
