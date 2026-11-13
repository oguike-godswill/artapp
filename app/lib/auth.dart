import 'package:flutter/foundation.dart';

import 'api.dart';
import 'models.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  AuthController(this.api) {
    api.onSessionExpired = _expire;
  }

  final ApiClient api;
  AuthStatus status = AuthStatus.unknown;
  User? user;

  Future<void> bootstrap() async {
    await api.loadTokens();
    if (!api.hasSession) {
      _set(AuthStatus.signedOut);
      return;
    }
    try {
      await _fetchMe();
    } on ApiException catch (e) {
      if (e.status == 401 || e.status == 404) {
        if (await api.refresh()) {
          try {
            await _fetchMe();
            return;
          } catch (_) {}
        }
        await api.clearTokens();
        _set(AuthStatus.signedOut);
      } else {
        // Offline / server down: keep the session, screens will show retry.
        _set(api.hasSession ? AuthStatus.signedIn : AuthStatus.signedOut);
      }
    }
  }

  Future<void> _fetchMe() async {
    final d = await api.get('/auth/me');
    user = User.fromJson(d['user'] as Map<String, dynamic>);
    _set(AuthStatus.signedIn);
  }

  Future<void> login(String email, String password) async {
    final d = await api.post('/auth/login', {'email': email.trim(), 'password': password});
    await _accept(d);
  }

  Future<void> register(String name, String email, String password) async {
    final d = await api.post('/auth/register', {'name': name.trim(), 'email': email.trim(), 'password': password});
    await _accept(d);
  }

  Future<void> updateName(String name) async {
    final d = await api.patch('/auth/me', {'name': name.trim()});
    user = User.fromJson(d['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> changePassword(String current, String next) async {
    final d = await api.post('/auth/change-password', {'currentPassword': current, 'newPassword': next});
    await _accept(d);
  }

  Future<void> logout() async {
    final rt = api.refreshToken;
    if (rt != null) {
      try {
        await api.post('/auth/logout', {'refreshToken': rt});
      } catch (_) {}
    }
    await api.clearTokens();
    user = null;
    _set(AuthStatus.signedOut);
  }

  Future<void> _accept(dynamic d) async {
    await api.saveTokens(d['accessToken'] as String, d['refreshToken'] as String);
    user = User.fromJson(d['user'] as Map<String, dynamic>);
    _set(AuthStatus.signedIn);
  }

  Future<void> _expire() async {
    await api.clearTokens();
    user = null;
    _set(AuthStatus.signedOut);
  }

  void _set(AuthStatus s) {
    status = s;
    notifyListeners();
  }
}
