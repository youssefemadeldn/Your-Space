import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';

/// Dot+line stepper bar — "Step {n} of 4 · {StepName}" eyebrow above a track
/// of 4 dots connected by 3 lines. Mirrors `person-wizard.html`'s `.stepper-*`
/// composition (upcoming: neutral fill; current: brand-primary + glow;
/// done: brand-primary + check icon; lines turn brand-primary once passed).
class PersonWizardStepIndicator extends StatelessWidget {
  final int currentStep;

  const PersonWizardStepIndicator({super.key, required this.currentStep});

  static const _stepNameKeys = [
    'people.wizard.step1.name',
    'people.wizard.step2.name',
    'people.wizard.step3.name',
    'people.wizard.step4.name',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'people.wizard.stepEyebrow'.tr(namedArgs: {
              'step': '${currentStep + 1}',
              'total': '${_stepNameKeys.length}',
              'name': _stepNameKeys[currentStep].tr(),
            }),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              for (var i = 0; i < _stepNameKeys.length; i++) ...[
                _StepDot(index: i, currentStep: currentStep),
                if (i != _stepNameKeys.length - 1)
                  Expanded(
                    child: Container(
                      height: 2.h,
                      color: i < currentStep ? AppColors.primary : AppColors.divider,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final int currentStep;

  const _StepDot({required this.index, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final isDone = index < currentStep;
    final isCurrent = index == currentStep;
    final backgroundColor = isDone || isCurrent ? AppColors.primary : AppColors.inputFill;
    final foregroundColor = isDone || isCurrent ? AppColors.surface : AppColors.textSecondary;

    return Container(
      width: 26.w,
      height: 26.w,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: isCurrent
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 8)]
            : null,
      ),
      alignment: Alignment.center,
      child: isDone
          ? Icon(Icons.check_rounded, size: 14.w, color: foregroundColor)
          : Text(
              '${index + 1}',
              style: AppTextStyles.labelSmall.copyWith(color: foregroundColor, fontWeight: FontWeight.w700),
            ),
    );
  }
}
