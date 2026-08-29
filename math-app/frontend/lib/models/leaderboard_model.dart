class LeaderboardEntry {
  final String id;
  final String name;
  final String avatar;
  final int weeklyStars;
  final int totalScore;
  final int lessonsCompleted;

  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.avatar,
    this.weeklyStars = 0,
    this.totalScore = 0,
    this.lessonsCompleted = 0,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: (json['id'] ?? json['user_id'] ?? '').toString(),
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '🐸',
      weeklyStars: json['weekly_stars'] ?? 0,
      totalScore: json['total_score'] ?? 0,
      lessonsCompleted: json['lessons_completed'] ?? 0,
    );
  }
}
