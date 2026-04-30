import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/persona_model.dart';
import 'package:flutter/material.dart';

void main() {
  group('Persona', () {
    test('achiever has correct emoji and colors', () {
      expect(Persona.achiever.emoji, equals('⭐'));
      expect(Persona.achiever.displayNameVi, equals('Học giỏi'));
      expect(Persona.achiever.displayNameEn, equals('High Achiever'));
      expect(Persona.achiever.backgroundColor, equals(const Color(0xFFFFF3E0)));
      expect(Persona.achiever.textColor, equals(const Color(0xFFE65100)));
    });

    test('struggler has correct emoji and colors', () {
      expect(Persona.struggler.emoji, equals('💙'));
      expect(Persona.struggler.displayNameVi, equals('Cần động viên'));
      expect(Persona.struggler.displayNameEn, equals('Needs Encouragement'));
      expect(
          Persona.struggler.backgroundColor, equals(const Color(0xFFE3F2FD)));
      expect(Persona.struggler.textColor, equals(const Color(0xFF1565C0)));
    });

    test('gamer has correct emoji and colors', () {
      expect(Persona.gamer.emoji, equals('🎮'));
      expect(Persona.gamer.displayNameVi, equals('Thích chơi game'));
      expect(Persona.gamer.displayNameEn, equals('Loves Games'));
      expect(Persona.gamer.backgroundColor, equals(const Color(0xFFE8F5E9)));
      expect(Persona.gamer.textColor, equals(const Color(0xFF2E7D32)));
    });

    test('silent has correct emoji and colors', () {
      expect(Persona.silent.emoji, equals('🦉'));
      expect(Persona.silent.displayNameVi, equals('Nhút nhát'));
      expect(Persona.silent.displayNameEn, equals('Quiet Learner'));
      expect(Persona.silent.backgroundColor, equals(const Color(0xFFF3E5F5)));
      expect(Persona.silent.textColor, equals(const Color(0xFF7B1FA2)));
    });

    test('fromString parses correctly', () {
      expect(Persona.fromString('achiever'), Persona.achiever);
      expect(Persona.fromString('gamer'), Persona.gamer);
      expect(Persona.fromString('struggler'), Persona.struggler);
      expect(Persona.fromString('silent'), Persona.silent);
      expect(Persona.fromString('unknown'), Persona.achiever);
    });
  });
}
