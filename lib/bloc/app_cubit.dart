import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// Events
abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

class InitializeApp extends AppEvent {}

class ToggleTheme extends AppEvent {}

class SetTheme extends AppEvent {
  final ThemeMode themeMode;

  const SetTheme(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class UpdateAppSettings extends AppEvent {
  final Map<String, dynamic> settings;

  const UpdateAppSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

// States
abstract class AppState extends Equatable {
  const AppState();

  @override
  List<Object?> get props => [];
}

class AppInitial extends AppState {}

class AppLoading extends AppState {}

class AppLoaded extends AppState {
  final ThemeMode themeMode;
  final Map<String, dynamic> settings;
  final bool isInitialized;

  const AppLoaded({
    this.themeMode = ThemeMode.system,
    this.settings = const {},
    this.isInitialized = false,
  });

  @override
  List<Object?> get props => [themeMode, settings, isInitialized];

  AppLoaded copyWith({
    ThemeMode? themeMode,
    Map<String, dynamic>? settings,
    bool? isInitialized,
  }) {
    return AppLoaded(
      themeMode: themeMode ?? this.themeMode,
      settings: settings ?? this.settings,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AppError extends AppState {
  final String message;

  const AppError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class AppCubit extends Cubit<AppState> {
  AppCubit() : super(AppInitial());

  Future<void> initializeApp() async {
    emit(AppLoading());
    
    try {
      // Load default settings
      final defaultSettings = {
        'mapStyle': 'mapbox://styles/mapbox/streets-v12',
        'enable3D': false,
        'enableOfflineMaps': true,
        'enableVoiceNavigation': true,
        'enableTraffic': false,
        'units': 'metric', // metric or imperial
      };

      emit(AppLoaded(
        themeMode: ThemeMode.system,
        settings: defaultSettings,
        isInitialized: true,
      ));
    } catch (e) {
      emit(AppError('Failed to initialize app: $e'));
    }
  }

  void toggleTheme() {
    final currentState = state;
    if (currentState is AppLoaded) {
      ThemeMode newThemeMode;
      switch (currentState.themeMode) {
        case ThemeMode.light:
          newThemeMode = ThemeMode.dark;
          break;
        case ThemeMode.dark:
          newThemeMode = ThemeMode.system;
          break;
        case ThemeMode.system:
          newThemeMode = ThemeMode.light;
          break;
      }
      emit(currentState.copyWith(themeMode: newThemeMode));
    }
  }

  void setTheme(ThemeMode themeMode) {
    final currentState = state;
    if (currentState is AppLoaded) {
      emit(currentState.copyWith(themeMode: themeMode));
    }
  }

  void updateSettings(Map<String, dynamic> newSettings) {
    final currentState = state;
    if (currentState is AppLoaded) {
      final updatedSettings = Map<String, dynamic>.from(currentState.settings);
      updatedSettings.addAll(newSettings);
      emit(currentState.copyWith(settings: updatedSettings));
    }
  }

  void updateSetting(String key, dynamic value) {
    final currentState = state;
    if (currentState is AppLoaded) {
      final updatedSettings = Map<String, dynamic>.from(currentState.settings);
      updatedSettings[key] = value;
      emit(currentState.copyWith(settings: updatedSettings));
    }
  }

  // Helper methods
  ThemeMode get currentThemeMode {
    final currentState = state;
    return currentState is AppLoaded ? currentState.themeMode : ThemeMode.system;
  }

  Map<String, dynamic> get currentSettings {
    final currentState = state;
    return currentState is AppLoaded ? currentState.settings : {};
  }

  bool get isInitialized {
    final currentState = state;
    return currentState is AppLoaded && currentState.isInitialized;
  }

  String get mapStyle {
    final currentState = state;
    if (currentState is AppLoaded) {
      return currentState.settings['mapStyle'] ?? 'mapbox://styles/mapbox/streets-v12';
    }
    return 'mapbox://styles/mapbox/streets-v12';
  }

  bool get enable3D {
    final currentState = state;
    if (currentState is AppLoaded) {
      return currentState.settings['enable3D'] ?? false;
    }
    return false;
  }

  bool get enableOfflineMaps {
    final currentState = state;
    if (currentState is AppLoaded) {
      return currentState.settings['enableOfflineMaps'] ?? true;
    }
    return true;
  }

  bool get enableVoiceNavigation {
    final currentState = state;
    if (currentState is AppLoaded) {
      return currentState.settings['enableVoiceNavigation'] ?? true;
    }
    return true;
  }

  bool get enableTraffic {
    final currentState = state;
    if (currentState is AppLoaded) {
      return currentState.settings['enableTraffic'] ?? false;
    }
    return false;
  }

  String get units {
    final currentState = state;
    if (currentState is AppLoaded) {
      return currentState.settings['units'] ?? 'metric';
    }
    return 'metric';
  }
} 