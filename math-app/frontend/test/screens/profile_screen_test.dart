import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/persona_model.dart';
import 'package:math_app/models/user_model.dart';
import 'package:math_app/providers/app_providers.dart';

void main() {
  group('UserNotifier (grade change fix)', () {
    test('setUser pushes new User into state immediately', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial: null
      expect(container.read(userProvider).valueOrNull, isNull);

      // Push grade-1 user
      final u1 = User(
        id: 'u1',
        name: 'Bé',
        persona: Persona.achiever,
        createdAt: DateTime.now(),
      );
      container.read(userProvider.notifier).setUser(u1);
      expect(container.read(userProvider).valueOrNull?.grade, 1);

      // Push grade-2 user (mimics the updateGrade flow)
      final u2 = u1.copyWith(grade: 2);
      container.read(userProvider.notifier).setUser(u2);

      // The UI sees grade=2 immediately — this is what was broken.
      expect(container.read(userProvider).valueOrNull?.grade, 2);
    });

    test('setUser pushes new grade immediately and survives invalidate', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial: grade 1
      final u1 = User(
        id: 'u1',
        name: 'Bé',
        persona: Persona.achiever,
        grade: 1,
        createdAt: DateTime.now(),
      );
      container.read(userProvider.notifier).setUser(u1);
      expect(container.read(userProvider).valueOrNull?.grade, 1);

      // User taps grade 2 — profile_screen flow:
      //   1. updateGrade returns new User
      //   2. setUser(newUser)
      final u2 = u1.copyWith(grade: 2);
      container.read(userProvider.notifier).setUser(u2);

      // The UI sees grade=2 immediately.
      expect(container.read(userProvider).valueOrNull?.grade, 2);

      // Downstream providers can still be invalidated for the new grade
      // (curriculum, subjects, progress). These DON'T touch userProvider.
      container.invalidate(curriculumProvider(2));
      container.invalidate(subjectsProvider(2));
      container.invalidate(rawProgressProvider);

      // userProvider value is preserved because we never invalidated it.
      expect(container.read(userProvider).valueOrNull?.grade, 2);
    });

    test('curriculum + subjects family providers can be invalidated safely', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Just ensure the invalidation calls don't crash.
      container.invalidate(curriculumProvider(2));
      container.invalidate(subjectsProvider(2));
      container.invalidate(rawProgressProvider);
      expect(true, isTrue);
    });
  });
}
