import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/assessment_screen.dart';
import '../screens/home_screen.dart';
import '../screens/lesson_screen.dart';
import '../screens/celebration_screen.dart';
import '../screens/pin_gate_screen.dart';
import '../screens/subject_screen.dart';
import '../screens/parent_dashboard_screen.dart';
import '../screens/pricing_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/review_screen.dart';
import '../screens/achievement_screen.dart';
import '../screens/language_lesson_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/admin_dashboard_screen.dart';

/// Public routes that do NOT require authentication.
const _publicRoutes = {
  '/login',
  '/welcome',
  '/parent-dashboard',
};

class AppRouter {
  final bool initialSignedIn;

  AppRouter({this.initialSignedIn = false});

  late final GoRouter _router = GoRouter(
    initialLocation: initialSignedIn ? '/home' : '/login',
    redirect: (context, state) {
      final token = AuthService().tokenNotifier.value;
      final isLoggedIn = token != null && token.isNotEmpty;
      final path = state.path ?? '';
      final isPublic = _publicRoutes.contains(path);

      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && path == '/login') return '/home';
      return null;
    },
    refreshListenable: _GoRouterRefreshStream(AuthService().tokenNotifier),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/assessment',
        builder: (context, state) => const AssessmentScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/pricing',
        builder: (context, state) => const PricingScreen(),
      ),
      GoRoute(
        path: '/subject/:subjectId',
        builder: (context, state) {
          final subjectId = state.pathParameters['subjectId']!;
          return SubjectScreen(subjectId: subjectId);
        },
      ),
      GoRoute(
        path: '/subject/:subjectId/:subSubjectId',
        builder: (context, state) {
          final subjectId = state.pathParameters['subjectId']!;
          final subSubjectId = state.pathParameters['subSubjectId']!;
          return SubjectScreen(
              subjectId: subjectId, subSubjectId: subSubjectId);
        },
      ),
      GoRoute(
        path: '/lesson/:subjectId/:lessonId',
        builder: (context, state) {
          final subjectId = state.pathParameters['subjectId']!;
          final lessonId = state.pathParameters['lessonId']!;
          return LessonScreen(subjectId: subjectId, lessonId: lessonId);
        },
      ),
      GoRoute(
        path: '/language-lesson/:subjectId/:lessonId',
        builder: (context, state) {
          final subjectId = state.pathParameters['subjectId']!;
          final lessonId = state.pathParameters['lessonId']!;
          return LanguageLessonScreen(subjectId: subjectId, lessonId: lessonId);
        },
      ),
      GoRoute(
        path: '/celebration',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CelebrationScreen(
            stars: extra?['stars'] ?? 1,
            persona: extra?['persona'] ?? 'achiever',
            subjectId: extra?['subjectId'] as String?,
            lessonId: extra?['lessonId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/parent-dashboard',
        builder: (context, state) => const PinGateScreen(),
      ),
      GoRoute(
        path: '/parent-dashboard/main',
        builder: (context, state) => const ParentDashboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => const ReviewScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );

  RouterDelegate<Object> get routerDelegate => _router.routerDelegate;
  RouteInformationParser<Object> get routeInformationParser =>
      _router.routeInformationParser;
  RouteInformationProvider get routeInformationProvider =>
      _router.routeInformationProvider;
}

/// Bridge between ValueNotifier and GoRouter's refreshListenable.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(ValueNotifier<String?> notifier) {
    notifier.addListener(_onChange);
  }

  void _onChange() => notifyListeners();
}
