import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  final ApiService _apiService = ApiService();

  Future<bool> checkAuthStatus() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/auth/me');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = User.fromJson(data);
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
    return false;
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = User.fromJson(data['user']);
        if (data['token'] != null) {
          await _apiService.setToken(data['token']);
        }
        _setLoading(false);
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Login failed';
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
    return false;
  }

  Future<bool> signup(String name, String email, String password) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/auth/signup', {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _user = User.fromJson(data['user']);
        if (data['token'] != null) {
          await _apiService.setToken(data['token']);
        }
        _setLoading(false);
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Signup failed';
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
    return false;
  }

  Future<void> logout() async {
    await _apiService.post('/auth/logout', {});
    await _apiService.clearToken();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
