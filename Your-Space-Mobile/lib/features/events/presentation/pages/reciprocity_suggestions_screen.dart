import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/entities/group.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/args/reciprocity_suggestions_args.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_button.dart';
import 'package:your_space_mobile/core/widgets/app_chip.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/app_profile_row.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';

import '../cubit/add_guests_action_cubit/add_guests_action_cubit.dart';
import '../cubit/add_guests_action_cubit/add_guests_action_state.dart';
import '../cubit/reciprocity_suggestions_cubit/reciprocity_suggestions_cubit.dart';
import '../cubit/reciprocity_suggestions_cubit/reciprocity_suggestions_state.dart';

class ReciprocitySuggestionsScreen extends StatelessWidget {
  final ReciprocitySuggestionsArgs args;

  const ReciprocitySuggestionsScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'events.reciprocity.title'.tr(namedArgs: {'eventName': args.eventName}),
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: BlocListener<AddGuestsActionCubit, AddGuestsActionState>(
          listener: (context, state) {
            if (state is AddGuestsActionSuccess) {
              context.read<ReciprocitySuggestionsCubit>().refresh();
            } else if (state is AddGuestsActionError) {
              getIt<SnackBarHelper>().showError(state.message);
            }
          },
          child: BlocBuilder<ReciprocitySuggestionsCubit, ReciprocitySuggestionsState>(
            builder: (context, state) => switch (state) {
              ReciprocitySuggestionsSuccess(
                :final suggestions,
                :final groups,
                :final selectedGroupId,
                :final hasNextPage,
                :final isLoadingMore,
              ) =>
                _ReciprocitySuggestionsBody(
                  eventId: args.eventId,
                  suggestions: suggestions,
                  groups: groups,
                  selectedGroupId: selectedGroupId,
                  hasNextPage: hasNextPage,
                  isLoadingMore: isLoadingMore,
                ),
              ReciprocitySuggestionsError(:final message) => ErrorStateWidget(
                  message: message,
                  onRetry: () => context.read<ReciprocitySuggestionsCubit>().load(args.eventId),
                ),
              _ => const AppLoadingIndicator(),
            },
          ),
        ),
      ),
    );
  }
}

class _ReciprocitySuggestionsBody extends StatefulWidget {
  final int eventId;
  final List<Person> suggestions;
  final List<Group> groups;
  final int? selectedGroupId;
  final bool hasNextPage;
  final bool isLoadingMore;

  const _ReciprocitySuggestionsBody({
    required this.eventId,
    required this.suggestions,
    required this.groups,
    required this.selectedGroupId,
    required this.hasNextPage,
    required this.isLoadingMore,
  });

  @override
  State<_ReciprocitySuggestionsBody> createState() => _ReciprocitySuggestionsBodyState();
}

class _ReciprocitySuggestionsBodyState extends State<_ReciprocitySuggestionsBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!widget.hasNextPage || widget.isLoadingMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      context.read<ReciprocitySuggestionsCubit>().loadMore();
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
                    onTap: () => context.read<ReciprocitySuggestionsCubit>().filterByGroup(null),
                  ),
                ),
                for (final group in widget.groups)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: 8.w),
                    child: AppChip(
                      label: group.name,
                      selected: widget.selectedGroupId == group.id,
                      onTap: () => context.read<ReciprocitySuggestionsCubit>().filterByGroup(group.id),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: widget.suggestions.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.favorite_border_rounded,
                    title: 'events.reciprocity.emptyTitle'.tr(),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: widget.suggestions.length + (widget.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= widget.suggestions.length) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: const AppLoadingIndicator(),
                        );
                      }
                      final person = widget.suggestions[index];
                      return AppProfileRow(
                        name: person.name,
                        groupName: person.groupName,
                        trailing: BlocBuilder<AddGuestsActionCubit, AddGuestsActionState>(
                          builder: (context, state) => AppButton(
                            label: 'events.reciprocity.addAsGuestCta'.tr(),
                            variant: AppButtonVariant.soft,
                            size: AppButtonSize.sm,
                            loading: state is AddGuestsActionSubmitting,
                            onPressed: () => context.read<AddGuestsActionCubit>().addPersons(
                                  eventId: widget.eventId,
                                  personIds: [person.id],
                                ),
                          ),
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
