import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/entities/neighborhood.dart';
import 'package:your_space_mobile/core/helpers/bottom_sheet_helper.dart';
import 'package:your_space_mobile/core/helpers/dialog_helper.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/args/classification_management_args.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/neighborhood_action_cubit/neighborhood_action_cubit.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/neighborhood_action_cubit/neighborhood_action_state.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/neighborhood_list_cubit/neighborhood_list_cubit.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/neighborhood_list_cubit/neighborhood_list_state.dart';

import 'classification_form_sheet.dart';
import 'classification_item.dart';
import 'classification_list_body.dart';

class NeighborhoodManagementScreen extends StatelessWidget {
  final ClassificationManagementArgs args;

  const NeighborhoodManagementScreen({super.key, required this.args});

  void _openForm(BuildContext context, {Neighborhood? neighborhood}) {
    final actionCubit = context.read<NeighborhoodActionCubit>();
    BottomSheetHelper.showAppBottomSheet(
      context,
      BlocProvider.value(
        value: actionCubit,
        child: BlocBuilder<NeighborhoodActionCubit, NeighborhoodActionState>(
          builder: (context, state) => ClassificationFormSheet(
            title: neighborhood == null
                ? 'classification.neighborhood.createTitle'.tr()
                : 'classification.neighborhood.editTitle'.tr(),
            initialName: neighborhood?.name,
            namePlaceholder: 'classification.neighborhood.namePlaceholder'.tr(),
            submitting: state is NeighborhoodActionSubmitting,
            errorText: state is NeighborhoodActionError ? state.message : null,
            saveLabel:
                neighborhood == null ? 'classification.neighborhood.createCta'.tr() : 'common.saveChanges'.tr(),
            cancelLabel: 'common.cancel'.tr(),
            onSubmit: (name) => neighborhood == null
                ? actionCubit.createNeighborhood(cityId: args.parentId, name: name)
                : actionCubit.updateNeighborhood(cityId: args.parentId, id: neighborhood.id, name: name),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Neighborhood neighborhood) {
    final actionCubit = context.read<NeighborhoodActionCubit>();
    getIt<DialogHelper>().showConfirmDialog(
      title: 'classification.neighborhood.deleteTitle'.tr(),
      message: 'classification.neighborhood.deleteBody'.tr(namedArgs: {'name': neighborhood.name}),
      confirmText: 'common.delete'.tr(),
      cancelText: 'common.cancel'.tr(),
      onConfirm: () => actionCubit.deleteNeighborhood(cityId: args.parentId, id: neighborhood.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'classification.neighborhood.screenTitle'.tr(),
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<NeighborhoodActionCubit, NeighborhoodActionState>(
            listener: (context, state) {
              if (state is NeighborhoodActionSaveSuccess) {
                Navigator.of(context).popUntil((route) => route.isFirst || !route.isCurrent);
                context.read<NeighborhoodListCubit>().load(args.parentId);
                getIt<SnackBarHelper>().showSuccess('classification.neighborhood.savedMessage'.tr());
              } else if (state is NeighborhoodActionDeleteSuccess) {
                context.read<NeighborhoodListCubit>().load(args.parentId);
                getIt<SnackBarHelper>().showSuccess('classification.neighborhood.deletedMessage'.tr());
              } else if (state is NeighborhoodActionError) {
                getIt<SnackBarHelper>().showError(state.message);
              }
            },
          ),
        ],
        child: BlocBuilder<NeighborhoodListCubit, NeighborhoodListState>(
          builder: (context, state) => switch (state) {
            NeighborhoodListSuccess(:final neighborhoods, :final hasNextPage, :final isLoadingMore) =>
              ClassificationListBody(
                parentLabel: 'classification.neighborhood.parentLabel'.tr(),
                parentName: args.parentName,
                parentIcon: Icons.location_city_rounded,
                items: neighborhoods
                    .map((n) => ClassificationItem(
                          id: n.id,
                          name: n.name,
                          caption: 'classification.neighborhood.personCaption'
                              .tr(namedArgs: {'count': '${n.personCount}'}),
                        ))
                    .toList(),
                hasNextPage: hasNextPage,
                isLoadingMore: isLoadingMore,
                searchHint: 'classification.neighborhood.searchHint'.tr(),
                itemIcon: Icons.signpost_rounded,
                emptyIcon: Icons.signpost_outlined,
                emptyTitle: 'classification.neighborhood.emptyTitle'.tr(),
                emptyBody: 'classification.neighborhood.emptyBody'.tr(),
                addLabel: 'classification.neighborhood.addLabel'.tr(),
                onSearch: (value) => context.read<NeighborhoodListCubit>().search(value),
                onLoadMore: () => context.read<NeighborhoodListCubit>().loadMore(),
                onRefresh: () => context.read<NeighborhoodListCubit>().refresh(),
                onEdit: (item) =>
                    _openForm(context, neighborhood: neighborhoods.firstWhere((n) => n.id == item.id)),
                onDelete: (item) =>
                    _confirmDelete(context, neighborhoods.firstWhere((n) => n.id == item.id)),
                onAdd: () => _openForm(context),
              ),
            NeighborhoodListError(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () => context.read<NeighborhoodListCubit>().load(args.parentId),
              ),
            _ => const AppLoadingIndicator(),
          },
        ),
      ),
    );
  }
}
