import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/theme/app_colors.dart';
import 'package:your_space_mobile/core/widgets/app_card.dart';
import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_list_tile.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';

import 'classification_item.dart';

/// Shared body for all 3 classification management screens (Subgroup/City/
/// Neighborhood) — search + list + FAB + empty state, driven entirely by
/// plain props and callbacks. No cubit awareness — each concrete screen
/// supplies its own entity-specific cubit pair around this widget.
class ClassificationListBody extends StatefulWidget {
  final String parentLabel;
  final String parentName;
  final IconData parentIcon;
  final List<ClassificationItem> items;
  final bool hasNextPage;
  final bool isLoadingMore;
  final String searchHint;
  final IconData itemIcon;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyBody;
  final String addLabel;
  final ValueChanged<String> onSearch;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final ValueChanged<ClassificationItem> onEdit;
  final ValueChanged<ClassificationItem> onDelete;
  final VoidCallback onAdd;

  const ClassificationListBody({
    super.key,
    required this.parentLabel,
    required this.parentName,
    required this.parentIcon,
    required this.items,
    required this.hasNextPage,
    required this.isLoadingMore,
    required this.searchHint,
    required this.itemIcon,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyBody,
    required this.addLabel,
    required this.onSearch,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  State<ClassificationListBody> createState() => _ClassificationListBodyState();
}

class _ClassificationListBodyState extends State<ClassificationListBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!widget.hasNextPage || widget.isLoadingMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      widget.onLoadMore();
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
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(widget.parentIcon, size: 18.w, color: AppColors.primary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: '${widget.parentLabel} ',
                        style: AppTextStylesForCaption.body,
                        children: [
                          TextSpan(text: widget.parentName, style: AppTextStylesForCaption.bold),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              AppInput(
                hintText: widget.searchHint,
                prefixIcon: Icons.search_rounded,
                onChanged: widget.onSearch,
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: widget.items.isEmpty
                    ? EmptyStateWidget(
                        icon: widget.emptyIcon,
                        title: widget.emptyTitle,
                        subtitle: widget.emptyBody,
                        actionLabel: widget.addLabel,
                        onAction: widget.onAdd,
                      )
                    : AppCard(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: RefreshIndicator(
                          onRefresh: widget.onRefresh,
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: widget.items.length + (widget.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= widget.items.length) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  child: const AppLoadingIndicator(),
                                );
                              }
                              final item = widget.items[index];
                              return AppListTile(
                                title: item.name,
                                subtitle: item.caption,
                                icon: widget.itemIcon,
                                divider: index != widget.items.length - 1,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                                      onPressed: () => widget.onEdit(item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                      onPressed: () => widget.onDelete(item),
                                    ),
                                  ],
                                ),
                                onTap: () => widget.onEdit(item),
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        PositionedDirectional(
          end: 20.w,
          bottom: 20.h,
          child: FloatingActionButton(onPressed: widget.onAdd, child: const Icon(Icons.add_rounded)),
        ),
      ],
    );
  }
}

/// Tiny local helper — the parent-scope strip needs a plain (non-.tr()) body
/// style plus a bold variant for the interpolated parent name; kept private
/// to this file rather than growing `AppTextStyles` for a single call site.
class AppTextStylesForCaption {
  AppTextStylesForCaption._();

  static TextStyle get body => TextStyle(fontSize: 13.sp, color: AppColors.textSecondary);
  static TextStyle get bold => TextStyle(fontSize: 13.sp, color: AppColors.textPrimary, fontWeight: FontWeight.w700);
}
