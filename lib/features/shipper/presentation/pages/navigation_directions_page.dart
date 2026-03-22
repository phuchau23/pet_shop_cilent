import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';

// Spacing constants
class _Sp {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
}

// Border radius constants
class _Rad {
  static const sm = 8.0;
  static const md = 12.0;
}

/// Model cho một bước chỉ dẫn đường đi
class NavigationStep {
  final int distance; // mét
  final int duration; // giây
  final String instruction;
  final String maneuver;
  final LatLng location;

  NavigationStep({
    required this.distance,
    required this.duration,
    required this.instruction,
    required this.maneuver,
    required this.location,
  });

  String get distanceText {
    if (distance < 1000) return '$distance m';
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  String get durationText {
    if (duration < 60) return '$duration giây';
    return '${(duration / 60).round()} phút';
  }
}

class NavigationDirectionsPage extends StatefulWidget {
  final LatLng start;
  final LatLng end;
  final String? startName;
  final String? endName;

  const NavigationDirectionsPage({
    super.key,
    required this.start,
    required this.end,
    this.startName,
    this.endName,
  });

  @override
  State<NavigationDirectionsPage> createState() =>
      _NavigationDirectionsPageState();
}

class _NavigationDirectionsPageState extends State<NavigationDirectionsPage> {
  List<NavigationStep> _steps = [];
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  String? _error;
  int _totalDistance = 0;
  int _totalDuration = 0;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchDirections();
  }

  Future<void> _fetchDirections() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // OSRM API với steps=true để lấy turn-by-turn instructions
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${widget.start.longitude},${widget.start.latitude};${widget.end.longitude},${widget.end.latitude}'
          '?overview=full&geometries=geojson&steps=true&alternatives=false';

