import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/services/daily_limit.dart';

void main() {
  group('shouldShowPaywall', () {
    test('free user with 0 lessons today — no paywall', () {
      expect(shouldShowPaywall(count: 0, tier: 'free'), isFalse);
    });

    test('free user with 49 lessons today — no paywall (just under cap)', () {
      expect(shouldShowPaywall(count: 49, tier: 'free'), isFalse);
    });

    test('free user at 50 lessons — paywall', () {
      expect(shouldShowPaywall(count: 50, tier: 'free'), isTrue);
    });

    test('free user past 50 — paywall (no over-cap relief)', () {
      expect(shouldShowPaywall(count: 100, tier: 'free'), isTrue);
    });

    test('premium user at 50 — no paywall', () {
      expect(shouldShowPaywall(count: 50, tier: 'premium'), isFalse);
    });

    test('premium user at 1000 — no paywall', () {
      expect(shouldShowPaywall(count: 1000, tier: 'premium'), isFalse);
    });

    test('unknown tier treated as free', () {
      expect(shouldShowPaywall(count: 50, tier: 'pro'), isTrue,
          reason: 'Unknown tier must not bypass the cap');
    });

    test('empty tier treated as free', () {
      expect(shouldShowPaywall(count: 50, tier: ''), isTrue);
    });
  });
}
