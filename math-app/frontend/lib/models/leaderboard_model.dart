class LeaderboardEntry {
  final String id;
  final String name;
  final String avatar;
  final int weeklyStars;

  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.avatar,
    this.weeklyStars = 0,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '🐸',
      weeklyStars: json['weekly_stars'] ?? 0,
    );
  }
}
