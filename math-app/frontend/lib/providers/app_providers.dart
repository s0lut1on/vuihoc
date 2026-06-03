import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/persona_model.dart';
import '../models/user_model.dart';
import '../models/lesson_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/user_api.dart';
import '../services/content_api.dart';
import '../services/progress_api.dart';

final apiServiceProvider =
    Provider<ApiService>((ref) => ApiService()..initialize());

final localeProvider = StateProvider<Locale>((ref) => const Locale('vi', 'VN'));

final ttsEnabledProvider = StateProvider<bool>((ref) => true);

final personaProvider = StateProvider<Persona?>((ref) => null);

final userIdProvider = StateProvider<String?>((ref) => null);

final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<User?>>(
    (ref) => UserNotifier(ref));

/// Rebuilds whenever token changes (login/logout).
final authUserProvider = Provider<String?>((ref) {
  final notifier = AuthService().tokenNotifier;
  notifier.addListener(ref.notifyListeners);
  ref.onDispose(() => notifier.removeListener(ref.notifyListeners));
  return notifier.value;
});

final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  // Rebuild whenever token changes (login/logout)
  final token = ref.watch(authUserProvider);
  if (token != null) {
    ApiService().setToken(token);
  }
  return AuthService().getCurrentUser();
});

/// User subscription tier derived from /auth/me (free or premium).
final currentUserTierProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.value?['tier'] as String? ?? 'free';
});

final curriculumProvider =
    FutureProvider.family<List<ApiLesson>, int>((ref, grade) => ContentApi.getCurriculum(grade: grade));

final subjectsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>(
    (ref, grade) => ContentApi.getSubjects(grade: grade));

/// Loads the user's progress (completed lesson IDs) from the backend.
/// Auto-refreshes when userId changes.
final userProgressProvider = FutureProvider<Set<String>>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null || userId.isEmpty) return {};
  final rows = await ProgressApi.getUserProgress(userId);
  return rows
      .where((r) => r['completed'] == true)
      .map((r) => r['lesson_id'] as String)
      .toSet();
});

class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;

  UserNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> loadUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final user = await UserApi.getUser(userId);
      _ref.read(personaProvider.notifier).state = user.persona;
      _ref.read(userIdProvider.notifier).state = user.id;
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createUser({
    required String name,
    required Persona persona,
    String locale = 'vi_VN',
    int grade = 1,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await UserApi.createUser(
        name: name,
        persona: persona.name,
        locale: locale,
        grade: grade,
      );
      _ref.read(personaProvider.notifier).state = user.persona;
      _ref.read(userIdProvider.notifier).state = user.id;
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Computes the next lesson the child should play.
/// Returns {subjectId, lessonId} for the first unlocked-but-uncompleted lesson.
final nextLessonProvider = FutureProvider<Map<String, String>?>((ref) async {
  final user = ref.watch(userProvider).value;
  final grade = user?.grade ?? 1;
  final lessons = await ref.watch(curriculumProvider(grade).future);
  final completed = await ref.watch(userProgressProvider.future);

  const subjectOrder = ['numbers', 'geometry', 'measurement', 'logic'];
  for (final subjectId in subjectOrder) {
    final subjectLessons = lessons
        .where((l) => l.subjectId == subjectId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    for (int i = 0; i < subjectLessons.length; i++) {
      final lesson = subjectLessons[i];
      final isUnlocked = i == 0 || completed.contains(subjectLessons[i - 1].id);
      if (isUnlocked && !completed.contains(lesson.id)) {
        return {'subjectId': subjectId, 'lessonId': lesson.id};
      }
    }
  }
  return null;
});

/// Total stars earned across all completed lessons.
final totalStarsProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null || userId.isEmpty) return 0;
  final rows = await ProgressApi.getUserProgress(userId);
  return rows.fold<int>(0, (sum, r) => sum + ((r['stars'] as int?) ?? 0));
});

final onboardingCompletedProvider = StateProvider<bool>((ref) => false);

final currentSubjectProvider = StateProvider<String>((ref) => 'numbers');
