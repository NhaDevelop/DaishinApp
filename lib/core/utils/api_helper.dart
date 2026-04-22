import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiHelper {
  // Singleton instance
  static final ApiHelper _instance = ApiHelper._privateConstructor();
  static ApiHelper get instance => _instance;

  // Use API constants instead of dotenv
  final String baseUrl = ApiConstants.baseUrl;

  // Add base URL for images (without /api suffix)
  String get imageBaseUrl {
    // Remove '/api' from the end if it exists for image URLs
    return baseUrl.endsWith('/api')
        ? baseUrl.substring(0, baseUrl.length - 4)
        : baseUrl;
  }

  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final Dio dio = Dio(
    BaseOptions(
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(milliseconds: ApiConstants.timeoutDuration),
      receiveTimeout: const Duration(milliseconds: ApiConstants.timeoutDuration),
    ),
  );

  final _unauthenticatedController = StreamController<void>.broadcast();
  Stream<void> get onUnauthenticated => _unauthenticatedController.stream;

  final _noNetworkController = StreamController<void>.broadcast();
  Stream<void> get onNoNetwork => _noNetworkController.stream;

  final _networkStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onNetworkStatusChanged => _networkStatusController.stream;

  ApiHelper._privateConstructor() {
    // Dio interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available AND not already set
          // This prevents overwriting Basic Auth during login
          if (!options.headers.containsKey('Authorization')) {
            final token = await storage.read(key: 'auth_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            _noNetworkController.add(null);
            _networkStatusController.add(false);
            return handler.resolve(
              Response(
                requestOptions: e.requestOptions,
                data: {'cancelled': true},
              ),
            );
          }
          if (e.response?.statusCode == 401) {
            _unauthenticatedController.add(null);
          }
          return handler.next(e);
        },
      ),
    );

    // Watch for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      hasNetwork().then((hasNet) {
        _networkStatusController.add(hasNet);
      });
    });
  }

  /// Check for internet access
  Future<bool> hasNetwork() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    // Check if there's no network connection
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    try {
      final result = await InternetAddress.lookup('google.com');
      final hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      return hasInternet;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Get full image URL from relative path
  String getImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';

    // If it's already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Remove leading slash if present to avoid double slashes
    final cleanPath =
        imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;

    // Construct full URL using imageBaseUrl
    return '$imageBaseUrl/$cleanPath';
  }

  /// Alternative method for more explicit image URL construction
  String buildImageUrl(String relativePath) {
    if (relativePath.isEmpty) return '';

    // Handle both cases: with or without leading slash
    final path = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$imageBaseUrl$path';
  }

  /// Save auth token
  Future<void> saveToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
  }

  /// Get auth token
  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  /// Clear auth token
  Future<void> clearToken() async {
    await storage.delete(key: 'auth_token');
  }

  void dispose() {
    _unauthenticatedController.close();
    _noNetworkController.close();
    _networkStatusController.close();
  }
}
