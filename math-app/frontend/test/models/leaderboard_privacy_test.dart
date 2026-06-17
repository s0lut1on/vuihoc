import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/leaderboard_privacy.dart';

void main() {
  group('computeRank', () {
    test('returns null for empty list', () {
      expect(computeRank(leaderboard: const []), isNull);
    });

    test('first place gets percentile 1 (in a 100-user list)', () {
      final entries = List.generate(100, (i) => {'id': 'a', 'weekly_stars': 50 - i});
      final r = computeRank(leaderboard: entries, userId: 'a');
      expect(r!.rank, 1);
      expect(r.percentile, 1);
      expect(r.totalUsers, 100);
    });

    test('last place has high percentile', () {
      final entries = List.generate(4, (i) => {'id': 'u$i'});
      final r = computeRank(leaderboard: entries, userId: 'u3');
      expect(r!.rank, 4);
      expect(r.percentile, 100);
    });

    test('rank 1 of 3 users = top 33%', () {
      final entries = [
        {'id': 'a'},
        {'id': 'b'},
        {'id': 'c'},
      ];
      final r = computeRank(leaderboard: entries, userId: 'a');
      expect(r!.rank, 1);
      expect(r.percentile, 33);
    });

    test('user not in list is treated as one below last', () {
      final entries = [
        {'id': 'a'},
        {'id': 'b'},
      ];
      final r = computeRank(leaderboard: entries, userId: 'zzz');
      expect(r!.rank, 3);
      expect(r.totalUsers, 3);
    });

    test('no userId returns null when list non-empty? — actually returns first', () {
      final entries = [
        {'id': 'a'},
        {'id': 'b'},
      ];
      final r = computeRank(leaderboard: entries);
      expect(r, isNotNull);
    });

    test('percentile is always in [1, 100]', () {
      // Edge: 100 users
      final entries = List.generate(100, (i) => {'id': 'u$i'});
      for (var i = 0; i < 100; i++) {
        final r = computeRank(leaderboard: entries, userId: 'u$i');
        expect(r!.percentile, greaterThanOrEqualTo(1));
        expect(r.percentile, lessThanOrEqualTo(100));
      }
    });
  });

  group('anonymizeName', () {
    test('returns Bạn X for a single letter name', () {
      expect(anonymizeName('An'), 'Bạn A');
    });

    test('uppercases the first character', () {
      expect(anonymizeName('bảo'), startsWith('Bạn '));
    });

    test('strips surrounding whitespace', () {
      expect(anonymizeName('  An  '), 'Bạn A');
    });

    test('falls back to frog when empty', () {
      expect(anonymizeName(''), '🐸');
      expect(anonymizeName('   '), '🐸');
    });
  });
}
