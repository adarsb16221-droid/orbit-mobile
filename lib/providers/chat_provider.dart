import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearChat() {
    _messages = [];
    _error = null;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Optimistically add user message
    _messages.add(ChatMessage(role: 'user', content: text));
    _error = null;
    _setLoading(true);

    try {
      final requestPayload = {
        'messages': _messages.map((m) => m.toJson()).toList(),
      };

      final response = await _apiService.post('/chat', requestPayload);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newMessages = data['messages'] as List<dynamic>?;
        if (newMessages != null && newMessages.isNotEmpty) {
          final lastMsg = newMessages.lastWhere(
            (m) => m['role'] == 'assistant' && m['content'] != null,
            orElse: () => null,
          );
          if (lastMsg != null) {
            String content = lastMsg['content'];
            // Clean up emotion tags if any
            content = content.replaceAll(RegExp(r'\[EMOTION:.*?\]\s*'), '');
            _messages.add(ChatMessage(role: 'assistant', content: content.trim()));
          }
        }
      } else {
        final data = json.decode(response.body);
        _error = data['error'] ?? 'Failed to send message';
        // Remove the user message if it failed completely
        _messages.removeLast();
      }
    } catch (e) {
      _error = 'Failed to connect to Hawk AI. Check your connection.';
      _messages.removeLast();
    }
    
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
