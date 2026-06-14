import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // Register silent-refresh hook with the API layer so Dio can refresh
    // expiring tokens before requests and on 401.
    ApiService().setTokenRefresher(refreshTokenSilently);
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: kIsWeb || !Platform.isAndroid
        ? const String.fromEnvironment(
            'GOOGLE_CLIENT_ID',
            defaultValue: '',
          )
        : null,
  );

  /// Notifies listeners whenever the auth token changes (login/logout/refresh).
  final ValueNotifier<String?> tokenNotifier = ValueNotifier<String?>(null);

  /// Single in-flight refresh; concurrent callers await the same future.
  Future<String?>? _pendingRefresh;

  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;

      Map<String, dynamic> payload;
      if (idToken != null) {
        payload = {'id_token': idToken};
      } else if (accessToken != null) {
        // On web google_sign_in returns access_token instead of id_token
        payload = {'access_token': accessToken};
      } else {
        return false;
      }

      final response = await ApiService().post('/auth/google', data: payload);

      final token = response['data']?['access_token'] as String?;
      if (token != null) {
        ApiService().setToken(token);
        await _persistToken(token);
        await _persistTokenType('google');
        tokenNotifier.value = token;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signInAsGuest() async {
    try {
      final response = await ApiService().post('/auth/guest', data: {});
      final token = response['data']?['access_token'] as String?;
      if (token != null) {
        ApiService().setToken(token);
        await _persistToken(token);
        await _persistTokenType('guest');
        tokenNotifier.value = token;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    ApiService().clearToken();
    final box = await Hive.openBox('auth');
    await box.delete('token');
    await box.delete('token_type');
    tokenNotifier.value = null;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await ApiService().get('/auth/me');
      return response['data'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isSignedIn() async {
    final storedToken = await _loadToken();
    if (storedToken != null) return true;
    return await _googleSignIn.isSignedIn();
  }

  Future<bool> silentSignIn() async {
    try {
      final storedToken = await _loadToken();
      if (storedToken != null) {
        ApiService().setToken(storedToken);
        final user = await getCurrentUser();
        if (user != null) {
          tokenNotifier.value = storedToken;
          return true;
        }
        await signOut();
      }

      final account = await _googleSignIn.signInSilently();
      if (account == null) return false;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken != null) {
        final response = await ApiService().post('/auth/google', data: {
          'id_token': idToken,
        });
        final token = response['data']?['access_token'] as String?;
        if (token != null) {
          ApiService().setToken(token);
          await _persistToken(token);
          await _persistTokenType('google');
          tokenNotifier.value = token;
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Silently obtain a new JWT. Coalesces concurrent callers.
  /// Returns the new token, or null if refresh failed (caller should sign out).
  Future<String?> refreshTokenSilently() async {
    if (_pendingRefresh != null) return _pendingRefresh!;
    final completer = Completer<String?>();
    _pendingRefresh = completer.future;
    try {
      final type = await _loadTokenType();
      String? newToken;
      if (type == 'google') {
        newToken = await _refreshGoogle();
      } else {
        newToken = await _refreshGuest();
      }
      if (newToken != null) {
        ApiService().setToken(newToken);
        await _persistToken(newToken);
        tokenNotifier.value = newToken;
      }
      completer.complete(newToken);
      return newToken;
    } catch (e) {
      completer.complete(null);
      return null;
    } finally {
      _pendingRefresh = null;
    }
  }

  Future<String?> _refreshGoogle() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return null;
      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      final Map<String, dynamic> payload;
      if (idToken != null) {
        payload = {'id_token': idToken};
      } else if (accessToken != null) {
        payload = {'access_token': accessToken};
      } else {
        return null;
      }
      final response =
          await ApiService().post('/auth/google', data: payload);
      return response['data']?['access_token'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _refreshGuest() async {
    try {
      final response = await ApiService().post('/auth/guest', data: {});
      return response['data']?['access_token'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistToken(String token) async {
    final box = await Hive.openBox('auth');
    await box.put('token', token);
  }

  Future<void> _persistTokenType(String type) async {
    final box = await Hive.openBox('auth');
    await box.put('token_type', type);
  }

  Future<String?> _loadToken() async {
    final box = await Hive.openBox('auth');
    return box.get('token') as String?;
  }

  Future<String?> _loadTokenType() async {
    final box = await Hive.openBox('auth');
    return box.get('token_type') as String?;
  }
}
