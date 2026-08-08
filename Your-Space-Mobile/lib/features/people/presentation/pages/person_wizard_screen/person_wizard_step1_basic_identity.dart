import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_input_label.dart';
import 'package:your_space_mobile/core/widgets/gender_chip_group.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/person_wizard_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/person_wizard_state.dart';

import 'person_wizard_photo_grid.dart';

class PersonWizardStep1BasicIdentity extends StatefulWidget {
  const PersonWizardStep1BasicIdentity({super.key});

  @override
  State<PersonWizardStep1BasicIdentity> createState() => _PersonWizardStep1BasicIdentityState();
}

class _PersonWizardStep1BasicIdentityState extends State<PersonWizardStep1BasicIdentity> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phone2Controller = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    super.dispose();
  }

  void _seed(PersonWizardReady state) {
    if (_seeded) return;
    _seeded = true;
    _nameController.text = state.name;
    _phoneController.text = state.phoneNumber;
    _phone2Controller.text = state.phoneNumber2;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonWizardCubit, PersonWizardState>(
      builder: (context, state) {
        if (state is! PersonWizardReady) return const SizedBox.shrink();
        _seed(state);
        final cubit = context.read<PersonWizardCubit>();

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInput(
                label: 'people.wizard.step1.nameLabel'.tr(),
                controller: _nameController,
                onChanged: cubit.updateName,
              ),
              SizedBox(height: 14.h),
              AppInput(
                label: 'people.wizard.step1.phoneLabel'.tr(),
                hintText: '+201234567890',
                prefixIcon: Icons.call_outlined,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                controller: _phoneController,
                onChanged: cubit.updatePhoneNumber,
              ),
              SizedBox(height: 14.h),
              AppInput(
                label: 'people.wizard.step1.phone2Label'.tr(),
                helperText: 'people.wizard.step1.optional'.tr(),
                hintText: '+201234567890',
                prefixIcon: Icons.call_outlined,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                controller: _phone2Controller,
                onChanged: cubit.updatePhoneNumber2,
              ),
              SizedBox(height: 14.h),
              AppInputLabel('people.wizard.step1.genderLabel'.tr()),
              SizedBox(height: 8.h),
              GenderChipGroup(selected: state.gender, onChanged: cubit.updateGender),
              SizedBox(height: 24.h),
              PersonWizardPhotoGrid(
                photos: state.stagedPhotos,
                onAdd: cubit.addPhoto,
                onRemove: cubit.removePhoto,
                onMarkPrimary: cubit.markPrimary,
              ),
            ],
          ),
        );
      },
    );
  }
}
