import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

class AppInputLabel extends StatelessWidget {
  final String text;

  const AppInputLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.labelLarge);
  }
}
