import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand — verbatim from globals.css
  static const Color primary = Color(0xFFB11E2E);
  static const Color primaryDark = Color(0xFF8B1623);
  static const Color brandRedSoft = Color(0xFFF8E5E8);
  static const Color secondary = Color(0xFF0B0B0B); // brand-black (dark surfaces, header)

  // Semantic
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFCA8A04);
  static const Color info = Color(0xFF1D4ED8);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFFAFAFA); // gray-50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF5F5F5); // gray-100

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A); // gray-900
  static const Color textSecondary = Color(0xFF6B6B6B); // gray-500
  static const Color textHint = Color(0xFFA3A3A3); // gray-400

  // Dividers & Shimmer
  static const Color divider = Color(0xFFE5E5E5); // gray-200
  static const Color shimmerBase = Color(0xFFE5E5E5);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