      print('🗺️ Fetching directions with steps...');

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['code'] == 'Ok' && data['routes'] != null) {
          final routes = data['routes'] as List<dynamic>;
          if (routes.isNotEmpty) {
            final route = routes[0] as Map<String, dynamic>;

            // Parse route geometry
            final geometry = route['geometry'] as Map<String, dynamic>;
            final coords = geometry['coordinates'] as List<dynamic>;
            final points = coords
                .map((c) {
                  if (c is List && c.length >= 2) {
                    return LatLng(
                      (c[1] as num).toDouble(),
                      (c[0] as num).toDouble(),
                    );
                  }
                  return null;
                })
                .whereType<LatLng>()
                .toList();

            // Parse steps (turn-by-turn instructions)
            final legs = route['legs'] as List<dynamic>?;
            final steps = <NavigationStep>[];

            if (legs != null && legs.isNotEmpty) {
              final leg = legs[0] as Map<String, dynamic>;
              final legSteps = leg['steps'] as List<dynamic>?;

              if (legSteps != null) {
                for (var stepData in legSteps) {
                  final step = stepData as Map<String, dynamic>;
                  final maneuver = step['maneuver'] as Map<String, dynamic>?;
                  final location = maneuver?['location'] as List<dynamic>?;

                  if (location != null && location.length >= 2) {
                    final stepLocation = LatLng(
                      (location[1] as num).toDouble(),
                      (location[0] as num).toDouble(),
                    );

                    final instruction = _formatInstruction(
                      step['maneuver'] as Map<String, dynamic>?,
                      step['name'] as String?,
                    );

                    steps.add(NavigationStep(
                      distance: ((step['distance'] as num?) ?? 0).toInt(),
                      duration: ((step['duration'] as num?) ?? 0).toInt(),
                      instruction: instruction,
                      maneuver: maneuver?['type'] as String? ?? 'straight',
                      location: stepLocation,
                    ));
                  }
                }
              }
            }

            final totalDistance = ((route['distance'] as num?) ?? 0).toInt();
            final totalDuration = ((route['duration'] as num?) ?? 0).toInt();

            if (mounted) {
              setState(() {
                _steps = steps;
                _routePoints = points;
                _totalDistance = totalDistance;
                _totalDuration = totalDuration;
                _isLoading = false;
              });

              // Fit map to show entire route
              if (points.isNotEmpty) {
                final bounds = LatLngBounds.fromPoints(points);
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(80),
                      ),
                    );
                  }
                });
              }
            }
            return;
          }
        }
      }

      throw Exception('Không thể lấy chỉ dẫn đường đi');
    } catch (e) {
      print('⚠️ Error fetching directions: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatInstruction(Map<String, dynamic>? maneuver, String? roadName) {
    if (maneuver == null) return 'Tiếp tục đi thẳng';

    final type = maneuver['type'] as String? ?? 'straight';
    final modifier = maneuver['modifier'] as String?;

    String instruction = '';

    switch (type) {
      case 'turn':
      case 'new name':
        switch (modifier) {
          case 'left':
            instruction = 'Rẽ trái';
            break;
          case 'right':
            instruction = 'Rẽ phải';
            break;
          case 'slight left':
            instruction = 'Rẽ nhẹ trái';
            break;
          case 'slight right':
            instruction = 'Rẽ nhẹ phải';
            break;
          case 'sharp left':
            instruction = 'Rẽ gắt trái';
            break;
          case 'sharp right':
            instruction = 'Rẽ gắt phải';
            break;
          default:
            instruction = 'Rẽ';
        }
        break;
      case 'merge':
        instruction = 'Nhập làn';
        break;
      case 'fork':
        instruction = modifier == 'left' ? 'Rẽ trái tại ngã ba' : 'Rẽ phải tại ngã ba';
        break;
      case 'roundabout':
        instruction = 'Vào bùng binh';
        break;
      case 'arrive':
        instruction = 'Đã đến đích';
        break;
      default:
        instruction = 'Tiếp tục đi thẳng';
    }

    if (roadName != null && roadName.isNotEmpty) {
      instruction += ' vào $roadName';
    }

    return instruction;
  }

  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver) {
      case 'turn':
      case 'new name':
        return Icons.turn_right;
      case 'merge':
        return Icons.merge;
      case 'fork':
        return Icons.fork_right;
      case 'roundabout':
        return Icons.roundabout_right;
      case 'arrive':
        return Icons.location_on;
      default:
        return Icons.straight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text(
          'Chỉ dẫn đường đi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: _Sp.lg),
                        Text(
                          'Không thể tải chỉ dẫn đường đi',
                          style: TextStyle(
                            color: AppColors.getTextSecondary(isDark),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: _Sp.md),
                        ElevatedButton(
                          onPressed: _fetchDirections,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Map view
                      _buildMapView(isDark),
                      // Summary card
                      _buildSummaryCard(isDark),
                      // Directions list
                      Expanded(
                        child: _buildDirectionsList(isDark),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildMapView(bool isDark) {
    if (_routePoints.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: widget.start,
          initialZoom: 13.0,
          minZoom: 5.0,
          maxZoom: 18.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.petshop.app',
            maxZoom: 19,
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 5.0,
                color: Colors.blue.withOpacity(0.8),
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: widget.start,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                ),
              ),
              Marker(
                point: widget.end,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.flag, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(_Sp.md),
      padding: const EdgeInsets.all(_Sp.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(_Rad.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              Icons.straighten,
              'Khoảng cách',
              _totalDistance < 1000
                  ? '$_totalDistance m'
                  : '${(_totalDistance / 1000).toStringAsFixed(1)} km',
              isDark,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildSummaryItem(
              Icons.access_time,
              'Thời gian',
              '${(_totalDuration / 60).round()} phút',
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      IconData icon, String label, String value, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(height: _Sp.xs),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        const SizedBox(height: _Sp.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.getTextSecondary(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionsList(bool isDark) {
    if (_steps.isEmpty) {
      return Center(
        child: Text(
          'Không có chỉ dẫn đường đi',
          style: TextStyle(color: AppColors.getTextSecondary(isDark)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: _Sp.md),
      itemCount: _steps.length,
      separatorBuilder: (context, index) => const SizedBox(height: _Sp.sm),
      itemBuilder: (context, index) {
        final step = _steps[index];
        return _buildStepCard(step, index, isDark);
      },
    );
  }

  Widget _buildStepCard(NavigationStep step, int index, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(_Sp.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(_Rad.md),
        border: Border.all(
          color: Colors.grey.shade300.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number & icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_Rad.sm),
            ),
            child: Icon(
              _getManeuverIcon(step.maneuver),
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: _Sp.md),
          // Instruction & details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.instruction,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: _Sp.xs),
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 14,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                    const SizedBox(width: _Sp.xs),
                    Text(
                      step.distanceText,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                    const SizedBox(width: _Sp.md),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.getTextSecondary(isDark),
                    ),
                    const SizedBox(width: _Sp.xs),
                    Text(
                      step.durationText,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
