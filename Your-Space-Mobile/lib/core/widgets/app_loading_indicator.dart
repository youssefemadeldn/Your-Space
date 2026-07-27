import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double? size;

  const AppLoadingIndicator({super.key, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    final resolvedSize = size ?? 32.w;
    return Center(
      child: SizedBox(
        width: resolvedSize,
        height: resolvedSize,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
      ),
    );
  }
}
