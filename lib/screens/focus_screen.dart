import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/hawk_header.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final ApiService _apiService = ApiService();
  int _timerMinutes = 25;
  int _timerSeconds = 0;
  bool _isFocusing = false;
  int? _earnedPoints;
  
  int _initialMinutes = 25;
  Timer? _timer;

  void _startFocus() {
    if (_timerMinutes <= 0 && _timerSeconds <= 0) return;
    
    setState(() {
      _initialMinutes = _timerMinutes;
      _isFocusing = true;
      _earnedPoints = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerSeconds == 0) {
          if (_timerMinutes == 0) {
            timer.cancel();
            _finishFocus();
          } else {
            _timerMinutes--;
            _timerSeconds = 59;
          }
        } else {
          _timerSeconds--;
        }
      });
    });
  }

  void _cancelFocus() {
    _timer?.cancel();
    setState(() {
      _isFocusing = false;
      _timerMinutes = _initialMinutes;
      _timerSeconds = 0;
    });
  }

  Future<void> _finishFocus() async {
    setState(() {
      _isFocusing = false;
    });
    
    int pointsToAward = _initialMinutes > 0 ? _initialMinutes : 1;
    
    try {
      final response = await _apiService.post('/user/points', {'points': pointsToAward});
      if (response.statusCode == 200) {
        setState(() {
          _earnedPoints = pointsToAward;
        });
      }
    } catch (e) {
      debugPrint('Failed to award points: $e');
    }
  }

  String _formatTime(int m, int s) {
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDark = themeProvider?.isDarkMode ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      body: SafeArea(
        child: Column(
          children: [
            const HawkHeader(
              title: 'Deep Focus',
              subtitle: 'Distraction-Free Timer',
              showBack: true,
            ),
            Expanded(
              child: Stack(
                children: [
                  // Background Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [Colors.blue.shade900, Colors.black87]
                            : [const Color(0xFF4648D4), const Color(0xFF131B2E)],
                      ),
                    ),
                  ),
                  
                  Center(
                    child: _isFocusing ? _buildActiveTimer() : _buildSetupTimer(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupTimer() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Focus Mode', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Eliminate distractions and get things done.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 32),
          
          // Face Avatar placeholder
          const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.face, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 32),

          if (_earnedPoints != null)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 40),
                  const SizedBox(height: 8),
                  const Text('Session Complete!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('You earned +$_earnedPoints Hawk Points', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),

          const Text('SET TIMER (MINUTES)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _timerMinutes = (_timerMinutes - 5).clamp(1, 120);
                  });
                },
                icon: const Icon(Icons.remove, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
              ),
              const SizedBox(width: 24),
              Text(
                _timerMinutes.toString(),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: () {
                  setState(() {
                    _timerMinutes = (_timerMinutes + 5).clamp(1, 120);
                  });
                },
                icon: const Icon(Icons.add, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _startFocus,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Focus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTimer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 80,
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.face, size: 100, color: Colors.white),
        ),
        const SizedBox(height: 48),
        
        Text(
          _formatTime(_timerMinutes, _timerSeconds),
          style: const TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 16),
        
        const Text(
          'DEEP WORK IN PROGRESS',
          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 2.0),
        ),
        const SizedBox(height: 48),
        
        OutlinedButton.icon(
          onPressed: _cancelFocus,
          icon: const Icon(Icons.close),
          label: const Text('Give Up'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          ),
        ),
      ],
    );
  }
}
