import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Visibility;
import 'package:mapbox_3d/map_navigation_controls.dart';

class TerrainView3D extends StatefulWidget {
  const TerrainView3D({super.key});

  @override
  State<TerrainView3D> createState() => _TerrainView3DState();
}

class _TerrainView3DState extends State<TerrainView3D> {
  MapboxMap? mapboxMap;
  List<Position> _routeCoordinates = [];
  int _currentRouteIndex = 0;
  Timer? _autoNavigationTimer;
  bool _isAutoNavigating = false;
  bool _showRouteInfo = true;

  // Center position based on test_trek.geojson coordinates
  final centerPosition = Position(-3.1472169, 52.6595692);

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  @override
  void dispose() {
    _autoNavigationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRouteData() async {
    try {
      final geoJsonString = await rootBundle.loadString('assets/test_trek.geojson');
      final decoded = json.decode(geoJsonString);
      final features = decoded['features'] as List;
      
      for (var feature in features) {
        final coordinates = feature['geometry']['coordinates'] as List;
        for (var coord in coordinates) {
          _routeCoordinates.add(Position(coord[0], coord[1]));
        }
      }
      
      if (_routeCoordinates.isNotEmpty) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading route data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Terrain View'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isAutoNavigating ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleAutoNavigation,
            tooltip: _isAutoNavigating ? 'Stop Navigation' : 'Start Navigation',
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showRouteInfoDialog,
            tooltip: 'Route Information',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main 3D Map
          MapWidget(
            key: const ValueKey<String>('streetViewMapWidget'),
            cameraOptions: CameraOptions(
              center: Point(coordinates: centerPosition),
              zoom: 18.0,
              bearing: 0,
              pitch: 65,
            ),
            styleUri: "mapbox://styles/mapbox/standard",
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
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

          // Route information panel
          //if (_showRouteInfo && _routeCoordinates.isNotEmpty)
            // Positioned(
            //   top: 100.0,
            //   left: 16.0,
            //   right: 16.0,
            //   child: Card(
            //     elevation: 4.0,
            //     child: Padding(
            //       padding: const EdgeInsets.all(16.0),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Row(
            //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //             children: [
            //               const Text(
            //                 'Route Information',
            //                 style: TextStyle(
            //                   fontSize: 16,
            //                   fontWeight: FontWeight.bold,
            //                 ),
            //               ),
            //               IconButton(
            //                 icon: const Icon(Icons.close),
            //                 onPressed: () => setState(() => _showRouteInfo = false),
            //                 iconSize: 20,
            //               ),
            //             ],
            //           ),
            //           const SizedBox(height: 8),
            //           Text('Total Points: ${_routeCoordinates.length}'),
            //           Text('Current Position: ${_currentRouteIndex + 1}'),
            //           Text('Auto Navigation: ${_isAutoNavigating ? "Active" : "Inactive"}'),
            //           const SizedBox(height: 8),
            //           Row(
            //             children: [
            //               Expanded(
            //                 child: ElevatedButton(
            //                   onPressed: _previousPoint,
            //                   child: const Text('Previous'),
            //                 ),
            //               ),
            //               const SizedBox(width: 8),
            //               Expanded(
            //                 child: ElevatedButton(
            //                   onPressed: _nextPoint,
            //                   child: const Text('Next'),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),

          // Street view controls
          // Positioned(
          //   bottom: 100.0,
          //   left: 16.0,
          //   right: 16.0,
          //   child: Card(
          //     elevation: 4.0,
          //     child: Padding(
          //       padding: const EdgeInsets.all(16.0),
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           const Text(
          //             'Street View Controls',
          //             style: TextStyle(
          //               fontSize: 16,
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //           const SizedBox(height: 12),
          //           Row(
          //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //             children: [
          //               _buildControlButton(
          //                 icon: Icons.visibility,
          //                 label: 'Street View',
          //                 onPressed: _toggleStreetView,
          //               ),
          //               _buildControlButton(
          //                 icon: Icons.view_in_ar,
          //                 label: '3D Buildings',
          //                 onPressed: _toggle3DBuildings,
          //               ),
          //               _buildControlButton(
          //                 icon: Icons.route,
          //                 label: 'Route',
          //                 onPressed: _toggleRouteVisibility,
          //               ),
          //             ],
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        
        onPressed: _showQuickActions,
        tooltip: 'Quick Actions',
        child: const Icon(Icons.navigation),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    // Add DEM source for 3D terrain
    await mapboxMap?.style.addSource(
      RasterDemSource(
        id: "mapbox-dem",
        url: "mapbox://mapbox.mapbox-terrain-dem-v1",
        tileSize: 512,
        maxzoom: 14,
      ),
    );
    // Enable 3D terrain with exaggeration (raw map for compatibility)
    await mapboxMap?.style.setStyleTerrain(json.encode({
      "source": "mapbox-dem",
      "exaggeration": 1.5,
    }));
    await _addRouteLayer();
    await _add3DBuildingsLayer();
    await _addStreetViewLayer();
    await _addRouteMarkers();
  }

  Future<void> _addRouteLayer() async {
    try {
      final geoJsonString = await rootBundle.loadString('assets/test_trek.geojson');
      
      // Add route source
      await mapboxMap?.style.addSource(
        GeoJsonSource(id: "street-route", data: geoJsonString),
      );

      // Add route line layer with enhanced styling
      await mapboxMap?.style.addLayer(
        LineLayer(id: "route-line", sourceId: "street-route")
          ..lineColor = Colors.blue.value
          ..lineWidth = 10.0
          ..lineOpacity = 0.9
          ..lineJoin = LineJoin.ROUND
          ..lineCap = LineCap.ROUND,
      );

      // Add route border for better visibility
      await mapboxMap?.style.addLayer(
        LineLayer(id: "route-border", sourceId: "street-route")
          ..lineColor = Colors.white.value
          ..lineWidth = 12.0
          ..lineOpacity = 0.7
          ..lineJoin = LineJoin.ROUND
          ..lineCap = LineCap.ROUND,
      );
    } catch (e) {
      print('Error adding route layer: $e');
    }
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
          'rgb(180, 180, 180)',
          50,
          'rgb(140, 140, 140)',
          100,
          'rgb(100, 100, 100)',
          200,
          'rgb(60, 60, 60)',
        ]
        ..fillExtrusionOpacity = 0.9
        ..fillExtrusionHeightExpression = ['get', 'height']
        ..fillExtrusionBaseExpression = ['get', 'min_height']
        ..fillExtrusionAmbientOcclusionIntensity = 0.4
        ..fillExtrusionAmbientOcclusionRadius = 3.0,
    );
  }

  Future<void> _addStreetViewLayer() async {
    // Add street view elements like street names, traffic signs, etc.
    await mapboxMap?.style.addLayer(
      SymbolLayer(id: "street-labels", sourceId: "composite")
        ..sourceLayer = "place_label"
        ..textFieldExpression = ['get', 'name']
        ..textSize = 12.0
        ..textColor = Colors.white.value
        ..textHaloColor = Colors.black.value
        ..textHaloWidth = 1.0
        ..textAnchor = TextAnchor.CENTER
        ..textOffset = [0, 0],
    );
  }

  Future<void> _addRouteMarkers() async {
    if (_routeCoordinates.isEmpty) return;

    // Add start marker
    final startPoint = Point(coordinates: _routeCoordinates.first);
    await mapboxMap?.style.addSource(
      GeoJsonSource(id: "start-marker", data: json.encode(startPoint)),
    );
    await mapboxMap?.style.addLayer(
      CircleLayer(id: "start-point", sourceId: "start-marker")
        ..circleRadius = 8.0
        ..circleColor = Colors.green.value
        ..circleOpacity = 0.9,
    );

    // Add end marker
    final endPoint = Point(coordinates: _routeCoordinates.last);
    await mapboxMap?.style.addSource(
      GeoJsonSource(id: "end-marker", data: json.encode(endPoint)),
    );
    await mapboxMap?.style.addLayer(
      CircleLayer(id: "end-point", sourceId: "end-marker")
        ..circleRadius = 8.0
        ..circleColor = Colors.red.value
        ..circleOpacity = 0.9,
    );
  }

  void _toggleAutoNavigation() {
    setState(() {
      _isAutoNavigating = !_isAutoNavigating;
    });

    if (_isAutoNavigating) {
      _startAutoNavigation();
    } else {
      _stopAutoNavigation();
    }
  }

  void _startAutoNavigation() {
    _autoNavigationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentRouteIndex < _routeCoordinates.length - 1) {
        _nextPoint();
      } else {
        _stopAutoNavigation();
        _showNavigationComplete();
      }
    });
  }

  void _stopAutoNavigation() {
    _autoNavigationTimer?.cancel();
  }

  void _nextPoint() {
    if (_currentRouteIndex < _routeCoordinates.length - 1) {
      setState(() {
        _currentRouteIndex++;
      });
      _updateCameraToCurrentPoint();
    }
  }

  void _previousPoint() {
    if (_currentRouteIndex > 0) {
      setState(() {
        _currentRouteIndex--;
      });
      _updateCameraToCurrentPoint();
    }
  }

  Future<void> _updateCameraToCurrentPoint() async {
    if (_currentRouteIndex < _routeCoordinates.length) {
      final currentPoint = _routeCoordinates[_currentRouteIndex];
      
      // Calculate bearing to next point if available
      double bearing = 0;
      if (_currentRouteIndex < _routeCoordinates.length - 1) {
        final nextPoint = _routeCoordinates[_currentRouteIndex + 1];
        bearing = _calculateBearing(currentPoint, nextPoint);
      }

      await mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: currentPoint),
          zoom: 19.0,
          bearing: bearing,
          pitch: 70,
        ),
        MapAnimationOptions(duration: 1000),
      );
    }
  }

  double _calculateBearing(Position from, Position to) {
    final lat1 = from.lat * (math.pi / 180);
    final lat2 = to.lat * (math.pi / 180);
    final dLon = (to.lng - from.lng) * (math.pi / 180);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x) * (180 / math.pi);

    return (bearing + 360) % 360;
  }

  void _showNavigationComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Street View Navigation Complete!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showRouteInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Route Points: ${_routeCoordinates.length}'),
            const SizedBox(height: 8),
            const Text('Route Source: test_trek.geojson'),
            const SizedBox(height: 8),
            const Text('Features:'),
            const Text('• 3D Street View Navigation'),
            const Text('• Auto-navigation along route'),
            const Text('• Enhanced 3D buildings'),
            const Text('• Street labels and markers'),
            const Text('• Interactive navigation controls'),
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

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Street View Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionButton(
                  icon: Icons.home,
                  label: 'Start Point',
                  onPressed: () {
                    Navigator.pop(context);
                    _goToStartPoint();
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.flag,
                  label: 'End Point',
                  onPressed: () {
                    Navigator.pop(context);
                    _goToEndPoint();
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.view_in_ar,
                  label: 'Max 3D',
                  onPressed: () {
                    Navigator.pop(context);
                    _setMaxPitch();
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.visibility,
                  label: 'Street Level',
                  onPressed: () {
                    Navigator.pop(context);
                    _setStreetLevel();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  Future<void> _goToStartPoint() async {
    if (_routeCoordinates.isNotEmpty) {
      setState(() => _currentRouteIndex = 0);
      await _updateCameraToCurrentPoint();
    }
  }

  Future<void> _goToEndPoint() async {
    if (_routeCoordinates.isNotEmpty) {
      setState(() => _currentRouteIndex = _routeCoordinates.length - 1);
      await _updateCameraToCurrentPoint();
    }
  }

  Future<void> _setMaxPitch() async {
    if (mapboxMap != null) {
      await mapboxMap!.flyTo(
        CameraOptions(pitch: 70.0),
        MapAnimationOptions(duration: 500),
      );
    }
  }

  Future<void> _setStreetLevel() async {
    if (mapboxMap != null) {
      await mapboxMap!.flyTo(
        CameraOptions(pitch: 0.0),
        MapAnimationOptions(duration: 500),
      );
    }
  }

  // void _toggleStreetView() {
  //   // Toggle street view mode
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Street View Mode Toggled')),
  //   );
  // }

  // void _toggle3DBuildings() {
  //   // Toggle 3D buildings visibility
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('3D Buildings Toggled')),
  //   );
  // }

  // void _toggleRouteVisibility() {
  //   // Toggle route visibility
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Route Visibility Toggled')),
  //   );
  // }
} 