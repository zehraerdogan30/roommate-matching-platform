import 'package:flutter/material.dart';

class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const BouncyButton({super.key, required this.child, this.onPressed});

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (widget.onPressed == null) return;
    await _c.forward();
    await _c.reverse();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final scale = 1 - _c.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: _tap,
        behavior: HitTestBehavior.opaque,
        child: widget.child,
      ),
    );
  }
}
