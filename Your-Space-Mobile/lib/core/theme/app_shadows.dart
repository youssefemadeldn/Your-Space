import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> softLg = [
    BoxShadow(color: Color(0x14000000), blurRadius: 40, offset: Offset(0, 12)),
  ];

  // Brand-red tinted shadow for primary CTAs
  static const List<BoxShadow> brand = [
    BoxShadow(color: Color(0x38B11E2E), blurRadius: 28, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> header = [
    BoxShadow(color: Color(0x73000000), blurRadius: 40, offset: Offset(0, 12)),
  ];
}
