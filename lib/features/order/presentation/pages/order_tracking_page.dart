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
  String? _error;
  Timer? _pollingTimer;
  late AnimationController _shipperAnimationController;
  late Animation<double> _shipperAnimation;
  
  // SignalR
  final SignalRService _signalRService = SignalRService();
  
  // Shipper location (realtime updates)
  double? _shipperLat;
  double? _shipperLng;
  
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
          setState(() {
            _shipperLat = lat;
            _shipperLng = lng;
          });
          
          // Update map camera to follow shipper
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
      setState(() {
        _isLoading = true;
        _error = null;
      });

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
        
        // Update shipper location from API response
        if (tracking.shipperCurrentLat != null && tracking.shipperCurrentLng != null) {
          _shipperLat = tracking.shipperCurrentLat;
          _shipperLng = tracking.shipperCurrentLng;
        }
      });
      
      print('✅ Tracking loaded, status: ${tracking.currentStatus}');
      print('✅ Will show map: ${tracking.currentStatus == 'shipping'}');
    } catch (e) {
      print('❌ Error fetching tracking: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _fetchTracking();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Theo dõi đơn hàng',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            // Navigate về home (BottomNavBar)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const BottomNavBar(),
              ),
              (route) => false,
            );
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lỗi: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchTracking,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _tracking == null
                  ? const Center(child: Text('Không có dữ liệu'))
                  : RefreshIndicator(
                      onRefresh: _fetchTracking,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            // Status Badge
                            _buildStatusBadge(),
                            const SizedBox(height: 24),
                            // Shipper Animation (nếu đang shipping)
                            if (_tracking!.currentStatus == 'shipping')
                              _buildShipperAnimation(),
                            const SizedBox(height: 24),
                            // Map với route (luôn hiển thị khi đang shipping)
                            if (_tracking!.currentStatus == 'shipping') ...[
                              Builder(
                                builder: (context) {
                                  print('🗺️ Rendering map widget, status: ${_tracking!.currentStatus}');
                                  return _buildMapSection();
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                            // Timeline
                            _buildTimeline(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildStatusBadge() {
    final statusColor = _getStatusColor(_tracking!.currentStatus);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(_tracking!.currentStatus),
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _tracking!.statusDisplayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _tracking!.statusDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          if (_tracking!.shipperId != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Shipper #${_tracking!.shipperId} đang giao hàng',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShipperAnimation() {
    return AnimatedBuilder(
      animation: _shipperAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shipperAnimation.value, 0),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping,
                  color: Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đang giao hàng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    Text(
                      'Shipper đang trên đường đến bạn',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapSection() {
    // Debug: Log location data
    print('📍 Map Debug - shopLat: ${_tracking!.shopLat}, shopLng: ${_tracking!.shopLng}');
    print('📍 Map Debug - customerLat: ${_tracking!.customerLat}, customerLng: ${_tracking!.customerLng}');
    print('📍 Map Debug - shipperCurrentLat: ${_tracking!.shipperCurrentLat}, shipperCurrentLng: ${_tracking!.shipperCurrentLng}');
    print('📍 Map Debug - _shipperLat: $_shipperLat, _shipperLng: $_shipperLng');
    
    // Lấy shop location (có thể null - dùng default nếu không có)
    LatLng? shopLatLng;
    if (_tracking!.shopLat != null && _tracking!.shopLng != null) {
      shopLatLng = LatLng(_tracking!.shopLat!, _tracking!.shopLng!);
    }
    
    // Lấy customer location (có thể null - dùng default nếu không có)
    LatLng? customerLatLng;
    if (_tracking!.customerLat != null && _tracking!.customerLng != null) {
      customerLatLng = LatLng(_tracking!.customerLat!, _tracking!.customerLng!);
    }
    
    // Lấy shipper location (ưu tiên realtime, fallback về API, có thể null)
    final shipperLat = _shipperLat ?? _tracking!.shipperCurrentLat;
    final shipperLng = _shipperLng ?? _tracking!.shipperCurrentLng;
    LatLng? shipperLatLng;
    if (shipperLat != null && shipperLng != null) {
      shipperLatLng = LatLng(shipperLat, shipperLng);
    }

    // Nếu không có location nào, vẫn hiển thị map với default location (Hà Nội)
    // Để user có thể thấy map ngay, location sẽ được cập nhật sau

    // Tính bounds để fit tất cả markers
    List<LatLng> allPoints = [];
    if (shopLatLng != null) allPoints.add(shopLatLng);
    if (customerLatLng != null) allPoints.add(customerLatLng);
    if (shipperLatLng != null) allPoints.add(shipperLatLng);
    
    // Center point và zoom để hiển thị tất cả
    LatLng centerLatLng;
    double initialZoom = 14.0;
    
    if (allPoints.length >= 2) {
      // Tính bounds để fit tất cả points
      double minLat = allPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
      double maxLat = allPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
      double minLng = allPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
      double maxLng = allPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
      
      centerLatLng = LatLng(
        (minLat + maxLat) / 2,
        (minLng + maxLng) / 2,
      );
      
      // Tính zoom dựa trên khoảng cách
      double latDiff = maxLat - minLat;
      double lngDiff = maxLng - minLng;
      double maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
      
      if (maxDiff > 0.1) {
        initialZoom = 11.0; // Zoom out nếu xa
      } else if (maxDiff > 0.05) {
        initialZoom = 12.0;
      } else if (maxDiff > 0.01) {
        initialZoom = 13.0;
      } else {
        initialZoom = 14.0; // Zoom in nếu gần
      }
    } else if (allPoints.isNotEmpty) {
      centerLatLng = allPoints.first;
      initialZoom = 14.0;
    } else {
      // Default: Hà Nội
      centerLatLng = const LatLng(21.0285, 105.8542);
      initialZoom = 13.0;
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
          // Map title và legend
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bản đồ theo dõi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (shopLatLng != null)
                      _buildLegendItem(
                        color: const Color(0xFFFF9800),
                        icon: Icons.store,
                        label: 'Cửa hàng',
                      ),
                    if (customerLatLng != null)
                      _buildLegendItem(
                        color: const Color(0xFFEA4335),
                        icon: Icons.location_on,
                        label: 'Vị trí của bạn',
                      ),
                    if (shipperLatLng != null)
                      _buildLegendItem(
                        color: const Color(0xFF4285F4),
                        icon: Icons.local_shipping,
                        label: 'Shipper đang đi',
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Map
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
                    // Fit bounds sau khi map ready để hiển thị tất cả markers
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
                        } catch (e) {
                          print('⚠️ Error fitting bounds: $e');
                        }
                      });
                    }
                  },
                ),
                children: [
                  // Tile layer
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.petshop.app',
                    maxZoom: 19,
                  ),
                  // Polyline layer - Route từ shop → shipper → customer
                  if (shopLatLng != null || customerLatLng != null || shipperLatLng != null)
                    PolylineLayer(
                      polylines: [
                        // Route từ shop đến customer (màu xám - dự kiến) - chỉ nếu có cả 2
                        if (shopLatLng != null && customerLatLng != null)
                          Polyline(
                            points: [shopLatLng, customerLatLng],
                            strokeWidth: 3.0,
                            color: Colors.grey.withOpacity(0.4),
                          ),
                        // Route từ shop đến shipper (màu xanh - đã đi) - chỉ hiển thị nếu có cả 2
                        if (shopLatLng != null && shipperLatLng != null)
                          Polyline(
                            points: [shopLatLng, shipperLatLng],
                            strokeWidth: 4.0,
                            color: const Color(0xFF4285F4).withOpacity(0.6),
                          ),
                        // Route từ shipper đến customer (màu đỏ - còn lại) - chỉ hiển thị nếu có cả 2
                        if (shipperLatLng != null && customerLatLng != null)
                          Polyline(
                            points: [shipperLatLng, customerLatLng],
                            strokeWidth: 4.0,
                            color: const Color(0xFFEA4335).withOpacity(0.6),
                          ),
                      ],
                    ),
                  // Markers
                  MarkerLayer(
                    markers: [
                      // Shop marker (vị trí bắt đầu của shipper)
                      if (shopLatLng != null)
                        Marker(
                          point: shopLatLng,
                          width: 60,
                          height: 60,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800), // Orange
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
                                child: const Icon(
                                  Icons.store,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Cửa hàng',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF9800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Customer marker (đích đến)
                      if (customerLatLng != null)
                        Marker(
                          point: customerLatLng,
                          width: 60,
                          height: 60,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEA4335), // Red
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
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Vị trí của bạn',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEA4335),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Shipper marker (vị trí hiện tại - realtime) - chỉ hiển thị nếu có location
                      if (shipperLatLng != null)
                        Marker(
                          point: shipperLatLng,
                          width: 60,
                          height: 60,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4285F4), // Blue
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
                                child: const Icon(
                                  Icons.local_shipping,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Shipper đang đi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Tiến trình đơn hàng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ..._tracking!.timeline.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == _tracking!.timeline.length - 1;
            final statusColor = _getStatusColor(item.status);

            return _buildTimelineItem(
              item: item,
              statusColor: statusColor,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required StatusTimelineItemDto item,
    required Color statusColor,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line và icon
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isCompleted || item.isCurrent
                    ? statusColor
                    : Colors.grey.shade300,
                border: Border.all(
                  color: item.isCurrent
                      ? statusColor
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: item.isCompleted
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    )
                  : item.isCurrent
                      ? Icon(
                          _getStatusIcon(item.status),
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: item.isCompleted
                    ? statusColor
                    : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.statusDisplayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: item.isCurrent
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: item.isCompleted || item.isCurrent
                        ? statusColor
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(item.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
