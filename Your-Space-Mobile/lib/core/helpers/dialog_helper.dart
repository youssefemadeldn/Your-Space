import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:injectable/injectable.dart';

import '../theme/app_text_styles.dart';

@lazySingleton
class DialogHelper {
  final GlobalKey<NavigatorState> _navigatorKey;

  DialogHelper(this._navigatorKey);

  BuildContext? get _context => _navigatorKey.currentContext;

  Future<void> showAppDialog({
    required String title,
    required String message,
    String confirmText = 'OK',
    VoidCallback? onConfirm,
  }) {
    final context = _context;
    if (context == null) return Future.value();

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: AppTextStyles.titleMedium),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onConfirm?.call();
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<void> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    final context = _context;
    if (context == null) return Future.value();

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: AppTextStyles.titleMedium),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onCancel?.call();
            },
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onConfirm?.call();
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<void> showLoadingDialog() {
    final context = _context;
    if (context == null) return Future.value();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: const CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  void hideDialog() {
    final context = _context;
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
