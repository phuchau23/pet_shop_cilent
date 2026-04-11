import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/routing_service.dart' as road;
import '../../../../core/storage/store_storage.dart';
import '../../../../core/theme/app_colors.dart';

class _Sp {
  static const sm = 8.0, md = 16.0;
}

/// Tab “Vị trí”: bản đồ cửa hàng + tuyến đường lái xe (OSRM) tới vị trí người dùng.
class StoreMapTabPage extends StatefulWidget {
  const StoreMapTabPage({super.key});

  @override
  State<StoreMapTabPage> createState() => _StoreMapTabPageState();
}

class _StoreMapTabPageState extends State<StoreMapTabPage> {
  final MapController _mapController = MapController();
  final road.RoutingService _routing = road.RoutingService();
  LatLng? _storeLatLng;
  LatLng? _userLatLng;
  List<LatLng> _routePolyline = [];
  double? _routeDistanceMeters;
  int? _routeDurationSeconds;
  bool _loadingStore = true;
  bool _loadingUserCompare = false;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    final lat = await StoreStorage.getStoreLatitude();
    final lng = await StoreStorage.getStoreLongitude();
    if (!mounted) return;
    setState(() {
      _storeLatLng = LatLng(lat, lng);
      _loadingStore = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_storeLatLng != null && mounted) {
        _mapController.move(_storeLatLng!, 15);
      }
    });
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(int seconds) {
    if (seconds < 3600) {
      final m = (seconds / 60).ceil();
      return '$m phút';
    }
    final h = seconds ~/ 3600;
    final m = ((seconds % 3600) / 60).ceil();
    return '$h giờ ${m > 0 ? '$m phút' : ''}'.trim();
  }

  Future<void> _compareMyLocationToStore() async {
    if (_storeLatLng == null) return;
    setState(() => _loadingUserCompare = true);
    try {
      final pos = await LocationService.getCurrentLocation();
      if (!mounted) return;
      if (pos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không lấy được vị trí. Bật GPS và cấp quyền vị trí.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final user = LatLng(pos.latitude, pos.longitude);
      final store = _storeLatLng!;

      road.Route? route;
      try {
        route = await _routing.calculateRoute(
          user,
          store,
          profile: 'driving',
        );
      } catch (_) {
        route = null;
      }

      if (!mounted) return;

      if (route != null && route.polyline.length >= 2) {
        setState(() {
          _userLatLng = user;
          _routePolyline = route!.polyline;
          _routeDistanceMeters = route.distance;
          _routeDurationSeconds = route.duration;
        });
        final bounds = LatLngBounds.fromPoints(route.polyline);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.fitCamera(
              CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(56)),
            );
          }
        });
      } else {
        final straight = LocationService.calculateDistance(
          user.latitude,
          user.longitude,
          store.latitude,
          store.longitude,
        );
        setState(() {
          _userLatLng = user;
          _routePolyline = [user, store];
          _routeDistanceMeters = straight;
          _routeDurationSeconds = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không tải được tuyến đường. Đang hiển thị đường thẳng tạm thời.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        final bounds = LatLngBounds.fromPoints([user, store]);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.fitCamera(
              CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(56)),
            );
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingUserCompare = false);
      }
    }
  }

  void _focusStore() {
    if (_storeLatLng == null) return;
    _mapController.move(_storeLatLng!, 15);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingStore || _storeLatLng == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final store = _storeLatLng!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: store,
              initialZoom: 15,
              minZoom: 5,
              maxZoom: 18,
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
              if (_routePolyline.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePolyline,
                      strokeWidth: 5,
                      color: const Color(0xFF4285F4).withOpacity(0.9),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: store,
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  if (_userLatLng != null)
                    Marker(
                      point: _userLatLng!,
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA4335),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + _Sp.sm,
            right: _Sp.md,
            child: Material(
              color: Colors.white,
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.08),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _focusStore,
                child: const Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primaryDark,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(_Sp.md, 0, _Sp.md, _Sp.sm),
                child: Material(
                  elevation: 6,
                  shadowColor: Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(_Sp.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_routeDistanceMeters != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.directions_car_rounded,
                                size: 20,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: _Sp.sm),
                              Expanded(
                                child: Text(
                                  _routeDurationSeconds != null
                                      ? 'Theo đường đi (ô tô): khoảng ${_formatDistance(_routeDistanceMeters!)} — ~${_formatDuration(_routeDurationSeconds!)}'
                                      : 'Khoảng cách: ${_formatDistance(_routeDistanceMeters!)} (đường thẳng — không tải được chỉ đường)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: _Sp.md),
                        ],
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed:
                                _loadingUserCompare ? null : _compareMyLocationToStore,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _loadingUserCompare
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textPrimary,
                                    ),
                                  )
                                : const Icon(Icons.near_me_rounded, size: 22),
                            label: Text(
                              _loadingUserCompare
                                  ? 'Đang định vị...'
                                  : 'Vị trí của tôi so với cửa hàng',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
