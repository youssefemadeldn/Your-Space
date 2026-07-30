import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/helpers/date_formatter_helper.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/args/event_form_args.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';

import '../cubit/event_form_cubit/event_form_cubit.dart';
import '../cubit/event_form_cubit/event_form_state.dart';

class EventFormScreen extends StatefulWidget {
  final EventFormArgs args;

  const EventFormScreen({super.key, required this.args});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _eventDate;
  String? _nameError;
  bool _initialized = false;

  bool get _isEditing => widget.args.eventId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _seedFromReady(EventFormReady state) {
    if (_initialized) return;
    _initialized = true;
    final event = state.event;
    if (event == null) return;
    _nameController.text = event.name;
    _nameArController.text = event.nameAr ?? '';
    _notesController.text = event.notes ?? '';
    _eventDate = event.eventDate;
    _dateController.text = DateFormatterHelper.formatDate(event.eventDate);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null) return;
    setState(() {
      _eventDate = picked;
      _dateController.text = DateFormatterHelper.formatDate(picked);
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'events.form.nameRequired'.tr());
      return;
    }
    context.read<EventFormCubit>().submit(
          eventId: widget.args.eventId,
          name: name,
          nameAr: _nameArController.text.trim().isEmpty ? null : _nameArController.text.trim(),
          eventDate: _eventDate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: _isEditing ? 'events.form.editTitle'.tr() : 'events.form.createTitle'.tr(),
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: BlocConsumer<EventFormCubit, EventFormState>(
          listener: (context, state) {
            if (state is EventFormSuccess) {
              getIt<SnackBarHelper>().showSuccess('events.savedMessage'.tr());
              context.pop();
            } else if (state is EventFormError) {
              getIt<SnackBarHelper>().showError(state.message);
            }
          },
          builder: (context, state) {
            if (state is EventFormInitial || state is EventFormLoading) {
              return const AppLoadingIndicator();
            }
            if (state is EventFormReady) _seedFromReady(state);
            final submitting = state is EventFormSubmitting;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppInput(
                    label: 'events.form.nameLabel'.tr(),
                    controller: _nameController,
                    errorText: _nameError,
                    enabled: !submitting,
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),
                  SizedBox(height: 14.h),
                  AppInput(
                    label: 'events.form.nameArLabel'.tr(),
                    controller: _nameArController,
                    enabled: !submitting,
                  ),
                  SizedBox(height: 14.h),
                  InkWell(
                    onTap: submitting ? null : _pickDate,
                    child: IgnorePointer(
                      child: AppInput(
                        label: 'events.form.dateLabel'.tr(),
                        suffixIcon: Icon(Icons.calendar_today_rounded, size: 18.w),
                        controller: _dateController,
                        enabled: !submitting,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  AppInput(
                    label: 'events.form.notesLabel'.tr(),
                    controller: _notesController,
                    multiline: true,
                    enabled: !submitting,
                  ),
                  SizedBox(height: 20.h),
                  AppButton(
                    label: _isEditing ? 'common.saveChanges'.tr() : 'events.form.createCta'.tr(),
                    fullWidth: true,
                    loading: submitting,
                    onPressed: _submit,
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
