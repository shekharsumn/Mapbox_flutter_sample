// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapNavigationControls extends StatefulWidget {
  final MapboxMap? mapboxMap;
  final bool initiallyExpanded;
  final Color? backgroundColor;
  final Color? iconColor;
  final double buttonSize;
  final EdgeInsets padding;

  const MapNavigationControls({
    super.key,
    required this.mapboxMap,
    this.initiallyExpanded = false,
    this.backgroundColor,
    this.iconColor,
    this.buttonSize = 48.0,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  State<MapNavigationControls> createState() => _MapNavigationControlsState();
}

class _MapNavigationControlsState extends State<MapNavigationControls>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  // Current values
  double _currentZoom = 12.0;
  double _currentBearing = 0.0;
  double _currentPitch = 0.0;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _zoomIn() async {
    if (widget.mapboxMap != null) {
      final camera = await widget.mapboxMap!.getCameraState();
      final newZoom = (camera.zoom + 1).clamp(0.0, 22.0);
      await widget.mapboxMap!.flyTo(
        CameraOptions(zoom: newZoom),
        MapAnimationOptions(duration: 500),
      );
      setState(() {
        _currentZoom = newZoom;
      });
    }
  }

  Future<void> _zoomOut() async {
    if (widget.mapboxMap != null) {
      final camera = await widget.mapboxMap!.getCameraState();
      final newZoom = (camera.zoom - 1).clamp(0.0, 22.0);
      await widget.mapboxMap!.flyTo(
        CameraOptions(zoom: newZoom),
        MapAnimationOptions(duration: 500),
      );
      setState(() {
        _currentZoom = newZoom;
      });
    }
  }

  Future<void> _resetBearing() async {
    if (widget.mapboxMap != null) {
      await widget.mapboxMap!.flyTo(
        CameraOptions(bearing: 0.0),
        MapAnimationOptions(duration: 500),
      );
      setState(() {
        _currentBearing = 0.0;
      });
    }
  }

  Future<void> _rotateLeft() async {
    if (widget.mapboxMap != null) {
      final camera = await widget.mapboxMap!.getCameraState();
      final newBearing = (camera.bearing - 45) % 360;
      await widget.mapboxMap!.flyTo(
        CameraOptions(bearing: newBearing),
        MapAnimationOptions(duration: 500),
      );
      setState(() {
        _currentBearing = newBearing;
      });
    }
  }

  Future<void> _rotateRight() async {
    if (widget.mapboxMap != null) {
      final camera = await widget.mapboxMap!.getCameraState();
      final newBearing = (camera.bearing + 45) % 360;
      await widget.mapboxMap!.flyTo(
        CameraOptions(bearing: newBearing),
        MapAnimationOptions(duration: 500),
      );
      setState(() {
        _currentBearing = newBearing;
      });
    }
  }

  Future<void> _setPitch(double pitch) async {
    if (widget.mapboxMap != null) {
      final newPitch = pitch.clamp(0.0, 60.0);
      await widget.mapboxMap!.flyTo(
        CameraOptions(pitch: newPitch),
        MapAnimationOptions(duration: 500),
      );
      setState(() {
        _currentPitch = newPitch;
      });
    }
  }

  Future<void> _resetPitch() async {
    await _setPitch(0.0);
  }

  Future<void> _setMaxPitch() async {
    await _setPitch(60.0);
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? iconColor,
    double? size,
  }) {
    return Container(
      width: size ?? widget.buttonSize,
      height: size ?? widget.buttonSize,
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        elevation: 2.0,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: onPressed,
          child: Icon(
            icon,
            color: iconColor ?? widget.iconColor ?? Colors.black87,
            size: (size ?? widget.buttonSize) * 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPitchSlider() {
    return Container(
      width: widget.buttonSize,
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: RotatedBox(
        quarterTurns: 3,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
          ),
          child: Slider(
            value: _currentPitch,
            min: 0.0,
            max: 60.0,
            divisions: 12,
            onChanged: (value) {
              setState(() {
                _currentPitch = value;
              });
            },
            onChangeEnd: (value) {
              _setPitch(value);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100.0,
      right: 16.0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main toggle button
                _buildControlButton(
                  icon: _isExpanded ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_left,
                  onPressed: _toggleExpanded,
                  tooltip: _isExpanded ? 'Collapse' : 'Expand',
                ),
                
                // Expanded controls
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8.0),
                      
                      // Zoom controls
                      _buildControlButton(
                        icon: Icons.add,
                        onPressed: _zoomIn,
                        tooltip: 'Zoom In',
                      ),
                      _buildControlButton(
                        icon: Icons.remove,
                        onPressed: _zoomOut,
                        tooltip: 'Zoom Out',
                      ),
                      
                      const SizedBox(height: 8.0),
                      
                      // Rotation controls
                      _buildControlButton(
                        icon: Icons.rotate_left,
                        onPressed: _rotateLeft,
                        tooltip: 'Rotate Left',
                      ),
                      _buildControlButton(
                        icon: Icons.navigation,
                        onPressed: _resetBearing,
                        tooltip: 'Reset Bearing',
                      ),
                      _buildControlButton(
                        icon: Icons.rotate_right,
                        onPressed: _rotateRight,
                        tooltip: 'Rotate Right',
                      ),
                      
                      const SizedBox(height: 8.0),
                      
                      // Pitch controls
                      _buildControlButton(
                        icon: Icons.view_agenda,
                        onPressed: _resetPitch,
                        tooltip: 'Reset Pitch',
                      ),
                      _buildPitchSlider(),
                      _buildControlButton(
                        icon: Icons.view_agenda_outlined,
                        onPressed: _setMaxPitch,
                        tooltip: 'Max Pitch',
                      ),
                      
                      const SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Additional utility widget for compass
class MapCompass extends StatefulWidget {
  final MapboxMap? mapboxMap;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const MapCompass({
    super.key,
    required this.mapboxMap,
    this.size = 40.0,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<MapCompass> createState() => _MapCompassState();
}

class _MapCompassState extends State<MapCompass> {
  double _bearing = 0.0;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    // Listen to camera changes by periodically checking camera state
    _updateBearing();
  }

  Future<void> _updateBearing() async {
    if (widget.mapboxMap != null) {
      try {
        final camera = await widget.mapboxMap!.getCameraState();
        if (mounted) {
          setState(() {
            _bearing = camera.bearing;
            _isVisible = camera.bearing != 0.0;
          });
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _resetBearing() async {
    if (widget.mapboxMap != null) {
      await widget.mapboxMap!.flyTo(
        CameraOptions(bearing: 0.0),
        MapAnimationOptions(duration: 500),
      );
      await _updateBearing();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Positioned(
      top: 100.0,
      left: 16.0,
      child: GestureDetector(
        onTap: _resetBearing,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -_bearing * 3.14159 / 180,
            child: Icon(
              Icons.navigation,
              color: widget.iconColor ?? Colors.black87,
              size: widget.size * 0.6,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
} 