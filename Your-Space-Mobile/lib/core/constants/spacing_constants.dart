import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Lazy getters only — ScreenUtil must be initialized before `.w`/`.h` run,
/// so these can never be `static const`.
class AppSpacing {
  AppSpacing._();

  // Horizontal
  static double get s4 => 4.w;
  static double get s8 => 8.w;
  static double get s12 => 12.w;
  static double get s16 => 16.w;
  static double get s20 => 20.w;
  static double get s24 => 24.w;
  static double get s32 => 32.w;
  static double get s48 => 48.w;
  static double get s64 => 64.w;

  // Vertical
  static double get v4 => 4.h;
  static double get v8 => 8.h;
  static double get v12 => 12.h;
  static double get v16 => 16.h;
  static double get v20 => 20.h;
  static double get v24 => 24.h;
  static double get v32 => 32.h;
  static double get v48 => 48.h;
  static double get v64 => 64.h;
}
