import '../../models/user_model.dart';

abstract class AuthRepository {
  /// Login with email and password
  Future<UserModel> login(String email, String password);

  /// Register a new user
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    required String role,
  });

  /// Logout current user
  Future<void> logout();

  /// Get current logged in user
  Future<UserModel?> getCurrentUser();

  /// Send password reset email
  Future<bool> forgotPassword(String email);

  /// Check if user is logged in
  Future<bool> isLoggedIn();
}
