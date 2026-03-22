import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pet_shop/core/network/api_client.dart';
import 'package:pet_shop/core/theme/app_colors.dart';
import 'package:pet_shop/core/widgets/toast_notification.dart';

import '../../data/datasources/remote/voucher_remote_data_source.dart';
import '../../data/models/voucher_dto.dart';

class Sp {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class Rad {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

enum _VoucherUiStatus { active, upcoming, expired }

class PromoCodesPage extends StatefulWidget {
  const PromoCodesPage({super.key});

  @override
  State<PromoCodesPage> createState() => _PromoCodesPageState();
}

class _PromoCodesPageState extends State<PromoCodesPage> {
  final ApiClient _apiClient = ApiClient();
  late final VoucherRemoteDataSource _voucherSource =
      VoucherRemoteDataSourceImpl(apiClient: _apiClient);

  bool _loading = true;
  String? _error;
  List<VoucherDto> _vouchers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _voucherSource.getVouchers();
      final activeOnly = list.where((v) => v.isActive).toList();
      activeOnly.sort(_compareVouchers);
      if (!mounted) return;
      setState(() {
        _vouchers = activeOnly;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  static int _compareVouchers(VoucherDto a, VoucherDto b) {
    final now = DateTime.now();
    int rank(VoucherDto v) {
      if (now.isBefore(v.startDate)) return 1;
      if (now.isAfter(v.endDate)) return 2;
      return 0;
    }

    final ra = rank(a);
    final rb = rank(b);
    if (ra != rb) return ra.compareTo(rb);
    if (ra == 0) return a.endDate.compareTo(b.endDate);
    if (ra == 1) return a.startDate.compareTo(b.startDate);
    return b.endDate.compareTo(a.endDate);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.getBackground(isDark);
    final textPrimary = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primaryDark,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              pinned: true,
              backgroundColor: bg,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Mã giảm giá',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_loading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryDark,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            if (!_loading && _error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  message: _error!,
                  onRetry: _load,
                  textSecondary: textSecondary,
                  textPrimary: textPrimary,
                ),
              ),
            if (!_loading && _error == null) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, Sp.md),
                  child: Text(
                    'Chọn mã và dán khi thanh toán. Kéo xuống để làm mới.',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              if (_vouchers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Hiện chưa có voucher khả dụng.',
                      style: TextStyle(color: textSecondary, fontSize: 15),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, Sp.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final v = _vouchers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: Sp.md),
                          child: _VoucherCard(
                            voucher: v,
                            isDark: isDark,
                            onCopy: () => _copyCode(context, v.code),
                          ),
                        );
                      },
                      childCount: _vouchers.length,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ToastNotification.show(
      context,
      message: 'Đã sao chép mã $code',
      type: ToastType.success,
      icon: Icons.check_rounded,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.textSecondary,
    required this.textPrimary,
  });

