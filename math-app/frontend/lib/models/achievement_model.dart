class Achievement {
  final String badgeType;
  final DateTime? earnedAt;
  final bool isNew;
  final String name;
  final String description;
  final String icon;
  final int threshold;

  bool get isEarned => earnedAt != null;

  const Achievement({
    required this.badgeType,
    this.earnedAt,
    this.isNew = false,
    required this.name,
    required this.description,
    required this.icon,
    required this.threshold,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      badgeType: json['badge_type'] ?? '',
      earnedAt: DateTime.tryParse(json['earned_at'] ?? ''),
      // COALESCE returns false when earnedAt is null
      isNew: json['is_new'] == true,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏅',
      threshold: json['threshold'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'badge_type': badgeType,
      'earned_at': earnedAt?.toIso8601String(),
      'is_new': isNew,
      'name': name,
      'description': description,
      'icon': icon,
      'threshold': threshold,
    };
  }
}
