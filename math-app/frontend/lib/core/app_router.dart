import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/login_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/assessment_screen.dart';
import '../screens/home_screen.dart';
import '../screens/lesson_screen.dart';
import '../screens/celebration_screen.dart';
import '../screens/pin_gate_screen.dart';
import '../screens/subject_screen.dart';
import '../screens/parent_dashboard_screen.dart';
import '../screens/profile_screen.dart';

class AppRouter {
  final bool initialSignedIn;

  AppRouter({this.initialSignedIn = false});

  late final GoRouter _router = GoRouter(
    initialLocation: initialSignedIn ? '/home' : '/login',
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
        path: '/subject/:subjectId',
        builder: (context, state) {
          final subjectId = state.pathParameters['subjectId']!;
          return SubjectScreen(subjectId: subjectId);
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
    ],
  );

  RouterDelegate<Object> get routerDelegate => _router.routerDelegate;
  RouteInformationParser<Object> get routeInformationParser =>
      _router.routeInformationParser;
  RouteInformationProvider get routeInformationProvider =>
      _router.routeInformationProvider;
}