  final String message;
  final VoidCallback onRetry;
  final Color textSecondary;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: textSecondary),
          const SizedBox(height: Sp.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: textPrimary, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: Sp.lg),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Rad.md),
              ),
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.voucher,
    required this.isDark,
    required this.onCopy,
  });

  final VoucherDto voucher;
  final bool isDark;
  final VoidCallback onCopy;

  static _VoucherUiStatus _status(VoucherDto v) {
    final now = DateTime.now();
    if (now.isBefore(v.startDate)) return _VoucherUiStatus.upcoming;
    if (now.isAfter(v.endDate)) return _VoucherUiStatus.expired;
    return _VoucherUiStatus.active;
  }

  @override
  Widget build(BuildContext context) {
    final status = _status(voucher);
    final surface = AppColors.getSurface(isDark);
    final textPrimary = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);

    final badgeLabel = switch (status) {
      _VoucherUiStatus.active => 'Đang áp dụng',
      _VoucherUiStatus.upcoming => 'Sắp mở',
      _VoucherUiStatus.expired => 'Đã hết hạn',
    };

    final badgeBg = switch (status) {
      _VoucherUiStatus.active => AppColors.success.withOpacity(0.12),
      _VoucherUiStatus.upcoming => AppColors.info.withOpacity(0.12),
      _VoucherUiStatus.expired => AppColors.textLight.withOpacity(0.2),
    };

    final badgeFg = switch (status) {
      _VoucherUiStatus.active => AppColors.success,
      _VoucherUiStatus.upcoming => AppColors.info,
      _VoucherUiStatus.expired => textSecondary,
    };

    final dimmed = status == _VoucherUiStatus.expired;

    return Opacity(
      opacity: dimmed ? 0.72 : 1,
      child: Material(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(Rad.lg),
        child: InkWell(
          onTap: status == _VoucherUiStatus.expired ? null : onCopy,
          borderRadius: BorderRadius.circular(Rad.lg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Rad.lg),
              border: Border.all(
                color: AppColors.primary.withOpacity(isDark ? 0.25 : 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Rad.lg),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 6,
                      color: dimmed
                          ? textSecondary.withOpacity(0.35)
                          : AppColors.primaryDark,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(Sp.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Sp.sm,
                                    vertical: Sp.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius:
                                        BorderRadius.circular(Rad.sm),
                                  ),
                                  child: Text(
                                    badgeLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: badgeFg,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _discountHeadline(voucher),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: dimmed
                                        ? textSecondary
                                        : AppColors.sale,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Sp.sm),
                            Text(
                              voucher.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: Sp.xs),
                            Text(
                              voucher.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: Sp.sm),
                            Wrap(
                              spacing: Sp.sm,
                              runSpacing: Sp.xs,
                              children: [
                                _MetaChip(
                                  icon: Icons.event_rounded,
                                  label:
                                      'HSD: ${_formatDate(voucher.endDate)}',
                                  isDark: isDark,
                                ),
                                if (voucher.minOrderAmount != null)
                                  _MetaChip(
                                    icon: Icons.shopping_bag_outlined,
                                    label:
                                        'Từ ${_formatVnd(voucher.minOrderAmount!)} đ',
                                    isDark: isDark,
                                  ),
                                if (voucher.usageLimit != null)
                                  _MetaChip(
                                    icon: Icons.people_outline_rounded,
                                    label:
                                        '${voucher.usedCount}/${voucher.usageLimit} lượt',
                                    isDark: isDark,
                                  ),
                              ],
                            ),
                            const SizedBox(height: Sp.md),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Sp.md,
                                      vertical: Sp.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryVeryLight
                                          .withOpacity(isDark ? 0.12 : 1),
                                      borderRadius:
                                          BorderRadius.circular(Rad.md),
                                      border: Border.all(
                                        color: AppColors.primary
                                            .withOpacity(0.45),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.tag_rounded,
                                          size: 18,
                                          color: AppColors.primaryDark,
                                        ),
                                        const SizedBox(width: Sp.sm),
                                        Expanded(
                                          child: Text(
                                            voucher.code,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.8,
                                              color: textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: Sp.sm),
                                SizedBox(
                                  height: 48,
                                  child: FilledButton(
                                    onPressed: status ==
                                            _VoucherUiStatus.expired
                                        ? null
                                        : onCopy,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primaryDark,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          textSecondary.withOpacity(0.2),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Sp.md,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(Rad.md),
                                      ),
                                    ),
                                    child: const Text('Sao chép'),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.getTextSecondary(isDark);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: Sp.xs),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: fg, height: 1.2),
        ),
      ],
    );
  }
}

String _discountHeadline(VoucherDto v) {
  if (v.isPercentage) {
    final d = v.discountValue.toDouble();
    final whole = d == d.roundToDouble();
    return '-${whole ? d.toInt() : d}%';
  }
  return '-${_formatVnd(v.discountValue.round())} đ';
}

String _formatVnd(int n) {
  final negative = n < 0;
  final s = (negative ? -n : n).toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return negative ? '-$buf' : buf.toString();
}

String _formatDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
