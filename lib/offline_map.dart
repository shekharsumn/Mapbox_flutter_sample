import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Visibility;
import 'package:http/http.dart' as http;
import 'package:mapbox_3d/map_navigation_controls.dart';

class CombinedOffline3DMap extends StatefulWidget {
  const CombinedOffline3DMap({super.key});

  @override
  State<CombinedOffline3DMap> createState() => _CombinedOffline3DMapState();
}

class _CombinedOffline3DMapState extends State<CombinedOffline3DMap> {
  MapboxMap? mapboxMap;
  bool isDownloadVisible = true;
  bool _stylePackComplete = false;
  bool _tileRegionComplete = false;
  final _tileRegionId = "san-francisco-tile-region";
  late Future<void> _downloadFuture;

  final centerPosition = Position(-122.3947, 37.7080);
  final carModelPosition = Position(-122.385374, 37.61501);

  final _tileRegionProgress = StreamController<double>.broadcast();
  final _stylePackProgress = StreamController<double>.broadcast();

  TileStore? _tileStore;
  OfflineManager? _offlineManager;

  static const geoJsonUrl =
      'https://raw.githubusercontent.com/shekharsumn/Mapbox_flutter_sample/main/assets/sf_airport_route.geojson';

  @override
  void initState() {
    super.initState();
    _downloadFuture = _downloadMapAssets();
  }

