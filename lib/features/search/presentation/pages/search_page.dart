import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/data/datasources/remote/product_remote_data_source.dart';
import '../../../products/data/repositories/product_repository_impl.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../products/presentation/pages/product_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  late final GetProductsUseCase _getProductsUseCase;

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
    _searchController.addListener(() {
      setState(() {}); // Rebuild để hiện/ẩn clear button
    });
  }

  void _initializeDependencies() {
    final apiClient = ApiClient();
    final remoteDataSource = ProductRemoteDataSourceImpl(apiClient: apiClient);
    final repository = ProductRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
    _getProductsUseCase = GetProductsUseCase(repository: repository);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final products = await _getProductsUseCase(
        pageNumber: 1,
        pageSize: 50,
        searchTerm: query.trim(),
      );

      if (mounted) {
        setState(() {
          _searchResults = products;
          _isLoading = false;
        });
        print('✅ Search results: ${_searchResults.length} items');
      }
    } catch (e) {
      print('❌ Error searching products: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildSearchBar(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // const SizedBox(width: 16),
          // const Icon(Icons.search, color: AppColors.primary, size: 22),
          // const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.textLight),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              onChanged: (value) {
                // Debounce search - search after user stops typing
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch(value);
                  }
                });
              },
              onSubmitted: (value) {
                _performSearch(value);
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.clear,
                color: AppColors.textLight,
                size: 20,
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults = [];
                  _hasSearched = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // Show 5 skeleton items
        itemBuilder: (context, index) {
          return const _ProductSearchCardSkeleton();
        },
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 80,
              color: AppColors.textLight.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Tìm kiếm sản phẩm',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhập tên sản phẩm để tìm kiếm',
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: AppColors.textLight.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy sản phẩm',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return _ProductSearchCard(
          product: product,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: product),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductSearchCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductSearchCard({required this.product, required this.onTap});

  String _formatPrice(double price) {
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

  @override
  Widget build(BuildContext context) {
    final hasImage = product.images.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
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
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: AppColors.primaryVeryLight,
                child: hasImage
                    ? Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.pets,
                            size: 40,
                            color: AppColors.primary.withOpacity(0.5),
                          );
                        },
                      )
                    : Icon(
                        Icons.pets,
                        size: 40,
                        color: AppColors.primary.withOpacity(0.5),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category.name,
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(product.finalPrice),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

class _ProductSearchCardSkeleton extends StatefulWidget {
  const _ProductSearchCardSkeleton();

  @override
  State<_ProductSearchCardSkeleton> createState() =>
      _ProductSearchCardSkeletonState();
}

class _ProductSearchCardSkeletonState extends State<_ProductSearchCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
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
            children: [
              // Product Image Skeleton - 80x80
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getShimmerColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Product Info Skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name Skeleton - 2 lines
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _getShimmerColor(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 16,
                      width: MediaQuery.of(context).size.width * 0.5,
                      decoration: BoxDecoration(
                        color: _getShimmerColor(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Category Skeleton
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: _getShimmerColor(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price Skeleton
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: _getShimmerColor(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron Icon Skeleton
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getShimmerColor(),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getShimmerColor() {
    final baseColor = AppColors.primaryVeryLight;
    final shimmerColor = AppColors.primary.withOpacity(0.3);
    return Color.lerp(baseColor, shimmerColor, _animation.value) ?? baseColor;
  }
}
