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
  late AnimationController _thinkController;
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
      duration: const Duration(milliseconds: 140),
    );

    // Talking animation
    _talkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Thinking pulsating animation
    _thinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.isSpeaking) {
      _talkController.repeat(reverse: true);
    }

    if (widget.isThinking) {
      _thinkController.repeat(reverse: true);
    }

    _scheduleNextBlink();
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

    // Speaking state changed
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _talkController.repeat(reverse: true);
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _talkController.stop();
      _talkController.reset();
    }

    // Thinking state changed
    if (widget.isThinking && !oldWidget.isThinking) {
      _thinkController.repeat(reverse: true);
    } else if (!widget.isThinking && oldWidget.isThinking) {
      _thinkController.stop();
      _thinkController.reset();
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _floatController.dispose();
    _blinkController.dispose();
    _talkController.dispose();
    _thinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAction = widget.isThinking || widget.isSpeaking || widget.emotion != 'neutral';

    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _blinkController, _talkController, _thinkController]),
      builder: (context, child) {
        final floatOffset = math.sin(_floatController.value * 2 * math.pi) * 8;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.size * 0.32),
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isAction ? const Color(0xFF93C5FD) : const Color(0xFF60A5FA).withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isAction
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.65)
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
                // Inner Glow Overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * 0.32),
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      radius: 0.8,
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Eyes & Eyebrows Container
                Positioned(
                  top: widget.size * 0.30,
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
                  bottom: widget.size * 0.20,
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

    // Emotion eyebrow angles and offsets (Exact replica of FaceAvatar.jsx)
    double eyebrowAngle = 0.0;
    double eyebrowY = 0.0;

    if (widget.emotion == 'angry') {
      eyebrowAngle = isLeft ? (20 * math.pi / 180) : (-20 * math.pi / 180);
      eyebrowY = 3.0;
      scaleY *= 0.6;
    } else if (widget.emotion == 'happy') {
      eyebrowAngle = 0.0;
      eyebrowY = -8.0;
    } else if (widget.emotion == 'worried') {
      eyebrowAngle = isLeft ? (-15 * math.pi / 180) : (15 * math.pi / 180);
      eyebrowY = -3.0;
    } else if (widget.emotion == 'confused') {
      eyebrowAngle = isLeft ? (15 * math.pi / 180) : (10 * math.pi / 180);
      eyebrowY = isLeft ? 1.0 : -6.0;
      if (isLeft) scaleY *= 0.6;
    } else if (widget.isThinking) {
      eyebrowAngle = isLeft ? (5 * math.pi / 180) : (-5 * math.pi / 180);
      eyebrowY = 2.0;
    }

    final eyeWidth = widget.size * 0.15;
    final eyeHeight = widget.size * 0.21;

    final isThinkingPulse = widget.isThinking && widget.emotion == 'neutral';
    final glowPulse = isThinkingPulse ? (_thinkController.value * 6) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Eyebrow
        Transform.translate(
          offset: Offset(0, eyebrowY),
          child: Transform.rotate(
            angle: eyebrowAngle,
            child: Container(
              width: eyeWidth * 1.4,
              height: 5.5,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),

        // Glowing Eye
        Transform.scale(
          scaleY: scaleY,
          child: Container(
            width: eyeWidth,
            height: eyeHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(eyeWidth * 0.38),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22D3EE).withValues(alpha: 0.85),
                  blurRadius: 18 + glowPulse,
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
    double baseWidth = widget.size * 0.22;
    double baseHeight = widget.size * 0.045;

    // Talking animation height modulation
    if (widget.isSpeaking) {
      baseHeight = widget.size * (0.04 + _talkController.value * 0.07);
    }

    if (widget.emotion == 'happy') {
      final happyWidth = widget.size * 0.28;
      final happyHeight = widget.isSpeaking
          ? widget.size * (0.08 + _talkController.value * 0.06)
          : widget.size * 0.11;

      return Container(
        width: happyWidth,
        height: happyHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF22D3EE),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(2),
            bottom: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22D3EE).withValues(alpha: 0.9),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 10,
            ),
          ],
        ),
      );
    } else if (widget.emotion == 'angry') {
      final angryWidth = widget.size * 0.18;
      final angryHeight = widget.isSpeaking ? (4.0 + _talkController.value * 5.0) : 3.0;

      return Container(
        width: angryWidth,
        height: angryHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.85),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    } else if (widget.emotion == 'worried') {
      final worriedWidth = widget.size * 0.12;
      final worriedHeight = widget.isSpeaking
          ? widget.size * (0.04 + _talkController.value * 0.04)
          : widget.size * 0.05;

      return Container(
        width: worriedWidth,
        height: worriedHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF67E8F9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF67E8F9).withValues(alpha: 0.7),
              blurRadius: 12,
            ),
          ],
        ),
      );
    } else if (widget.emotion == 'confused') {
      final confusedWidth = widget.size * 0.18;
      final confusedHeight = widget.isSpeaking
          ? widget.size * (0.04 + _talkController.value * 0.04)
          : widget.size * 0.055;

      return Transform.translate(
        offset: const Offset(4, 0),
        child: Transform.rotate(
          angle: -15 * math.pi / 180,
          child: Container(
            width: confusedWidth,
            height: confusedHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF67E8F9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF67E8F9).withValues(alpha: 0.7),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Default Neutral Mouth
    return Container(
      width: baseWidth,
      height: baseHeight,
      decoration: BoxDecoration(
        color: widget.isSpeaking ? const Color(0xFF22D3EE) : const Color(0xFFBAE6FD).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22D3EE).withValues(alpha: widget.isSpeaking ? 0.9 : 0.4),
            blurRadius: widget.isSpeaking ? 16 : 8,
            spreadRadius: widget.isSpeaking ? 1 : 0,
          ),
        ],
      ),
    );
  }
}
