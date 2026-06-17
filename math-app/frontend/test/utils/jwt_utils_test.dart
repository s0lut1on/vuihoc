import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/utils/jwt_utils.dart';

/// Build a JWT with the given payload (no real signature, just for tests).
String makeJwt(Map<String, dynamic> payload) {
  String b64(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${b64({'alg': 'none'})}.${b64(payload)}.sig';
}

void main() {
  group('JwtUtil', () {
    test('decode returns null for null/empty/malformed', () {
      expect(JwtUtil.decode(null), isNull);
      expect(JwtUtil.decode(''), isNull);
      expect(JwtUtil.decode('not-a-jwt'), isNull);
      expect(JwtUtil.decode('a.b'), isNull);
    });

    test('decode returns payload for valid JWT', () {
      final jwt = makeJwt({'sub': 'u1', 'exp': 9999999999});
      final payload = JwtUtil.decode(jwt);
      expect(payload, isNotNull);
      expect(payload!['sub'], 'u1');
      expect(payload['exp'], 9999999999);
    });

    test('isExpired true for past exp, false for future', () {
      final past =
          makeJwt({'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60});
      final future = makeJwt(
          {'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600});
      expect(JwtUtil.isExpired(past), true);
      expect(JwtUtil.isExpired(future), false);
    });

    test('isExpired true when exp claim missing', () {
      final jwt = makeJwt({'sub': 'u1'});
      expect(JwtUtil.isExpired(jwt), true);
    });

    test('isExpiringSoon with default 60s threshold', () {
      final in30s =
          makeJwt({'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 30});
      final in5min =
          makeJwt({'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300});
      expect(JwtUtil.isExpiringSoon(in30s), true);
      expect(JwtUtil.isExpiringSoon(in5min), false);
    });

    test('isExpiringSoon respects custom threshold', () {
      final in3min =
          makeJwt({'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 180});
      expect(JwtUtil.isExpiringSoon(in3min), false);
      expect(
        JwtUtil.isExpiringSoon(in3min, threshold: const Duration(minutes: 5)),
        true,
      );
    });

    test('getExpiration returns null for missing exp', () {
      expect(JwtUtil.getExpiration(makeJwt({'sub': 'x'})), isNull);
    });
  });
}
