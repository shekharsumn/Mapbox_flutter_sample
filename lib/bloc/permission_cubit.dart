import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';

// Events
abstract class PermissionEvent extends Equatable {
  const PermissionEvent();

  @override
  List<Object?> get props => [];
}

class LoadPermissions extends PermissionEvent {}

class RequestPermission extends PermissionEvent {
  final Permission permission;

  const RequestPermission(this.permission);

  @override
  List<Object?> get props => [permission];
}

class RequestAllPermissions extends PermissionEvent {}

class RefreshPermissions extends PermissionEvent {}

// States
abstract class PermissionState extends Equatable {
  const PermissionState();

  @override
  List<Object?> get props => [];
}

class PermissionInitial extends PermissionState {}

class PermissionLoading extends PermissionState {}

class PermissionLoaded extends PermissionState {
  final Map<Permission, PermissionStatus> permissionStatuses;

  const PermissionLoaded(this.permissionStatuses);

  @override
  List<Object?> get props => [permissionStatuses];

  PermissionLoaded copyWith({
    Map<Permission, PermissionStatus>? permissionStatuses,
  }) {
    return PermissionLoaded(
      permissionStatuses ?? this.permissionStatuses,
    );
  }
}

class PermissionError extends PermissionState {
  final String message;

  const PermissionError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class PermissionCubit extends Cubit<PermissionState> {
  PermissionCubit() : super(PermissionInitial());

  final List<Permission> _permissions = [
    Permission.locationWhenInUse,
    Permission.locationAlways,
    Permission.camera,
    Permission.microphone,
    Permission.storage,
    Permission.audio,
  ];

  Future<void> loadPermissions() async {
    emit(PermissionLoading());
    
    try {
      Map<Permission, PermissionStatus> statuses = {};
      
      for (Permission permission in _permissions) {
        statuses[permission] = await permission.status;
      }
      
      emit(PermissionLoaded(statuses));
    } catch (e) {
      emit(PermissionError('Failed to load permissions: $e'));
    }
  }

  Future<void> requestPermission(Permission permission) async {
    try {
      final currentState = state;
      if (currentState is PermissionLoaded) {
        final status = await permission.request();
        final updatedStatuses = Map<Permission, PermissionStatus>.from(currentState.permissionStatuses);
        updatedStatuses[permission] = status;
        emit(PermissionLoaded(updatedStatuses));
      }
    } catch (e) {
      emit(PermissionError('Failed to request permission: $e'));
    }
  }

  Future<void> requestAllPermissions() async {
    emit(PermissionLoading());
    
    try {
      Map<Permission, PermissionStatus> statuses = {};
      
      for (Permission permission in _permissions) {
        statuses[permission] = await permission.request();
      }
      
      emit(PermissionLoaded(statuses));
    } catch (e) {
      emit(PermissionError('Failed to request all permissions: $e'));
    }
  }

  Future<void> refreshPermissions() async {
    await loadPermissions();
  }

  bool areLocationPermissionsGranted() {
    final currentState = state;
    if (currentState is PermissionLoaded) {
      return currentState.permissionStatuses[Permission.locationWhenInUse] == PermissionStatus.granted &&
             currentState.permissionStatuses[Permission.locationAlways] == PermissionStatus.granted;
    }
    return false;
  }

  bool areAllPermissionsGranted() {
    final currentState = state;
    if (currentState is PermissionLoaded) {
      return currentState.permissionStatuses.values.every((status) => status == PermissionStatus.granted);
    }
    return false;
  }

  List<Permission> getDeniedPermissions() {
    final currentState = state;
    if (currentState is PermissionLoaded) {
      return currentState.permissionStatuses.entries
          .where((entry) => entry.value != PermissionStatus.granted)
          .map((entry) => entry.key)
          .toList();
    }
    return [];
  }
} 