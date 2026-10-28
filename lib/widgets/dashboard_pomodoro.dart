import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPomodoro extends StatefulWidget {
  const DashboardPomodoro({super.key});

  @override
  State<DashboardPomodoro> createState() => _DashboardPomodoroState();
}

class _DashboardPomodoroState extends State<DashboardPomodoro> {
  int _timerSeconds = 25 * 60;
  bool _isRunning = false;
  int _timerMode = 25; // 25 for focus, 5 for break
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timerSeconds > 0) {
          setState(() => _timerSeconds--);
        } else {
          timer.cancel();
          setState(() => _isRunning = false);
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _timerSeconds = _timerMode * 60;
    });
  }

  void _toggleMode() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _timerMode = _timerMode == 25 ? 5 : 25;
      _timerSeconds = _timerMode * 60;
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  TextStyle _outfit({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing}) {
    try {
      return GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    } catch (_) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF171F33),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4648D4).withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Bar: Mode Title & Toggle Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _timerMode == 25 ? 'DEEP FOCUS' : 'SHORT BREAK',
                style: _outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: const Color(0xFF908FA0),
                ),
              ),
              InkWell(
                onTap: _toggleMode,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Switch to ${_timerMode == 25 ? 'Break' : 'Focus'}',
                    style: const TextStyle(
                      color: Color(0xFF8083FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Digital Timer Display
          Text(
            _formatTime(_timerSeconds),
            style: _outfit(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFC0C1FF),
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 16),

          // Action Controls: Reset, Play/Pause, Skip
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset Button
              IconButton.filledTonal(
                onPressed: _resetTimer,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                icon: const Icon(Icons.replay, size: 20),
              ),
              const SizedBox(width: 16),

              // Play / Pause Main Button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4648D4).withValues(alpha: 0.4),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton.filled(
                  onPressed: _toggleTimer,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF4648D4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Switch / Skip Button
              IconButton.filledTonal(
                onPressed: _toggleMode,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.all(12),
                ),
                icon: const Icon(Icons.skip_next, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
