import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/face_avatar.dart';
import '../widgets/hawk_header.dart';
import 'focus_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();

  String _emotion = 'neutral';
  String _displayedText = '';
  Timer? _typewriterTimer;
  String _targetText = '';

  @override
  void initState() {
    super.initState();
    _targetText = "Hello! I am Hawk, your personal AI companion. How can I assist you with your health, wealth, or knowledge today?";
    _startTypewriter(_targetText);
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _textController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _startTypewriter(String text) {
    _typewriterTimer?.cancel();
    _targetText = text;
    _displayedText = '';

    int i = 0;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (i < text.length) {
        setState(() {
          _displayedText = text.substring(0, i + 1);
        });
        i++;
      } else {
        timer.cancel();
      }
    });
  }

  void _extractEmotion(String content) {
    final match = RegExp(r'\[EMOTION:\s*(angry|happy|neutral|worried|confused)\]', caseSensitive: false)
        .firstMatch(content);
    if (match != null) {
      setState(() {
        _emotion = match.group(1)!.toLowerCase();
      });
    }
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    await chatProvider.sendMessage(text);

    // Get latest assistant message
    final messages = chatProvider.messages;
    final lastAssistant = messages.reversed.firstWhere(
      (m) => m.role == 'assistant',
      orElse: () => ChatMessage(role: 'assistant', content: ''),
    );

    if (lastAssistant.content.isNotEmpty) {
      _extractEmotion(lastAssistant.content);
      _startTypewriter(lastAssistant.content);
    }
  }

  void _showChatLogModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildChatLogSheet(),
    );
  }

  Widget _buildChatLogSheet() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final messages = chatProvider.messages;

        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return Material(
              color: const Color(0xFF131B2E),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history, color: Color(0xFF8083FF), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Conversation Log',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              tooltip: 'Clear Chat',
                              onPressed: () {
                                chatProvider.clearChat();
                                _startTypewriter("Chat cleared. How can I help you now?");
                                Navigator.pop(context);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 20),

                  // Messages List
                  Expanded(
                    child: messages.isEmpty
                        ? const Center(
                            child: Text(
                              'No conversation history yet.',
                              style: TextStyle(color: Color(0xFF908FA0), fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: messages.length,
                            itemBuilder: (ctx, i) {
                              final msg = messages[i];
                              final isUser = msg.role == 'user';
                              return Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isUser ? const Color(0xFF4648D4) : const Color(0xFF1E283F),
                                    borderRadius: BorderRadius.circular(16).copyWith(
                                      bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
                                      bottomLeft: !isUser ? const Radius.circular(2) : const Radius.circular(16),
                                    ),
                                    border: Border.all(
                                      color: isUser
                                          ? const Color(0xFF8083FF).withValues(alpha: 0.3)
                                          : Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isUser ? 'YOU' : 'HAWK',
                                        style: TextStyle(
                                          color: isUser ? Colors.white70 : const Color(0xFF8083FF),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        msg.content,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;
    final isLoading = chatProvider.isLoading;
    final isSpeaking = !isLoading && _displayedText.isNotEmpty && _displayedText != _targetText;

    return Scaffold(
      backgroundColor: themeProvider?.bg ?? (isDark ? const Color(0xFF0B1326) : const Color(0xFFF8F9FF)),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (AI Chat & Focus) matching Header.jsx
            HawkHeader(
              title: 'AI Chat & Focus',
              subtitle: 'Intelligent Companion',
              actions: [
                // Focus Mode Shortcut Pill
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FocusScreen()));
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8083FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF8083FF).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.center_focus_strong, size: 13, color: Color(0xFF8083FF)),
                        SizedBox(width: 4),
                        Text(
                          'Focus Mode',
                          style: TextStyle(color: Color(0xFF8083FF), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Chat Log Button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeProvider?.circleBtnBg ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    border: Border.all(color: themeProvider?.circleBtnBorder ?? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1))),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.history,
                      size: 18,
                      color: isDark ? const Color(0xFFC0C1FF) : const Color(0xFF4648D4),
                    ),
                    tooltip: 'Conversation Log',
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                    onPressed: _showChatLogModal,
                  ),
                ),
              ],
            ),

            // 2. Main Content: FaceAvatar + Speech Bubble
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Character Avatar (Left/Top)
                    Center(
                      child: FaceAvatar(
                        isThinking: isLoading,
                        isSpeaking: isSpeaking,
                        emotion: _emotion,
                        size: 160,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Speech Bubble Tail
                    CustomPaint(
                      size: const Size(20, 12),
                      painter: _SpeechTailPainter(
                        color: themeProvider?.surface ?? (isDark ? const Color(0xFF171F33) : Colors.white),
                      ),
                    ),

                    // Speech Bubble Box
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 120),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        color: themeProvider?.surface ?? (isDark ? const Color(0xFF171F33) : Colors.white),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: themeProvider?.cardBorder ?? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // "HAWK" Name Badge
                          Positioned(
                            top: -36,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4648D4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: themeProvider?.surface ?? (isDark ? const Color(0xFF171F33) : Colors.white),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4648D4).withValues(alpha: 0.4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'HAWK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),

                          // Text Content
                          isLoading
                              ? const Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8083FF)),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Thinking...',
                                      style: TextStyle(
                                        color: Color(0xFF8083FF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  _displayedText,
                                  style: TextStyle(
                                    color: themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : const Color(0xFF0D1C2E)),
                                    fontSize: 14,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // 3. User Input Box at Bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white),
                border: Border(top: BorderSide(color: themeProvider?.border ?? (isDark ? Colors.white10 : Colors.black12))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeProvider?.surfaceContainer ?? (isDark ? const Color(0xFF171F33) : const Color(0xFFEFF4FF)),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: themeProvider?.cardBorder ?? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black12)),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(
                          color: themeProvider?.textPrimary ?? (isDark ? Colors.white : const Color(0xFF0D1C2E)),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type your response to Hawk...',
                          hintStyle: TextStyle(
                            color: themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : const Color(0xFF64748B)),
                            fontSize: 13,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Glowing Send Button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4648D4).withValues(alpha: 0.4),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: IconButton.filled(
                      onPressed: _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF4648D4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                      icon: const Icon(Icons.send, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeechTailPainter extends CustomPainter {
  final Color color;
  _SpeechTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
