import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:math' as Math;
import 'package:mapbox_3d/map_navigation_controls.dart';

class TurnByTurnNavigation extends StatefulWidget {
  const TurnByTurnNavigation({super.key});

  @override
  State<TurnByTurnNavigation> createState() => _TurnByTurnNavigationState();
}

class _TurnByTurnNavigationState extends State<TurnByTurnNavigation> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  List<PointAnnotation> _routePoints = [];
  int _currentPointIndex = 0;
  Timer? _navigationTimer;
  bool _isNavigating = false;

  // Route coordinates from test_trek.geojson
  final List<Position> _routeCoordinates = [];
  final centerPosition = Position(-122.3947, 37.7080);

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRouteData() async {
    try {
      final geoJsonString = await rootBundle.loadString('assets/test_trek.geojson');
      final decoded = json.decode(geoJsonString);
      final coordinates = decoded['features'][0]['geometry']['coordinates'] as List;
      
      for (var coord in coordinates) {
        _routeCoordinates.add(Position(coord[0], coord[1]));
      }
    } catch (e) {
      print('Error loading route data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turn-by-Turn Navigation'),
        actions: [
          IconButton(
            icon: Icon(_isNavigating ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleNavigation,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: MapWidget(
                  key: const ValueKey<String>('navigationMapWidget'),
                  cameraOptions: CameraOptions(
                    center: Point(coordinates: centerPosition),
                    zoom: 16.5,
                    bearing: 25,
                    pitch: 60,
                  ),
                  styleUri: MapboxStyles.SATELLITE_STREETS,
                  onMapCreated: _onMapCreated,
                  onStyleLoadedListener: _onStyleLoaded,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Navigation Status: ${_isNavigating ? "Active" : "Inactive"}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current Point: ${_currentPointIndex + 1}/${_routeCoordinates.length}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _previousPoint,
                          child: const Text('Previous'),
                        ),
                        ElevatedButton(
                          onPressed: _nextPoint,
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Navigation controls overlay
          if (mapboxMap != null) ...[
            MapNavigationControls(
              mapboxMap: mapboxMap,
              initiallyExpanded: false,
              backgroundColor: Colors.white.withOpacity(0.9),
              iconColor: Colors.black87,
            ),
            MapCompass(
              mapboxMap: mapboxMap,
              backgroundColor: Colors.white.withOpacity(0.9),
              iconColor: Colors.black87,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    await _addRouteLayer();
    await _setupPointAnnotations();
    await _add3DBuildingsLayer();
  }

  Future<void> _addRouteLayer() async {
    try {
      final geoJsonString = await rootBundle.loadString('assets/test_trek.geojson');
      
      // Add route source
      await mapboxMap?.style.addSource(
        GeoJsonSource(id: "navigation-route", data: geoJsonString),
      );

      // Add route line layer
      await mapboxMap?.style.addLayer(
        LineLayer(id: "route-line", sourceId: "navigation-route")
          ..lineColor = Colors.blue.value
          ..lineWidth = 8.0
          ..lineOpacity = 0.9
          ..lineJoin = LineJoin.ROUND
          ..lineCap = LineCap.ROUND,
      );

      // Add route points layer
      await mapboxMap?.style.addLayer(
        CircleLayer(id: "route-points", sourceId: "navigation-route")
          ..circleRadius = 8.0
          ..circleColor = Colors.red.value
          ..circleOpacity = 0.9,
      );
    } catch (e) {
      print('Error adding route layer: $e');
    }
  }

  Future<void> _setupPointAnnotations() async {
    _pointAnnotationManager = await mapboxMap?.annotations.createPointAnnotationManager();
    await _addRoutePoints();
  }

  Future<void> _addRoutePoints() async {
    if (_routeCoordinates.isEmpty) return;

    for (int i = 0; i < _routeCoordinates.length; i++) {
      final point = Point(coordinates: _routeCoordinates[i]);
      
      final annotation = PointAnnotationOptions(
        geometry: point,
        iconSize: i == 0 ? 1.5 : 1.0, // Start point is larger
        iconImage: i == 0 ? "marker-start" : "marker-point",
        textField: "${i + 1}",
        textSize: 12.0,
        textColor: Colors.white.value,
        textHaloColor: Colors.black.value,
        textHaloWidth: 1.0,
      );

      final createdAnnotation = await _pointAnnotationManager?.create(annotation);
      if (createdAnnotation != null) {
        _routePoints.add(createdAnnotation);
      }
    }

    // Set initial camera position to start point
    if (_routeCoordinates.isNotEmpty) {
      await mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: _routeCoordinates[0]),
          zoom: 16.5,
          bearing: 25,
          pitch: 60,
        ),
        MapAnimationOptions(duration: 2000),
      );
    }
  }

  void _toggleNavigation() {
    setState(() {
      _isNavigating = !_isNavigating;
    });

    if (_isNavigating) {
      _startNavigation();
    } else {
      _stopNavigation();
    }
  }

  void _startNavigation() {
    _navigationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPointIndex < _routeCoordinates.length - 1) {
        _nextPoint();
      } else {
        _stopNavigation();
        _showNavigationComplete();
      }
    });
  }

  void _stopNavigation() {
    _navigationTimer?.cancel();
  }

  void _nextPoint() {
    if (_currentPointIndex < _routeCoordinates.length - 1) {
      setState(() {
        _currentPointIndex++;
      });
      _updateCameraToCurrentPoint();
      _showTurnInstruction();
    }
  }

  void _previousPoint() {
    if (_currentPointIndex > 0) {
      setState(() {
        _currentPointIndex--;
      });
      _updateCameraToCurrentPoint();
      _showTurnInstruction();
    }
  }

  Future<void> _updateCameraToCurrentPoint() async {
    if (_currentPointIndex < _routeCoordinates.length) {
      final currentPoint = _routeCoordinates[_currentPointIndex];
      
      // Calculate bearing to next point if available
      double bearing = 0;
      if (_currentPointIndex < _routeCoordinates.length - 1) {
        final nextPoint = _routeCoordinates[_currentPointIndex + 1];
        bearing = _calculateBearing(currentPoint, nextPoint);
      }

      await mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: currentPoint),
          zoom: 17.5,
          bearing: bearing,
          pitch: 65,
        ),
        MapAnimationOptions(duration: 1000),
      );
    }
  }

  double _calculateBearing(Position from, Position to) {
    final lat1 = from.lat * (Math.pi / 180);
    final lat2 = to.lat * (Math.pi / 180);
    final dLon = (to.lng - from.lng) * (Math.pi / 180);

    final y = Math.sin(dLon) * Math.cos(lat2);
    final x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon);
    final bearing = Math.atan2(y, x) * (180 / Math.pi);

    return (bearing + 360) % 360;
  }

  void _showTurnInstruction() {
    if (_currentPointIndex < _routeCoordinates.length - 1) {
      final currentPoint = _routeCoordinates[_currentPointIndex];
      final nextPoint = _routeCoordinates[_currentPointIndex + 1];
      final bearing = _calculateBearing(currentPoint, nextPoint);
      
      String instruction = _getTurnInstruction(bearing);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Turn $instruction'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getTurnInstruction(double bearing) {
    if (bearing >= 315 || bearing < 45) return 'North';
    if (bearing >= 45 && bearing < 135) return 'East';
    if (bearing >= 135 && bearing < 225) return 'South';
    if (bearing >= 225 && bearing < 315) return 'West';
    return 'Forward';
  }

  void _showNavigationComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation Complete!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _add3DBuildingsLayer() async {
    await mapboxMap?.style.addLayer(
      FillExtrusionLayer(id: "3d-buildings", sourceId: "composite")
        ..sourceLayer = "building"
        ..filter = ['==', 'extrude', 'true']
        ..minZoom = 15
        ..fillExtrusionColorExpression = [
          'interpolate',
          ['linear'],
          ['get', 'height'],
          0,
          'rgb(200, 200, 200)',
          100,
          'rgb(150, 150, 150)',
          200,
          'rgb(100, 100, 100)',
        ]
        ..fillExtrusionOpacity = 0.8
        ..fillExtrusionHeightExpression = ['get', 'height']
        ..fillExtrusionBaseExpression = ['get', 'min_height']
        ..fillExtrusionAmbientOcclusionIntensity = 0.3
        ..fillExtrusionAmbientOcclusionRadius = 2.0,
    );
  }
} 