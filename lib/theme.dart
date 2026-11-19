import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF0B0A12);
  static const purple = Color(0xFF9B5CFF);
  static const pink = Color(0xFFFF6FB5);
  static const text = Color(0xFFF4F1FA);
  static const muted = Color(0xFFB9B0CC);
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.bg,
  );
  return base.copyWith(
    textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
  );
}

/// The cosmic background image with a dark gradient so text stays readable.
class SpaceBackground extends StatelessWidget {
  final Widget child;
  const SpaceBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/background.jpg', fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.80),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Translucent "glass" panel. Blur is optional because it is costly in long lists.
class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;

  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 18,
    this.blur = false,
  });

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
    if (!blur) return panel;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: panel,
      ),
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  final Color color;
  const Tag(this.text, {super.key, this.color = AppColors.purple});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppColors.text),
      ),
    );
  }
}
