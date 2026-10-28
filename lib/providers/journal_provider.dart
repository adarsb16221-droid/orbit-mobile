import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class JournalProvider with ChangeNotifier {
  Map<String, String> _entries = {};
  bool _isLoading = false;
  String? _error;

  Map<String, String> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  Future<void> fetchAllJournals() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/journal');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _entries = data.map((key, value) => MapEntry(key, value.toString()));
        _error = null;
      } else {
        _error = 'Failed to load journals';
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> saveJournal(String date, String content) async {
    try {
      final response = await _apiService.post('/journal', {
        date: content,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        _entries[date] = content;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }
    return false;
  }
  
  // Keep this for backwards compatibility if needed, but it's redundant now
  Future<void> fetchJournal(String date) async {
    await fetchAllJournals();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
