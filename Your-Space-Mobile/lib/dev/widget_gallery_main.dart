// Temporary manual-QA entry point for the lib/core/widgets/ shared widget
// library. Run with: flutter run -t lib/dev/widget_gallery_main.dart
// Delete this file (and lib/dev/) once the widgets have been visually
// verified and before the first real feature lands.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constants/app_constants.dart';
import '../core/entities/invite_method.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_app_bar.dart';
import '../core/widgets/app_avatar.dart';
import '../core/widgets/app_badge.dart';
import '../core/widgets/app_bottom_nav.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_checkbox.dart';
import '../core/widgets/app_chip.dart';
import '../core/widgets/app_input.dart';
import '../core/widgets/app_list_tile.dart';
import '../core/widgets/app_otp_input.dart';
import '../core/widgets/app_password_input.dart';
import '../core/widgets/app_profile_row.dart';
import '../core/widgets/app_select.dart';
import '../core/widgets/app_switch.dart';
import '../core/widgets/app_tabs.dart';
import '../core/widgets/invite_method_chip_group.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const WidgetGalleryApp(),
    ),
  );
}

class WidgetGalleryApp extends StatelessWidget {
  const WidgetGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize:
          const Size(AppConstants.kDesignWidth, AppConstants.kDesignHeight),
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: const WidgetGalleryScreen(),
      ),
    );
  }
}

class WidgetGalleryScreen extends StatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends State<WidgetGalleryScreen> {
  bool _checked = true;
  bool _switched = true;
  bool _chipSelected = true;
  bool _buttonLoading = false;
  String? _otpValue;
  int _tabsIndex = 0;
  String? _selectValue;
  InviteMethod? _inviteMethod;
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Widget gallery',
        trailing: IconButton(
          icon: const Icon(Icons.translate_rounded),
          onPressed: () {
            final next = context.locale.languageCode == 'en'
                ? const Locale('ar')
                : const Locale('en');
            context.setLocale(next);
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            const _SectionTitle('Buttons'),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [
                AppButton(
                    label: 'Create event',
                    icon: Icons.add_rounded,
                    onPressed: () {}),
                AppButton(
                    label: 'Remind me later',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {}),
                AppButton(
                    label: 'Edit',
                    variant: AppButtonVariant.soft,
                    size: AppButtonSize.sm,
                    onPressed: () {}),
                AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.text,
                    onPressed: () {}),
                AppButton(
                    label: 'Dark',
                    variant: AppButtonVariant.dark,
                    onPressed: () {}),
                const AppButton(label: 'Disabled', onPressed: null),
                AppButton(
                  label: 'Toggle loading',
                  loading: _buttonLoading,
                  onPressed: () =>
                      setState(() => _buttonLoading = !_buttonLoading),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            AppButton(label: 'Full width', fullWidth: true, onPressed: () {}),
            SizedBox(height: 24.h),
            const _SectionTitle('Inputs'),
            const AppInput(
              label: 'Event name',
              hintText: 'e.g. Dinner at ours',
              prefixIcon: Icons.celebration_rounded,
            ),
            SizedBox(height: 16.h),
            const AppInput(
              label: 'Phone',
              errorText: "That number doesn't look right",
            ),
            SizedBox(height: 16.h),
            const AppPasswordInput(
              label: 'Password',
              hintText: 'Enter password',
            ),
            SizedBox(height: 16.h),
            AppOtpInput(
              label: 'Verification code',
              onCompleted: (code) => setState(() => _otpValue = code),
            ),
            if (_otpValue != null) Text('OTP entered: $_otpValue'),
            SizedBox(height: 24.h),
            const _SectionTitle('Checkbox & Switch'),
            AppCheckbox(
              checked: _checked,
              label: 'Sara Adel',
              onChanged: (value) => setState(() => _checked = value),
            ),
            SizedBox(height: 8.h),
            AppSwitch(
              checked: _switched,
              label: 'Remind me to reciprocate',
              onChanged: (value) => setState(() => _switched = value),
            ),
            SizedBox(height: 24.h),
            const _SectionTitle('Chips'),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                AppChip(
                  label: 'Family',
                  selected: _chipSelected,
                  count: 24,
                  onTap: () => setState(() => _chipSelected = !_chipSelected),
                ),
                AppChip(
                    label: 'Work friends',
                    icon: Icons.group_rounded,
                    onTap: () {}),
              ],
            ),
            SizedBox(height: 24.h),
            const _SectionTitle('Badges'),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: const [
                AppBadge(
                    label: 'Confirmed',
                    tone: AppBadgeTone.success,
                    icon: Icons.check_rounded),
                AppBadge(label: 'Pending', tone: AppBadgeTone.warning),
                AppBadge(label: 'Declined', tone: AppBadgeTone.error),
                AppBadge(label: 'Maybe', tone: AppBadgeTone.info),
                AppBadge(label: 'Host', tone: AppBadgeTone.brand),
                AppBadge(label: 'Draft', tone: AppBadgeTone.neutral),
              ],
            ),
            SizedBox(height: 24.h),
            const _SectionTitle('List tile'),
            AppListTile(
              avatarName: 'Sara Adel',
              title: 'Sara Adel',
              subtitle: 'Family · invited 2×',
              trailing: const AppBadge(
                  label: 'Confirmed', tone: AppBadgeTone.success),
              divider: true,
            ),
            AppListTile(
              icon: Icons.group_rounded,
              title: 'Work friends group',
              subtitle: '12 members',
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
            SizedBox(height: 24.h),
            const _SectionTitle('Avatar'),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: const [
                AppAvatar(name: 'Sara Adel'),
                AppAvatar(name: 'Omar Khaled'),
                AppAvatar(name: 'Mona Tarek'),
                AppAvatar(name: 'Youssef Hassan'),
                AppAvatar(name: 'Laila Fathy'),
              ],
            ),
            SizedBox(height: 24.h),
            const _SectionTitle('Card'),
            AppCard(
              child: Text(
                'Guest progress, group rows, and other content sit inside AppCard.',
              ),
            ),
            SizedBox(height: 24.h),
            const _SectionTitle('Select'),
            AppSelect(
              label: 'Group',
              value: _selectValue,
              placeholder: 'Choose a group',
              options: const ['Family', 'Close friends', 'Work friends', 'Neighbors'],
              onChanged: (value) => setState(() => _selectValue = value),
            ),
            SizedBox(height: 24.h),
            const _SectionTitle('Tabs'),
            AppTabs(
              tabs: const ['People', 'By group'],
              activeIndex: _tabsIndex,
              onChanged: (index) => setState(() => _tabsIndex = index),
            ),
            SizedBox(height: 24.h),
            const _SectionTitle('Profile row'),
            AppProfileRow(
              name: 'Sara Adel',
              groupName: 'Family',
              phoneNumber: '+201001234567',
              trailing: const AppBadge(label: 'Invited you', tone: AppBadgeTone.info),
            ),
            AppProfileRow(
              name: 'Omar Khaled',
              groupName: 'Family',
              leading: const Checkbox(value: true, onChanged: null),
            ),
            SizedBox(height: 24.h),
            const _SectionTitle('Invite method chip group'),
            InviteMethodChipGroup(
              selected: _inviteMethod,
              onChanged: (method) => setState(() => _inviteMethod = method),
            ),
            SizedBox(height: 24.h),
            const _SectionTitle('Bottom nav'),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: AppBottomNav(
                currentIndex: _bottomNavIndex,
                onTap: (index) => setState(() => _bottomNavIndex = index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
