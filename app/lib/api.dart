import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'theme.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

/// HTTP client that attaches the access token, and transparently refreshes it
/// (single-flight) when the server answers 401.
class ApiClient {
  ApiClient({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final http.Client _http = http.Client();
  static const _kAccess = 'solis_access';
  static const _kRefresh = 'solis_refresh';

  String? _access;
  String? _refresh;
  Future<bool>? _refreshing;

  /// Called when the session can no longer be refreshed.
  void Function()? onSessionExpired;

  bool get hasSession => _refresh != null;

  Future<void> loadTokens() async {
    try {
      _access = await _storage.read(key: _kAccess);
      _refresh = await _storage.read(key: _kRefresh);
    } catch (_) {
      await clearTokens();
    }
  }

  Future<void> saveTokens(String access, String refresh) async {
    _access = access;
    _refresh = refresh;
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }

  String? get refreshToken => _refresh;

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body);
  Future<dynamic> patch(String path, [Object? body]) => _send('PATCH', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, [Object? body, bool retried = false]) async {
    final uri = Uri.parse('${AppConfig.apiUrl}/api$path');
    final req = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json'
      ..headers['Bypass-Tunnel-Reminder'] = 'true';
    if (_access != null) req.headers['Authorization'] = 'Bearer $_access';
    if (body != null) req.body = jsonEncode(body);

    http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(req).timeout(const Duration(seconds: 15)));
    } on TimeoutException {
      throw ApiException(0, 'Connection timed out (${AppConfig.apiUrl}). Tap server settings to configure.');
    } catch (_) {
      throw ApiException(0, 'Cannot reach server at ${AppConfig.apiUrl}. Check connection or change server.');
    }

    if (res.statusCode == 401 && !retried && _refresh != null && !path.startsWith('/auth/')) {
      if (await _refreshTokens()) return _send(method, path, body, true);
      onSessionExpired?.call();
    }

    final data = res.body.isEmpty ? null : _tryJson(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    final msg = (data is Map && data['error'] is String) ? data['error'] as String : 'Request failed (${res.statusCode})';
    throw ApiException(res.statusCode, msg);
  }

  dynamic _tryJson(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _refreshTokens() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final rt = _refresh;
    if (rt == null) return false;
    try {
      final res = await _http
          .post(Uri.parse('${AppConfig.apiUrl}/api/auth/refresh'),
              headers: {'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true'}, body: jsonEncode({'refreshToken': rt}))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        await saveTokens(d['accessToken'] as String, d['refreshToken'] as String);
        return true;
      }
      if (res.statusCode == 401) await clearTokens();
      return false;
    } catch (_) {
      return false; // network: keep tokens, try later
    }
  }

  /// Exposed for app start: try to obtain a fresh access token.
  Future<bool> refresh() => _refreshTokens();
}
