import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final String baseUrl;
  late Dio _dio;
  static String? _token;

  ApiService._internal({this.baseUrl = '/api'}) {
    final resolvedBase = kIsWeb ? baseUrl : 'http://localhost$baseUrl';
    _dio = Dio(BaseOptions(
      baseUrl: resolvedBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        options.headers['Content-Type'] = 'application/json';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException error, handler) {
        return handler.next(error);
      },
    ));
  }

  void initialize({Dio? dio}) {
    if (dio != null) {
      _dio = dio;
    }
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

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParams}) async {
    final response = await _dio.get(path, queryParameters: queryParams);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? data}) async {
    final response = await _dio.post(path, data: data);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await _dio.delete(path);
    return _parseResponse(response);
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

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
