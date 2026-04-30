import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb || !Platform.isAndroid
        ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'
        : null,
  );

  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) return false;

      final response = await ApiService().post('/auth/google', data: {
        'id_token': idToken,
      });

      final token = response['data']?['access_token'] as String?;
      if (token != null) {
        ApiService().setToken(token);
        await _persistToken(token);
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
  }

  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  Future<bool> silentSignIn() async {
    try {
      final storedToken = await _loadToken();
      if (storedToken != null) {
        ApiService().setToken(storedToken);
        return true;
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
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _persistToken(String token) async {
    final box = await Hive.openBox('auth');
    await box.put('token', token);
  }

  Future<String?> _loadToken() async {
    final box = await Hive.openBox('auth');
    return box.get('token') as String?;
  }
}
