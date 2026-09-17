import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/link.dart';

class LinkProvider with ChangeNotifier {
  List<Link> _links = [];
  bool _isLoading = false;
  String? _error;

  List<Link> get links => _links;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  Future<void> fetchLinks() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/links');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _links = data.map((json) => Link.fromJson(json)).toList();
        _error = null;
      } else {
        _error = 'Failed to load links';
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> addLink(Link link) async {
    try {
      final response = await _apiService.post('/links', link.toJson());
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _links.add(Link.fromJson(data));
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }
    return false;
  }

  Future<bool> deleteLink(String id) async {
    try {
      final response = await _apiService.delete('/links?id=$id');
      if (response.statusCode == 200) {
        _links.removeWhere((l) => l.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }
    return false;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
