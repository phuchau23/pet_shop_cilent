import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/animated_section.dart';
import '../../../../core/widgets/animated_grid_item.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/data/datasources/remote/product_remote_data_source.dart';
import '../../../products/data/repositories/product_repository_impl.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../products/presentation/pages/product_detail_page.dart';

class ProductSection extends StatefulWidget {
  const ProductSection({super.key});

  @override
  State<ProductSection> createState() => _ProductSectionState();
}

class _ProductSectionState extends State<ProductSection> {
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  late final GetProductsUseCase _getProductsUseCase;

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
    _loadProducts();
  }

  void _initializeDependencies() {
    final apiClient = ApiClient();
    final remoteDataSource = ProductRemoteDataSourceImpl(apiClient: apiClient);
    final repository = ProductRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
    _getProductsUseCase = GetProductsUseCase(repository: repository);
  }

  Future<void> _loadProducts({bool loadMore = false}) async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _products = [];
        _currentPage = 1;
        _hasMore = true;
      }
    });

    try {
      final products = await _getProductsUseCase(
        pageNumber: _currentPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _products.addAll(products);
          } else {
            _products = products;
          }
          _currentPage++;
          _hasMore = products.length == _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  List<Product> get _displayedProducts {
    return _products.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        // Section Header
        SliverToBoxAdapter(
          child: AnimatedSection(
            delay: const Duration(milliseconds: 400),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: _SectionHeader(title: 'Sản phẩm nổi bật', onSeeAll: () {}),
            ),
          ),
        ),
        // Products Horizontal Scroll
        if (_isLoading && _products.isEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 6, // 5 products + 1 view more
                itemBuilder: (context, index) {
                  if (index == 5) {
                    // View More Card skeleton
                    return Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: SizedBox(
                        width: 180,
                        child: _ViewMoreCardSkeleton(),
                      ),
                    );
                  }
                  return Padding(
                    padding: EdgeInsets.only(right: index == 4 ? 0 : 16),
                    child: SizedBox(width: 180, child: _ProductCardSkeleton()),
                  );
                },
              ),
            ),
          )
        else if (_products.isEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pets_outlined,
                      size: 48,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có sản phẩm',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: SizedBox(
              height: 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _displayedProducts.length + 1, // +1 for ViewMoreCard
                itemBuilder: (context, index) {
                  if (index == _displayedProducts.length) {
                    // View More Card
                    return AnimatedGridItem(
                      delay: Duration(milliseconds: 100 + (index * 50)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: SizedBox(
                          width: 180,
                          child: _ViewMoreCard(
                            onTap: () {
                              // TODO: Navigate to full products page
                            },
                          ),
                        ),
                      ),
                    );
                  }
                  return AnimatedGridItem(
                    delay: Duration(milliseconds: 100 + (index * 50)),
                    child: Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 180,
                        child: ProductCard(product: _displayedProducts[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
            height: 1.3,
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

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(product: widget.product),
      ),
    );
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  String _formatPrice(double price) {
    if (price <= 0) {
      return 'Liên hệ';
    }

    final priceInt = price.toInt();
    final priceString = priceInt.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < priceString.length; i++) {
      if (i > 0 && (priceString.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(priceString[i]);
    }

    return '${buffer.toString()} đ';
  }

  Widget _buildPlaceholderImage() {
    return SkeletonImage(
      width: double.infinity,
      height: double.infinity,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.product.images.isNotEmpty;
    final isOnSale = widget.product.isOnSale;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Full-cover image
                hasImage
                    ? Image.network(
                        widget.product.images.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SkeletonImage(
                            width: double.infinity,
                            height: double.infinity,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),

                // Bottom gradient overlay
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),

                // Product info at bottom
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                          letterSpacing: -0.2,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _formatPrice(widget.product.finalPrice),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          ),
                          if (isOnSale) ...[
                            const SizedBox(width: 6),
                            Text(
                              _formatPrice(widget.product.price),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.6),
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.white.withValues(
                                  alpha: 0.6,
                                ),
                                height: 1.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Sale badge – top left
                if (isOnSale)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sale,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${widget.product.discountPercent.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),

                // Favorite button – top right
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Implement favorite functionality
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// View More Card
class _ViewMoreCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ViewMoreCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: -10,
            ),
          ],
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.primary.withValues(alpha: 0.4),
            strokeWidth: 2,
            dashLength: 8,
            dashSpace: 4,
            radius: 28,
          ),
          child: SizedBox(
            height: 320,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Icon(Icons.add, size: 32, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Xem thêm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Skeleton cho View More Card
class _ViewMoreCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkeletonCircle(size: 64),
          const SizedBox(height: 16),
          SkeletonText(width: 80, height: 16),
        ],
      ),
    );
  }
}

// Custom Painter for Dashed Border
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashSpace,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0;
      while (distance < pathMetric.length) {
        final extractPath = pathMetric.extractPath(
          distance,
          distance + dashLength,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashLength + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Skeleton cho Product Card
class _ProductCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          SkeletonImage(width: double.infinity, height: double.infinity),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonText(width: double.infinity, height: 13),
                const SizedBox(height: 6),
                SkeletonText(width: 90, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
