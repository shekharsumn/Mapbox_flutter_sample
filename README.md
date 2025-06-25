
# 🗺️ MapBox 3D Flutter App – Technical Documentation

---

## 📦 Project Overview

**MapBox 3D** is a cross-platform Flutter application demonstrating integration with Mapbox for interactive 3D and styled maps. The app supports Android and iOS, and features a launch screen with selectable map types.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.32.4 or later)
- Android Studio or Xcode (for platform-specific builds)
- A valid [Mapbox Access Token](https://account.mapbox.com/access-tokens/)

### Installation

1. **Clone the repository:**
   ```sh
   git clone <repo-url>
   cd clone_location
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Add your Mapbox Access Token:**
   - Edit `.vscode/launch.json` or pass via `--dart-define`:
     ```
     --dart-define ACCESS_TOKEN=public_mapbox_token
     ```

4. **Add required assets:**
   - Place `sf_airport_route.geojson` and any other required files in the `assets/` directory.
   - Ensure `pubspec.yaml` includes:
     ```yaml
     assets:
       - assets/sf_airport_route.geojson
     ```

5. **Run the app:**
   ```sh
   flutter run
   ```

---

## 🏗️ Project Structure

```
lib/
  main.dart
  map_type_selection_screen.dart
assets/
  sf_airport_route.geojson
  sportcar.glb
.vscode/
  launch.json
android/
ios/
```

---

## 🗺️ Features

- **Launch Screen:** 2x2 grid of map type cards (Streets, Satellite, Outdoors, Light)
- **Map Screen:** Loads Mapbox map with selected style and zoom
- **Location Permissions:** Requests and handles permissions on both Android and iOS
- **Asset Loading:** Loads GeoJSON and 3D model assets for map overlays

---

## ⚙️ Configuration

### Mapbox Access Token

- Set via `--dart-define` or in your IDE’s launch configuration.
- Example for VS Code:
  ```json
  "args": [
    "--dart-define",
    "ACCESS_TOKEN=your_mapbox_token"
  ]
  ```

### Android Permissions

- `android/app/src/main/AndroidManifest.xml` includes:
  - `INTERNET`
  - `ACCESS_FINE_LOCATION`
  - `ACCESS_COARSE_LOCATION`
  - `ACCESS_NETWORK_STATE`
  - `CHANGE_NETWORK_STATE`
  - `CHANGE_WIFI_STATE`
  - `ACCESS_WIFI_STATE`

### iOS Permissions

- `ios/Runner/Info.plist` includes:
  - `NSLocationWhenInUseUsageDescription`
  - `NSLocationAlwaysAndWhenInUseUsageDescription`
  - `NSLocationAlwaysUsageDescription`
  - `NSLocalNetworkUsageDescription`

---

## 🛠️ Development Notes

- **Hot reload** does not pick up new assets. Use **hot restart** or a full rebuild after adding assets.
- If you see asset errors, check the path and registration in `pubspec.yaml`.
- For local network debugging on iOS, ensure the app has Local Network permission in device settings.

---

## 🧩 Dependencies

- `mapbox_maps_flutter`
- `permission_handler`
- `cupertino_icons`

---

## 📝 Useful Links

- [Flutter Documentation](https://docs.flutter.dev/)
- [Mapbox Flutter Plugin](https://pub.dev/packages/mapbox_maps_flutter)
- [Mapbox Access Tokens](https://account.mapbox.com/access-tokens/)

---

## 🐞 Troubleshooting

- **Map not loading:** Check access token, permissions, and network.
- **Asset not found:** Ensure asset exists, is non-empty, and is registered in `pubspec.yaml`.
- **iOS Local Network error:** Add `NSLocalNetworkUsageDescription` to `Info.plist` and enable permission in device settings.
