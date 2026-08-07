import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/person_details_args.dart';
import 'package:your_space_mobile/core/router/args/person_form_args.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/widgets/app_badge.dart';
import 'package:your_space_mobile/core/widgets/app_chip.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/app_profile_row.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';

import '../../cubit/people_list_cubit/people_list_cubit.dart';

class PeopleListBody extends StatefulWidget {
  final List<Person> people;
  final List<Group> groups;
  final int? selectedGroupId;
  final bool hasNextPage;
  final bool isLoadingMore;

  const PeopleListBody({
    super.key,
    required this.people,
    required this.groups,
    required this.selectedGroupId,
    required this.hasNextPage,
    required this.isLoadingMore,
  });

  @override
  State<PeopleListBody> createState() => _PeopleListBodyState();
}

class _PeopleListBodyState extends State<PeopleListBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!widget.hasNextPage || widget.isLoadingMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      context.read<PeopleListCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

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
                    selected: widget.selectedGroupId == null,
                    onTap: () => context.read<PeopleListCubit>().filterByGroup(null),
                  ),
                ),
                for (final group in widget.groups)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: 8.w),
                    child: AppChip(
                      label: group.name,
                      selected: widget.selectedGroupId == group.id,
                      onTap: () => context.read<PeopleListCubit>().filterByGroup(group.id),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: widget.people.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.people_alt_rounded,
                    title: 'people.list.emptyTitle'.tr(),
                    actionLabel: 'people.list.emptyAction'.tr(),
                    onAction: () =>
                        context.pushNamed(AppRoutes.personForm, extra: const PersonFormArgs()),
                  )
                : RefreshIndicator(
                    onRefresh: () => context.read<PeopleListCubit>().refresh(),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: widget.people.length + (widget.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= widget.people.length) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: const AppLoadingIndicator(),
                          );
                        }
                        final person = widget.people[index];
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
          ),
        ],
      ),
    );
  }
}
