import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final String baseUrl;
  late Dio _dio;
  static String? _token;

  /// Called by the Dio interceptor to silently refresh the JWT on a 401
  /// response. Set via [setTokenRefresher]. Returns the new token, or
  /// null on failure.
  ///
  /// Note: proactive refresh (5 min before expiry) is handled by
  /// [AuthService._scheduleProactiveRefresh] — this hook is only the
  /// 401 fallback for edge cases (device asleep, clock skew, etc.).
  Future<String?> Function()? _tokenRefresher;

  /// Reference to our own interceptor so we can remove it on re-setup
  /// without disturbing caller-supplied ones.
  Interceptor? _authInterceptor;

  ApiService._internal({this.baseUrl = '/api'}) {
    final resolvedBase = kIsWeb ? baseUrl : 'http://localhost$baseUrl';
    _dio = Dio(BaseOptions(
      baseUrl: resolvedBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Idempotent: only our own interceptor is removed, so any
    // caller-supplied interceptors (e.g. test mocks) stay intact.
    if (_authInterceptor != null) {
      _dio.interceptors.remove(_authInterceptor);
    }
    _authInterceptor = InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: (response, handler) => handler.next(response),
      onError: _onError,
    );
    _dio.interceptors.add(_authInterceptor!);
  }

  Future<void> _onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (_token != null) {
      options.headers['Authorization'] = 'Bearer $_token';
    }
    options.headers['Content-Type'] = 'application/json';
    return handler.next(options);
  }

  Future<void> _onError(
      DioException error, ErrorInterceptorHandler handler) async {
    final status = error.response?.statusCode;
    final retried = error.requestOptions.extra['_retried'] == true;
    if (status == 401 &&
        _tokenRefresher != null &&
        !retried &&
        !error.requestOptions.path.contains('/auth/')) {
      final fresh = await _tokenRefresher!();
      if (fresh != null) {
        final newReq = error.requestOptions;
        newReq.headers['Authorization'] = 'Bearer $fresh';
        newReq.extra['_retried'] = true;
        try {
          final response = await _dio.fetch(newReq);
          return handler.resolve(response);
        } catch (_) {
          return handler.next(error);
        }
      }
    }
    return handler.next(error);
  }

  void initialize({Dio? dio}) {
    if (dio != null) {
      _dio = dio;
    }
    _setupInterceptors();
  }

  factory ApiService.withBaseUrl(String baseUrl) {
    return ApiService._internal(baseUrl: baseUrl);
  }

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  String? get token => _token;

  void setTokenRefresher(Future<String?> Function()? refresher) {
    _tokenRefresher = refresher;
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return _parseResponse(response);
    } on DioException catch (e) {
      throw ApiException(
          'HTTP ${e.response?.statusCode ?? '???'}: ${e.message ?? ''}');
    }
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return _parseResponse(response);
    } on DioException catch (e) {
      throw ApiException(
          'HTTP ${e.response?.statusCode ?? '???'}: ${e.message ?? ''}');
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return _parseResponse(response);
    } on DioException catch (e) {
      throw ApiException(
          'HTTP ${e.response?.statusCode ?? '???'}: ${e.message ?? ''}');
    }
  }

  Map<String, dynamic> _parseResponse(Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data is Map) {
        final body = response.data as Map<String, dynamic>;
        final success = body['success'] as bool? ?? true;
        if (success) {
          return body;
        }
        throw ApiException(body['error'] as String? ?? 'API error');
      }
      return {'success': true, 'data': response.data};
    }
    throw ApiException('HTTP ${response.statusCode}');
  }
}

/// Marker type so we can identify and remove our own interceptor
/// without disturbing caller-supplied ones.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
