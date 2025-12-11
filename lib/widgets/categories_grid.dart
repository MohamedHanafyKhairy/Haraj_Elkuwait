import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../utils/constants.dart';

class CategoriesGrid extends StatelessWidget {
  final List<Category> categories;
  final Function(Category)? onCategoryTap;

  const CategoriesGrid({
    super.key,
    required this.categories,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    // تم إضافة Directionality هنا لعكس اتجاه العناصر ليكون من اليمين لليسار
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.85,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(context, category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category) {
    return GestureDetector(
      onTap: onCategoryTap != null
          ? () => onCategoryTap!(category)
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: category.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: category.imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: AppColors.lightColor,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.lightColor,
                    child: const Icon(
                      Icons.category,
                      size: 40,
                      color: AppColors.grayColor,
                    ),
                  ),
                )
                    : Container(
                  color: AppColors.lightColor,
                  child: const Icon(
                    Icons.category,
                    size: 40,
                    color: AppColors.grayColor,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}