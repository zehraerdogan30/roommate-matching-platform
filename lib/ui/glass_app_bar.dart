import 'dart:ui';
import 'package:flutter/material.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final bool centerTitle;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AppBar(
          centerTitle: centerTitle,
          title: title,
          actions: actions,
          backgroundColor: Colors.white.withOpacity(0.55),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
    );
  }
}
