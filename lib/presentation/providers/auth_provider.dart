import 'package:daishin_order_app/core/utils/async_value.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/abstract/auth_repository.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  UserModel? _currentUser;
  AsyncValue<UserModel?> _authState = const AsyncValue.success(null);
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  AsyncValue<UserModel?> get authState => _authState;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;

  /// Initialize - check if user is already logged in
  Future<void> initialize() async {
    try {
      // Add artificial delay to show Splash Screen animation
      await Future.delayed(const Duration(milliseconds: 2500));
      _currentUser = await _authRepository.getCurrentUser();
      _authState = AsyncValue.success(_currentUser);
    } catch (e) {
      _authState = AsyncValue.error(e);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    _authState = const AsyncValue.loading();
    notifyListeners();

    try {
      final user = await _authRepository.login(email, password);
      _currentUser = user;
      _authState = AsyncValue.success(user);
      notifyListeners();
    } catch (e) {
      _authState = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Register new user
  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    required String role,
  }) async {
    _authState = const AsyncValue.loading();
    notifyListeners();

    try {
      final user = await _authRepository.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );
      _currentUser = user;
      _authState = AsyncValue.success(user);
      notifyListeners();
    } catch (e) {
      _authState = AsyncValue.error(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _authRepository.logout();
      _currentUser = null;
      _authState = const AsyncValue.success(null);
      notifyListeners();
    } catch (e) {
      _authState = AsyncValue.error(e);
      notifyListeners();
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    try {
      return await _authRepository.forgotPassword(email);
    } catch (e) {
      rethrow;
    }
  }
}
