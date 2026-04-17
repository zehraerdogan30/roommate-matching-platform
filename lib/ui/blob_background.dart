import 'dart:math' as math;
import 'package:flutter/material.dart';

class BlobBackground extends StatefulWidget {
  final Widget child;
  const BlobBackground({super.key, required this.child});

  @override
  State<BlobBackground> createState() => _BlobBackgroundState();
}

class _BlobBackgroundState extends State<BlobBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final a = math.sin(t * math.pi * 2);
        final b = math.cos(t * math.pi * 2);

        return Stack(
          children: [
            // base gradient wash
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6E5AE6).withOpacity(0.14),
                    const Color(0xFFFF5EA8).withOpacity(0.08),
                    const Color(0xFF22D3EE).withOpacity(0.10),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.35, 0.7, 1.0],
                ),
              ),
            ),

            // blobs
            Positioned(
              top: -120 + 20 * a,
              left: -80 + 25 * b,
              child: _blob(260, const Color(0xFF6E5AE6), 0.18),
            ),
            Positioned(
              bottom: -160 + 25 * b,
              right: -100 + 20 * a,
              child: _blob(320, const Color(0xFFFF5EA8), 0.14),
            ),
            Positioned(
              top: 140 + 16 * b,
              right: -140 + 18 * a,
              child: _blob(240, const Color(0xFF22D3EE), 0.12),
            ),

            widget.child,
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(0.0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
