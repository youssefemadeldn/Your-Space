import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/entities/subgroup.dart';
import 'package:your_space_mobile/core/helpers/bottom_sheet_helper.dart';
import 'package:your_space_mobile/core/helpers/dialog_helper.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/args/classification_management_args.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/subgroup_action_cubit/subgroup_action_cubit.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/subgroup_action_cubit/subgroup_action_state.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/subgroup_list_cubit/subgroup_list_cubit.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/subgroup_list_cubit/subgroup_list_state.dart';

import 'classification_form_sheet.dart';
import 'classification_item.dart';
import 'classification_list_body.dart';

class SubgroupManagementScreen extends StatelessWidget {
  final ClassificationManagementArgs args;

  const SubgroupManagementScreen({super.key, required this.args});

  void _openForm(BuildContext context, {SubGroup? subGroup}) {
    final actionCubit = context.read<SubGroupActionCubit>();
    BottomSheetHelper.showAppBottomSheet(
      context,
      BlocProvider.value(
        value: actionCubit,
        child: BlocBuilder<SubGroupActionCubit, SubGroupActionState>(
          builder: (context, state) => ClassificationFormSheet(
            title: subGroup == null
                ? 'classification.subgroup.createTitle'.tr()
                : 'classification.subgroup.editTitle'.tr(),
            initialName: subGroup?.name,
            namePlaceholder: 'classification.subgroup.namePlaceholder'.tr(),
            submitting: state is SubGroupActionSubmitting,
            errorText: state is SubGroupActionError ? state.message : null,
            saveLabel: subGroup == null ? 'classification.subgroup.createCta'.tr() : 'common.saveChanges'.tr(),
            cancelLabel: 'common.cancel'.tr(),
            onSubmit: (name) => subGroup == null
                ? actionCubit.createSubGroup(groupId: args.parentId, name: name)
                : actionCubit.updateSubGroup(groupId: args.parentId, id: subGroup.id, name: name),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SubGroup subGroup) {
    final actionCubit = context.read<SubGroupActionCubit>();
    getIt<DialogHelper>().showConfirmDialog(
      title: 'classification.subgroup.deleteTitle'.tr(),
      message: 'classification.subgroup.deleteBody'.tr(namedArgs: {'name': subGroup.name}),
      confirmText: 'common.delete'.tr(),
      cancelText: 'common.cancel'.tr(),
      onConfirm: () => actionCubit.deleteSubGroup(groupId: args.parentId, id: subGroup.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'classification.subgroup.screenTitle'.tr(),
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<SubGroupActionCubit, SubGroupActionState>(
            listener: (context, state) {
              if (state is SubGroupActionSaveSuccess) {
                Navigator.of(context).popUntil((route) => route.isFirst || !route.isCurrent);
                context.read<SubGroupListCubit>().load(args.parentId);
                getIt<SnackBarHelper>().showSuccess('classification.subgroup.savedMessage'.tr());
              } else if (state is SubGroupActionDeleteSuccess) {
                context.read<SubGroupListCubit>().load(args.parentId);
                getIt<SnackBarHelper>().showSuccess('classification.subgroup.deletedMessage'.tr());
              } else if (state is SubGroupActionError) {
                getIt<SnackBarHelper>().showError(state.message);
              }
            },
          ),
        ],
        child: BlocBuilder<SubGroupListCubit, SubGroupListState>(
          builder: (context, state) => switch (state) {
            SubGroupListSuccess(:final subGroups, :final hasNextPage, :final isLoadingMore) =>
              ClassificationListBody(
                parentLabel: 'classification.subgroup.parentLabel'.tr(),
                parentName: args.parentName,
                parentIcon: Icons.family_restroom_rounded,
                items: subGroups
                    .map((s) => ClassificationItem(
                          id: s.id,
                          name: s.name,
                          caption: 'classification.subgroup.personCaption'
                              .tr(namedArgs: {'count': '${s.personCount}'}),
                        ))
                    .toList(),
                hasNextPage: hasNextPage,
                isLoadingMore: isLoadingMore,
                searchHint: 'classification.subgroup.searchHint'.tr(),
                itemIcon: Icons.folder_rounded,
                emptyIcon: Icons.folder_off_rounded,
                emptyTitle: 'classification.subgroup.emptyTitle'.tr(),
                emptyBody: 'classification.subgroup.emptyBody'.tr(),
                addLabel: 'classification.subgroup.addLabel'.tr(),
                onSearch: (value) => context.read<SubGroupListCubit>().search(value),
                onLoadMore: () => context.read<SubGroupListCubit>().loadMore(),
                onRefresh: () => context.read<SubGroupListCubit>().refresh(),
                onEdit: (item) => _openForm(
                  context,
                  subGroup: subGroups.firstWhere((s) => s.id == item.id),
                ),
                onDelete: (item) => _confirmDelete(
                  context,
                  subGroups.firstWhere((s) => s.id == item.id),
                ),
                onAdd: () => _openForm(context),
              ),
            SubGroupListError(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () => context.read<SubGroupListCubit>().load(args.parentId),
              ),
            _ => const AppLoadingIndicator(),
          },
        ),
      ),
    );
  }
}
