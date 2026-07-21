import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solducci/service/time_management_service.dart';
import 'time_management_event.dart';
import 'time_management_state.dart';

class TimeManagementBloc extends Bloc<TimeManagementEvent, TimeManagementState> {
  final TimeManagementService _service;
  StreamSubscription? _scenariosSubscription;

  TimeManagementBloc({TimeManagementService? service})
      : _service = service ?? TimeManagementService(),
        super(TimeManagementInitial()) {
    
    on<SubscribeToTimeScenarios>(_onSubscribeToTimeScenarios);
    on<TimeScenariosUpdated>(_onTimeScenariosUpdated);
    on<CreateTimeScenarioRequested>(_onCreateTimeScenarioRequested);
  }

  void _onSubscribeToTimeScenarios(
    SubscribeToTimeScenarios event,
    Emitter<TimeManagementState> emit,
  ) {
    emit(TimeManagementLoading());
    
    _scenariosSubscription?.cancel();
    _scenariosSubscription = _service.timeScenariosStream.listen(
      (scenarios) {
        add(TimeScenariosUpdated(scenarios));
      },
      onError: (error) {
        emit(TimeManagementError(error.toString()));
      },
    );
  }

  void _onTimeScenariosUpdated(
    TimeScenariosUpdated event,
    Emitter<TimeManagementState> emit,
  ) {
    emit(TimeManagementLoaded(scenarios: event.scenarios));
  }

  Future<void> _onCreateTimeScenarioRequested(
    CreateTimeScenarioRequested event,
    Emitter<TimeManagementState> emit,
  ) async {
    try {
      await _service.createTimeScenario(event.scenario);
      // Stream will auto-update the list
    } catch (e) {
      emit(TimeManagementError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _scenariosSubscription?.cancel();
    return super.close();
  }
}
