/// Helper that takes a list of leaderboard entries (which may include the
/// current user's id) and computes their percentile.
///
/// This is a frontend-only derivation. The backend exposes a global
/// leaderboard via `/users/leaderboard/global`; we treat the user's
/// index in that list as their rank. When `userId` matches an entry, we use
/// that entry's rank directly. When the user is not in the list, we assume
/// the list is sorted descending by score and that the user is below all
/// entries shown.
///
/// Returns null when there is no data at all.

class LeaderboardRank {
  /// Integer percentile (lower = better). 5 means "Top 5%". Always in [1, 100].
  final int percentile;

  /// 1-based rank within the leaderboard list. 1 = first place.
  final int rank;

  /// Total number of users in the leaderboard, including the current user
  /// (best-effort; may underestimate when the user is not in the list).
  final int totalUsers;
  const LeaderboardRank(
      {required this.percentile, required this.rank, required this.totalUsers});
}

LeaderboardRank? computeRank({
  required List<Map<String, dynamic>> leaderboard,
  String? userId,
}) {
  if (leaderboard.isEmpty) return null;
  final total = leaderboard.length;
  int? myRank;
  if (userId != null && userId.isNotEmpty) {
    for (var i = 0; i < leaderboard.length; i++) {
      if (leaderboard[i]['id'] == userId) {
        myRank = i + 1;
        break;
      }
    }
  }
  // If user is not in the list, treat them as just below the last entry
  // (rank = total + 1). Conservative estimate.
  final rank = myRank ?? (total + 1);
  final effectiveTotal = rank > total ? total + 1 : total;
  // Percentile = "in the top X% of users" = round((rank / total) * 100),
  // clamped to [1, 100]. rank=1/1 → 100; rank=1/100 → 1; rank=100/100 → 100.
  final pct = ((rank * 100) / effectiveTotal).clamp(1, 100).round();
  return LeaderboardRank(
      percentile: pct, rank: rank, totalUsers: effectiveTotal);
}

String anonymizeName(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return 'Bạn 🐸';
  return t;
}
