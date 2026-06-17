/// Daily lesson cap for free users.
const int freeTierDailyLimit = 50;

/// Whether the paywall should be shown for the given user.
///
/// Free users hit the cap at [freeTierDailyLimit]. Only `premium` is exempt;
/// unknown or empty tier strings are treated as free so a missing or garbled
/// tier value never silently bypasses the cap.
bool shouldShowPaywall({required int count, required String tier}) {
  if (tier == 'premium') return false;
  return count >= freeTierDailyLimit;
}
