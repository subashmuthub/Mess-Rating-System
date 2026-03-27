import 'package:flutter/material.dart';

class AppStyle {
  static const Color primary = Color(0xFF0C4A6E);
  static const Color primaryDark = Color(0xFF082F49);
  static const Color accent = Color(0xFF0EA5E9);
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color pageBackground = Color(0xFFF4F7FB);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static BoxDecoration authFieldDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
    );
  }
}
