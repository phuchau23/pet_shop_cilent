import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../order/data/datasources/remote/order_remote_data_source.dart';
import '../../../order/data/models/voucher_response_dto.dart';

class SpecialOffersSection extends StatefulWidget {
  const SpecialOffersSection({super.key});

  @override
  State<SpecialOffersSection> createState() => _SpecialOffersSectionState();
}

class _SpecialOffersSectionState extends State<SpecialOffersSection> {
  List<VoucherResponseDto> _vouchers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final dataSource = OrderRemoteDataSourceImpl(apiClient: ApiClient());
      final vouchers = await dataSource.getVouchers();

      // Chỉ lấy các voucher đang active
      final activeVouchers = vouchers.where((v) => v.isActive).toList();

      if (mounted) {
        setState(() {
          _vouchers = activeVouchers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading vouchers: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Voucher Khuyến Mãi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                ? SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lỗi: $_error',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadVouchers,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _vouchers.isEmpty
                ? const SizedBox(
                    height: 200,
                    child: Center(child: Text('Không có voucher nào')),
                  )
                : SizedBox(
                    height: 95,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _vouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = _vouchers[index];
                        return VoucherCard(voucher: voucher);
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class VoucherCard extends StatelessWidget {
  final VoucherResponseDto voucher;

  const VoucherCard({super.key, required this.voucher});

  String _getDiscountText() {
    if (voucher.discountType == 'percentage') {
      return '${voucher.discountValue.toInt()}%';
    } else {
      return '${(voucher.discountValue / 1000).toStringAsFixed(0)}K';
    }
  }

  String _getDiscountLabel() {
    if (voucher.discountType == 'percentage') {
      return 'OFF';
    } else {
      return 'VNĐ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 85,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          // Main voucher card with perforated border
          CustomPaint(
            painter: PerforatedBorderPainter(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    children: [
                      // DISCOUNT banner at top
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.red.shade900,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'DISCOUNT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Circle with percentage
                      Center(
                        child: Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            color: Colors.transparent,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getDiscountText(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              const Text(
                                'OFF',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Semi-circular cutout on left
                      Positioned(
                        left: -8,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Semi-circular cutout on right
                      Positioned(
                        right: -8,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
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

// Custom painter for perforated border
class PerforatedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dashWidth = 3.0;
    final dashSpace = 2.0;
    final radius = 8.0;

    // Top border with dashes
    _drawDashedLine(
      canvas,
      Offset(radius, 0),
      Offset(size.width - radius, 0),
      paint,
      dashWidth,
      dashSpace,
    );

    // Bottom border with dashes
    _drawDashedLine(
      canvas,
      Offset(radius, size.height),
      Offset(size.width - radius, size.height),
      paint,
      dashWidth,
      dashSpace,
    );

    // Left border with dashes and semi-circle cutout
    _drawDashedLine(
      canvas,
      Offset(0, radius),
      Offset(0, size.height / 2 - 6),
      paint,
      dashWidth,
      dashSpace,
    );
    _drawDashedLine(
      canvas,
      Offset(0, size.height / 2 + 6),
      Offset(0, size.height - radius),
      paint,
      dashWidth,
      dashSpace,
    );

    // Right border with dashes and semi-circle cutout
    _drawDashedLine(
      canvas,
      Offset(size.width, radius),
      Offset(size.width, size.height / 2 - 6),
      paint,
      dashWidth,
      dashSpace,
    );
    _drawDashedLine(
      canvas,
      Offset(size.width, size.height / 2 + 6),
      Offset(size.width, size.height - radius),
      paint,
      dashWidth,
      dashSpace,
    );

    // Semi-circular cutout on left side
    final cutoutPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, size.height / 2), 6, cutoutPaint);

    // Semi-circular cutout on right side
    canvas.drawCircle(Offset(size.width, size.height / 2), 6, cutoutPaint);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    final path = Path();
    final distance = (end - start).distance;
    final direction = (end - start) / distance;
    var currentDistance = 0.0;

    while (currentDistance < distance) {
      final dashStart = start + direction * currentDistance;
      final dashEnd =
          start +
          direction * (currentDistance + dashWidth).clamp(0.0, distance);
      path.moveTo(dashStart.dx, dashStart.dy);
      path.lineTo(dashEnd.dx, dashEnd.dy);
      currentDistance += dashWidth + dashSpace;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
