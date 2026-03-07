import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../../core/services/signalr_service.dart';
import '../../data/models/order_tracking_response_dto.dart';
import '../../data/datasources/remote/order_remote_data_source.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderTrackingPage extends ConsumerStatefulWidget {
  final int orderId;

  const OrderTrackingPage({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends ConsumerState<OrderTrackingPage>
    with SingleTickerProviderStateMixin {
  OrderTrackingResponseDto? _tracking;
  bool _isLoading = true;
  bool _isInitialLoad = true;
  String? _error;
  Timer? _pollingTimer;
  late AnimationController _shipperAnimationController;
  late Animation<double> _shipperAnimation;
  
  // SignalR
  final SignalRService _signalRService = SignalRService();

  // Shipper location (ValueNotifier để chỉ rebuild marker layer, không rebuild cả trang)
  final _shipperPositionNotifier = ValueNotifier<LatLng?>(null);

  // OSRM routes
  List<LatLng> _shopToCustomerRoute = [];
  List<LatLng> _shipperRoute = [];

  // Shipper → customer: distance + ETA từ OSRM
  int? _remainingDistanceM;
  int? _remainingDurationS;

  // Map controller
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _shipperAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _shipperAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _shipperAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _fetchTracking();
    _startPolling();
    _connectSignalR();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _shipperAnimationController.dispose();
    _shipperPositionNotifier.dispose();
    _signalRService.disconnect();
    super.dispose();
  }

  Future<void> _connectSignalR() async {
    try {
      // Setup callbacks
      _signalRService.onShipperAssigned = (data) {
        print('📨 ShipperAssigned: $data');
        // Refresh tracking data to get shipper info
        _fetchTracking();
      };

      _signalRService.onShipperLocationUpdated = (data) {
        print('📨 ShipperLocationUpdated: $data');
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();

        if (lat != null && lng != null) {
          // Chỉ update notifier, không setState → không rebuild cả trang
          _shipperPositionNotifier.value = LatLng(lat, lng);
          _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
        }
      };

      _signalRService.onOrderStatusChanged = (data) {
        print('📨 OrderStatusChanged: $data');
        final status = data['status'] as String?;
        if (status != null) {
          // Refresh tracking data
          _fetchTracking();
          
          // Disconnect if delivered or cancelled
          if (status == 'delivered' || status == 'cancelled') {
            _signalRService.disconnect();
          }
        }
      };

      // Connect to SignalR
      await _signalRService.connect(widget.orderId);
    } catch (e) {
      print('❌ Error connecting SignalR: $e');
      // Continue without SignalR - polling will still work
    }
  }

  Future<void> _fetchTracking() async {
    try {
      if (_isInitialLoad) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final dataSource = OrderRemoteDataSourceImpl(apiClient: ApiClient());
      final tracking = await dataSource.getOrderTracking(widget.orderId);

      // Debug: Log tracking data
      print('📦 Tracking Data:');
      print('  - orderId: ${tracking.orderId}');
      print('  - currentStatus: ${tracking.currentStatus}');
      print('  - shopLat: ${tracking.shopLat}, shopLng: ${tracking.shopLng}');
      print('  - customerLat: ${tracking.customerLat}, customerLng: ${tracking.customerLng}');
      print('  - shipperCurrentLat: ${tracking.shipperCurrentLat}, shipperCurrentLng: ${tracking.shipperCurrentLng}');
      print('  - shipperId: ${tracking.shipperId}');

      setState(() {
        _tracking = tracking;
        _isLoading = false;
        _isInitialLoad = false;
      });

      // Update shipper position notifier từ API response
      final LatLng? shipperPos = (tracking.shipperCurrentLat != null && tracking.shipperCurrentLng != null)
          ? LatLng(tracking.shipperCurrentLat!, tracking.shipperCurrentLng!)
          : null;
      if (shipperPos != null) {
        _shipperPositionNotifier.value = shipperPos;
      }

      // Fetch OSRM routes (đường bộ thực tế)
      final LatLng? shopPos = (tracking.shopLat != null && tracking.shopLng != null)
          ? LatLng(tracking.shopLat!, tracking.shopLng!)
          : null;
      final LatLng? customerPos = (tracking.customerLat != null && tracking.customerLng != null)
          ? LatLng(tracking.customerLat!, tracking.customerLng!)
          : null;

      if (shopPos != null && customerPos != null && _shopToCustomerRoute.isEmpty) {
        final result = await _fetchOsrmRoute(shopPos, customerPos);
        if (mounted) setState(() => _shopToCustomerRoute = result.points);
      }
      if (shopPos != null && shipperPos != null) {
        final result = await _fetchOsrmRoute(shopPos, shipperPos);
        if (mounted) setState(() => _shipperRoute = result.points);
      }
      // Fetch shipper→customer route để lấy distance + ETA
      if (shipperPos != null && customerPos != null) {
        final result = await _fetchOsrmRoute(shipperPos, customerPos);
        if (mounted) {
          setState(() {
            _remainingDistanceM = result.distanceM;
            _remainingDurationS = result.durationS;
          });
        }
      }
    } catch (e) {
      if (_isInitialLoad) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _fetchTracking();
      }
    });
  }

  /// Gọi OSRM API lấy route, distance(m), duration(s). Fallback đường thẳng nếu lỗi.
  Future<({List<LatLng> points, int distanceM, int durationS})> _fetchOsrmRoute(
      LatLng from, LatLng to) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson';
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final route = data['routes'][0] as Map<String, dynamic>;
        final coords = route['geometry']['coordinates'] as List<dynamic>;
        final points = coords
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        final distanceM = ((route['distance'] as num?) ?? 0).toInt();
        final durationS = ((route['duration'] as num?) ?? 0).toInt();
        return (points: points, distanceM: distanceM, durationS: durationS);
      }
    } catch (_) {}
    return (points: [from, to], distanceM: 0, durationS: 0);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'confirmed':
        return Colors.green;
      case 'shipping':
        return Colors.orange;
      case 'delivered':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle;
      case 'shipping':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} giờ trước';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return isoString;
    }
  }

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'confirmed':
        return [const Color(0xFF3B82F6), const Color(0xFF60A5FA)];
      case 'shipping':
        return [const Color(0xFFF97316), const Color(0xFFFB923C)];
      case 'delivered':
        return [const Color(0xFF22C55E), const Color(0xFF4ADE80)];
      case 'cancelled':
        return [const Color(0xFFEF4444), const Color(0xFFF87171)];
      default:
        return [const Color(0xFF9CA3AF), const Color(0xFFD1D5DB)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const BottomNavBar()),
              (route) => false,
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theo dõi đơn hàng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(
              'Đơn #${widget.orderId}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        toolbarHeight: 60,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.orange.shade400),
                  ),
                  const SizedBox(height: 16),
                  Text('Đang tải...', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.wifi_off_rounded, size: 40, color: Colors.red.shade300),
                        ),
                        const SizedBox(height: 20),
                        const Text('Không thể tải đơn hàng',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_error!, style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchTracking,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _tracking == null
                  ? const Center(child: Text('Không có dữ liệu'))
                  : RefreshIndicator(
                      onRefresh: _fetchTracking,
                      color: Colors.orange,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _buildHeroStatusCard(),
                            if (_tracking!.currentStatus == 'confirmed' ||
                                _tracking!.currentStatus == 'shipping') ...[
                              const SizedBox(height: 16),
                              _buildMapSection(),
                            ],
                            const SizedBox(height: 16),
                            _buildTimeline(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildHeroStatusCard() {
    final status = _tracking!.currentStatus;
    final gradientColors = _getStatusGradient(status);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          children: [
            // Icon (animated for shipping)
            if (status == 'shipping')
              AnimatedBuilder(
                animation: _shipperAnimation,
                builder: (context, _) => Transform.translate(
                  offset: Offset(_shipperAnimation.value, 0),
                  child: _buildStatusIconBubble(gradientColors[0], Icons.moped),
                ),
              )
            else
              _buildStatusIconBubble(gradientColors[0], _getStatusIcon(status)),
            const SizedBox(height: 16),
            Text(
              _tracking!.statusDisplayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              _tracking!.statusDescription,
              style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (_tracking!.shipperId != null) ...[
              const SizedBox(height: 20),
              _buildShipperInfoCard(gradientColors[0]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIconBubble(Color color, IconData icon) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: 38),
    );
  }

  String _formatDistance(int meters) {
    if (meters == 0) return '...';
    if (meters < 1000) return '${meters} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '...';
    if (seconds < 60) return '< 1 phút';
    final mins = (seconds / 60).round();
    if (mins < 60) return '~$mins phút';
    final hrs = mins ~/ 60;
    final rem = mins % 60;
    return rem > 0 ? '~${hrs}h${rem}p' : '~${hrs} giờ';
  }

  Widget _buildShipperInfoCard(Color accentColor) {
    final name = _tracking!.shipperName ?? 'Shipper #${_tracking!.shipperId}';
    final hasEta = _remainingDistanceM != null && _remainingDistanceM! > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
              ],
            ),
            child: Icon(Icons.delivery_dining_rounded, color: accentColor, size: 26),
          ),
          const SizedBox(width: 12),
          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Đang trên đường giao hàng',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Distance + ETA pill
          if (hasEta)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    _formatDistance(_remainingDistanceM!),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  Text(
                    _formatDuration(_remainingDurationS ?? 0),
                    style: TextStyle(fontSize: 10, color: accentColor.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    LatLng? shopLatLng;
    if (_tracking!.shopLat != null && _tracking!.shopLng != null) {
      shopLatLng = LatLng(_tracking!.shopLat!, _tracking!.shopLng!);
    }

    LatLng? customerLatLng;
    if (_tracking!.customerLat != null && _tracking!.customerLng != null) {
      customerLatLng = LatLng(_tracking!.customerLat!, _tracking!.customerLng!);
    }

    // Dùng giá trị hiện tại của notifier để tính bounds ban đầu
    final initialShipperPos = _shipperPositionNotifier.value;

    final List<LatLng> allPoints = [
      if (shopLatLng != null) shopLatLng,
      if (customerLatLng != null) customerLatLng,
      if (initialShipperPos != null) initialShipperPos,
    ];

    LatLng centerLatLng;
    double initialZoom = 14.0;

    if (allPoints.length >= 2) {
      final minLat = allPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
      final maxLat = allPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
      final minLng = allPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
      final maxLng = allPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
      centerLatLng = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
      final maxDiff = (maxLat - minLat) > (maxLng - minLng) ? (maxLat - minLat) : (maxLng - minLng);
      if (maxDiff > 0.1) initialZoom = 11.0;
      else if (maxDiff > 0.05) initialZoom = 12.0;
      else if (maxDiff > 0.01) initialZoom = 13.0;
      else initialZoom = 14.0;
    } else if (allPoints.isNotEmpty) {
      centerLatLng = allPoints.first;
    } else {
      centerLatLng = const LatLng(10.8415, 106.8099); // FPT HCM default
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Bản đồ theo dõi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: centerLatLng,
                  initialZoom: initialZoom,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onMapReady: () {
                    if (allPoints.length >= 2) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        try {
                          final bounds = LatLngBounds.fromPoints(allPoints);
                          _mapController.fitCamera(
                            CameraFit.bounds(
                              bounds: bounds,
                              padding: const EdgeInsets.all(50),
                            ),
                          );
                        } catch (_) {}
                      });
                    }
                  },
                ),
                children: [
                  // OSM tile layer
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.petshop.app',
                    maxZoom: 19,
                  ),
                  // Polylines: xám (shop→customer) + xanh (shop→shipper) — route đường bộ từ OSRM
                  PolylineLayer(
                    polylines: [
                      if (_shopToCustomerRoute.isNotEmpty)
                        Polyline(
                          points: _shopToCustomerRoute,
                          strokeWidth: 4.0,
                          color: Colors.grey.shade600,
                        ),
                      if (_shipperRoute.isNotEmpty)
                        Polyline(
                          points: _shipperRoute,
                          strokeWidth: 4.0,
                          color: const Color(0xFF4285F4).withOpacity(0.8),
                        ),
                    ],
                  ),
                  // Static markers: shop + customer
                  MarkerLayer(
                    markers: [
                      if (shopLatLng != null)
                        Marker(
                          point: shopLatLng,
                          width: 44,
                          height: 44,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800),
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
                            child: const Icon(Icons.store, color: Colors.white, size: 20),
                          ),
                        ),
                      if (customerLatLng != null)
                        Marker(
                          point: customerLatLng,
                          width: 44,
                          height: 44,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA4335),
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
                    ],
                  ),
                  // Shipper marker (realtime, không rebuild cả trang)
                  ValueListenableBuilder<LatLng?>(
                    valueListenable: _shipperPositionNotifier,
                    builder: (context, shipperPos, _) {
                      if (shipperPos == null) return const SizedBox.shrink();
                      return MarkerLayer(
                        markers: [
                          Marker(
                            point: shipperPos,
                            width: 44,
                            height: 44,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4285F4),
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
                              child: const Icon(Icons.moped, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
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

  Widget _buildTimeline() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Tiến trình đơn hàng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: _tracking!.timeline.asMap().entries.map((entry) {
                return _buildTimelineItem(
                  item: entry.value,
                  statusColor: _getStatusColor(entry.value.status),
                  isLast: entry.key == _tracking!.timeline.length - 1,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required StatusTimelineItemDto item,
    required Color statusColor,
    required bool isLast,
  }) {
    final isActive = item.isCompleted || item.isCurrent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left rail: dot + line
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (item.isCurrent)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.35),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.circle, color: Colors.white, size: 10),
                  )
                else if (item.isCompleted)
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                  )
                else
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                  ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: item.isCompleted ? statusColor.withOpacity(0.25) : Colors.grey.shade200,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.statusDisplayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: item.isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isActive ? AppColors.textPrimary : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(item.timestamp),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.grey.shade500 : Colors.grey.shade400,
                      height: 1.4,
                    ),
                  ),
                  if (item.isCurrent) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Hiện tại',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
