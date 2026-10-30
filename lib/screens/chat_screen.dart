import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  final FlutterTts _flutterTts = FlutterTts();

  String _emotion = 'neutral';
  String _displayedText = '';
  Timer? _typewriterTimer;
  String _targetText = '';

  bool _isVoiceEnabled = true;
  bool _isTtsSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();

    _targetText =
        "Hello! I am Hawk, your personal AI companion. How can I assist you with your health, wealth, or knowledge today?";
    _startTypewriter(_targetText);
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        if (mounted) setState(() => _isTtsSpeaking = true);
      });

      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isTtsSpeaking = false);
      });

      _flutterTts.setCancelHandler(() {
        if (mounted) setState(() => _isTtsSpeaking = false);
      });

      _flutterTts.setErrorHandler((msg) {
        if (mounted) setState(() => _isTtsSpeaking = false);
      });
    } catch (e) {
      debugPrint("FlutterTts init error: $e");
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _flutterTts.stop();
    _textController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  String _cleanTextForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'\[EMOTION:\s*(angry|happy|neutral|worried|confused)\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
        .replaceAll(RegExp(r'[*#_~`]'), '')
        .trim();
  }

  void _speakIfEnabled(String text) async {
    if (!_isVoiceEnabled) return;
    final speechText = _cleanTextForSpeech(text);
    if (speechText.isEmpty) return;

    try {
      await _flutterTts.stop();
      await _flutterTts.speak(speechText);
    } catch (e) {
      debugPrint("TTS error: $e");
    }
  }

  void _toggleVoice() {
    setState(() {
      _isVoiceEnabled = !_isVoiceEnabled;
      if (!_isVoiceEnabled) {
        _flutterTts.stop();
        _isTtsSpeaking = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(
              _isVoiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(_isVoiceEnabled ? 'Voice Enabled' : 'Voice Muted'),
          ],
        ),
      ),
    );
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

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Stop ongoing speech before requesting new reply
    await _flutterTts.stop();
    setState(() {
      _isTtsSpeaking = false;
    });

    await chatProvider.sendMessage(text);

    // Get latest assistant message and emotion
    final messages = chatProvider.messages;
    final lastAssistant = messages.reversed.firstWhere(
      (m) => m.role == 'assistant',
      orElse: () => ChatMessage(role: 'assistant', content: ''),
    );

    if (lastAssistant.content.isNotEmpty) {
      // Expression is updated dynamically from ChatProvider (extracted from [EMOTION: ...])
      setState(() {
        _emotion = chatProvider.lastEmotion;
      });

      _startTypewriter(lastAssistant.content);
      _speakIfEnabled(lastAssistant.content);
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
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;
    final surface = themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white);
    final textPrimary = themeProvider?.textPrimary ?? (isDark ? const Color(0xFFDAE2FD) : const Color(0xFF0D1C2E));

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final messages = chatProvider.messages;

        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return Material(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
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
                        Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              color: themeProvider?.primary ?? (isDark ? const Color(0xFF8083FF) : const Color(0xFF4648D4)),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Conversation Log',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              tooltip: 'Clear Chat',
                              onPressed: () {
                                _flutterTts.stop();
                                chatProvider.clearChat();
                                setState(() {
                                  _emotion = 'neutral';
                                  _isTtsSpeaking = false;
                                });
                                _startTypewriter("Chat cleared. How can I help you now?");
                                Navigator.pop(context);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.black45, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(color: themeProvider?.divider ?? (isDark ? Colors.white10 : Colors.black12), height: 20),

                  // Messages List
                  Expanded(
                    child: messages.isEmpty
                        ? Center(
                            child: Text(
                              'No conversation history yet.',
                              style: TextStyle(
                                color: themeProvider?.textSecondary ?? (isDark ? const Color(0xFF908FA0) : const Color(0xFF64748B)),
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 8,
                              bottom: MediaQuery.of(context).padding.bottom + 24,
                            ),
                            itemCount: messages.length,
                            itemBuilder: (ctx, i) {
                              final msg = messages[i];
                              final isUser = msg.role == 'user';
                              return Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.80,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? (themeProvider?.primary ?? const Color(0xFF4648D4))
                                        : (isDark ? const Color(0xFF1E283F) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(16).copyWith(
                                      bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
                                      bottomLeft: !isUser ? const Radius.circular(2) : const Radius.circular(16),
                                    ),
                                    border: Border.all(
                                      color: isUser
                                          ? Colors.transparent
                                          : (themeProvider?.cardBorder ?? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06))),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isUser ? 'YOU' : 'HAWK',
                                        style: TextStyle(
                                          color: isUser
                                              ? Colors.white.withValues(alpha: 0.8)
                                              : (themeProvider?.primary ?? const Color(0xFF8083FF)),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        msg.content,
                                        style: TextStyle(
                                          color: isUser
                                              ? Colors.white
                                              : (themeProvider?.textPrimary ?? (isDark ? Colors.white : const Color(0xFF0D1C2E))),
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

    // Speaking state combines TTS audio output and typewriter animation
    final isTypewriting = !isLoading && _displayedText.isNotEmpty && _displayedText != _targetText;
    final isSpeaking = _isTtsSpeaking || isTypewriting;

    final primaryColor = themeProvider?.primary ?? (isDark ? const Color(0xFF8083FF) : const Color(0xFF4648D4));

    return Scaffold(
      backgroundColor: themeProvider?.bg ?? (isDark ? const Color(0xFF0B1326) : const Color(0xFFF8F9FF)),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header with Focus Mode, Voice Toggle, and Chat Log (Matching website Header)
            HawkHeader(
              title: 'AI Chat & Focus',
              subtitle: 'Intelligent Companion',
              showThemeToggle: false,
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
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.center_focus_strong, size: 13, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Focus Mode',
                          style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Voice On / Off Button (Volume toggle)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isVoiceEnabled
                        ? primaryColor.withValues(alpha: 0.2)
                        : (themeProvider?.circleBtnBg ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05))),
                    border: Border.all(
                      color: _isVoiceEnabled
                          ? primaryColor.withValues(alpha: 0.5)
                          : (themeProvider?.circleBtnBorder ?? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1))),
                    ),
                    boxShadow: _isVoiceEnabled
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isVoiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      size: 18,
                      color: _isVoiceEnabled
                          ? primaryColor
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    tooltip: _isVoiceEnabled ? 'Mute Voice' : 'Enable Voice',
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                    onPressed: _toggleVoice,
                  ),
                ),
                const SizedBox(width: 6),

                // Chat Log Button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeProvider?.circleBtnBg ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    border: Border.all(
                      color: themeProvider?.circleBtnBorder ?? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.history_rounded,
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Character Avatar (with animated face expressions)
                    Center(
                      child: FaceAvatar(
                        isThinking: isLoading,
                        isSpeaking: isSpeaking,
                        emotion: _emotion,
                        size: 170,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Speech Bubble Tail pointing to avatar
                    CustomPaint(
                      size: const Size(20, 12),
                      painter: _SpeechTailPainter(
                        color: themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white),
                      ),
                    ),

                    // Speech Bubble Box
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 120),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        color: themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: themeProvider?.cardBorder ??
                              (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
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
                          // "HAWK" Name Badge (Matching website style)
                          Positioned(
                            top: -36,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4648D4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: themeProvider?.surface ?? (isDark ? const Color(0xFF131B2E) : Colors.white),
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
                              ? Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Thinking...',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  _displayedText,
                                  style: TextStyle(
                                    color: themeProvider?.textPrimary ??
                                        (isDark ? const Color(0xFFDAE2FD) : const Color(0xFF0D1C2E)),
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
                border: Border(
                  top: BorderSide(
                    color: themeProvider?.border ?? (isDark ? Colors.white10 : Colors.black12),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeProvider?.surfaceContainer ??
                            (isDark ? const Color(0xFF171F33) : const Color(0xFFEFF4FF)),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: themeProvider?.cardBorder ??
                              (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black12),
                        ),
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
                            color: themeProvider?.textSecondary ??
                                (isDark ? const Color(0xFF908FA0) : const Color(0xFF64748B)),
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
                      icon: const Icon(Icons.send_rounded, size: 20),
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
