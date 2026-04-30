import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/persona_model.dart';
import '../models/user_model.dart';
import '../models/lesson_model.dart';
import '../services/api_service.dart';
import '../services/user_api.dart';
import '../services/content_api.dart';

final apiServiceProvider =
    Provider<ApiService>((ref) => ApiService()..initialize());

final localeProvider = StateProvider<Locale>((ref) => const Locale('vi', 'VN'));

final personaProvider = StateProvider<Persona?>((ref) => null);

final userIdProvider = StateProvider<String?>((ref) => null);

final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<User?>>(
    (ref) => UserNotifier(ref));

final curriculumProvider =
    FutureProvider<List<ApiLesson>>((ref) => ContentApi.getCurriculum());

final subjectsProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ContentApi.getSubjects());

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
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await UserApi.createUser(
        name: name,
        persona: persona.name,
        locale: locale,
      );
      _ref.read(personaProvider.notifier).state = user.persona;
      _ref.read(userIdProvider.notifier).state = user.id;
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final onboardingCompletedProvider = StateProvider<bool>((ref) => false);

final currentSubjectProvider = StateProvider<String>((ref) => 'numbers');
