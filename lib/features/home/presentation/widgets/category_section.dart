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
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            widget.isLoading
                ? const SizedBox(
                    height: 110,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.categories.length,
                      itemBuilder: (context, index) {
                        final category = widget.categories[index];
                        final isSelected = _selectedCategoryIndex == index;
                        // Dùng CategoryIconMapper để lấy icon và color dựa trên name
                        final iconData = CategoryIconMapper.getCategoryIcon(
                          category.name,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
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

class CategoryItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final Map<String, dynamic> iconData;

  const CategoryItem({
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
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Icon(
            iconData['icon'] as IconData,
            color: isSelected ? Colors.white : AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 80,
          height: 32,
          child: Text(
            category.description ?? '',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
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
