import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String role;
  final String content;
  final String emotion;

  ChatMessage({
    required this.role,
    required this.content,
    this.emotion = 'neutral',
  });

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
  String _lastEmotion = 'neutral';

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get lastEmotion => _lastEmotion;

  void clearChat() {
    _messages = [];
    _error = null;
    _lastEmotion = 'neutral';
    notifyListeners();
  }

  void setLastEmotion(String emotion) {
    _lastEmotion = emotion;
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
            final rawContent = (lastMsg['content'] as String?) ?? '';
            String detectedEmotion = 'neutral';

            final match = RegExp(
              r'\[EMOTION:\s*(angry|happy|neutral|worried|confused)\]',
              caseSensitive: false,
            ).firstMatch(rawContent);

            if (match != null) {
              detectedEmotion = match.group(1)!.toLowerCase();
            } else {
              detectedEmotion = _inferEmotionFromText(rawContent);
            }

            _lastEmotion = detectedEmotion;

            final cleanContent = rawContent.replaceAll(
              RegExp(r'\[EMOTION:\s*(angry|happy|neutral|worried|confused)\]\s*', caseSensitive: false),
              '',
            ).trim();

            _messages.add(ChatMessage(
              role: 'assistant',
              content: cleanContent,
              emotion: detectedEmotion,
            ));
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

  String _inferEmotionFromText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('congrat') ||
        lower.contains('great job') ||
        lower.contains('awesome') ||
        lower.contains('fantastic') ||
        lower.contains('well done') ||
        lower.contains('excellent') ||
        lower.contains('proud') ||
        lower.contains('amazing') ||
        lower.contains('happy') ||
        lower.contains('good work') ||
        lower.contains('🎉') ||
        lower.contains('🔥')) {
      return 'happy';
    }
    if (lower.contains('warning') ||
        lower.contains('urgent') ||
        lower.contains('stress') ||
        lower.contains('worried') ||
        lower.contains('careful') ||
        lower.contains('concern') ||
        lower.contains('danger') ||
        lower.contains('struggling') ||
        lower.contains('behind schedule')) {
      return 'worried';
    }
    if (lower.contains('confus') ||
        lower.contains('pardon') ||
        lower.contains('not sure') ||
        lower.contains('could you clarify') ||
        lower.contains('what do you mean') ||
        lower.contains('unclear') ||
        lower.contains('huh') ||
        lower.contains('?')) {
      return 'confused';
    }
    if (lower.contains('angry') ||
        lower.contains('furious') ||
        lower.contains('unacceptable') ||
        lower.contains('stop doing') ||
        lower.contains('terrible') ||
        lower.contains('fail')) {
      return 'angry';
    }
    return 'neutral';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
