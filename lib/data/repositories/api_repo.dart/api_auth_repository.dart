import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../abstract/auth_repository.dart';
import '../../models/user_model.dart';
import '../../dto/login_response_dto.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_helper.dart';

class ApiAuthRepository implements AuthRepository {
  static const String _userKey = 'logged_in_user';
  UserModel? _currentUser;
  String? _authToken;

  final ApiHelper _apiHelper = ApiHelper.instance;

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      // Create Basic Auth credentials
      final credentials = base64Encode(utf8.encode('$email:$password'));

      const url = '${ApiConstants.baseUrl}${ApiConstants.login}';

      // DEBUG: Print request details
      print('🔍 LOGIN DEBUG:');
      print('URL: $url');
      print('Username: $email');
      print('Password: $password');
      print('Basic Auth: Basic $credentials');

      final response = await _apiHelper.dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Basic $credentials',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.json, // Force JSON parsing
        ),
      );

      // DEBUG: Print response
      print('Response Status: ${response.statusCode}');
      print('Response Data: ${response.data}');

      if (response.statusCode == 200) {
        // Handle both String and Map responses
        Map<String, dynamic> jsonData;

        if (response.data is String) {
          // If response is a String, parse it as JSON
          jsonData = json.decode(response.data);
        } else if (response.data is Map<String, dynamic>) {
          // If already a Map, use it directly
          jsonData = response.data;
        } else {
          throw Exception(
              'Unexpected response format: ${response.data.runtimeType}');
        }

        // Parse response into DTO
        final loginResponse = LoginResponseDto.fromJson(jsonData);

        if (loginResponse.isSuccess && loginResponse.data != null) {
          // Extract token
          _authToken = loginResponse.data!.token;

          // Convert DTO to Model (mapping logic in repository)
          _currentUser = _mapDtoToModel(loginResponse.data!.userData);

          if (_currentUser == null || _authToken == null) {
            throw Exception('Failed to parse user data');
          }

          // Save token and user to storage
          await _saveAuthData(_authToken!, _currentUser!);

          return _currentUser!;
        } else {
          throw Exception(loginResponse.message);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on FormatException {
      // JSON parsing error
      throw Exception(
          'Invalid response format from server. Please contact support.');
    } on TypeError catch (e) {
      // Type mismatch error
      throw Exception('Response data type mismatch: ${e.toString()}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Please try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Connection error. Please check your internet connection.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Service not found. Please contact support.');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    required String role,
  }) async {
    // Registration is not available via API
    throw Exception(
        'Registration is not available. Please contact administrator.');
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _authToken = null;

    // Clear from storage
    await _apiHelper.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    // Try to load from storage
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    final token = await _apiHelper.getToken();

    if (userJson != null && token != null) {
      try {
        final userData = json.decode(userJson);
        _currentUser = UserModel.fromJson(userData);
        _authToken = token;
        return _currentUser;
      } catch (e) {
        // If error, clear invalid data
        await prefs.remove(_userKey);
        await _apiHelper.clearToken();
      }
    }

    return null;
  }

  @override
  Future<bool> forgotPassword(String email) async {
    // Forgot password is not available via API
    throw Exception(
        'Password reset is not available. Please contact administrator.');
  }

  @override
  Future<bool> isLoggedIn() async {
    if (_currentUser != null && _authToken != null) {
      return true;
    }

    // Check storage
    final user = await getCurrentUser();
    return user != null && _authToken != null;
  }

  Future<void> _saveAuthData(String token, UserModel user) async {
    // Save token to secure storage
    await _apiHelper.saveToken(token);

    // Save user to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }

  /// Map DTO to Domain Model
  /// This is where DTO → Model conversion happens (CDPV pattern)
  UserModel _mapDtoToModel(UserDataDto dto) {
    return UserModel(
      id: dto.id,
      email: dto.email,
      name: '${dto.firstName} ${dto.lastName}',
      phone: null, // Not provided in current API
      role: _mapGroupIdToRole(dto.groupId),
      avatar: null, // Not provided in current API
      createdAt: DateTime.now(),
      companyId: dto.companyId,
      groupId: dto.groupId,
      firstName: dto.firstName,
      lastName: dto.lastName,
      salePersonId: dto.salePersonId,
      consignment: dto.consignment,
    );
  }

  /// Map group_id to user role (business logic)
  String _mapGroupIdToRole(String groupId) {
    switch (groupId) {
      case '1':
        return 'admin';
      case '2':
        return 'business';
      case '3':
        return 'retail';
      default:
        return 'retail';
    }
  }

  /// Get the current auth token
  String? get authToken => _authToken;
}
