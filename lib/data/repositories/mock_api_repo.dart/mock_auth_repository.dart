import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../abstract/auth_repository.dart';
import '../../models/user_model.dart';

class MockAuthRepository implements AuthRepository {
  static const String _userKey = 'logged_in_user';
  UserModel? _currentUser;

  // Mock users database
  final List<Map<String, dynamic>> _users = [
    {
      'id': '1',
      'email': 'admin@test.com',
      'password': 'password123',
      'name': 'Admin User',
      'phone': '+855123456789',
      'role': 'business',
      'created_at':
          DateTime.now().subtract(const Duration(days: 365)).toIso8601String(),
    },
    {
      'id': '2',
      'email': 'test@test.com',
      'password': 'password123',
      'name': 'Test User',
      'phone': '+855987654321',
      'role': 'retail',
      'created_at':
          DateTime.now().subtract(const Duration(days: 180)).toIso8601String(),
    },
  ];

  @override
  Future<UserModel> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Find user
    final userData = _users.firstWhere(
      (user) => user['email'] == email && user['password'] == password,
      orElse: () => throw Exception('Invalid email or password'),
    );

    _currentUser = UserModel.fromJson(userData);

    // Save to SharedPreferences
    await _saveUser(_currentUser!);

    return _currentUser!;
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    required String role,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Check if email already exists
    final exists = _users.any((user) => user['email'] == email);
    if (exists) {
      throw Exception('Email already registered');
    }

    // Create new user
    final newUser = {
      'id': (_users.length + 1).toString(),
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
    };

    _users.add(newUser);
    _currentUser = UserModel.fromJson(newUser);

    // Save to SharedPreferences
    await _saveUser(_currentUser!);

    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;

    // Clear from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    // Try to load from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      try {
        final userData = json.decode(userJson);
        _currentUser = UserModel.fromJson(userData);
        return _currentUser;
      } catch (e) {
        // If error, clear invalid data
        await prefs.remove(_userKey);
      }
    }

    return null;
  }

  @override
  Future<bool> forgotPassword(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Check if email exists
    final exists = _users.any((user) => user['email'] == email);
    if (!exists) {
      throw Exception('Email not found');
    }

    // Simulate sending email
    return true;
  }

  @override
  Future<bool> isLoggedIn() async {
    if (_currentUser != null) {
      return true;
    }

    // Check SharedPreferences
    final user = await getCurrentUser();
    return user != null;
  }

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }
}
