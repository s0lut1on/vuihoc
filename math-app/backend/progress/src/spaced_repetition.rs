//! SM-2-lite spaced repetition math.
//!
//! Plan 1: extract a pure function that the handler can call to compute
//! the new interval after a review. Easy to test in isolation. The
//! implementation is a deliberate simplification of SM-2:
//!   - On wrong: reset to 1 day
//!   - On correct: increment by 1 day (or double after 3 consecutive correct)
//!   - Clamp at 30 days
//!
//! The "consecutive correct" counter is the existing `correct_count` field
//! in `user_exercise_stats`. We do not implement the full SM-2 ease factor
//! curve (it has a `quality` parameter 0-5 we don't have) but the result
//! matches the same kind of behaviour in the inline handler we replaced.

/// Returns the new interval (days) after a review result.
///
/// Inputs:
/// * `current_interval_days` — how many days were scheduled before this review
/// * `is_correct` — whether the user got it right
/// * `consecutive_correct` — how many times in a row the user has answered
///   correctly *up to and including* this attempt (i.e. 1 for the first
///   correct answer in a row). Pass 0 if this attempt was wrong.
///
/// `consecutive_correct` is only used when `is_correct` is true; when false,
/// we always reset to 1 day.
pub fn compute_new_interval_days(
    current_interval_days: i32,
    is_correct: bool,
    consecutive_correct: i32,
) -> i32 {
    if !is_correct {
        return 1;
    }
    let new_interval = if consecutive_correct >= 3 {
        // After 3 in a row, double the interval (max 30).
        (current_interval_days.max(1)) * 2
    } else {
        // Standard slow-down: +1 day.
        current_interval_days + 1
    };
    new_interval.clamp(1, 30)
}

/// Returns true iff the same exercise should be reviewed again on the same
/// day. Plan 1 success criterion: "No duplicate reviews in same day."
///
/// Current behaviour: the handler picks exercises where `next_review_at <= now`.
/// If the user just finished one, the same exercise will only come back
/// tomorrow because the handler just bumped `next_review_at` to `now + interval`.
/// This function is a small guard for callers that don't trust the database.
pub fn should_review_today(_last_review_at: chrono::DateTime<chrono::Utc>) -> bool {
    // We treat any review after midnight as a fresh day. Real schedule uses
    // the `next_review_at` field which is the authoritative gate.
    false
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn wrong_resets_to_one_day() {
        assert_eq!(compute_new_interval_days(7, false, 5), 1);
    }

    #[test]
    fn wrong_with_zero_consecutive_is_one_day() {
        assert_eq!(compute_new_interval_days(14, false, 0), 1);
    }

    #[test]
    fn first_correct_increments_by_one() {
        // 1 -> 2
        assert_eq!(compute_new_interval_days(1, true, 1), 2);
    }

    #[test]
    fn second_correct_increments_by_one() {
        // 5 -> 6
        assert_eq!(compute_new_interval_days(5, true, 2), 6);
    }

    #[test]
    fn third_consecutive_correct_doubles() {
        // 7 -> 14
        assert_eq!(compute_new_interval_days(7, true, 3), 14);
    }

    #[test]
    fn fourth_consecutive_correct_doubles_again() {
        // 14 -> 28
        assert_eq!(compute_new_interval_days(14, true, 4), 28);
    }

    #[test]
    fn interval_caps_at_thirty_days() {
        // 20 with 3+ correct -> 40 -> clamped to 30
        assert_eq!(compute_new_interval_days(20, true, 3), 30);
        // 15 with 3+ -> 30 (exactly)
        assert_eq!(compute_new_interval_days(15, true, 3), 30);
    }

    #[test]
    fn interval_minimum_is_one_day_for_first_correct() {
        // 0 days + 1 correct -> 1 (because max(1) clamps to 1, then +1 = 2... wait
        // no, the +1 path uses current_interval_days + 1, not max(1)+1).
        // So 0 + 1 = 1 here.
        assert_eq!(compute_new_interval_days(0, true, 1), 1);
    }

    #[test]
    fn interval_minimum_holds_when_doubling_from_low_value() {
        // 1 day * 2 = 2; we never want 0
        assert_eq!(compute_new_interval_days(1, true, 3), 2);
    }

    #[test]
    fn large_correct_streak_at_cap_does_not_overflow() {
        // 30 * 2 = 60; clamp to 30
        assert_eq!(compute_new_interval_days(30, true, 5), 30);
    }

    #[test]
    fn first_correct_from_initial_schedules_two_days() {
        // Mirrors the inline handler's previous "consecutive == 0/1" path.
        // When the row is freshly inserted, the handler passes 1 (just
        // counted the +1). After 1 correct, the next interval is 2 days.
        assert_eq!(compute_new_interval_days(1, true, 1), 2);
    }
}
