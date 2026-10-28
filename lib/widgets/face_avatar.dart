import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class FaceAvatar extends StatefulWidget {
  final bool isThinking;
  final bool isSpeaking;
  final String emotion; // 'neutral', 'happy', 'angry', 'worried', 'confused'
  final double size;

  const FaceAvatar({
    super.key,
    this.isThinking = false,
    this.isSpeaking = false,
    this.emotion = 'neutral',
    this.size = 180,
  });

  @override
  State<FaceAvatar> createState() => _FaceAvatarState();
}

class _FaceAvatarState extends State<FaceAvatar> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _blinkController;
  late AnimationController _talkController;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();

    // Floating animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Blinking animation
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Periodic blink timer
    _scheduleNextBlink();

    // Talking animation
    _talkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    if (widget.isSpeaking) {
      _talkController.repeat(reverse: true);
    }
  }

  void _scheduleNextBlink() {
    if (!mounted) return;
    _blinkTimer = Timer(Duration(seconds: 3 + math.Random().nextInt(4)), () async {
      if (!mounted) return;
      if (!widget.isThinking) {
        await _blinkController.forward();
        if (mounted) await _blinkController.reverse();
      }
      _scheduleNextBlink();
    });
  }

  @override
  void didUpdateWidget(covariant FaceAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _talkController.repeat(reverse: true);
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _talkController.stop();
      _talkController.reset();
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _floatController.dispose();
    _blinkController.dispose();
    _talkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAction = widget.isThinking || widget.isSpeaking || widget.emotion != 'neutral';

    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _blinkController, _talkController]),
      builder: (context, child) {
        final floatOffset = math.sin(_floatController.value * 2 * math.pi) * 8;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.size * 0.3),
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isAction ? const Color(0xFF93C5FD) : const Color(0xFF60A5FA),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isAction
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.6)
                      : const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: isAction ? 36 : 24,
                  spreadRadius: isAction ? 4 : 1,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Eyes Row
                Positioned(
                  top: widget.size * 0.32,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildEye(isLeft: true),
                      SizedBox(width: widget.size * 0.22),
                      _buildEye(isLeft: false),
                    ],
                  ),
                ),

                // Mouth
                Positioned(
                  bottom: widget.size * 0.22,
                  child: _buildMouth(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEye({required bool isLeft}) {
    double scaleY = 1.0 - (_blinkController.value * 0.85);

    // Emotion eyebrow rotation
    double eyebrowAngle = 0.0;
    double eyebrowY = 0.0;

    if (widget.emotion == 'angry') {
      eyebrowAngle = isLeft ? (20 * math.pi / 180) : (-20 * math.pi / 180);
      eyebrowY = 2;
      scaleY *= 0.6;
    } else if (widget.emotion == 'happy') {
      eyebrowY = -4;
    } else if (widget.emotion == 'worried') {
      eyebrowAngle = isLeft ? (-15 * math.pi / 180) : (15 * math.pi / 180);
      eyebrowY = -2;
    } else if (widget.emotion == 'confused') {
      eyebrowAngle = isLeft ? (15 * math.pi / 180) : (10 * math.pi / 180);
      eyebrowY = isLeft ? 1 : -4;
      if (isLeft) scaleY *= 0.7;
    } else if (widget.isThinking) {
      eyebrowAngle = isLeft ? (5 * math.pi / 180) : (-5 * math.pi / 180);
      eyebrowY = 2;
    }

    final eyeWidth = widget.size * 0.16;
    final eyeHeight = widget.size * 0.22;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Eyebrow
        Transform.translate(
          offset: Offset(0, eyebrowY),
          child: Transform.rotate(
            angle: eyebrowAngle,
            child: Container(
              width: eyeWidth * 1.3,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Glowing Eye
        Transform.scale(
          scaleY: scaleY,
          child: Container(
            width: eyeWidth,
            height: eyeHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(eyeWidth * 0.35),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF67E8F9).withValues(alpha: 0.9),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Colors.white,
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMouth() {
    double width = widget.size * 0.22;
    double height = widget.size * 0.05;

    if (widget.isSpeaking) {
      height = widget.size * (0.04 + _talkController.value * 0.06);
    }

    if (widget.emotion == 'happy') {
      width = widget.size * 0.3;
      height = widget.size * 0.1;
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF22D3EE),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22D3EE).withValues(alpha: 0.8),
              blurRadius: 16,
            ),
          ],
        ),
      );
    } else if (widget.emotion == 'worried') {
      return Container(
        width: widget.size * 0.14,
        height: widget.size * 0.06,
        decoration: BoxDecoration(
          color: const Color(0xFF67E8F9),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: const Color(0xFF67E8F9).withValues(alpha: 0.6), blurRadius: 10),
          ],
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22D3EE).withValues(alpha: 0.8),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
