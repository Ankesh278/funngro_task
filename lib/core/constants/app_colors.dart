import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF1E88E5);
  static const primaryLight = Color(0xFFE3F2FD);
  static const primaryDark = Color(0xFF0D47A1);

  // Surfaces & Borders
  static const surface = Colors.white;
  static const background = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFF1F5F9);

  // Text
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  // Status & Feedback
  static const success = Color(0xFF16A34A);
  static const successLight = Color(0xFFDCFCE7);
  static const successBorder = Color(0xFF86EFAC);

  static const error = Color(0xFFDC2626);
  static const errorLight = Color(0xFFFEE2E2);
  static const errorBorder = Color(0xFFFCA5A5);
  static const errorDark = Color(0xFF991B1B);

  static const warning = Color(0xFFD97706);
}
