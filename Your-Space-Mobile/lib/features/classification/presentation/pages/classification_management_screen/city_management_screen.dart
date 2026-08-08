import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:your_space_mobile/core/di/injection_container.dart';
import 'package:your_space_mobile/core/entities/city.dart';
import 'package:your_space_mobile/core/helpers/bottom_sheet_helper.dart';
import 'package:your_space_mobile/core/helpers/dialog_helper.dart';
import 'package:your_space_mobile/core/helpers/snack_bar_helper.dart';
import 'package:your_space_mobile/core/router/args/classification_management_args.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/city_action_cubit/city_action_cubit.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/city_action_cubit/city_action_state.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/city_list_cubit/city_list_cubit.dart';
import 'package:your_space_mobile/features/classification/presentation/cubit/city_list_cubit/city_list_state.dart';

import 'classification_form_sheet.dart';
import 'classification_item.dart';
import 'classification_list_body.dart';

class CityManagementScreen extends StatelessWidget {
  final ClassificationManagementArgs args;

  const CityManagementScreen({super.key, required this.args});

  void _openForm(BuildContext context, {City? city}) {
    final actionCubit = context.read<CityActionCubit>();
    BottomSheetHelper.showAppBottomSheet(
      context,
      BlocProvider.value(
        value: actionCubit,
        child: BlocBuilder<CityActionCubit, CityActionState>(
          builder: (context, state) => ClassificationFormSheet(
            title:
                city == null ? 'classification.city.createTitle'.tr() : 'classification.city.editTitle'.tr(),
            initialName: city?.name,
            namePlaceholder: 'classification.city.namePlaceholder'.tr(),
            submitting: state is CityActionSubmitting,
            errorText: state is CityActionError ? state.message : null,
            saveLabel: city == null ? 'classification.city.createCta'.tr() : 'common.saveChanges'.tr(),
            cancelLabel: 'common.cancel'.tr(),
            onSubmit: (name) => city == null
                ? actionCubit.createCity(governorateId: args.parentId, name: name)
                : actionCubit.updateCity(governorateId: args.parentId, id: city.id, name: name),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, City city) {
    final actionCubit = context.read<CityActionCubit>();
    getIt<DialogHelper>().showConfirmDialog(
      title: 'classification.city.deleteTitle'.tr(),
      message: 'classification.city.deleteBody'.tr(namedArgs: {'name': city.name}),
      confirmText: 'common.delete'.tr(),
      cancelText: 'common.cancel'.tr(),
      onConfirm: () => actionCubit.deleteCity(governorateId: args.parentId, id: city.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'classification.city.screenTitle'.tr(),
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<CityActionCubit, CityActionState>(
            listener: (context, state) {
              if (state is CityActionSaveSuccess) {
                Navigator.of(context).popUntil((route) => route.isFirst || !route.isCurrent);
                context.read<CityListCubit>().load(args.parentId);
                getIt<SnackBarHelper>().showSuccess('classification.city.savedMessage'.tr());
              } else if (state is CityActionDeleteSuccess) {
                context.read<CityListCubit>().load(args.parentId);
                getIt<SnackBarHelper>().showSuccess('classification.city.deletedMessage'.tr());
              } else if (state is CityActionError) {
                getIt<SnackBarHelper>().showError(state.message);
              }
            },
          ),
        ],
        child: BlocBuilder<CityListCubit, CityListState>(
          builder: (context, state) => switch (state) {
            CityListSuccess(:final cities, :final hasNextPage, :final isLoadingMore) => ClassificationListBody(
                parentLabel: 'classification.city.parentLabel'.tr(),
                parentName: args.parentName,
                parentIcon: Icons.location_city_rounded,
                items: cities
                    .map((c) => ClassificationItem(
                          id: c.id,
                          name: c.name,
                          caption: 'classification.city.neighborhoodCaption'
                              .tr(namedArgs: {'count': '${c.neighborhoodCount}'}),
                        ))
                    .toList(),
                hasNextPage: hasNextPage,
                isLoadingMore: isLoadingMore,
                searchHint: 'classification.city.searchHint'.tr(),
                itemIcon: Icons.place_rounded,
                emptyIcon: Icons.location_off_rounded,
                emptyTitle: 'classification.city.emptyTitle'.tr(),
                emptyBody: 'classification.city.emptyBody'.tr(),
                addLabel: 'classification.city.addLabel'.tr(),
                onSearch: (value) => context.read<CityListCubit>().search(value),
                onLoadMore: () => context.read<CityListCubit>().loadMore(),
                onRefresh: () => context.read<CityListCubit>().refresh(),
                onEdit: (item) => _openForm(context, city: cities.firstWhere((c) => c.id == item.id)),
                onDelete: (item) => _confirmDelete(context, cities.firstWhere((c) => c.id == item.id)),
                onAdd: () => _openForm(context),
              ),
            CityListError(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () => context.read<CityListCubit>().load(args.parentId),
              ),
            _ => const AppLoadingIndicator(),
          },
        ),
      ),
    );
  }
}
