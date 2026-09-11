/// Daily lesson cap for free users. Set to 0 = no cap (unlimited free lessons).
const int freeTierDailyLimit = 0;

/// Whether the paywall should be shown for the given user.
///
/// Free tier now has unlimited lessons. Paywall is only shown for premium
/// feature upsell (email reports, multi-child, CSV export, etc.) — not for
/// blocking lesson access.
bool shouldShowPaywall({required int count, required String tier}) {
  return false;
}
