import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/mock/entities/group.dart';
import 'package:your_space_mobile/core/mock/entities/person.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/person_details_args.dart';
import 'package:your_space_mobile/core/router/args/person_form_args.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_badge.dart';
import 'package:your_space_mobile/core/widgets/app_bottom_nav.dart';
import 'package:your_space_mobile/core/widgets/app_chip.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/app_profile_row.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';

import '../cubit/people_list_cubit/people_list_cubit.dart';
import '../cubit/people_list_cubit/people_list_state.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: 'people.list.title'.tr()),
      body: SafeArea(
        child: BlocBuilder<PeopleListCubit, PeopleListState>(
          builder: (context, state) => switch (state) {
            PeopleListSuccess(:final people, :final groups, :final selectedGroupId) => _PeopleListBody(
                people: people,
                groups: groups,
                selectedGroupId: selectedGroupId,
              ),
            PeopleListError(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () => context.read<PeopleListCubit>().load(),
              ),
            _ => const AppLoadingIndicator(),
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(AppRoutes.personForm, extra: const PersonFormArgs()),
        child: const Icon(Icons.person_add_rounded),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}

class _PeopleListBody extends StatelessWidget {
  final List<Person> people;
  final List<Group> groups;
  final int? selectedGroupId;

  const _PeopleListBody({required this.people, required this.groups, required this.selectedGroupId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            hintText: 'people.list.searchHint'.tr(),
            prefixIcon: Icons.search_rounded,
            onChanged: (value) => context.read<PeopleListCubit>().search(value),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 40.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 8.w),
                  child: AppChip(
                    label: 'people.list.allChip'.tr(),
                    selected: selectedGroupId == null,
                    onTap: () => context.read<PeopleListCubit>().filterByGroup(null),
                  ),
                ),
                for (final group in groups)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: 8.w),
                    child: AppChip(
                      label: group.name,
                      selected: selectedGroupId == group.id,
                      onTap: () => context.read<PeopleListCubit>().filterByGroup(group.id),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: people.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.people_alt_rounded,
                    title: 'people.list.emptyTitle'.tr(),
                    actionLabel: 'people.list.emptyAction'.tr(),
                    onAction: () =>
                        context.pushNamed(AppRoutes.personForm, extra: const PersonFormArgs()),
                  )
                : ListView.builder(
                    itemCount: people.length,
                    itemBuilder: (context, index) {
                      final person = people[index];
                      return AppProfileRow(
                        name: person.name,
                        groupName: person.groupName,
                        phoneNumber: person.phoneNumber,
                        trailing: person.hasReciprocityHistory
                            ? AppBadge(label: 'people.list.reciprocityBadge'.tr(), tone: AppBadgeTone.info)
                            : const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                        onTap: () => context.pushNamed(
                          AppRoutes.personDetails,
                          extra: PersonDetailsArgs(personId: person.id, personName: person.name),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
