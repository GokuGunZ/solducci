import 'package:equatable/equatable.dart';
import 'package:solducci/models/time_scenario.dart';

abstract class TimeManagementState extends Equatable {
  const TimeManagementState();

  @override
  List<Object?> get props => [];
}

class TimeManagementInitial extends TimeManagementState {}

class TimeManagementLoading extends TimeManagementState {}

class TimeManagementLoaded extends TimeManagementState {
  final List<TimeScenario> scenarios;
  
  const TimeManagementLoaded({required this.scenarios});

  List<TimeScenario> get radarScenarios => 
      scenarios.where((s) => s.scenarioType == 'availability').toList();
      
  List<TimeScenario> get eventScenarios => 
      scenarios.where((s) => s.scenarioType != 'availability').toList();

  @override
  List<Object?> get props => [scenarios];
}

class TimeManagementError extends TimeManagementState {
  final String message;

  const TimeManagementError(this.message);

  @override
  List<Object?> get props => [message];
}
