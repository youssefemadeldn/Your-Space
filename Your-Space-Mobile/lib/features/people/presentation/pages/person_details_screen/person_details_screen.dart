import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:your_space_mobile/core/router/app_routes.dart';
import 'package:your_space_mobile/core/router/args/person_details_args.dart';
import 'package:your_space_mobile/core/router/args/person_form_args.dart';
import 'package:your_space_mobile/core/widgets/app_app_bar.dart';
import 'package:your_space_mobile/core/widgets/app_loading_indicator.dart';
import 'package:your_space_mobile/core/widgets/error_state_widget.dart';

import '../../cubit/person_details_cubit/person_details_cubit.dart';
import '../../cubit/person_details_cubit/person_details_state.dart';
import 'person_details_body.dart';

class PersonDetailsScreen extends StatelessWidget {
  final PersonDetailsArgs args;

  const PersonDetailsScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: args.personName,
        onBack: () => context.pop(),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.pushNamed(
            AppRoutes.personForm,
            extra: PersonFormArgs(personId: args.personId),
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<PersonDetailsCubit, PersonDetailsState>(
          builder: (context, state) => switch (state) {
            PersonDetailsSuccess(:final person, :final occasions) =>
              PersonDetailsBody(person: person, occasions: occasions),
            PersonDetailsError(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () => context.read<PersonDetailsCubit>().loadDetails(args.personId),
              ),
            _ => const AppLoadingIndicator(),
          },
        ),
      ),
    );
  }
}
