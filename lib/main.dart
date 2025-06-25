import 'package:flutter/material.dart';
import 'package:mapbox_3d/offline_map.dart';
//import 'package:mapbox_3d/route_map.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request location permission
  await Permission.locationWhenInUse.request();

  // Pass your access token to MapboxOptions so you can load a map
  //String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
  String accessToken = "pk.eyJ1Ijoic2hla2hhcnN1bW4iLCJhIjoiY21jOTM0aXJtMGs4ejJpczkwbnJocjdlZyJ9.GUXxuUnJYY7-9UfKQEuIIg";
  MapboxOptions.setAccessToken(accessToken);
  debugPrint("Mapbox Access Token: $accessToken");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapbox Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      //home: const RouteMapExample(),
      home: const CombinedOffline3DMap(),
    );
  }
}

/* enum MapType { streets, satellite, outdoors, light }

class MapScreen extends StatelessWidget {
  final MapType mapType;
  const MapScreen({super.key, required this.mapType});

  String getStyleUrl() {
    switch (mapType) {
      case MapType.streets:
        return MapboxStyles.MAPBOX_STREETS;
      case MapType.satellite:
        return MapboxStyles.SATELLITE;
      case MapType.outdoors:
        return MapboxStyles.OUTDOORS;
      case MapType.light:
        return MapboxStyles.LIGHT;
    }
  }

  @override
  Widget build(BuildContext context) {
    CameraOptions camera = CameraOptions(
      center: Point(coordinates: Position(-98.0, 39.5)),
      zoom: 2,
      bearing: 0,
      pitch: 0,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: MapWidget(
        cameraOptions: camera,
        styleUri: getStyleUrl(),
      ),
    );
  }
} */
