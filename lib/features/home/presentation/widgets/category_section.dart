import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/animated_grid_item.dart';
import '../../../../core/widgets/animated_section.dart';
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
        child: AnimatedSection(
          delay: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonText(width: 100, height: 22),
                    SkeletonText(width: 70, height: 14),
                  ],
                ),
                const SizedBox(height: 16),
                // Category circle skeleton
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: index == 7 ? 0 : 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SkeletonCircle(size: 56),
                            const SizedBox(height: 6),
                            SkeletonText(width: 56, height: 10),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.categories.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: AnimatedSection(
        delay: const Duration(milliseconds: 300),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Danh mục', onSeeAll: () {}),
              const SizedBox(height: 12),
              // Horizontal scroll với hình tròn nhỏ
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.categories.length,
                  itemBuilder: (context, index) {
                    final category = widget.categories[index];
                    final isSelected = _selectedCategoryIndex == index;
                    final iconData = CategoryIconMapper.getCategoryIcon(
                      category.name,
                    );

                    return AnimatedGridItem(
                      delay: Duration(milliseconds: 50 + (index * 30)),
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == widget.categories.length - 1 ? 0 : 12,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                          },
                          child: CategoryCircleItem(
                            category: category,
                            isSelected: isSelected,
                            iconData: iconData,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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
            color: isSelected ? AppColors.primary : AppColors.primaryVeryLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
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
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
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

class CategoryGridItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final Map<String, dynamic> iconData;

  CategoryGridItem({
    super.key,
    required this.category,
    required this.isSelected,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.primaryLight.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primaryVeryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData['icon'] as IconData,
              color: isSelected ? Colors.white : AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              category.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryCircleItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final Map<String, dynamic> iconData;

  CategoryCircleItem({
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
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.primaryVeryLight,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 2)
                : Border.all(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    width: 1,
                  ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            iconData['icon'] as IconData,
            color: isSelected ? Colors.white : AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 56,
          child: Text(
            category.name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
