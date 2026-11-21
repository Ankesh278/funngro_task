import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const h1 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const subtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const badge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static const payout = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.success,
  );

  static const infoHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const errorText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.errorDark,
  );
}
