import 'package:flutter/material.dart';
import 'package:mapbox_3d/offline_map.dart';
import 'package:mapbox_3d/turn_navigation.dart';
import 'package:mapbox_3d/navigation_demo.dart';
import 'package:mapbox_3d/permission_status_widget.dart';
import 'package:mapbox_3d/terrain_3d.dart';
import 'package:mapbox_3d/cubit_integration_example.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mapbox_3d/permission_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_3d/bloc/bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request all necessary permissions for Mapbox features
  await _requestPermissions();

  // Pass your access token to MapboxOptions so you can load a map
  //String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
  String accessToken = "pk.eyJ1Ijoic2hla2hhcnN1bW4iLCJhIjoiY21jOTM0aXJtMGs4ejJpczkwbnJocjdlZyJ9.GUXxuUnJYY7-9UfKQEuIIg";
  MapboxOptions.setAccessToken(accessToken);
  debugPrint("Mapbox Access Token: $accessToken");

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  // Request all permissions and log the results
  Map<Permission, PermissionStatus> statuses = await PermissionUtils.requestAllPermissions();
  
  // Log permission statuses for debugging
  statuses.forEach((permission, status) {
    debugPrint('${permission.toString()}: $status');
  });
  
  // Check if location permissions are granted (most critical)
  bool locationGranted = await PermissionUtils.areLocationPermissionsGranted();
  if (!locationGranted) {
    debugPrint('Warning: Location permissions not granted. Map features may be limited.');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppCubit>(
          create: (context) => AppCubit()..initializeApp(),
        ),
        BlocProvider<NavigationCubit>(
          create: (context) => NavigationCubit()..initializeNavigation(),
        ),
      ],
      child: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Mapbox Demo',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.dark,
            ),
            themeMode: state is AppLoaded ? state.themeMode : ThemeMode.system,
            home: const MapSelectionScreen(),
          );
        },
      ),
    );
  }
}

class MapSelectionScreen extends StatelessWidget {
  const MapSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapbox 3D Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<AppCubit, AppState>(
            builder: (context, state) {
              return IconButton(
                onPressed: () {
                  context.read<AppCubit>().toggleTheme();
                },
                icon: Icon(
                  state is AppLoaded && state.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                tooltip: 'Toggle Theme',
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildMapCard(
              context,
              'Offline 3D Map',
              Icons.map,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CombinedOffline3DMap()),
              ),
            ),
            _buildMapCard(
              context,
              'Turn Navigation',
              Icons.navigation,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TurnByTurnNavigation()),
              ),
            ),
            _buildMapCard(
              context,
              'Navigation Demo',
              Icons.explore,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NavigationDemo()),
              ),
            ),
            _buildMapCard(
              context,
              'Terrain View 3D',
              Icons.streetview,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TerrainView3D()),
              ),
            ),
            _buildMapCard(
              context,
              'CUBIT Integration Example',
              Icons.integration_instructions,
              Colors.pink,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CubitIntegrationExample()),
              ),
            ),
            _buildMapCard(
              context,
              'Settings',
              Icons.settings,
              Colors.purple,
              () => _showSettings(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.8), color],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48.0,
                color: Colors.white,
              ),
              const SizedBox(height: 16.0),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Permissions'),
              subtitle: const Text('Manage app permissions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PermissionSettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('App Settings'),
              subtitle: const Text('Configure app preferences'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppSettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              subtitle: const Text('App information and version'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Mapbox 3D Demo',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.map, size: 48),
      children: const [
        Text('A comprehensive Mapbox Flutter demo app featuring:'),
        SizedBox(height: 8),
        Text('• Offline 3D maps with custom models'),
        Text('• Turn-by-turn navigation'),
        Text('• Interactive navigation controls'),
        Text('• Permission management'),
        Text('• Multiple map styles'),
        Text('• CUBIT state management'),
      ],
    );
  }
}

class PermissionSettingsScreen extends StatelessWidget {
  const PermissionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: PermissionStatusWidget(),
      ),
    );
  }
}

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          if (state is AppLoaded) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Theme',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: const Text('Light'),
                                  leading: Radio<ThemeMode>(
                                    value: ThemeMode.light,
                                    groupValue: state.themeMode,
                                    onChanged: (ThemeMode? value) {
                                      if (value != null) {
                                        context.read<AppCubit>().setTheme(value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListTile(
                                  title: const Text('Dark'),
                                  leading: Radio<ThemeMode>(
                                    value: ThemeMode.dark,
                                    groupValue: state.themeMode,
                                    onChanged: (ThemeMode? value) {
                                      if (value != null) {
                                        context.read<AppCubit>().setTheme(value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListTile(
                                  title: const Text('System'),
                                  leading: Radio<ThemeMode>(
                                    value: ThemeMode.system,
                                    groupValue: state.themeMode,
                                    onChanged: (ThemeMode? value) {
                                      if (value != null) {
                                        context.read<AppCubit>().setTheme(value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Map Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Enable 3D Mode'),
                            subtitle: const Text('Show maps in 3D by default'),
                            value: state.settings['enable3D'] ?? false,
                            onChanged: (bool value) {
                              context.read<AppCubit>().updateSetting('enable3D', value);
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Enable Offline Maps'),
                            subtitle: const Text('Allow downloading maps for offline use'),
                            value: state.settings['enableOfflineMaps'] ?? true,
                            onChanged: (bool value) {
                              context.read<AppCubit>().updateSetting('enableOfflineMaps', value);
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Enable Voice Navigation'),
                            subtitle: const Text('Provide voice guidance during navigation'),
                            value: state.settings['enableVoiceNavigation'] ?? true,
                            onChanged: (bool value) {
                              context.read<AppCubit>().updateSetting('enableVoiceNavigation', value);
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Enable Traffic'),
                            subtitle: const Text('Show real-time traffic information'),
                            value: state.settings['enableTraffic'] ?? false,
                            onChanged: (bool value) {
                              context.read<AppCubit>().updateSetting('enableTraffic', value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}