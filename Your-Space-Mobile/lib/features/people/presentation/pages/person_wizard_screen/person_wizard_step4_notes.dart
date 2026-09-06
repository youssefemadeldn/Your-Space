import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/person_wizard_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/person_wizard_state.dart';

class PersonWizardStep4Notes extends StatefulWidget {
  const PersonWizardStep4Notes({super.key});

  @override
  State<PersonWizardStep4Notes> createState() => _PersonWizardStep4NotesState();
}

class _PersonWizardStep4NotesState extends State<PersonWizardStep4Notes> {
  final _notesController = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _seed(PersonWizardReady state) {
    if (_seeded) return;
    _seeded = true;
    _notesController.text = state.notes;
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
                label: 'people.wizard.step4.notesLabel'.tr(),
                hintText: 'people.wizard.step4.notesHint'.tr(),
                helperText: 'people.wizard.step1.optional'.tr(),
                controller: _notesController,
                multiline: true,
                maxLength: 2000,
                onChanged: cubit.updateNotes,
              ),
            ],
          ),
        );
      },
    );
  }
}
