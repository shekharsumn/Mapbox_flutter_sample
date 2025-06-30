import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static final Map<Permission, String> _permissionDescriptions = {
    Permission.locationWhenInUse: 'Location access is needed to show your position on the map and provide navigation.',
    Permission.locationAlways: 'Background location is needed for turn-by-turn navigation.',
    Permission.camera: 'Camera access is needed for AR navigation and 3D model visualization.',
    Permission.microphone: 'Microphone access is needed for voice navigation and audio feedback.',
    Permission.storage: 'Storage access is needed to save offline maps and navigation data.',
    Permission.audio: 'Audio access is needed for navigation voice guidance.',
  };

  /// Request all necessary permissions for Mapbox features
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = {};
    
    for (Permission permission in _permissionDescriptions.keys) {
      statuses[permission] = await permission.request();
    }
    
    return statuses;
  }

  /// Check if all required permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    for (Permission permission in _permissionDescriptions.keys) {
      if (await permission.status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  /// Get a list of denied permissions
  static Future<List<Permission>> getDeniedPermissions() async {
    List<Permission> deniedPermissions = [];
    
    for (Permission permission in _permissionDescriptions.keys) {
      if (await permission.status != PermissionStatus.granted) {
        deniedPermissions.add(permission);
      }
    }
    
    return deniedPermissions;
  }

  /// Show a dialog explaining why a permission is needed
  static Future<bool> showPermissionDialog(
    BuildContext context,
    Permission permission,
  ) async {
    final description = _permissionDescriptions[permission] ?? 
        'This permission is required for the app to function properly.';
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Required'),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Grant Permission'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Request a specific permission with user-friendly dialog
  static Future<PermissionStatus> requestPermissionWithDialog(
    BuildContext context,
    Permission permission,
  ) async {
    // Check current status
    PermissionStatus status = await permission.status;
    
    if (status == PermissionStatus.granted) {
      return status;
    }
    
    // Show explanation dialog if permission is denied
    if (status == PermissionStatus.denied) {
      bool shouldRequest = await showPermissionDialog(context, permission);
      if (!shouldRequest) {
        return status;
      }
    }
    
    // Request permission
    status = await permission.request();
    
    // If permanently denied, show settings dialog
    if (status == PermissionStatus.permanentlyDenied) {
      bool openSettings = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'This permission is required for the app to function properly. '
              'Please enable it in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      ) ?? false;
      
      if (openSettings) {
        await openAppSettings();
        // Check status again after returning from settings
        status = await permission.status;
      }
    }
    
    return status;
  }

  /// Request all permissions with user-friendly dialogs
  static Future<Map<Permission, PermissionStatus>> requestAllPermissionsWithDialogs(
    BuildContext context,
  ) async {
    Map<Permission, PermissionStatus> statuses = {};
    
    for (Permission permission in _permissionDescriptions.keys) {
      statuses[permission] = await requestPermissionWithDialog(context, permission);
    }
    
    return statuses;
  }

  /// Get permission status summary for debugging
  static Future<String> getPermissionStatusSummary() async {
    StringBuffer summary = StringBuffer();
    summary.writeln('Permission Status Summary:');
    
    for (Permission permission in _permissionDescriptions.keys) {
      PermissionStatus status = await permission.status;
      summary.writeln('${permission.toString()}: $status');
    }
    
    return summary.toString();
  }

  /// Check if location permissions are granted (most critical for Mapbox)
  static Future<bool> areLocationPermissionsGranted() async {
    return await Permission.locationWhenInUse.status == PermissionStatus.granted &&
           await Permission.locationAlways.status == PermissionStatus.granted;
  }

  /// Request only location permissions (minimal requirement)
  static Future<Map<Permission, PermissionStatus>> requestLocationPermissions() async {
    Map<Permission, PermissionStatus> statuses = {};
    
    statuses[Permission.locationWhenInUse] = await Permission.locationWhenInUse.request();
    statuses[Permission.locationAlways] = await Permission.locationAlways.request();
    
    return statuses;
  }
} 