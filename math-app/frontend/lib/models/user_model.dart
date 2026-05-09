import 'persona_model.dart';

class User {
  final String id;
  final String name;
  final Persona persona;
  final String avatar;
  final int totalLessons;
  final int totalStars;
  final int streakDays;
  final int gems;
  final String locale;
  final String tier;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    this.persona = Persona.achiever,
    this.avatar = '🐸',
    this.totalLessons = 0,
    this.totalStars = 0,
    this.streakDays = 0,
    this.gems = 0,
    this.locale = 'vi_VN',
    this.tier = 'free',
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      persona: Persona.fromString(json['persona'] ?? 'achiever'),
      avatar: json['avatar'] ?? '🐸',
      totalLessons: json['total_lessons'] ?? 0,
      totalStars: json['total_stars'] ?? 0,
      streakDays: json['streak_days'] ?? 0,
      gems: json['gems'] ?? 0,
      locale: json['locale'] ?? 'vi_VN',
      tier: json['tier'] ?? 'free',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isPremium => tier == 'premium';

  User copyWith({
    String? id,
    String? name,
    Persona? persona,
    String? avatar,
    int? totalLessons,
    int? totalStars,
    int? streakDays,
    int? gems,
    String? locale,
    String? tier,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      persona: persona ?? this.persona,
      avatar: avatar ?? this.avatar,
      totalLessons: totalLessons ?? this.totalLessons,
      totalStars: totalStars ?? this.totalStars,
      streakDays: streakDays ?? this.streakDays,
      gems: gems ?? this.gems,
      locale: locale ?? this.locale,
      tier: tier ?? this.tier,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
