import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/widgets/app_button.dart';

/// Sticky Back/Next footer. Back is rendered on every step (via
/// `Visibility.maintain`, not conditionally absent) so the layout never
/// shifts between steps — mirrors the mockup's `visibility:hidden` (not
/// `display:none`) treatment on step 1.
class PersonWizardFooter extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const PersonWizardFooter({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.loading,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Expanded(
                child: Visibility.maintain(
                  visible: currentStep > 0,
                  child: AppButton(
                    label: 'common.back'.tr(),
                    variant: AppButtonVariant.secondary,
                    onPressed: loading ? null : onBack,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AppButton(
                  label: isLastStep ? 'people.wizard.saveCta'.tr() : 'common.next'.tr(),
                  icon: isLastStep ? Icons.check_rounded : null,
                  loading: loading,
                  onPressed: loading ? null : onNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
