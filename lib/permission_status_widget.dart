import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mapbox_3d/permission_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_3d/bloc/bloc.dart';

class PermissionStatusWidget extends StatelessWidget {
  const PermissionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PermissionCubit()..loadPermissions(),
      child: const _PermissionStatusWidgetContent(),
    );
  }
}

class _PermissionStatusWidgetContent extends StatelessWidget {
  const _PermissionStatusWidgetContent();

  Color _getStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.orange;
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      case PermissionStatus.restricted:
        return Colors.red;
      case PermissionStatus.limited:
        return Colors.yellow;
      case PermissionStatus.provisional:
        return Colors.blue;
    }
  }

  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.locationWhenInUse:
        return 'Location (When In Use)';
      case Permission.locationAlways:
        return 'Location (Always)';
      case Permission.camera:
        return 'Camera';
      case Permission.microphone:
        return 'Microphone';
      case Permission.storage:
        return 'Storage';
      case Permission.audio:
        return 'Audio';
      default:
        return permission.toString().split('.').last;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PermissionCubit, PermissionState>(
      builder: (context, state) {
        if (state is PermissionLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Loading permission status...'),
                ],
              ),
            ),
          );
        }

        if (state is PermissionError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PermissionCubit>().loadPermissions();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is PermissionLoaded) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Permission Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          context.read<PermissionCubit>().refreshPermissions();
                        },
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...(state.permissionStatuses.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(entry.value),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_getPermissionName(entry.key)),
                          ),
                          Text(
                            entry.value.toString().split('.').last,
                            style: TextStyle(
                              color: _getStatusColor(entry.value),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await PermissionUtils.requestAllPermissionsWithDialogs(context);
                            if (context.mounted) {
                              context.read<PermissionCubit>().refreshPermissions();
                            }
                          },
                          child: const Text('Request All Permissions'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await openAppSettings();
                          if (context.mounted) {
                            context.read<PermissionCubit>().refreshPermissions();
                          }
                        },
                        child: const Text('Open Settings'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No permission data available'),
          ),
        );
      },
    );
  }
} 