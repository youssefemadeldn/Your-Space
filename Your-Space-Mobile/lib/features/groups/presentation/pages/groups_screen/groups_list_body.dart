import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/widgets/app_card.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_list_tile.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';

import '../../cubit/groups_list_cubit/groups_list_cubit.dart';
import 'group_form_sheet.dart';

class GroupsListBody extends StatefulWidget {
  final List<Group> groups;
  final bool hasNextPage;
  final bool isLoadingMore;

  const GroupsListBody({
    super.key,
    required this.groups,
    required this.hasNextPage,
    required this.isLoadingMore,
  });

  @override
  State<GroupsListBody> createState() => _GroupsListBodyState();
}

class _GroupsListBodyState extends State<GroupsListBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!widget.hasNextPage || widget.isLoadingMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      context.read<GroupsListCubit>().loadMore();
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
            hintText: 'groups.list.searchHint'.tr(),
            prefixIcon: Icons.search_rounded,
            onChanged: (value) => context.read<GroupsListCubit>().search(value),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: widget.groups.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.groups_rounded,
                    title: 'groups.list.emptyTitle'.tr(),
                    actionLabel: 'groups.list.emptyAction'.tr(),
                    onAction: () => GroupFormSheet.open(context),
                  )
                : AppCard(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: RefreshIndicator(
                      onRefresh: () => context.read<GroupsListCubit>().refresh(),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: widget.groups.length + (widget.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= widget.groups.length) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              child: const AppLoadingIndicator(),
                            );
                          }
                          final group = widget.groups[index];
                          return AppListTile(
                            avatarName: group.name,
                            title: group.name,
                            trailing:
                                const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                            divider: index != widget.groups.length - 1,
                            onTap: () => GroupFormSheet.open(context, group: group),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
