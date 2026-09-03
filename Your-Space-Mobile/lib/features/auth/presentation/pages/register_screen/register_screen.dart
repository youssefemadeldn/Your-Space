import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/helpers/regex_helper.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/confirm_email_args.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_logo_header.dart';

import '../../cubit/register_cubit/register_cubit.dart';
import '../../cubit/register_cubit/register_state.dart';
import 'register_form_fields.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  Gender? _selectedGender;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _firstNameError = firstName.isEmpty ? 'auth.validation.requiredFirstName'.tr() : null;
      _lastNameError = lastName.isEmpty ? 'auth.validation.requiredLastName'.tr() : null;
      _emailError =
          RegexHelper.validate(RegexHelper.email, email) ? null : 'auth.validation.invalidEmail'.tr();
      _phoneError = phone.isEmpty || RegexHelper.validate(RegexHelper.internationalPhone, phone)
          ? null
          : 'auth.validation.invalidPhone'.tr();
      _passwordError =
          RegexHelper.validate(RegexHelper.accountPassword, password) ? null : 'auth.passwordRule'.tr();
      _confirmPasswordError =
          confirmPassword == password ? null : 'auth.validation.passwordMismatch'.tr();
    });

    return _firstNameError == null &&
        _lastNameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;
  }

  void _submit() {
    if (!_validate()) return;
    context.read<RegisterCubit>().register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          gender: _selectedGender,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<RegisterCubit, RegisterState>(
          listener: (context, state) {
            if (state is RegisterSuccess) {
              getIt<SnackBarHelper>().showSuccess('auth.register.doneMessage'.tr());
              context.pushNamed(
                AppRoutes.confirmEmail,
                extra: ConfirmEmailArgs(email: state.user.email),
              );
              return;
            }
            if (state is RegisterError) {
              if (state.errorCode == 'Auth.Register.EmailExists') {
                setState(() => _emailError = state.message);
                return;
              }
              if (state.isNetworkError) {
                getIt<SnackBarHelper>().showError(
                  'common.networkError'.tr(),
                  actionLabel: 'common.retry'.tr(),
                  onAction: _submit,
                );
                return;
              }
              getIt<SnackBarHelper>().showError(state.message);
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppLogoHeader(compact: true, logoSize: 44.w),
                Text(
                  'auth.register.title'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 4.h),
                Text(
                  'auth.register.body'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 22.h),
                RegisterFormFields(
                  firstNameController: _firstNameController,
                  lastNameController: _lastNameController,
                  emailController: _emailController,
                  phoneController: _phoneController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  firstNameError: _firstNameError,
                  lastNameError: _lastNameError,
                  emailError: _emailError,
                  phoneError: _phoneError,
                  passwordError: _passwordError,
                  confirmPasswordError: _confirmPasswordError,
                  selectedGender: _selectedGender,
                  onFirstNameChanged: (_) {
                    if (_firstNameError != null) setState(() => _firstNameError = null);
                  },
                  onLastNameChanged: (_) {
                    if (_lastNameError != null) setState(() => _lastNameError = null);
                  },
                  onEmailChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                  onPhoneChanged: (_) {
                    if (_phoneError != null) setState(() => _phoneError = null);
                  },
                  onPasswordChanged: (_) {
                    if (_passwordError != null) setState(() => _passwordError = null);
                  },
                  onConfirmPasswordChanged: (_) {
                    if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
                  },
                  onGenderChanged: (gender) => setState(() {
                    _selectedGender = gender;
                  }),
                ),
                SizedBox(height: 20.h),
                BlocBuilder<RegisterCubit, RegisterState>(
                  builder: (context, state) => AppButton(
                    label: 'auth.register.submit'.tr(),
                    fullWidth: true,
                    loading: state is RegisterLoading,
                    onPressed: _submit,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'auth.register.haveAccount'.tr(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text('auth.register.logIn'.tr()),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
