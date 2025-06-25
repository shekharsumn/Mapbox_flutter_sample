import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class CombinedOffline3DMap extends StatefulWidget {
  const CombinedOffline3DMap({super.key});

  @override
  State<CombinedOffline3DMap> createState() => _CombinedOffline3DMapState();
}

class _CombinedOffline3DMapState extends State<CombinedOffline3DMap> {
  MapboxMap? mapboxMap;
  final _tileRegionId = "san-francisco-tile-region";

  final centerPosition = Position(-122.3947, 37.7080);
  final carModelPosition = Position(-122.385374, 37.61501);

  final _tileRegionProgress = StreamController<double>.broadcast();
  final _stylePackProgress = StreamController<double>.broadcast();

  TileStore? _tileStore;
  OfflineManager? _offlineManager;

  @override
  void dispose() {
    _tileRegionProgress.close();
    _stylePackProgress.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Offline 3D Route Map")),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: _downloadMapAssets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return MapWidget(
                    key: const ValueKey<String>('mapWidget'),
                    cameraOptions: CameraOptions(
                      center: Point(coordinates: centerPosition),
                      zoom: 12,
                      bearing: 0,
                      pitch: 0,
                    ),
                    styleUri: MapboxStyles.SATELLITE_STREETS,
                    onMapCreated: _onMapCreated,
                    onStyleLoadedListener: _onStyleLoaded,
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          SizedBox(
            height: 80,
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                children: [
                  StreamBuilder<double>(
                    stream: _stylePackProgress.stream,
                    builder: (context, snapshot) {
                      return LinearProgressIndicator(
                        value: snapshot.data ?? 0,
                        semanticsLabel: "Style Pack",
                      );
                    },
                  ),
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
            ),
          ),
        ],
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
        .then((_) => _stylePackProgress.add(1));

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
        .then((_) => _tileRegionProgress.add(1));

    // Wait until both streams complete
    await Future.wait([
      _stylePackProgress.stream.firstWhere((v) => v >= 1),
      _tileRegionProgress.stream.firstWhere((v) => v >= 1),
    ]);
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
      ..modelScale = [4, 4, 4]
      ..modelRotation = [0, 0, 60]
      ..modelType = ModelType.COMMON_3D;

    await mapboxMap?.style.addLayer(carModelLayer);
  }

  Future<void> _addRouteGeoJson() async {
    final geoJsonString = await rootBundle.loadString(
      'assets/sf_airport_route.geojson',
    );

    // Add GeoJSON route line source
    await mapboxMap?.style.addSource(
      GeoJsonSource(id: "route-source", data: geoJsonString),
    );

    // Add the route line layer
    await mapboxMap?.style.addLayer(
      LineLayer(id: "route-line", sourceId: "route-source")
        ..lineColor = Colors.blue.value
        ..lineWidth = 6.0,
    );
  }

  Future<void> _addStartEndMarkersFromGeoJson() async {
    final geoJsonString = await rootBundle.loadString(
      'assets/sf_airport_route.geojson',
    );
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
}
