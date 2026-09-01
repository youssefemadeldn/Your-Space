import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_password_input.dart';

import 'package:your_space_mobile/features/auth/presentation/cubit/delete_account_cubit/delete_account_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/delete_account_cubit/delete_account_state.dart';

/// Password-confirmed, irreversible account deletion. [host] is the Settings
/// screen's context — used to navigate to login once the dialog has closed.
class DeleteAccountDialog extends StatefulWidget {
  final BuildContext host;

  const DeleteAccountDialog({super.key, required this.host});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'auth.validation.requiredCurrentPassword'.tr());
      return;
    }
    context.read<DeleteAccountCubit>().submit(password: _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('settings.deleteAccountDialog.title'.tr(), style: AppTextStyles.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('settings.deleteAccountDialog.warning'.tr(), style: AppTextStyles.bodyMedium),
          SizedBox(height: 16.h),
          AppPasswordInput(
            label: 'settings.deleteAccountDialog.passwordLabel'.tr(),
            controller: _passwordController,
            errorText: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr()),
        ),
        BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
          listener: (context, state) {
            switch (state) {
              case DeleteAccountSuccess():
                Navigator.of(context).pop();
                if (!widget.host.mounted) return;
                widget.host.go(AppRoutes.login);
                getIt<SnackBarHelper>().showSuccess('settings.deleteAccountDialog.doneMessage'.tr());
              case DeleteAccountError(isNetworkError: true):
                getIt<SnackBarHelper>().showError(
                  'common.networkError'.tr(),
                  actionLabel: 'common.retry'.tr(),
                  onAction: _submit,
                );
              case DeleteAccountError(message: final message):
                setState(() => _error = message);
              case DeleteAccountInitial() || DeleteAccountLoading():
                break;
            }
          },
          builder: (context, state) {
            final loading = state is DeleteAccountLoading;
            return TextButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'settings.deleteAccountDialog.confirm'.tr(),
                      style: const TextStyle(color: AppColors.error),
                    ),
            );
          },
        ),
      ],
    );
  }
}
