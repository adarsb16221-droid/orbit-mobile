import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/widget_service.dart';
import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  Future<void> fetchTasks(String userId) async {
    _setLoading(true);
    try {
      final responses = await Future.wait([
        _apiService.get('/tasks'),
        _apiService.get('/challenges')
      ]);

      final taskResponse = responses[0];
      final challengeResponse = responses[1];

      if (taskResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(taskResponse.body);
        _tasks = data.map((json) => Task.fromJson(json)).toList();
        
        if (challengeResponse.statusCode == 200) {
          final List<dynamic> challengesData = json.decode(challengeResponse.body);
          final String todayStr = DateTime.now().toIso8601String().split('T')[0];
          
          for (var c in challengesData) {
            if (c['status'] == 'accepted') {
              final bool isCreator = c['creator']['_id'] == userId;
              final bool isSelf = c['creator']['_id'] == c['recipient']['_id'];
              final bool isMutual = c['type'] == 'mutual';

              for (var t in c['tasks']) {
                bool isCompleted = false;
                if (isMutual && !isSelf) {
                  if (t['isDaily'] == true) {
                    final creatorHistory = t['creatorHistory'] as List<dynamic>?;
                    final recipientHistory = t['recipientHistory'] as List<dynamic>?;
                    isCompleted = isCreator 
                        ? (creatorHistory?.contains(todayStr) ?? false)
                        : (recipientHistory?.contains(todayStr) ?? false);
                  } else {
                    isCompleted = isCreator ? (t['creatorCompleted'] == true) : (t['recipientCompleted'] == true);
                  }
                } else {
                  if (!isMutual && isCreator && !isSelf) continue;
                  if (t['isDaily'] == true) {
                    final recipientHistory = t['recipientHistory'] as List<dynamic>?;
                    isCompleted = (recipientHistory?.contains(todayStr) ?? false);
                  } else {
                    isCompleted = (t['recipientCompleted'] == true);
                  }
                }

                _tasks.add(Task(
                  id: t['_id'],
                  text: t['title'] ?? '',
                  category: 'Challenge',
                  priority: 'medium',
                  isRegular: t['isDaily'] == true,
                  isGoal: false,
                  completed: isCompleted,
                  challengeId: c['_id'],
                  challengeName: isSelf ? 'My Challenge' : (isMutual ? 'Mutual Challenge' : 'Solo Challenge'),
                  subtasks: [],
                  order: 0.0,
                ));
              }
            }
          }
        }
        
        _error = null;
        WidgetService.updateWidgetData(tasks: _tasks);
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
        WidgetService.updateWidgetData(tasks: _tasks);
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
      if (task.challengeId != null) {
        // Handle challenge task completion
        final response = await _apiService.patch(
          '/challenges/${task.challengeId}',
          {'taskId': task.id, 'completed': task.completed},
        );
        if (response.statusCode == 200) {
          final index = _tasks.indexWhere((t) => t.id == task.id);
          if (index != -1) {
            _tasks[index] = task;
            WidgetService.updateWidgetData(tasks: _tasks);
            notifyListeners();
          }
          return true;
        }
      } else {
        // Normal task
        final response = await _apiService.put('/tasks', task.toJson());
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final index = _tasks.indexWhere((t) => t.id == task.id);
          if (index != -1) {
            _tasks[index] = Task.fromJson(data);
            WidgetService.updateWidgetData(tasks: _tasks);
            notifyListeners();
          }
          return true;
        }
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
        WidgetService.updateWidgetData(tasks: _tasks);
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
