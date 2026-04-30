import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/user_model.dart';
import 'package:math_app/models/persona_model.dart';

void main() {
  group('User', () {
    test('default values are set correctly', () {
      final user = User(
        id: 'u1',
        name: 'Be An',
        createdAt: DateTime(2024, 1, 15),
      );
      expect(user.id, 'u1');
      expect(user.name, 'Be An');
      expect(user.persona, Persona.achiever);
      expect(user.avatar, '🐸');
      expect(user.totalLessons, 0);
      expect(user.totalStars, 0);
      expect(user.streakDays, 0);
      expect(user.gems, 0);
      expect(user.locale, 'vi_VN');
    });

    test('fromJson parses correctly', () {
      final jsonUser = {
        'id': 'u2',
        'name': 'Be Minh',
        'persona': 'gamer',
        'avatar': '🎮',
        'total_lessons': 5,
        'total_stars': 12,
        'streak_days': 3,
        'gems': 100,
        'locale': 'en_US',
        'created_at': '2024-03-15T10:30:00Z',
      };
      final user = User.fromJson(jsonUser);
      expect(user.id, 'u2');
      expect(user.name, 'Be Minh');
      expect(user.persona, Persona.gamer);
      expect(user.avatar, '🎮');
      expect(user.totalLessons, 5);
      expect(user.totalStars, 12);
      expect(user.streakDays, 3);
      expect(user.gems, 100);
      expect(user.locale, 'en_US');
    });

    test('fromJson handles null values with defaults', () {
      final json = {'id': '', 'name': '', 'created_at': ''};
      final user = User.fromJson(json);
      expect(user.persona, Persona.achiever);
      expect(user.avatar, '🐸');
      expect(user.totalLessons, 0);
      expect(user.locale, 'vi_VN');
    });

    test('copyWith preserves unchanged fields', () {
      final user = User(
        id: 'u1',
        name: 'Be An',
        totalStars: 10,
        createdAt: DateTime.now(),
      );
      final updated = user.copyWith(totalStars: 15);
      expect(updated.id, 'u1');
      expect(updated.name, 'Be An');
      expect(updated.totalStars, 15);
      expect(updated.persona, Persona.achiever);
    });

    test('copyWith updates persona', () {
      final user = User(
        id: 'u1',
        name: 'Be An',
        createdAt: DateTime.now(),
      );
      final updated = user.copyWith(persona: Persona.silent);
      expect(updated.persona, Persona.silent);
    });
  });
}
