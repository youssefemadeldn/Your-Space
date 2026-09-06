import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/person_details_args.dart';
import 'package:your_space_mobile/core/router/args/person_wizard_args.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/person_wizard_cubit.dart';
import 'package:your_space_mobile/features/people/presentation/cubit/person_wizard_cubit/person_wizard_state.dart';

import 'person_wizard_footer.dart';
import 'person_wizard_step1_basic_identity.dart';
import 'person_wizard_step2_classification_location.dart';
import 'person_wizard_step3_relationships.dart';
import 'person_wizard_step4_notes.dart';
import 'person_wizard_step_indicator.dart';

/// Shell for the 4-step Add/Edit Person wizard — AppBar, step indicator, a
/// non-lazy `PageView` (so each step's controllers survive Back/Next), and a
/// sticky footer. `currentStep` is local widget state, not cubit state —
/// mirrors `OnboardingScreen`'s established precedent.
class PersonWizardScreen extends StatefulWidget {
  final PersonWizardArgs args;

  const PersonWizardScreen({super.key, required this.args});

  @override
  State<PersonWizardScreen> createState() => _PersonWizardScreenState();
}

class _PersonWizardScreenState extends State<PersonWizardScreen> {
  static const _totalSteps = 4;

  final _pageController = PageController();
  int _currentStep = 0;

  bool get _isEditing => widget.args.personId != null;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
    _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _goNext() {
    final cubit = context.read<PersonWizardCubit>();
    if (_currentStep == _totalSteps - 1) {
      cubit.submit();
      return;
    }
    final error = cubit.validateStep(_currentStep);
    if (error != null) {
      getIt<SnackBarHelper>().showError(error.tr());
      return;
    }
    setState(() => _currentStep++);
    _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: _isEditing ? 'people.wizard.editTitle'.tr() : 'people.wizard.createTitle'.tr(),
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<PersonWizardCubit, PersonWizardState>(
          listener: (context, state) {
            if (state is PersonWizardSubmitSuccess) {
              getIt<SnackBarHelper>().showSuccess('people.wizard.submit.savedMessage'.tr());
              if (state.partialFailureKeys != null) {
                getIt<SnackBarHelper>().showWarning(state.partialFailureKeys!.map((k) => k.tr()).join('\n'));
              }
              context.pushReplacementNamed(
                AppRoutes.personDetails,
                extra: PersonDetailsArgs(personId: state.personId, personName: state.personName),
              );
            } else if (state is PersonWizardReady && state.submitError != null) {
              getIt<SnackBarHelper>().showError(state.submitError!);
            }
          },
          builder: (context, state) {
            if (state is PersonWizardInitial || state is PersonWizardLoading) {
              return const AppLoadingIndicator();
            }
            if (state is PersonWizardError) {
              return ErrorStateWidget(
                message: state.message,
                onRetry: () => context.read<PersonWizardCubit>().initialize(widget.args.personId),
              );
            }

            return Column(
              children: [
                PersonWizardStepIndicator(currentStep: _currentStep),
                Expanded(
                  child: PageView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      PersonWizardStep1BasicIdentity(),
                      PersonWizardStep2ClassificationLocation(),
                      PersonWizardStep3Relationships(),
                      PersonWizardStep4Notes(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BlocBuilder<PersonWizardCubit, PersonWizardState>(
        builder: (context, state) {
          if (state is! PersonWizardReady) return const SizedBox.shrink();
          return PersonWizardFooter(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            loading: state.isSubmitting,
            onBack: _goBack,
            onNext: _goNext,
          );
        },
      ),
    );
  }
}
