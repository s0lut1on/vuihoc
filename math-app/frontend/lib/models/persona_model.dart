import 'package:flutter/material.dart';

enum Persona {
  achiever,
  struggler,
  gamer,
  silent;

  static Persona fromString(String value) {
    switch (value) {
      case 'struggler':
        return Persona.struggler;
      case 'gamer':
        return Persona.gamer;
      case 'silent':
        return Persona.silent;
      case 'achiever':
      default:
        return Persona.achiever;
    }
  }

  String get displayNameVi {
    switch (this) {
      case Persona.achiever:
        return 'Học giỏi';
      case Persona.struggler:
        return 'Cần động viên';
      case Persona.gamer:
        return 'Thích chơi game';
      case Persona.silent:
        return 'Nhút nhát';
    }
  }

  String get displayNameEn {
    switch (this) {
      case Persona.achiever:
        return 'High Achiever';
      case Persona.struggler:
        return 'Needs Encouragement';
      case Persona.gamer:
        return 'Loves Games';
      case Persona.silent:
        return 'Quiet Learner';
    }
  }

  String get emoji => switch (this) {
        Persona.achiever => '⭐',
        Persona.struggler => '💙',
        Persona.gamer => '🎮',
        Persona.silent => '🦉',
      };

  Color get backgroundColor => switch (this) {
        Persona.achiever => const Color(0xFFFFF3E0),
        Persona.struggler => const Color(0xFFE3F2FD),
        Persona.gamer => const Color(0xFFE8F5E9),
        Persona.silent => const Color(0xFFF3E5F5),
      };

  Color get textColor => switch (this) {
        Persona.achiever => const Color(0xFFE65100),
        Persona.struggler => const Color(0xFF1565C0),
        Persona.gamer => const Color(0xFF2E7D32),
        Persona.silent => const Color(0xFF7B1FA2),
      };
}
