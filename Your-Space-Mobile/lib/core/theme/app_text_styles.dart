import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_font_weight.dart';

class AppTextStyles {
  AppTextStyles._();

  // Cairo — display & headings (Arabic-optimised for large text)
  static TextStyle get displayLarge => GoogleFonts.cairo(
        fontSize: 34.sp,
        fontWeight: AppFontWeight.extraBold,
        color: AppColors.textPrimary,
        height: 1.15,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.cairo(
        fontSize: 28.sp,
        fontWeight: AppFontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get headlineLarge => GoogleFonts.cairo(
        fontSize: 32.sp,
        fontWeight: AppFontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get headlineMedium => GoogleFonts.cairo(
        fontSize: 28.sp,
        fontWeight: AppFontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get headlineSmall => GoogleFonts.cairo(
        fontSize: 24.sp,
        fontWeight: AppFontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  // Tajawal — body & UI (Arabic-first, strong Latin coverage)
  static TextStyle get titleLarge => GoogleFonts.tajawal(
        fontSize: 22.sp,
        fontWeight: AppFontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get titleMedium => GoogleFonts.tajawal(
        fontSize: 18.sp,
        fontWeight: AppFontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyLarge => GoogleFonts.tajawal(
        fontSize: 16.sp,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textPrimary,
        height: 1.7,
      );

  static TextStyle get bodyMedium => GoogleFonts.tajawal(
        fontSize: 14.sp,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textPrimary,
        height: 1.7,
      );

  static TextStyle get bodySmall => GoogleFonts.tajawal(
        fontSize: 12.sp,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textSecondary,
        height: 1.7,
      );

  static TextStyle get labelLarge => GoogleFonts.tajawal(
        fontSize: 14.sp,
        fontWeight: AppFontWeight.medium,
        color: AppColors.textPrimary,
      );

  // Inter — Latin micro-labels (eyebrows, caps badges)
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: AppFontWeight.semiBold,
        color: AppColors.textSecondary,
        letterSpacing: 0.14 * 11.sp,
      );
}
