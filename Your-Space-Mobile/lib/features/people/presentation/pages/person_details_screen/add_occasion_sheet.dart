import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/helpers/bottom_sheet_helper.dart';
import 'package:your_space_mobile/core/helpers/date_formatter_helper.dart';
import 'package:your_space_mobile/core/mock/entities/invite_method.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_switch.dart';
import 'package:your_space_mobile/core/widgets/invite_method_chip_group.dart';

import '../../cubit/add_occasion_cubit/add_occasion_cubit.dart';
import '../../cubit/add_occasion_cubit/add_occasion_state.dart';

class AddOccasionSheet extends StatefulWidget {
  final int personId;
  final String personName;

  const AddOccasionSheet({super.key, required this.personId, required this.personName});

  static Future<void> open(BuildContext context, {required int personId, required String personName}) {
    final actionCubit = context.read<AddOccasionCubit>();
    return BottomSheetHelper.showAppBottomSheet(
      context,
      BlocProvider.value(
        value: actionCubit,
        child: AddOccasionSheet(personId: personId, personName: personName),
      ),
      isScrollable: true,
      maxHeightFraction: 0.85,
    );
  }

  @override
  State<AddOccasionSheet> createState() => _AddOccasionSheetState();
}

class _AddOccasionSheetState extends State<AddOccasionSheet> {
  bool _invitedMe = true;
  InviteMethod? _inviteMethod;
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _date;

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateController.text = DateFormatterHelper.formatDate(picked);
    });
  }

  void _submit() {
    context.read<AddOccasionCubit>().submit(
          personId: widget.personId,
          invitedMe: _invitedMe,
          inviteMethod: _invitedMe ? _inviteMethod : null,
          occasionName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
          occasionDate: _date,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
      child: BlocConsumer<AddOccasionCubit, AddOccasionState>(
        listener: (context, state) {
          if (state is AddOccasionSuccess) Navigator.of(context).pop();
        },
        builder: (context, state) {
          final submitting = state is AddOccasionSubmitting;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'people.occasion.addTitle'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                AppSwitch(
                  checked: _invitedMe,
                  label: 'people.occasion.invitedSwitch'.tr(namedArgs: {'name': widget.personName}),
                  onChanged: submitting ? null : (value) => setState(() => _invitedMe = value),
                ),
                SizedBox(height: 14.h),
                if (_invitedMe)
                  InviteMethodChipGroup(
                    selected: _inviteMethod,
                    onChanged: submitting ? (_) {} : (method) => setState(() => _inviteMethod = method),
                  )
                else
                  Text(
                    'people.occasion.methodHint'.tr(),
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                SizedBox(height: 14.h),
                AppInput(
                  label: 'people.occasion.nameLabel'.tr(),
                  controller: _nameController,
                  enabled: !submitting,
                ),
                SizedBox(height: 14.h),
                InkWell(
                  onTap: submitting ? null : _pickDate,
                  child: IgnorePointer(
                    child: AppInput(
                      label: 'people.occasion.dateLabel'.tr(),
                      hintText: 'people.occasion.dateFutureHint'.tr(),
                      suffixIcon: Icon(Icons.calendar_today_rounded, size: 18.w),
                      controller: _dateController,
                      enabled: !submitting,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                AppInput(
                  label: 'people.occasion.notesLabel'.tr(),
                  controller: _notesController,
                  multiline: true,
                  enabled: !submitting,
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'common.cancel'.tr(),
                        variant: AppButtonVariant.secondary,
                        onPressed: submitting ? null : () => Navigator.of(context).pop(),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: AppButton(
                        label: 'common.save'.tr(),
                        loading: submitting,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