  @override
  void dispose() {
    _tileRegionProgress.close();
    _stylePackProgress.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offline 3D Route Map"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showNavigationSettings,
            tooltip: 'Navigation Settings',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: FutureBuilder(
                  future: _downloadFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return MapWidget(
                        key: const ValueKey<String>('mapWidget'),
                        cameraOptions: CameraOptions(
                          center: Point(coordinates: centerPosition),
                          zoom: 16.5,
                          bearing: 25,
                          pitch: 60,
                        ),
                        styleUri: MapboxStyles.SATELLITE_STREETS,
                        onMapCreated: _onMapCreated,
                        onStyleLoadedListener: _onStyleLoaded,
                      );
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
              Visibility(
                visible: isDownloadVisible,
                child: SizedBox(
                  height: 140,
                  child: Card(
                    margin: const EdgeInsets.all(2),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Style Pack:"),
                                StreamBuilder<double>(
                                  stream: _stylePackProgress.stream,
                                  builder: (context, snapshot) {
                                    return LinearProgressIndicator(
                                      value: snapshot.data ?? 0,
                                      semanticsLabel: "Style Pack",
                                    );
                                  },
                                ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Tile Region:"),
                                StreamBuilder<double>(
                                  stream: _tileRegionProgress.stream,
                                  builder: (context, snapshot) {
                                    return LinearProgressIndicator(
                                      value: snapshot.data ?? 0,
                                      semanticsLabel: "Tile Region",
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActions,
        tooltip: 'Quick Actions',
        child: const Icon(Icons.navigation),
      ),
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    await _addModelLayer();
    await _addRouteGeoJson();
    await _addStartEndMarkersFromGeoJson();
    await _add3DBuildingsLayer();
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

  Future<void> _downloadMapAssets() async {
    await _initOfflineMap();

    // Download style
    final stylePackOptions = StylePackLoadOptions(
      glyphsRasterizationMode:
          GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY,
      metadata: {'purpose': 'demo'},
      acceptExpired: true,
    );
    _offlineManager
        ?.loadStylePack(MapboxStyles.SATELLITE_STREETS, stylePackOptions, (
          progress,
        ) {
          final pct =
              progress.completedResourceCount / progress.requiredResourceCount;
          _stylePackProgress.add(pct);
        })
        .then((_) {
          _stylePackProgress.add(1);
          _stylePackComplete = true;
          _checkDownloadComplete();
        });

    // Download tile region
    final geometry = Point(coordinates: centerPosition).toJson();
    final regionOptions = TileRegionLoadOptions(
      geometry: geometry,
      descriptorsOptions: [
        TilesetDescriptorOptions(
          styleURI: MapboxStyles.SATELLITE_STREETS,
          minZoom: 0,
          maxZoom: 17,
        ),
      ],
      acceptExpired: true,
      networkRestriction: NetworkRestriction.NONE,
    );

    _tileStore
        ?.loadTileRegion(_tileRegionId, regionOptions, (progress) {
          final pct =
              progress.completedResourceCount / progress.requiredResourceCount;
          _tileRegionProgress.add(pct);
        })
        .then((_) {
          _tileRegionProgress.add(1);
          _tileRegionComplete = true;
          _checkDownloadComplete();
        });

    // Wait until both streams complete
    await Future.wait([
      _stylePackProgress.stream.firstWhere((v) => v >= 1),
      _tileRegionProgress.stream.firstWhere((v) => v >= 1),
    ]);
  }

  void _checkDownloadComplete() {
    if (_stylePackComplete && _tileRegionComplete) {
      if (mounted) {
        setState(() {
          isDownloadVisible = false;
        });
      }
    }
  }

  Future<void> _initOfflineMap() async {
    _offlineManager = await OfflineManager.create();
    _tileStore = await TileStore.createDefault();
    _tileStore?.setDiskQuota(null);
  }

  Future<void> _addModelLayer() async {
    final carModelId = "model-car";
    final carModelUri = "asset://assets/sportcar.glb";

    await mapboxMap?.style.addStyleModel(carModelId, carModelUri);

    await mapboxMap?.style.addSource(
      GeoJsonSource(
        id: "car-source",
        data: json.encode(Point(coordinates: carModelPosition)),
      ),
    );

    final carModelLayer = ModelLayer(id: "model-layer", sourceId: "car-source")
      ..modelId = carModelUri
      ..modelScale = [3.5, 3.5, 3.5]
      ..modelRotation = [0, 0, 45]
      ..modelType = ModelType.COMMON_3D;

    await mapboxMap?.style.addLayer(carModelLayer);
  }

  Future<String> _loadGeoJsonFromNetwork() async {
    final response = await http.get(Uri.parse(geoJsonUrl));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load GeoJSON');
    }
  }

  Future<void> _addRouteGeoJson() async {
    final geoJsonString = await _loadGeoJsonFromNetwork();
    // Add GeoJSON route line source
    await mapboxMap?.style.addSource(
      GeoJsonSource(id: "route-source", data: geoJsonString),
    );
    // Add the route line layer
    await mapboxMap?.style.addLayer(
      LineLayer(id: "route-line", sourceId: "route-source")
        ..lineColor = Colors.blue.value
        ..lineWidth = 8.0
        ..lineOpacity = 0.9
        ..lineJoin = LineJoin.ROUND
        ..lineCap = LineCap.ROUND,
    );
  }

  Future<void> _addStartEndMarkersFromGeoJson() async {
    final geoJsonString = await _loadGeoJsonFromNetwork();
    final decoded = json.decode(geoJsonString);
    final coordinates =
        decoded['features'][0]['geometry']['coordinates'] as List;
    final startCoord = coordinates.first;
    final endCoord = coordinates.last;
    final startPosition = Point(
      coordinates: Position(startCoord[0], startCoord[1]),
    );
    final endPosition = Point(coordinates: Position(endCoord[0], endCoord[1]));

    // Load the custom marker image
    final ByteData startBytes = await rootBundle.load(
      'assets/marker-green.png',
    );
    final ByteData endBytes = await rootBundle.load('assets/marker-red.png');
    final Uint8List startImageData = startBytes.buffer.asUint8List();
    final Uint8List endImageData = endBytes.buffer.asUint8List();

    // Create PointAnnotationManager
    final pointAnnotationManager = await mapboxMap?.annotations
        .createPointAnnotationManager();

    // Start Marker
    final startAnnotation = PointAnnotationOptions(
      geometry: startPosition,
      image: startImageData,
      iconSize: 0.2,
    );

    // End Marker
    final endAnnotation = PointAnnotationOptions(
      geometry: endPosition,
      image: endImageData,
      iconSize: 0.2,
    );

    // Add both annotations to the map
    await pointAnnotationManager?.create(startAnnotation);
    await pointAnnotationManager?.create(endAnnotation);
  }

  void _showNavigationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('3D Navigation Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Navigation Controls',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Tap the arrow button to expand/collapse controls\n'
              '• Use + and - buttons to zoom in/out\n'
              '• Use rotation buttons to change bearing\n'
              '• Use pitch slider to change map tilt\n'
              '• Tap compass to reset bearing to north',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              '3D Features',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• 3D buildings with height-based coloring\n'
              '• Enhanced route visualization\n'
              '• 3D car model with realistic positioning\n'
              '• Offline map capabilities\n'
              '• Satellite street view for better 3D effect',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera Settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Zoom: 16.5 (optimal 3D viewing)\n'
              '• Bearing: 25° (dynamic angle)\n'
              '• Pitch: 60° (dramatic 3D tilt)',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetToDefaultView();
            },
            child: const Text('Reset View'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefaultView() async {
    await mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: centerPosition),
        zoom: 16.5,
        bearing: 25,
        pitch: 60,
      ),
      MapAnimationOptions(duration: 1000),
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
              'Quick Navigation Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionButton(
                  icon: Icons.home,
                  label: 'Reset View',
                  onPressed: () {
                    Navigator.pop(context);
                    _resetToDefaultView();
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.zoom_in,
                  label: 'Zoom In',
                  onPressed: () {
                    Navigator.pop(context);
                    _zoomIn();
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.zoom_out,
                  label: 'Zoom Out',
                  onPressed: () {
                    Navigator.pop(context);
                    _zoomOut();
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.rotate_left,
                  label: 'Rotate Left',
                  onPressed: () {
                    Navigator.pop(context);
                    _rotateLeft();
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.rotate_right,
                  label: 'Rotate Right',
                  onPressed: () {
                    Navigator.pop(context);
                    _rotateRight();
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

  Future<void> _zoomIn() async {
    if (mapboxMap != null) {
      final camera = await mapboxMap!.getCameraState();
      final newZoom = (camera.zoom + 1).clamp(0.0, 22.0);
      await mapboxMap!.flyTo(
        CameraOptions(zoom: newZoom),
        MapAnimationOptions(duration: 500),
      );
    }
  }

  Future<void> _zoomOut() async {
    if (mapboxMap != null) {
      final camera = await mapboxMap!.getCameraState();
      final newZoom = (camera.zoom - 1).clamp(0.0, 22.0);
      await mapboxMap!.flyTo(
        CameraOptions(zoom: newZoom),
        MapAnimationOptions(duration: 500),
      );
    }
  }

  Future<void> _rotateLeft() async {
    if (mapboxMap != null) {
      final camera = await mapboxMap!.getCameraState();
      final newBearing = (camera.bearing - 45) % 360;
      await mapboxMap!.flyTo(
        CameraOptions(bearing: newBearing),
        MapAnimationOptions(duration: 500),
      );
    }
  }

  Future<void> _rotateRight() async {
    if (mapboxMap != null) {
      final camera = await mapboxMap!.getCameraState();
      final newBearing = (camera.bearing + 45) % 360;
      await mapboxMap!.flyTo(
        CameraOptions(bearing: newBearing),
        MapAnimationOptions(duration: 500),
      );
    }
  }

  Future<void> _setMaxPitch() async {
    if (mapboxMap != null) {
      await mapboxMap!.flyTo(
        CameraOptions(pitch: 60.0),
        MapAnimationOptions(duration: 500),
      );
    }
  }
}
