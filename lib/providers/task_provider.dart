import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  Future<void> fetchTasks() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/tasks');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _tasks = data.map((json) => Task.fromJson(json)).toList();
        _error = null;
      } else {
        _error = 'Failed to load tasks';
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> addTask(Task task) async {
    try {
      final response = await _apiService.post('/tasks', task.toJson());
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _tasks.insert(0, Task.fromJson(data));
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }
    return false;
  }

  Future<bool> updateTask(Task task) async {
    try {
      final response = await _apiService.put('/tasks', task.toJson());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = Task.fromJson(data);
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }
    return false;
  }

  Future<bool> deleteTask(String id) async {
    try {
      final response = await _apiService.delete('/tasks?id=$id');
      if (response.statusCode == 200) {
        _tasks.removeWhere((t) => t.id == id);
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
