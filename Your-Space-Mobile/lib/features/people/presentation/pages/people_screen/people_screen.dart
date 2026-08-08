import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/person_wizard_args.dart';
import 'package:your_space_mobile/core/theme/app_text_styles.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';

import '../../cubit/people_list_cubit/people_list_cubit.dart';
import '../../cubit/people_list_cubit/people_list_state.dart';
import 'people_list_body.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('people.list.title'.tr(), style: AppTextStyles.headlineSmall),
              ),
            ),
            Expanded(
              child: BlocListener<PeopleListCubit, PeopleListState>(
                listenWhen: (previous, current) {
                  if (current is! PeopleListSuccess) return false;
                  final previousErrorId = previous is PeopleListSuccess ? previous.loadMoreErrorId : 0;
                  return current.loadMoreErrorId != previousErrorId;
                },
                listener: (context, state) {
                  final message = (state as PeopleListSuccess).loadMoreErrorMessage;
                  if (message == null) return;
                  getIt<SnackBarHelper>().showError(
                    message,
                    actionLabel: 'common.retry'.tr(),
                    onAction: () => context.read<PeopleListCubit>().loadMore(),
                  );
                },
                child: BlocBuilder<PeopleListCubit, PeopleListState>(
                  builder: (context, state) => switch (state) {
                    PeopleListSuccess(
                      :final people,
                      :final groups,
                      :final selectedGroupId,
                      :final hasNextPage,
                      :final isLoadingMore,
                    ) =>
                      PeopleListBody(
                        people: people,
                        groups: groups,
                        selectedGroupId: selectedGroupId,
                        hasNextPage: hasNextPage,
                        isLoadingMore: isLoadingMore,
                      ),
                    PeopleListError(:final message) => ErrorStateWidget(
                        message: message,
                        onRetry: () => context.read<PeopleListCubit>().load(),
                      ),
                    _ => const AppLoadingIndicator(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(AppRoutes.personWizard, extra: const PersonWizardArgs()),
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }
}
