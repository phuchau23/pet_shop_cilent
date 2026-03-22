import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/data/datasources/remote/product_remote_data_source.dart';
import '../../../products/data/mock_data/mock_products.dart';
import '../../../products/data/repositories/product_repository_impl.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../products/presentation/pages/product_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.embedInBottomNav = false});

  final bool embedInBottomNav;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isFocused = false;
  List<Product> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  List<String> _suggestedBrands = [];
  bool _brandsLoading = false;
  String? _selectedBrandName;
  late final GetProductsUseCase _getProductsUseCase;
  late final AnimationController _resultsAnimController;

  @override
  void initState() {
    super.initState();
    _resultsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _initializeDependencies();
    _loadSuggestedBrands();
    _searchController.addListener(() => setState(() {}));
    _searchFocus.addListener(() => setState(() => _isFocused = _searchFocus.hasFocus));
  }

  Future<void> _loadSuggestedBrands() async {
    setState(() => _brandsLoading = true);
    try {
      final products = await _getProductsUseCase(pageNumber: 1, pageSize: 100);
      final names = <String>{};
      for (final p in products) {
        final n = p.brand.name.trim();
        if (n.isNotEmpty) names.add(n);
      }
      final sorted = names.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (mounted) {
        setState(() {
          _suggestedBrands = sorted.take(14).toList();
          _brandsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _suggestedBrands = MockProducts.brands.map((b) => b.name).toList();
          _brandsLoading = false;
        });
      }
    }
  }

  void _initializeDependencies() {
    final apiClient = ApiClient();
    final remoteDataSource = ProductRemoteDataSourceImpl(apiClient: apiClient);
    final repository = ProductRepositoryImpl(remoteDataSource: remoteDataSource);
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
    _resultsAnimController.reset();
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
        _resultsAnimController.forward();
      }
    } catch (_) {
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
    _searchFocus.dispose();
    _resultsAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.embedInBottomNav) ...[
          _buildEmbedHeader(),
          const SizedBox(height: 4),
        ] else ...[
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(child: _buildSearchField()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (!_hasSearched && !_isLoading) _buildBrandSection(),
        Expanded(child: _buildBody()),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.embedInBottomNav ? SafeArea(child: body) : body,
    );
  }

  Widget _buildEmbedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tìm kiếm',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.6,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _buildSearchField(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused
              ? AppColors.primaryDark.withValues(alpha: 0.6)
              : AppColors.textLight.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: _isFocused ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search_rounded,
            size: 20,
            color: _isFocused ? AppColors.primaryDark : AppColors.textLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              autofocus: !widget.embedInBottomNav,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
                hintStyle: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              onChanged: (value) {
                if (_selectedBrandName != null &&
                    value.trim() != _selectedBrandName) {
                  setState(() => _selectedBrandName = null);
                }
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) _performSearch(value);
                });
              },
              onSubmitted: _performSearch,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchResults = [];
                  _hasSearched = false;
                  _selectedBrandName = null;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.textLight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 15, color: AppColors.textSecondary),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildBrandSection() {
    if (_brandsLoading && _suggestedBrands.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, __) => _BrandPillSkeleton(),
          ),
        ),
      );
    }
    if (_suggestedBrands.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              Icon(Icons.label_rounded, size: 14, color: AppColors.primaryDark.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              const Text(
                'Thương hiệu nổi bật',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _suggestedBrands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final name = _suggestedBrands[i];
              return _BrandPill(
                label: name,
                selected: _selectedBrandName == name,
                onTap: () {
                  setState(() => _selectedBrandName = name);
                  _searchController.text = name;
                  _performSearch(name);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const _ProductGridCardSkeleton(),
      );
    }

    if (!_hasSearched) return _buildEmptyPrompt();
    if (_searchResults.isEmpty) return _buildNoResults();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryVeryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '${_searchResults.length} kết quả',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FadeTransition(
            opacity: _resultsAnimController,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final product = _searchResults[index];
                return _ProductGridCard(
                  product: product,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(product: product),
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

  Widget _buildEmptyPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryVeryLight, Colors.white],
                ),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(
                Icons.search_rounded,
                size: 42,
                color: AppColors.primaryDark.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tìm sản phẩm yêu thích',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gõ tên sản phẩm hoặc\nchọn thương hiệu phía trên',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: AppColors.textSecondary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceLight,
                border: Border.all(color: AppColors.textLight.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.textLight.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không tìm thấy sản phẩm',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử từ khóa khác hoặc\nchọn thương hiệu gợi ý',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: AppColors.textSecondary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Brand Pill ───────────────────────────────────────────────────────────────

class _BrandPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BrandPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.textLight.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColors.primaryDark.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: selected ? 10 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class _BrandPillSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primaryVeryLight,
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}

// ─── Product Grid Card ────────────────────────────────────────────────────────

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductGridCard({required this.product, required this.onTap});

  String _formatPrice(double price) {
    final s = price.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = product.images.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  width: double.infinity,
                  color: AppColors.primaryVeryLight,
                  child: hasImage
                      ? Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.pets, size: 36, color: AppColors.primary),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.pets, size: 36, color: AppColors.primary),
                        ),
                ),
              ),
            ),

            // Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryVeryLight,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              product.brand.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatPrice(product.finalPrice),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _ProductGridCardSkeleton extends StatefulWidget {
  const _ProductGridCardSkeleton();

  @override
  State<_ProductGridCardSkeleton> createState() => _ProductGridCardSkeletonState();
}

class _ProductGridCardSkeletonState extends State<_ProductGridCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _shimmer {
    return Color.lerp(
      AppColors.primaryVeryLight,
      AppColors.primary.withValues(alpha: 0.2),
      _anim.value,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(color: _shimmer, width: double.infinity),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 13, width: double.infinity, decoration: BoxDecoration(color: _shimmer, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(height: 13, width: 80, decoration: BoxDecoration(color: _shimmer, borderRadius: BorderRadius.circular(4))),
                    const Spacer(),
                    Container(height: 18, width: 60, decoration: BoxDecoration(color: _shimmer, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 5),
                    Container(height: 14, width: 70, decoration: BoxDecoration(color: _shimmer, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
