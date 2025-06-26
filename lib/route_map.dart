import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'interface/example.dart';

class RouteMapExample extends StatefulWidget implements Example {
  @override
  final Widget leading = const Icon(Icons.view_in_ar);
  @override
  final String title = 'Display a 3D model in a model layer';
  @override
  final String subtitle = 'Showcase the usage of a 3D model layer.';

  const RouteMapExample({super.key});

  @override
  State<StatefulWidget> createState() => _RouteMapExampleState();
}

class _RouteMapExampleState extends State<RouteMapExample> {
  MapboxMap? mapboxMap;

  final centerPosition = Position(-122.385374, 37.61501);
  final carModelPosition = Position(-122.385374,37.61501);

  @override
  Widget build(BuildContext context) {
    return MapWidget(
        cameraOptions: CameraOptions(
            center: Point(coordinates: centerPosition),
            zoom: 16.5,
            bearing: 25,
            pitch: 60),
        key: const ValueKey<String>('mapWidget'),
        styleUri: MapboxStyles.SATELLITE_STREETS,
        onMapCreated: _onMapCreated,
        onStyleLoadedListener: _onStyleLoaded);
  }

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
  }

  _onStyleLoaded(StyleLoadedEventData data) async {
    addModelLayer();
    final data = await rootBundle.loadString('assets/sf_airport_route.geojson');
    await mapboxMap?.style.addSource(GeoJsonSource(id: "line", data: data));
    await _addRouteLine();
    await _add3DBuildingsLayer();
  }

  addModelLayer() async {
    if (mapboxMap == null) {
      throw Exception("MapboxMap is not ready yet");
    }

    // 1.) Add the two 3D models to the style
    final carModelId = "model-car-id";
    final carModelUri = "asset://assets/sportcar.glb";
    await mapboxMap?.style.addStyleModel(carModelId, carModelUri);

    // 2.) Add the two geojson sources to provide coordinates for the models
    var carModelLocation = Point(coordinates: carModelPosition);
    await mapboxMap?.style.addSource(
        GeoJsonSource(id: "carSourceId", data: json.encode(carModelLocation)));

    // 3.) Add the two model layers to the map, specifying the model id and geojson source id
    var carModelLayer = ModelLayer(id: "model-car-id", sourceId: "carSourceId");
    carModelLayer.modelId =
        "asset://assets/sportcar.glb"; // Local assets need to be referenced directly
    carModelLayer.modelScale = [3.5, 3.5, 3.5];
    carModelLayer.modelRotation = [0, 0, 45];
    carModelLayer.modelType = ModelType.COMMON_3D;
    mapboxMap?.style.addLayer(carModelLayer);
  }

  _addRouteLine() async {
    await mapboxMap?.style.addLayer(LineLayer(
      id: "line-layer",
      sourceId: "line",
      // ignore: deprecated_member_use
      lineBorderColor: Colors.black.value,
      // Defines a line-width, line-border-width and line-color at different zoom extents
      // by interpolating exponentially between stops.
      // Doc: https://docs.mapbox.com/style-spec/reference/expressions/
      lineWidthExpression: [
        'interpolate',
        ['exponential', 1.5],
        ['zoom'],
        4.0,
        6.0,
        10.0,
        7.0,
        13.0,
        9.0,
        16.0,
        3.0,
        19.0,
        7.0,
        22.0,
        21.0,
      ],
      lineBorderWidthExpression: [
        'interpolate',
        ['exponential', 1.5],
        ['zoom'],
        9.0,
        1.0,
        16.0,
        3.0,
      ],
      lineColorExpression: [
        'interpolate',
        ['linear'],
        ['zoom'],
        8.0,
        'rgb(51, 102, 255)',
        11.0,
        [
          'coalesce',
          ['get', 'route-color'],
          'rgb(51, 102, 255)'
        ],
      ],
    ));
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
