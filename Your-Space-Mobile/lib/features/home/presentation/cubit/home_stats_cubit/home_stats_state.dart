import 'package:equatable/equatable.dart';

sealed class HomeStatsState extends Equatable {
  const HomeStatsState();
  @override
  List<Object?> get props => const [];
}

final class HomeStatsInitial extends HomeStatsState {
  const HomeStatsInitial();
}

final class HomeStatsLoading extends HomeStatsState {
  const HomeStatsLoading();
}

final class HomeStatsSuccess extends HomeStatsState {
  final int groupsCount;
  final int peopleCount;
  final int eventsCount;
  final String firstName;

  const HomeStatsSuccess({
    required this.groupsCount,
    required this.peopleCount,
    required this.eventsCount,
    required this.firstName,
  });

  @override
  List<Object?> get props => [groupsCount, peopleCount, eventsCount, firstName];
}

final class HomeStatsError extends HomeStatsState {
  final String message;
  const HomeStatsError(this.message);
  @override
  List<Object?> get props => [message];
}
