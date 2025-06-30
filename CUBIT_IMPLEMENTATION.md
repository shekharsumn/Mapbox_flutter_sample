# CUBIT State Management Implementation

This project has been updated to use CUBIT (Component Unified Business Logic and Information Transfer) for state management using the `flutter_bloc` package.

## Overview

CUBIT is a simplified version of BLoC (Business Logic Component) that provides a clean separation of concerns and predictable state management. It's perfect for managing complex state in Flutter applications.

## Architecture

The project now uses three main CUBITs:

### 1. AppCubit (`lib/bloc/app_cubit.dart`)
Manages global application state including:
- Theme management (Light/Dark/System)
- App settings and preferences
- Global configuration

**States:**
- `AppInitial`: Initial state
- `AppLoading`: Loading state
- `AppLoaded`: Loaded with theme and settings
- `AppError`: Error state

**Key Methods:**
- `initializeApp()`: Initialize app with default settings
- `toggleTheme()`: Cycle through theme modes
- `setTheme(ThemeMode)`: Set specific theme
- `updateSetting(String, dynamic)`: Update individual settings

### 2. NavigationCubit (`lib/bloc/navigation_cubit.dart`)
Manages navigation and map-related state:
- Current location and destination
- Map style and 3D mode
- Navigation status

**States:**
- `NavigationInitial`: Initial state
- `NavigationLoading`: Loading state
- `NavigationActive`: Active navigation with location data
- `NavigationError`: Error state

**Key Methods:**
- `initializeNavigation()`: Initialize with default location
- `startNavigation(Point)`: Start navigation to destination
- `stopNavigation()`: Stop current navigation
- `updateLocation(Point)`: Update current location
- `setMapStyle(String)`: Change map style
- `toggle3DMode(bool)`: Enable/disable 3D mode

### 3. PermissionCubit (`lib/bloc/permission_cubit.dart`)
Manages app permissions:
- Permission status tracking
- Permission requests
- Permission validation

**States:**
- `PermissionInitial`: Initial state
- `PermissionLoading`: Loading permissions
- `PermissionLoaded`: Loaded with permission statuses
- `PermissionError`: Error state

**Key Methods:**
- `loadPermissions()`: Load current permission statuses
- `requestPermission(Permission)`: Request specific permission
- `requestAllPermissions()`: Request all permissions
- `refreshPermissions()`: Refresh permission statuses
- `areLocationPermissionsGranted()`: Check location permissions
- `areAllPermissionsGranted()`: Check all permissions

## Usage Examples

### Basic CUBIT Usage

```dart
// In a widget
BlocBuilder<AppCubit, AppState>(
  builder: (context, state) {
    if (state is AppLoaded) {
      return Text('Theme: ${state.themeMode.name}');
    }
    return CircularProgressIndicator();
  },
)
```

### Accessing CUBIT Methods

```dart
// Toggle theme
context.read<AppCubit>().toggleTheme();

// Start navigation
context.read<NavigationCubit>().startNavigation(destination);

// Request permissions
context.read<PermissionCubit>().requestAllPermissions();
```

### Multi-CUBIT Integration

```dart
// Using multiple CUBITs in one widget
BlocBuilder<AppCubit, AppState>(
  builder: (context, appState) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, navState) {
        // Combine states from both CUBITs
        return YourWidget();
      },
    );
  },
)
```

## Setup

### 1. Dependencies
The following dependencies have been added to `pubspec.yaml`:

```yaml
dependencies:
  flutter_bloc: ^8.1.4
  equatable: ^2.0.5
```

### 2. Provider Setup
CUBITs are provided at the app level in `main.dart`:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider<AppCubit>(
      create: (context) => AppCubit()..initializeApp(),
    ),
    BlocProvider<NavigationCubit>(
      create: (context) => NavigationCubit()..initializeNavigation(),
    ),
  ],
  child: YourApp(),
)
```

### 3. Local CUBITs
For widget-specific state, CUBITs can be created locally:

```dart
BlocProvider(
  create: (context) => PermissionCubit()..loadPermissions(),
  child: PermissionStatusWidget(),
)
```

## Benefits of CUBIT Implementation

1. **Predictable State Management**: All state changes go through CUBITs, making the app behavior predictable.

2. **Separation of Concerns**: Business logic is separated from UI code.

3. **Testability**: CUBITs can be easily unit tested in isolation.

4. **Reusability**: CUBITs can be reused across different widgets.

5. **Debugging**: State changes are easily traceable and debuggable.

6. **Performance**: Efficient rebuilds with `BlocBuilder` and `BlocProvider`.

## Migration from Previous State Management

The following components have been migrated to use CUBITs:

1. **PermissionStatusWidget**: Now uses `PermissionCubit` instead of local state
2. **Main App**: Uses `AppCubit` for theme management
3. **Settings Screen**: New `AppSettingsScreen` with CUBIT integration
4. **Navigation**: `NavigationCubit` for map and navigation state

## Best Practices

1. **Keep CUBITs Focused**: Each CUBIT should handle a specific domain of your app.

2. **Use Equatable**: All states should extend `Equatable` for proper comparison.

3. **Handle Errors**: Always include error states in your CUBITs.

4. **Async Operations**: Use `emit()` to update state after async operations.

5. **State Immutability**: States should be immutable and use `copyWith()` for updates.

## Example Integration

See `lib/cubit_integration_example.dart` for a complete example of how to integrate CUBITs with Mapbox functionality, including:

- Real-time state updates
- Multi-CUBIT usage
- UI state management
- Navigation controls
- Settings integration

## Testing

CUBITs can be tested using the `bloc_test` package:

```dart
blocTest<AppCubit, AppState>(
  build: () => AppCubit(),
  act: (cubit) => cubit.toggleTheme(),
  expect: () => [AppLoaded(themeMode: ThemeMode.dark)],
);
```

## Future Enhancements

Potential improvements for the CUBIT implementation:

1. **Persistence**: Add state persistence using `hydrated_bloc`
2. **Analytics**: Track state changes for analytics
3. **Middleware**: Add logging or other middleware
4. **Repository Pattern**: Integrate with data repositories
5. **Dependency Injection**: Use proper DI for CUBIT dependencies 