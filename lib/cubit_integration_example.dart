import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_3d/bloc/bloc.dart';
import 'package:permission_handler/permission_handler.dart';

/// Example screen demonstrating CUBIT integration with Mapbox
class CubitIntegrationExample extends StatelessWidget {
  const CubitIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CUBIT Integration Example'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<AppCubit, AppState>(
            builder: (context, appState) {
              return IconButton(
                onPressed: () {
                  context.read<AppCubit>().toggleTheme();
                },
                icon: Icon(
                  appState is AppLoaded && appState.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                tooltip: 'Toggle Theme',
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NavigationCubit, NavigationState>(
        builder: (context, state) {
          if (state is NavigationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NavigationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NavigationCubit>().initializeNavigation();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is NavigationActive) {
            return Stack(
              children: [
                // Map Widget
                MapWidget(
                  key: const ValueKey<String>('cubitMapWidget'),
                  cameraOptions: CameraOptions(
                    center: state.currentLocation,
                    zoom: 15.0,
                    bearing: 0,
                    pitch: state.is3DMode ? 45 : 0,
                  ),
                  styleUri: state.mapStyle,
                  onMapCreated: (MapboxMap mapboxMap) {
                    // You can store the mapboxMap reference if needed
                  },
                ),

                // Navigation Controls Overlay
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: '3d_toggle',
                        onPressed: () {
                          context.read<NavigationCubit>().toggle3DMode(!state.is3DMode);
                        },
                        tooltip: 'Toggle 3D Mode',
                        child: Icon(state.is3DMode ? Icons.view_in_ar : Icons.view_in_ar_outlined),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'style_toggle',
                        onPressed: () {
                          final newStyle = state.mapStyle.contains('satellite')
                              ? 'mapbox://styles/mapbox/streets-v12'
                              : 'mapbox://styles/mapbox/satellite-v9';
                          context.read<NavigationCubit>().setMapStyle(newStyle);
                        },
                        tooltip: 'Toggle Map Style',
                        child: const Icon(Icons.layers),
                      ),
                    ],
                  ),
                ),

                // Navigation Status Panel
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Navigation Status',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: state.isNavigating ? Colors.green : Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  state.isNavigating ? 'Active' : 'Inactive',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Current Location: ${state.currentLocation.coordinates.lat.toStringAsFixed(4)}, ${state.currentLocation.coordinates.lng.toStringAsFixed(4)}'),
                          Text('Destination: ${state.destination.coordinates.lat.toStringAsFixed(4)}, ${state.destination.coordinates.lng.toStringAsFixed(4)}'),
                          Text('3D Mode: ${state.is3DMode ? "Enabled" : "Disabled"}'),
                          Text('Map Style: ${state.mapStyle.split('/').last}'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: state.isNavigating
                                      ? () {
                                          context.read<NavigationCubit>().stopNavigation();
                                        }
                                      : () {
                                          // Start navigation to a sample destination
                                          final destination = Point(
                                            coordinates: Position(
                                              state.currentLocation.coordinates.lng + 0.01,
                                              state.currentLocation.coordinates.lat + 0.01,
                                            ),
                                          );
                                          context.read<NavigationCubit>().startNavigation(destination);
                                        },
                                  child: Text(state.isNavigating ? 'Stop Navigation' : 'Start Navigation'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Settings Integration
                Positioned(
                  top: 16,
                  left: 16,
                  child: BlocBuilder<AppCubit, AppState>(
                    builder: (context, appState) {
                      if (appState is AppLoaded) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'App Settings',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '3D: ${appState.settings['enable3D'] ?? false ? "On" : "Off"}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                Text(
                                  'Offline: ${appState.settings['enableOfflineMaps'] ?? true ? "On" : "Off"}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                Text(
                                  'Voice: ${appState.settings['enableVoiceNavigation'] ?? true ? "On" : "Off"}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            );
          }

          return const Center(
            child: Text('No navigation state available'),
          );
        },
      ),
    );
  }
}

/// Example of a custom widget that uses multiple CUBITs
class MultiCubitExample extends StatelessWidget {
  const MultiCubitExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-CUBIT Example'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CUBIT State Management Demo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // App State Section
            BlocBuilder<AppCubit, AppState>(
              builder: (context, appState) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'App State',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (appState is AppLoaded) ...[
                          Text('Theme: ${appState.themeMode.name}'),
                          Text('Initialized: ${appState.isInitialized}'),
                          Text('Settings Count: ${appState.settings.length}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              context.read<AppCubit>().toggleTheme();
                            },
                            child: const Text('Toggle Theme'),
                          ),
                        ] else if (appState is AppLoading) ...[
                          const CircularProgressIndicator(),
                        ] else if (appState is AppError) ...[
                          Text('Error: ${appState.message}'),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Navigation State Section
            BlocBuilder<NavigationCubit, NavigationState>(
              builder: (context, navState) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Navigation State',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (navState is NavigationActive) ...[
                          Text('3D Mode: ${navState.is3DMode ? "Enabled" : "Disabled"}'),
                          Text('Navigating: ${navState.isNavigating ? "Yes" : "No"}'),
                          Text('Map Style: ${navState.mapStyle.split('/').last}'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    context.read<NavigationCubit>().toggle3DMode(!navState.is3DMode);
                                  },
                                  child: Text(navState.is3DMode ? 'Disable 3D' : 'Enable 3D'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    final newStyle = navState.mapStyle.contains('satellite')
                                        ? 'mapbox://styles/mapbox/streets-v12'
                                        : 'mapbox://styles/mapbox/satellite-v9';
                                    context.read<NavigationCubit>().setMapStyle(newStyle);
                                  },
                                  child: const Text('Toggle Style'),
                                ),
                              ),
                            ],
                          ),
                        ] else if (navState is NavigationLoading) ...[
                          const CircularProgressIndicator(),
                        ] else if (navState is NavigationError) ...[
                          Text('Error: ${navState.message}'),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Permission State Section
            BlocBuilder<PermissionCubit, PermissionState>(
              builder: (context, permState) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Permission State',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (permState is PermissionLoaded) ...[
                          Text('Total Permissions: ${permState.permissionStatuses.length}'),
                          Text('Granted: ${permState.permissionStatuses.values.where((status) => status == PermissionStatus.granted).length}'),
                          Text('Denied: ${permState.permissionStatuses.values.where((status) => status == PermissionStatus.denied).length}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              context.read<PermissionCubit>().refreshPermissions();
                            },
                            child: const Text('Refresh Permissions'),
                          ),
                        ] else if (permState is PermissionLoading) ...[
                          const CircularProgressIndicator(),
                        ] else if (permState is PermissionError) ...[
                          Text('Error: ${permState.message}'),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 