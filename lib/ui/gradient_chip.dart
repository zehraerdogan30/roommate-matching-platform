import 'package:flutter/material.dart';

class GradientChip extends StatelessWidget {
  final String text;
  const GradientChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6E5AE6).withOpacity(0.20),
            const Color(0xFFFF5EA8).withOpacity(0.12),
            const Color(0xFF22D3EE).withOpacity(0.14),
          ],
        ),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
