import 'dart:convert';

/// JWT payload reader. Decodes the payload (middle segment) without
/// verifying the signature — verification is the server's job.
class JwtUtil {
  JwtUtil._();

  /// Decode the payload of a JWT. Returns null if malformed.
  static Map<String, dynamic>? decode(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      var normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decoded = utf8.decode(base64.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) return json;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// `exp` claim as DateTime, or null if missing/malformed.
  static DateTime? getExpiration(String? token) {
    final payload = decode(token);
    if (payload == null) return null;
    final exp = payload['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
  }

  /// True if token is missing, malformed, or already expired.
  static bool isExpired(String? token) {
    final exp = getExpiration(token);
    if (exp == null) return true;
    return !DateTime.now().isBefore(exp);
  }

  /// True if token is expired OR expiring within [threshold].
  static bool isExpiringSoon(
    String? token, {
    Duration threshold = const Duration(seconds: 60),
  }) {
    final exp = getExpiration(token);
    if (exp == null) return true;
    return !DateTime.now().add(threshold).isBefore(exp);
  }
}
