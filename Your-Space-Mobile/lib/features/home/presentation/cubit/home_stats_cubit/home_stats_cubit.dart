import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/mock/mock_data_store.dart';

import 'home_stats_state.dart';

@injectable
class HomeStatsCubit extends Cubit<HomeStatsState> {
  final MockDataStore _store;

  HomeStatsCubit(this._store) : super(const HomeStatsInitial());

  Future<void> load() async {
    emit(const HomeStatsLoading());
    await Future.delayed(_store.simulatedLatency);
    emit(HomeStatsSuccess(
      groupsCount: _store.groups().length,
      peopleCount: _store.people().length,
      eventsCount: _store.events().length,
    ));
  }
}
