import 'package:equatable/equatable.dart';
import 'package:solducci/models/time_scenario.dart';

abstract class TimeManagementEvent extends Equatable {
  const TimeManagementEvent();

  @override
  List<Object?> get props => [];
}

class SubscribeToTimeScenarios extends TimeManagementEvent {}

class TimeScenariosUpdated extends TimeManagementEvent {
  final List<TimeScenario> scenarios;

  const TimeScenariosUpdated(this.scenarios);

  @override
  List<Object?> get props => [scenarios];
}

class CreateTimeScenarioRequested extends TimeManagementEvent {
  final TimeScenario scenario;

  const CreateTimeScenarioRequested(this.scenario);

  @override
  List<Object?> get props => [scenario];
}
