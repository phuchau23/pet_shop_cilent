import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../categories/domain/entities/category.dart';

class CategorySection extends StatefulWidget {
  final List<Category> categories;
  final bool isLoading;

  const CategorySection({
    super.key,
    required this.categories,
    required this.isLoading,
  });

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.categories.isEmpty) {
    return SliverToBoxAdapter(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                'Danh mục',
                  style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2,
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    ),
                  ),
                ),
              ],
            ),
        ),
      );
    }

    if (widget.categories.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Danh mục',
              onSeeAll: () {},
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.categories.length,
                      itemBuilder: (context, index) {
                        final category = widget.categories[index];
                        final isSelected = _selectedCategoryIndex == index;
                        final iconData = CategoryIconMapper.getCategoryIcon(
                          category.name,
                        );

                        return Padding(
                    padding: EdgeInsets.only(
                      right: index == widget.categories.length - 1 ? 0 : 16,
                    ),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryIndex = index;
                              });
                            },
                            child: CategoryItem(
                              category: category,
                              isSelected: isSelected,
                              iconData: iconData,
                            ),
                          ),
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

class CategoryItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final Map<String, dynamic> iconData;

  CategoryItem({
    super.key,
    required this.category,
    required this.isSelected,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.primaryVeryLight.withOpacity(0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.transparent,
              width: 0,
            ),
          ),
          child: Icon(
            iconData['icon'] as IconData,
            color: isSelected ? Colors.white : AppColors.primary,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 72,
          child: Text(
            category.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
