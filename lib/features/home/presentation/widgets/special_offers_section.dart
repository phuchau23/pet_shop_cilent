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
    if (_isLoading && _vouchers.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (_error != null && _vouchers.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (_vouchers.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Ưu đãi đặc biệt',
              onSeeAll: () {},
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 108,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _vouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = _vouchers[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == _vouchers.length - 1 ? 0 : 12,
                    ),
                    child: VoucherCard(voucher: voucher),
                  );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Xem tất cả',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 108,
              decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
                  decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                            child: Text(
                'GIẢM',
                              style: TextStyle(
                                color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                  height: 1,
                              ),
                            ),
                          ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getDiscountText(),
                                style: const TextStyle(
                                  color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                                  height: 1,
                    letterSpacing: -0.5,
                                ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                              ),
                const SizedBox(height: 4),
                Text(
                  voucher.name,
                                style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                          ),
              ],
                      ),
                    ],
                  ),
      ),
    );
  }
}
