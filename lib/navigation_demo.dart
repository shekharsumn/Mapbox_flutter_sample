import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mapbox_3d/map_navigation_controls.dart';
import 'package:mapbox_3d/permission_status_widget.dart';

class NavigationDemo extends StatefulWidget {
  const NavigationDemo({super.key});

  @override
  State<NavigationDemo> createState() => _NavigationDemoState();
}

class _NavigationDemoState extends State<NavigationDemo> {
  MapboxMap? mapboxMap;
  String _currentStyle = MapboxStyles.MAPBOX_STREETS;
  bool _showCompass = true;
  bool _showNavigationControls = true;
  bool _showPermissionStatus = false;

  final List<String> _mapStyles = [
    MapboxStyles.MAPBOX_STREETS,
    MapboxStyles.SATELLITE_STREETS,
    MapboxStyles.OUTDOORS,
    MapboxStyles.LIGHT,
    MapboxStyles.DARK,
  ];

  final List<String> _styleNames = [
    'Streets',
    'Satellite',
    'Outdoors',
    'Light',
    'Dark',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Controls Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main map
          MapWidget(
            key: const ValueKey<String>('demoMapWidget'),
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(-122.3947, 37.7080)),
              zoom: 16.5,
              bearing: 25,
              pitch: 65,
            ),
            styleUri: _currentStyle,
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
          ),

          // Navigation controls
          if (_showNavigationControls && mapboxMap != null)
            MapNavigationControls(
              mapboxMap: mapboxMap,
              initiallyExpanded: false,
              backgroundColor: Colors.white.withOpacity(0.9),
              iconColor: Colors.black87,
            ),

          // Compass
          if (_showCompass && mapboxMap != null)
            MapCompass(
              mapboxMap: mapboxMap,
              backgroundColor: Colors.white.withOpacity(0.9),
              iconColor: Colors.black87,
            ),

          // Permission status widget
          if (_showPermissionStatus)
            Positioned(
              top: 100.0,
              left: 16.0,
              right: 16.0,
              child: PermissionStatusWidget(),
            ),

          // Style selector
          Positioned(
            bottom: 100.0,
            left: 16.0,
            right: 16.0,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Map Style',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _styleNames.length,
                        itemBuilder: (context, index) {
                          final isSelected = _mapStyles[index] == _currentStyle;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(_styleNames[index]),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _currentStyle = _mapStyles[index];
                                  });
                                  _updateMapStyle();
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
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

  Future<void> _updateMapStyle() async {
    if (mapboxMap != null) {
      await mapboxMap!.loadStyleURI(_currentStyle);
      // Re-add 3D buildings after style change with a small delay
      Future.delayed(const Duration(milliseconds: 500), () async {
        await _add3DBuildingsLayer();
      });
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Show Navigation Controls'),
              value: _showNavigationControls,
              onChanged: (value) {
                setState(() {
                  _showNavigationControls = value;
                });
                Navigator.pop(context);
              },
            ),
            SwitchListTile(
              title: const Text('Show Compass'),
              value: _showCompass,
              onChanged: (value) {
                setState(() {
                  _showCompass = value;
                });
                Navigator.pop(context);
              },
            ),
            SwitchListTile(
              title: const Text('Show Permission Status'),
              value: _showPermissionStatus,
              onChanged: (value) {
                setState(() {
                  _showPermissionStatus = value;
                });
                Navigator.pop(context);
              },
            ),
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
}
