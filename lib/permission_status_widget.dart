import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mapbox_3d/permission_utils.dart';

class PermissionStatusWidget extends StatefulWidget {
  const PermissionStatusWidget({super.key});

  @override
  State<PermissionStatusWidget> createState() => _PermissionStatusWidgetState();
}

class _PermissionStatusWidgetState extends State<PermissionStatusWidget> {
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatuses();
  }

  Future<void> _loadPermissionStatuses() async {
    setState(() {
      _isLoading = true;
    });

    Map<Permission, PermissionStatus> statuses = {};
    final permissions = [
      Permission.locationWhenInUse,
      Permission.locationAlways,
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.audio,
    ];

    for (Permission permission in permissions) {
      statuses[permission] = await permission.status;
    }

    setState(() {
      _permissionStatuses = statuses;
      _isLoading = false;
    });
  }

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
      default:
        return Colors.grey;
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
    if (_isLoading) {
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
                  onPressed: _loadPermissionStatuses,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...(_permissionStatuses.entries.map((entry) {
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
                      _loadPermissionStatuses();
                    },
                    child: const Text('Request All Permissions'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await openAppSettings();
                    _loadPermissionStatuses();
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
} 