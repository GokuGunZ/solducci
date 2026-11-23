import 'package:equatable/equatable.dart';
import 'package:solducci/features/life_os/domain/models/models.dart';

enum LifeOsCenterStatus { initial, loading, success, failure }

class LifeOsCenterState extends Equatable {
  final LifeOsCenterStatus status;
  final List<LifeEntity> seeds;
  final List<LifeEntity> activeEntities;
  final bool isCapturing;
  final String? captureError;
  final String? lastFailedCaptureTitle;
  final String? generalError;

  const LifeOsCenterState({
    this.status = LifeOsCenterStatus.initial,
    this.seeds = const [],
    this.activeEntities = const [],
    this.isCapturing = false,
    this.captureError,
    this.lastFailedCaptureTitle,
    this.generalError,
  });

  bool get isLoading => status == LifeOsCenterStatus.loading;
  bool get hasError => status == LifeOsCenterStatus.failure || captureError != null;

  int get seedCount => seeds.length;
  int get activeEntityCount => activeEntities.length;
  int get totalEntityCount => seedCount + activeEntityCount;

  LifeOsCenterState copyWith({
    LifeOsCenterStatus? status,
    List<LifeEntity>? seeds,
    List<LifeEntity>? activeEntities,
    bool? isCapturing,
    String? Function()? captureError,
    String? Function()? lastFailedCaptureTitle,
    String? Function()? generalError,
  }) {
    return LifeOsCenterState(
      status: status ?? this.status,
      seeds: seeds ?? this.seeds,
      activeEntities: activeEntities ?? this.activeEntities,
      isCapturing: isCapturing ?? this.isCapturing,
      captureError: captureError != null ? captureError() : this.captureError,
      lastFailedCaptureTitle: lastFailedCaptureTitle != null
          ? lastFailedCaptureTitle()
          : this.lastFailedCaptureTitle,
      generalError: generalError != null ? generalError() : this.generalError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        seeds,
        activeEntities,
        isCapturing,
        captureError,
        lastFailedCaptureTitle,
        generalError,
      ];
}
