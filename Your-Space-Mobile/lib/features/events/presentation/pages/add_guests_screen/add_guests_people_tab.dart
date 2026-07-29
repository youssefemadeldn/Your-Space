import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:your_space_mobile/core/widgets/app_input.dart';
import 'package:your_space_mobile/core/widgets/app_profile_row.dart';
import 'package:your_space_mobile/core/widgets/empty_state_widget.dart';

import '../../cubit/add_guests_list_cubit/add_guests_list_state.dart';

class AddGuestsPeopleTab extends StatefulWidget {
  final AddGuestsListSuccess state;
  final Set<int> selectedPersonIds;
  final ValueChanged<int> onToggle;

  const AddGuestsPeopleTab({
    super.key,
    required this.state,
    required this.selectedPersonIds,
    required this.onToggle,
  });

  @override
  State<AddGuestsPeopleTab> createState() => _AddGuestsPeopleTabState();
}

class _AddGuestsPeopleTabState extends State<AddGuestsPeopleTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final people = _query.isEmpty
        ? widget.state.availablePeople
        : widget.state.availablePeople
            .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            hintText: 'people.list.searchHint'.tr(),
            prefixIcon: Icons.search_rounded,
            onChanged: (value) => setState(() => _query = value),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: people.isEmpty
                ? EmptyStateWidget(icon: Icons.people_outline_rounded, title: 'people.list.emptyTitle'.tr())
                : ListView.builder(
                    itemCount: people.length,
                    itemBuilder: (context, index) {
                      final person = people[index];
                      final checked = widget.selectedPersonIds.contains(person.id);
                      return AppProfileRow(
                        name: person.name,
                        groupName: person.groupName,
                        leading: Checkbox(
                          value: checked,
                          onChanged: (_) => widget.onToggle(person.id),
                        ),
                        onTap: () => widget.onToggle(person.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
