import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/providers/app_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('localeProvider', () {
    test('defaults to vi_VN', () {
      expect(container.read(localeProvider), const Locale('vi', 'VN'));
    });

    test('can be set to en_US', () {
      container.read(localeProvider.notifier).state = const Locale('en', 'US');
      expect(container.read(localeProvider), const Locale('en', 'US'));
    });
  });

  group('ttsEnabledProvider', () {
    test('defaults to true', () {
      expect(container.read(ttsEnabledProvider), isTrue);
    });

    test('can be set to false', () {
      container.read(ttsEnabledProvider.notifier).state = false;
      expect(container.read(ttsEnabledProvider), isFalse);
    });
  });

  group('personaProvider', () {
    test('defaults to null', () {
      expect(container.read(personaProvider), isNull);
    });
  });

  group('userIdProvider', () {
    test('defaults to null', () {
      expect(container.read(userIdProvider), isNull);
    });

    test('can be set', () {
      container.read(userIdProvider.notifier).state = 'user-123';
      expect(container.read(userIdProvider), 'user-123');
    });
  });

  group('onboardingCompletedProvider', () {
    test('defaults to false', () {
      expect(container.read(onboardingCompletedProvider), isFalse);
    });

    test('can be set to true', () {
      container.read(onboardingCompletedProvider.notifier).state = true;
      expect(container.read(onboardingCompletedProvider), isTrue);
    });
  });

  group('currentSubjectProvider', () {
    test('defaults to numbers', () {
      expect(container.read(currentSubjectProvider), 'numbers');
    });

    test('can be set to geometry', () {
      container.read(currentSubjectProvider.notifier).state = 'geometry';
      expect(container.read(currentSubjectProvider), 'geometry');
    });
  });

  group('audioMutedProvider', () {
    test('defaults to false', () {
      expect(container.read(audioMutedProvider), isFalse);
    });

    test('can be toggled to true', () {
      container.read(audioMutedProvider.notifier).state = true;
      expect(container.read(audioMutedProvider), isTrue);
    });
  });

  group('dailyReminderEnabledProvider', () {
    test('defaults to true', () {
      expect(container.read(dailyReminderEnabledProvider), isTrue);
    });

    test('can be set to false', () {
      container.read(dailyReminderEnabledProvider.notifier).state = false;
      expect(container.read(dailyReminderEnabledProvider), isFalse);
    });
  });

  group('unlockAnimationsEnabledProvider', () {
    test('defaults to true', () {
      expect(container.read(unlockAnimationsEnabledProvider), isTrue);
    });

    test('can be set to false', () {
      container.read(unlockAnimationsEnabledProvider.notifier).state = false;
      expect(container.read(unlockAnimationsEnabledProvider), isFalse);
    });
  });
}