import 'package:flutter/material.dart';
import '../db/database.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  bool _isAuthenticated = false;

  // ── Session expiry ────────────────────────────────────────────────────────
  static const Duration _sessionTimeout = Duration(hours: 8);
  DateTime? _loginTime;

  // ── Brute-force protection ────────────────────────────────────────────────
  static const int _maxAttempts   = 5;
  static const Duration _lockDuration = Duration(minutes: 15);
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  // ── Getters ───────────────────────────────────────────────────────────────
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated {
    if (!_isAuthenticated) return false;
    // Auto-expire stale sessions
    if (_loginTime != null &&
        DateTime.now().difference(_loginTime!) > _sessionTimeout) {
      logout();
      return false;
    }
    return true;
  }

  String get userName =>
      _currentUser?['full_name'] ?? _currentUser?['username'] ?? '';
  String get userRole => _currentUser?['role'] ?? 'user';
  bool get isAdmin    => userRole == 'admin';

  /// Remaining lockout duration, or null if not locked.
  Duration? get lockoutRemaining {
    if (_lockedUntil == null) return null;
    final rem = _lockedUntil!.difference(DateTime.now());
    return rem.isNegative ? null : rem;
  }

  // ── Init (auto-login) ─────────────────────────────────────────────────────
  Future<void> init() async {
    final autoLogin = await AppDatabase.instance.getSetting('auto_login');
    if (autoLogin == '1') {
      final savedUser = await AppDatabase.instance.getSetting('saved_user');
      if (savedUser.isNotEmpty) await _loadUser(savedUser);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<LoginResult> login(String username, String password) async {
    // Check lockout
    final rem = lockoutRemaining;
    if (rem != null) {
      final mins = rem.inMinutes + 1;
      return LoginResult.locked(
        'الحساب مقفل بسبب محاولات متعددة. حاول بعد $mins دقيقة.');
    }

    try {
      final result = await AppDatabase.instance.query(
        'users',
        // Compare hashed password — never plain text
        where: 'username = ? AND password = ? AND is_active = 1',
        whereArgs: [username, hashPassword(password)],
      );

      if (result.isNotEmpty) {
        // Successful login — reset counters
        _failedAttempts = 0;
        _lockedUntil    = null;
        _currentUser    = result.first;
        _isAuthenticated = true;
        _loginTime      = DateTime.now();

        await AppDatabase.instance.update(
          'users',
          {'last_login': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [_currentUser!['id']],
        );
        notifyListeners();
        return LoginResult.success();
      }

      // Failed login
      _failedAttempts++;
      if (_failedAttempts >= _maxAttempts) {
        _lockedUntil = DateTime.now().add(_lockDuration);
        _failedAttempts = 0;
        return LoginResult.locked(
          'تم قفل الحساب لمدة ${_lockDuration.inMinutes} دقيقة '
          'بسبب تجاوز عدد محاولات تسجيل الدخول.');
      }
      final remaining = _maxAttempts - _failedAttempts;
      return LoginResult.failed(
        'اسم المستخدم أو كلمة المرور غير صحيحة. '
        'متبقي $remaining محاولة.');
    } catch (e) {
      return LoginResult.failed('حدث خطأ أثناء تسجيل الدخول.');
    }
  }

  // ── Change password ───────────────────────────────────────────────────────
  Future<bool> changePassword(String oldPass, String newPass) async {
    if (_currentUser == null) return false;
    final result = await AppDatabase.instance.query(
      'users',
      where: 'id = ? AND password = ?',
      whereArgs: [_currentUser!['id'], hashPassword(oldPass)],
    );
    if (result.isNotEmpty) {
      await AppDatabase.instance.update(
        'users',
        {'password': hashPassword(newPass)},
        where: 'id = ?',
        whereArgs: [_currentUser!['id']],
      );
      return true;
    }
    return false;
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  void logout() {
    _currentUser     = null;
    _isAuthenticated = false;
    _loginTime       = null;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<void> _loadUser(String username) async {
    final result = await AppDatabase.instance.query(
      'users',
      where: 'username = ? AND is_active = 1',
      whereArgs: [username],
    );
    if (result.isNotEmpty) {
      _currentUser     = result.first;
      _isAuthenticated = true;
      _loginTime       = DateTime.now();
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async =>
      AppDatabase.instance.query('users', orderBy: 'id');
}

// ── Result type ───────────────────────────────────────────────────────────────
enum LoginStatus { success, failed, locked }

class LoginResult {
  final LoginStatus status;
  final String? message;
  LoginResult._(this.status, this.message);
  factory LoginResult.success()            => LoginResult._(LoginStatus.success, null);
  factory LoginResult.failed(String msg)   => LoginResult._(LoginStatus.failed,  msg);
  factory LoginResult.locked(String msg)   => LoginResult._(LoginStatus.locked,  msg);
  bool get isSuccess => status == LoginStatus.success;
}
