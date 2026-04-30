import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:math_app/services/local_storage_service.dart';
import 'package:math_app/models/user_model.dart';
import 'package:math_app/models/persona_model.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('LocalStorageService', () {
    test('save and retrieve user', () async {
      final user = User(
        id: 'u_test',
        name: 'Be An',
        persona: Persona.gamer,
        totalStars: 5,
        gems: 100,
        createdAt: DateTime(2024, 1, 15),
      );

      await LocalStorageService.saveUser(user);
      final retrieved = await LocalStorageService.getUser();
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Be An');
      expect(retrieved.persona, Persona.gamer);
      expect(retrieved.totalStars, 5);
      expect(retrieved.gems, 100);
    });

    test('getUser returns null when no user stored', () async {
      final user = await LocalStorageService.getUser();
      expect(user, isNull);
    });

    test('onboarding completion persists', () async {
      expect(await LocalStorageService.isOnboardingComplete(), isFalse);
      await LocalStorageService.saveOnboardingComplete();
      expect(await LocalStorageService.isOnboardingComplete(), isTrue);
    });

    test('locale defaults to vi_VN', () async {
      final locale = await LocalStorageService.getLocale();
      expect(locale, 'vi_VN');
    });

    test('save and retrieve locale', () async {
      await LocalStorageService.saveLocale('en_US');
      final locale = await LocalStorageService.getLocale();
      expect(locale, 'en_US');
    });
  });
}
