import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// Events
abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeNavigation extends NavigationEvent {}

class StartNavigation extends NavigationEvent {
  final Point destination;
  final Point? origin;

  const StartNavigation(this.destination, {this.origin});

  @override
  List<Object?> get props => [destination, origin];
}

class StopNavigation extends NavigationEvent {}

class UpdateLocation extends NavigationEvent {
  final Point location;

  const UpdateLocation(this.location);

  @override
  List<Object?> get props => [location];
}

class SetMapStyle extends NavigationEvent {
  final String styleUrl;

  const SetMapStyle(this.styleUrl);

  @override
  List<Object?> get props => [styleUrl];
}

class Toggle3DMode extends NavigationEvent {
  final bool enabled;

  const Toggle3DMode(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

// States
abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object?> get props => [];
}

class NavigationInitial extends NavigationState {}

class NavigationLoading extends NavigationState {}

class NavigationActive extends NavigationState {
  final Point currentLocation;
  final Point destination;
  final Point? origin;
  final String mapStyle;
  final bool is3DMode;
  final bool isNavigating;

  const NavigationActive({
    required this.currentLocation,
    required this.destination,
    this.origin,
    this.mapStyle = 'mapbox://styles/mapbox/streets-v12',
    this.is3DMode = false,
    this.isNavigating = false,
  });

  @override
  List<Object?> get props => [
    currentLocation,
    destination,
    origin,
    mapStyle,
    is3DMode,
    isNavigating,
  ];

  NavigationActive copyWith({
    Point? currentLocation,
    Point? destination,
    Point? origin,
    String? mapStyle,
    bool? is3DMode,
    bool? isNavigating,
  }) {
    return NavigationActive(
      currentLocation: currentLocation ?? this.currentLocation,
      destination: destination ?? this.destination,
      origin: origin ?? this.origin,
      mapStyle: mapStyle ?? this.mapStyle,
      is3DMode: is3DMode ?? this.is3DMode,
      isNavigating: isNavigating ?? this.isNavigating,
    );
  }
}

class NavigationError extends NavigationState {
  final String message;

  const NavigationError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationInitial());

  Future<void> initializeNavigation() async {
    emit(NavigationLoading());
    
    try {
      // Default location (San Francisco)
      final defaultLocation = Point(coordinates: Position(-122.4194, 37.7749));
      
      emit(NavigationActive(
        currentLocation: defaultLocation,
        destination: defaultLocation,
      ));
    } catch (e) {
      emit(NavigationError('Failed to initialize navigation: $e'));
    }
  }

  Future<void> startNavigation(Point destination, {Point? origin}) async {
    try {
      final currentState = state;
      if (currentState is NavigationActive) {
        emit(currentState.copyWith(
          destination: destination,
          origin: origin,
          isNavigating: true,
        ));
      }
    } catch (e) {
      emit(NavigationError('Failed to start navigation: $e'));
    }
  }

  Future<void> stopNavigation() async {
    try {
      final currentState = state;
      if (currentState is NavigationActive) {
        emit(currentState.copyWith(isNavigating: false));
      }
    } catch (e) {
      emit(NavigationError('Failed to stop navigation: $e'));
    }
  }

  Future<void> updateLocation(Point location) async {
    try {
      final currentState = state;
      if (currentState is NavigationActive) {
        emit(currentState.copyWith(currentLocation: location));
      }
    } catch (e) {
      emit(NavigationError('Failed to update location: $e'));
    }
  }

  Future<void> setMapStyle(String styleUrl) async {
    try {
      final currentState = state;
      if (currentState is NavigationActive) {
        emit(currentState.copyWith(mapStyle: styleUrl));
      }
    } catch (e) {
      emit(NavigationError('Failed to set map style: $e'));
    }
  }

  Future<void> toggle3DMode(bool enabled) async {
    try {
      final currentState = state;
      if (currentState is NavigationActive) {
        emit(currentState.copyWith(is3DMode: enabled));
      }
    } catch (e) {
      emit(NavigationError('Failed to toggle 3D mode: $e'));
    }
  }

  // Helper methods
  bool get isNavigating {
    final currentState = state;
    return currentState is NavigationActive && currentState.isNavigating;
  }

  bool get is3DMode {
    final currentState = state;
    return currentState is NavigationActive && currentState.is3DMode;
  }

  String get currentMapStyle {
    final currentState = state;
    return currentState is NavigationActive ? currentState.mapStyle : 'mapbox://styles/mapbox/streets-v12';
  }

  Point? get currentLocation {
    final currentState = state;
    return currentState is NavigationActive ? currentState.currentLocation : null;
  }

  Point? get destination {
    final currentState = state;
    return currentState is NavigationActive ? currentState.destination : null;
  }
} 