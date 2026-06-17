import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/core/build_info.dart';

void main() {
  group('build_info', () {
    test('kBuildVersion defaults to "dev" when no APP_VERSION provided', () {
      // In the test runner, String.fromEnvironment returns the default
      // because the test binary is built without --dart-define=APP_VERSION.
      expect(kBuildVersion, equals('dev'));
    });

    test('kBuildVersion is a compile-time constant', () {
      // The fact that this compiles is the test — const can't reference
      // anything mutable.
      const v = kBuildVersion;
      expect(v.isNotEmpty, isTrue);
    });

    test('kIsDebugBuild has a stable bool value', () {
      expect(kIsDebugBuild, isA<bool>());
    });
  });
}
