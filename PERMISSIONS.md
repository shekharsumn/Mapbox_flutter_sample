# Mapbox 3D App - Permissions Guide

This document outlines all the permissions required for the Mapbox 3D Flutter app and explains why each permission is needed.

## Android Permissions

### Location Permissions
- **`ACCESS_FINE_LOCATION`** - Required for precise GPS location for navigation and user positioning
- **`ACCESS_COARSE_LOCATION`** - Required for approximate location when GPS is not available

### Network Permissions
- **`INTERNET`** - Required for downloading map tiles, GeoJSON data, and Mapbox services
- **`ACCESS_NETWORK_STATE`** - Required to check network connectivity for offline/online map switching
- **`CHANGE_NETWORK_STATE`** - Required for managing network connections
- **`ACCESS_WIFI_STATE`** - Required to check WiFi connectivity
- **`CHANGE_WIFI_STATE`** - Required for managing WiFi connections

### Storage Permissions
- **`WRITE_EXTERNAL_STORAGE`** - Required for saving offline maps and navigation data
- **`READ_EXTERNAL_STORAGE`** - Required for reading saved offline maps and data
- **`READ_MEDIA_IMAGES`** (Android 13+) - Required for accessing images for map overlays
- **`READ_MEDIA_VIDEO`** (Android 13+) - Required for video content in AR features
- **`READ_MEDIA_AUDIO`** (Android 13+) - Required for audio navigation files
- **`READ_MEDIA_VISUAL_USER_SELECTED`** (Android 14+) - Required for user-selected media access

### System Permissions
- **`WAKE_LOCK`** - Required to keep the device awake during navigation
- **`FOREGROUND_SERVICE`** - Required for background navigation services
- **`CAMERA`** - Required for AR navigation and 3D model visualization
- **`RECORD_AUDIO`** - Required for voice navigation and audio feedback
- **`MODIFY_AUDIO_SETTINGS`** - Required for adjusting audio during navigation

### Hardware Features (Optional)
- **`android.hardware.location.gps`** - GPS hardware (optional)
- **`android.hardware.location.network`** - Network-based location (optional)
- **`android.hardware.camera`** - Camera hardware (optional)
- **`android.hardware.camera.autofocus`** - Camera autofocus (optional)
- **`android.hardware.microphone`** - Microphone hardware (optional)
- **`android.hardware.wifi`** - WiFi hardware (optional)
- **`android.hardware.bluetooth`** - Bluetooth hardware (optional)
- **`android.hardware.bluetooth_le`** - Bluetooth LE hardware (optional)

## iOS Permissions

### Location Permissions
- **`NSLocationWhenInUseUsageDescription`** - Required for location access when app is in use
- **`NSLocationAlwaysAndWhenInUseUsageDescription`** - Required for background location access
- **`NSLocationAlwaysUsageDescription`** - Required for background location (legacy iOS)
- **`NSLocationTemporaryUsageDescriptionDictionary`** - Required for precise location (iOS 14+)

### Hardware Permissions
- **`NSCameraUsageDescription`** - Required for camera access in AR navigation
- **`NSMicrophoneUsageDescription`** - Required for microphone access in voice navigation
- **`NSPhotoLibraryUsageDescription`** - Required for saving map screenshots
- **`NSPhotoLibraryAddUsageDescription`** - Required for adding photos to library

### Network Permissions
- **`NSLocalNetworkUsageDescription`** - Required for local network access during development

### Background Modes
- **`location`** - Required for background location tracking during navigation
- **`audio`** - Required for background audio during voice navigation
- **`background-processing`** - Required for background map processing

### Device Capabilities
- **`location-services`** - Required for location services
- **`gps`** - Required for GPS functionality
- **`armv7`** - Required for ARM architecture support

### App Transport Security
- **`NSAllowsArbitraryLoads`** - Allows HTTP connections for development
- **`NSExceptionDomains`** - Specific domain exceptions for Mapbox services

## Permission Usage in Code

### Requesting Permissions
The app uses the `permission_handler` package to request permissions:

```dart
// Request all permissions at once
Map<Permission, PermissionStatus> statuses = await PermissionUtils.requestAllPermissions();

// Request specific permission with user-friendly dialog
PermissionStatus status = await PermissionUtils.requestPermissionWithDialog(context, Permission.locationWhenInUse);
```

### Checking Permission Status
```dart
// Check if all permissions are granted
bool allGranted = await PermissionUtils.areAllPermissionsGranted();

// Check if location permissions are granted (most critical)
bool locationGranted = await PermissionUtils.areLocationPermissionsGranted();
```

### Permission Status Widget
The app includes a `PermissionStatusWidget` that displays:
- Current status of all permissions
- Color-coded status indicators
- Buttons to request permissions or open settings
- Real-time status updates

## Permission Flow

1. **App Launch**: Basic permissions are requested automatically
2. **Feature Access**: Additional permissions are requested when specific features are used
3. **User Denial**: If permissions are denied, the app shows explanatory dialogs
4. **Settings Redirect**: If permissions are permanently denied, users are guided to device settings

## Troubleshooting

### Common Issues

1. **Location not working**: Ensure both `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` are granted
2. **Offline maps not saving**: Check storage permissions are granted
3. **Camera features not working**: Ensure camera permission is granted
4. **Voice navigation not working**: Check microphone permission is granted

### Debug Information
Use the permission status widget or check debug logs for permission status:
```dart
String summary = await PermissionUtils.getPermissionStatusSummary();
debugPrint(summary);
```

## Best Practices

1. **Request permissions when needed**: Don't request all permissions at startup
2. **Explain why permissions are needed**: Use descriptive permission messages
3. **Handle permission denials gracefully**: Provide alternative functionality when possible
4. **Test on different Android/iOS versions**: Permissions behave differently across versions
5. **Respect user choices**: Don't repeatedly request denied permissions

## Privacy Considerations

- Location data is only used for navigation and map positioning
- Camera access is only used for AR features when explicitly requested
- Microphone access is only used for voice navigation
- Storage access is only used for offline map data
- No personal data is collected or transmitted beyond what's necessary for app functionality 