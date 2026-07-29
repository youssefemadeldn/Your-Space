import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/helpers/bottom_sheet_helper.dart';
import 'package:your_space_mobile/core/mock/entities/group.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';

import '../../cubit/group_action_cubit/group_action_cubit.dart';
import '../../cubit/group_action_cubit/group_action_state.dart';

class GroupFormSheet extends StatefulWidget {
  final Group? group;

  const GroupFormSheet({super.key, this.group});

  /// A modal bottom sheet is a sibling route of the page in the Navigator's
  /// overlay, not a descendant of the page-level `BlocProvider` — so the
  /// already-resolved cubit instance must be explicitly re-provided into it.
  static Future<void> open(BuildContext context, {Group? group}) {
    final actionCubit = context.read<GroupActionCubit>();
    return BottomSheetHelper.showAppBottomSheet(
      context,
      BlocProvider.value(value: actionCubit, child: GroupFormSheet(group: group)),
    );
  }

  @override
  State<GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends State<GroupFormSheet> {
  late final _nameController = TextEditingController(text: widget.group?.name);
  late final _nameArController = TextEditingController(text: widget.group?.nameAr);
  String? _nameError;

  bool get _isEditing => widget.group != null;

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'groups.form.nameRequired'.tr());
      return;
    }
    final nameAr = _nameArController.text.trim();
    final cubit = context.read<GroupActionCubit>();
    if (_isEditing) {
      cubit.updateGroup(id: widget.group!.id, name: name, nameAr: nameAr.isEmpty ? null : nameAr);
    } else {
      cubit.createGroup(name: name, nameAr: nameAr.isEmpty ? null : nameAr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEditing ? 'groups.form.editTitle'.tr() : 'groups.form.createTitle'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          BlocBuilder<GroupActionCubit, GroupActionState>(
            builder: (context, state) {
              final submitting = state is GroupActionSubmitting;
              return AppInput(
                label: 'groups.form.nameLabel'.tr(),
                controller: _nameController,
                errorText: _nameError,
                enabled: !submitting,
                maxLength: 200,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              );
            },
          ),
          SizedBox(height: 12.h),
          BlocBuilder<GroupActionCubit, GroupActionState>(
            builder: (context, state) => AppInput(
              label: 'groups.form.nameArLabel'.tr(),
              controller: _nameArController,
              enabled: state is! GroupActionSubmitting,
              maxLength: 200,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: BlocBuilder<GroupActionCubit, GroupActionState>(
                  builder: (context, state) => AppButton(
                    label: 'common.cancel'.tr(),
                    variant: AppButtonVariant.secondary,
                    onPressed: state is GroupActionSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: BlocBuilder<GroupActionCubit, GroupActionState>(
                  builder: (context, state) => AppButton(
                    label: _isEditing ? 'common.saveChanges'.tr() : 'groups.form.createCta'.tr(),
                    loading: state is GroupActionSubmitting,
                    onPressed: _submit,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
