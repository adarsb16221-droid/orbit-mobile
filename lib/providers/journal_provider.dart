import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/journal.dart';

class JournalProvider with ChangeNotifier {
  Journal? _todayJournal;
  bool _isLoading = false;
  String? _error;

  Journal? get todayJournal => _todayJournal;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  Future<void> fetchJournal(String date) async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/journal?date=$date');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['date'] != null) {
          _todayJournal = Journal.fromJson(data);
        } else {
          _todayJournal = null; // No entry for this date
        }
        _error = null;
      } else {
        _error = 'Failed to load journal';
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> saveJournal(String date, String content) async {
    try {
      final response = await _apiService.post('/journal', {
        'date': date,
        'content': content,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _todayJournal = Journal.fromJson(data);
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
