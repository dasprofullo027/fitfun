import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get profile => _profile;
  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((data) {
      if (data.session != null) {
        loadProfile();
      } else {
        _profile = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadProfile() async {
    if (!isAuthenticated) return;
    try {
      _isLoading = true;
      notifyListeners();
      _profile = await _authService.getProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final res = await _authService.login(email, password);
      if (res.user != null) {
        _profile = await _authService.getProfile();
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(
    String email,
    String password,
    String fullName, {
    String? goal,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final res = await _authService.register(
        email,
        password,
        fullName,
        goal: goal,
      );
      if (res.user != null) {
        _profile = await _authService.getProfile();
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authService.logout();
      _profile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    String? goal,
    String? avatarUrl,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updated = await _authService.updateProfile(
        fullName: fullName,
        goal: goal,
        avatarUrl: avatarUrl,
      );
      if (updated != null) {
        _profile = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
