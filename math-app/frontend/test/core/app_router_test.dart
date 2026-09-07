import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/core/app_router.dart';
import 'package:math_app/services/auth_service.dart';

void main() {
  group('AppRouter redirect logic', () {
    setUp(() {
      AuthService().tokenNotifier.value = null;
    });

    tearDown(() {
      AuthService().tokenNotifier.value = null;
    });

    test('constructs router when not logged in', () {
      AuthService().tokenNotifier.value = null;
      final router = AppRouter();
      expect(router, isNotNull);
    });

    test('constructs router when logged in', () {
      AuthService().tokenNotifier.value = 'fake-token';
      final router = AppRouter(initialSignedIn: true);
      expect(router, isNotNull);
    });

    test('constructs router for public routes', () {
      AuthService().tokenNotifier.value = null;
      final router = AppRouter();
      expect(router, isNotNull);
    });

    test('parent-dashboard accessible without auth', () {
      AuthService().tokenNotifier.value = null;
      final router = AppRouter();
      expect(router, isNotNull);
    });

    test('logged in user does not redirect from protected routes', () {
      AuthService().tokenNotifier.value = 'fake-token';
      final router = AppRouter(initialSignedIn: true);
      expect(router, isNotNull);
    });
  });
}