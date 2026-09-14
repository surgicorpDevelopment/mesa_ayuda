import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api);

  final ApiClient _api;
  bool loading = true;
  String? error;

  AppUser? get user => _api.currentUser;
  bool get isAuthenticated => _api.accessToken != null && user != null;
  ApiClient get api => _api;

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();
    await _api.loadSession();
    loading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    error = null;
    loading = true;
    notifyListeners();
    try {
      await _api.login(username.trim(), password);
      loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearSession();
    notifyListeners();
  }
}
