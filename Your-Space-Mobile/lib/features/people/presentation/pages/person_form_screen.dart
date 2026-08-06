import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/helpers/regex_helper.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/person_form_args.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_input_label.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/app_select.dart';
import 'package:your_space_mobile/core/widgets/gender_chip_group.dart';

import '../cubit/person_form_cubit/person_form_cubit.dart';
import '../cubit/person_form_cubit/person_form_state.dart';

class PersonFormScreen extends StatefulWidget {
  final PersonFormArgs args;

  const PersonFormScreen({super.key, required this.args});

  @override
  State<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends State<PersonFormScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _notesController = TextEditingController();
  int? _selectedGroupId;
  Gender? _selectedGender;
  List<Group> _availableGroups = const [];
  String? _nameError;
  String? _phoneError;
  String? _phone2Error;
  String? _genderError;
  bool _initialized = false;

  bool get _isEditing => widget.args.personId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _seedFromReady(PersonFormReady state) {
    _availableGroups = state.availableGroups;
    if (_initialized) return;
    _initialized = true;
    final person = state.person;
    if (person != null) {
      _nameController.text = person.name;
      _phoneController.text = person.phoneNumber ?? '';
      _phone2Controller.text = person.phoneNumber2 ?? '';
      _notesController.text = person.notes ?? '';
      _selectedGroupId = person.groupId;
      _selectedGender = person.gender;
    } else if (state.availableGroups.isNotEmpty) {
      _selectedGroupId = state.availableGroups.first.id;
    }
  }

  String? get _selectedGroupName {
    for (final group in _availableGroups) {
      if (group.id == _selectedGroupId) return group.name;
    }
    return null;
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final phone2 = _phone2Controller.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'people.form.nameRequired'.tr() : null;
      _phoneError = phone.isEmpty || RegexHelper.validate(RegexHelper.internationalPhone, phone)
          ? null
          : 'auth.validation.invalidPhone'.tr();
      _phone2Error = phone2.isEmpty || RegexHelper.validate(RegexHelper.internationalPhone, phone2)
          ? null
          : 'auth.validation.invalidPhone'.tr();
      _genderError = _selectedGender == null ? 'people.form.genderRequired'.tr() : null;
    });
    return _nameError == null &&
        _phoneError == null &&
        _phone2Error == null &&
        _genderError == null &&
        _selectedGroupId != null;
  }

  void _submit() {
    if (!_validate()) return;
    context.read<PersonFormCubit>().submit(
          personId: widget.args.personId,
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          phoneNumber2: _phone2Controller.text.trim().isEmpty ? null : _phone2Controller.text.trim(),
          gender: _selectedGender!,
          groupId: _selectedGroupId!,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: _isEditing ? 'people.form.editTitle'.tr() : 'people.form.createTitle'.tr(),
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: BlocConsumer<PersonFormCubit, PersonFormState>(
          listener: (context, state) {
            if (state is PersonFormSuccess) {
              getIt<SnackBarHelper>().showSuccess('people.form.savedMessage'.tr());
              context.pop();
            } else if (state is PersonFormError) {
              getIt<SnackBarHelper>().showError(state.message);
            }
          },
          builder: (context, state) {
            if (state is PersonFormInitial || state is PersonFormLoading) {
              return const AppLoadingIndicator();
            }
            if (state is PersonFormReady) _seedFromReady(state);

            final submitting = state is PersonFormSubmitting;
            final noGroups = _availableGroups.isEmpty;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppInput(
                    label: 'people.form.nameLabel'.tr(),
                    controller: _nameController,
                    errorText: _nameError,
                    enabled: !submitting,
                    maxLength: 200,
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),
                  SizedBox(height: 14.h),
                  AppInput(
                    label: 'people.form.phoneLabel'.tr(),
                    hintText: '+201234567890',
                    prefixIcon: Icons.call_outlined,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    controller: _phoneController,
                    errorText: _phoneError,
                    enabled: !submitting,
                    onChanged: (_) {
                      if (_phoneError != null) setState(() => _phoneError = null);
                    },
                  ),
                  SizedBox(height: 14.h),
                  AppInput(
                    label: 'people.form.phone2Label'.tr(),
                    hintText: '+201234567890',
                    prefixIcon: Icons.call_outlined,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    controller: _phone2Controller,
                    errorText: _phone2Error,
                    enabled: !submitting,
                    onChanged: (_) {
                      if (_phone2Error != null) setState(() => _phone2Error = null);
                    },
                  ),
                  SizedBox(height: 14.h),
                  AppInputLabel('people.form.genderLabel'.tr()),
                  SizedBox(height: 8.h),
                  GenderChipGroup(
                    selected: _selectedGender,
                    onChanged: submitting
                        ? (_) {}
                        : (gender) => setState(() {
                              _selectedGender = gender;
                              _genderError = null;
                            }),
                  ),
                  if (_genderError != null) ...[
                    SizedBox(height: 6.h),
                    Text(_genderError!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                  ],
                  SizedBox(height: 14.h),
                  if (noGroups)
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: AppColors.brandRedSoft,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('people.form.noGroupsCallout'.tr(), style: AppTextStyles.bodyMedium),
                          SizedBox(height: 10.h),
                          AppButton(
                            label: 'people.form.createGroupCta'.tr(),
                            variant: AppButtonVariant.soft,
                            size: AppButtonSize.sm,
                            onPressed: () => context.go(AppRoutes.groups),
                          ),
                        ],
                      ),
                    )
                  else
                    AppSelect(
                      label: 'people.form.groupLabel'.tr(),
                      value: _selectedGroupName,
                      options: _availableGroups.map((g) => g.name).toList(),
                      enabled: !submitting,
                      onChanged: (name) {
                        final match = _availableGroups.firstWhere((g) => g.name == name);
                        setState(() => _selectedGroupId = match.id);
                      },
                    ),
                  SizedBox(height: 14.h),
                  AppInput(
                    label: 'people.form.notesLabel'.tr(),
                    controller: _notesController,
                    multiline: true,
                    maxLength: 2000,
                    enabled: !submitting,
                  ),
                  SizedBox(height: 20.h),
                  AppButton(
                    label: _isEditing ? 'common.saveChanges'.tr() : 'people.form.saveCta'.tr(),
                    fullWidth: true,
                    loading: submitting,
                    onPressed: noGroups ? null : _submit,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
