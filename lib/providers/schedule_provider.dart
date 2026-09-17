import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/schedule.dart';

class ScheduleProvider with ChangeNotifier {
  List<Schedule> _schedules = [];
  bool _isLoading = false;
  String? _error;

  List<Schedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  Future<void> fetchSchedules() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/schedule');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _schedules = data.map((json) => Schedule.fromJson(json)).toList();
        _error = null;
      } else {
        _error = 'Failed to load schedules';
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> addSchedule(Schedule schedule) async {
    try {
      final response = await _apiService.post('/schedule', schedule.toJson());
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _schedules.add(Schedule.fromJson(data));
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }
    return false;
  }

  Future<bool> deleteSchedule(String id) async {
    try {
      final response = await _apiService.delete('/schedule?id=$id');
      if (response.statusCode == 200) {
        _schedules.removeWhere((s) => s.id == id);
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
