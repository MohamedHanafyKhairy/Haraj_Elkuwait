import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/ad_model.dart';
import '../utils/constants.dart';
import '../screens/ad_detail_screen.dart';

class AdCard extends StatelessWidget {
  final Ad ad;
  final double? width;
  final bool isGridItem;

  const AdCard({
    super.key,
    required this.ad,
    this.width,
    this.isGridItem = false,
  });

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'الآن';
    if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} دقيقة';
    if (difference.inHours < 24) return 'منذ ${difference.inHours} ساعة';
    if (difference.inDays < 7) return 'منذ ${difference.inDays} يوم';
    if (difference.inDays < 30) return 'منذ ${(difference.inDays / 7).floor()} أسبوع';
    if (difference.inDays < 365) return 'منذ ${(difference.inDays / 30).floor()} شهر';
    return 'منذ أكثر من سنة';
  }

  @override
  Widget build(BuildContext context) {
    // حساب ارتفاع الصورة بناءً على isGridItem أو width
    double imageHeight;

    if (isGridItem) {
      // ارتفاع ثابت للشبكات
      imageHeight = 160;
    } else if (width != null) {
      // نسبي للسلايدر إذا كان width محدد
      imageHeight = width! * 0.80; // نسبة ارتفاع 3:4 (العرض × 0.75)
    } else {
      // قيمة افتراضية
      imageHeight = 180;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdDetailScreen(ad: ad),
          ),
        );
      },
      child: Container(
        width: width,
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
          border: ad.isFeatured
              ? Border.all(color: AppColors.featuredBadge, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: ad.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: ad.imageUrl,
                    height: imageHeight,
                    width: width ?? double.infinity,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      height: imageHeight,
                      width: width ?? double.infinity,
                      color: AppColors.lightColor,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: imageHeight,
                      width: width ?? double.infinity,
                      color: AppColors.lightColor,
                      child: const Icon(
                        Icons.broken_image,
                        size: 48,
                        color: AppColors.grayColor,
                      ),
                    ),
                  )
                      : Container(
                    height: imageHeight,
                    width: width ?? double.infinity,
                    color: AppColors.lightColor,
                    child: const Icon(
                      Icons.image,
                      size: 48,
                      color: AppColors.grayColor,
                    ),
                  ),
                ),
                if (ad.isFeatured)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.featuredBadge,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'مميز',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // العنوان مع توسيط عمودي ومسافة ثابتة
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.topRight,
                        child: Text(
                          ad.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),

                    // مساحة ثابتة بين العنوان والسعر والتاريخ
                    const SizedBox(height: 8),

                    // السعر والتاريخ في صف ثابت في الأسفل
                    Container(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${ad.price.toStringAsFixed(0)} ${AppStrings.kwd}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              _getTimeAgo(ad.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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