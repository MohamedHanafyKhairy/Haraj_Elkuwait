import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_app_haraj/widgets/app_header.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'add_ad_screen.dart';
import 'home_screen.dart'; // إضافة الاستيراد

class SelectAdTypeScreen extends StatefulWidget {
  final String categoryId;

  const SelectAdTypeScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<SelectAdTypeScreen> createState() => _SelectAdTypeScreenState();
}

class _SelectAdTypeScreenState extends State<SelectAdTypeScreen> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  int availableNormalSlots = 0;
  int availablePrimeSlots = 0;
  int usedNormalSlots = 0;
  int usedPrimeSlots = 0;
  int maxNormalSlots = 5;
  int maxPrimeSlots = 2;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        isLoading = true;
      });

      final profile = await AuthService.fetchUserProfile();

      if (profile != null && mounted) {
        setState(() {
          userProfile = profile;

          // استخراج بيانات الحصص من الاستجابة
          availableNormalSlots = profile['availableNormalSlots'] ?? 0;
          availablePrimeSlots = profile['availablePrimeSlots'] ?? 0;
          usedNormalSlots = profile['usedNormalSlots'] ?? 0;
          usedPrimeSlots = profile['usedPrimeSlots'] ?? 0;
          maxNormalSlots = profile['maxNormalSlots'] ?? 5;
          maxPrimeSlots = profile['maxPrimeSlots'] ?? 2;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');

      // استخدام القيم الافتراضية في حالة الخطأ
      if (mounted) {
        setState(() {
          availableNormalSlots = 5;
          availablePrimeSlots = 2;
          usedNormalSlots = 0;
          usedPrimeSlots = 0;
          maxNormalSlots = 5;
          maxPrimeSlots = 2;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // دالة للانتقال إلى صفحة إنشاء الإعلان
  void _navigateToAddAdScreen(String adType) {
    if (userProfile == null) {
      _showErrorDialog('يرجى تسجيل الدخول أولاً');
      return;
    }

    // من المكان الذي تستدعي منه الشاشة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAdScreen(adType: adType, userProfile: userProfile!)
      ),
    );
  }

  // دالة لعرض خطأ
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xffffffff),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // كلمة "العودة للرئيسية" على اليسار (البداية)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(),));
                        },
                        child: const Row(
                          children: [
                            const Text(
                              'العودة للرئيسية',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // كلمة "إعلاناتي" على اليمين (النهاية)
                      const Text(
                        'أضافه اعلان',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10,),
                  // العنوان الرئيسي
                  Text(
                    'اختر نوع إعلانك',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ملخص الحصص المتاحة
                  if (!isLoading)

                    const SizedBox(height: 20),

                  // بطاقة الإعلان العادي
                  isLoading
                      ? _buildLoadingCard()
                      : GestureDetector(
                    onTap: () {
                      if (availableNormalSlots > 0) {
                        _navigateToAddAdScreen('عادي');
                      } else {
                        _showNoSlotsDialog('العادي');
                      }
                    },
                    child: _buildAdCard(
                      title: 'إعلان عادي',
                      price: 'مجاني',
                      timeAgo: 'مدة 30 يوم',
                      isFeatured: false,
                      availableSlots: availableNormalSlots,
                      maxSlots: maxNormalSlots,
                      usedSlots: usedNormalSlots,
                      imageUrl:
                      'https://via.placeholder.com/400x200?text=إعلان+عادي',
                    ),
                  ),
                  const SizedBox(height: 25),

                  // بطاقة الإعلان المميز
                  isLoading
                      ? _buildLoadingCard()
                      : GestureDetector(
                    onTap: () {
                      if (availablePrimeSlots > 0) {
                        _navigateToAddAdScreen('مميز');
                      } else {
                        _showNoSlotsDialog('المميز');
                      }
                    },
                    child: _buildAdCard(
                      title: 'إعلان مميز',
                      price: 'مجاني',
                      timeAgo: 'مدة 30 يوم',
                      isFeatured: true,
                      availableSlots: availablePrimeSlots,
                      maxSlots: maxPrimeSlots,
                      usedSlots: usedPrimeSlots,
                      imageUrl:
                      'https://via.placeholder.com/400x200?text=إعلان+مميز',
                    ),
                  ),
                  const SizedBox(height: 40),

                  // زر الإلغاء
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.grayColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuotaItem(String label, int available, int max, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$available / $max',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'متاحة',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grayColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard({
    required String title,
    required String price,
    required String timeAgo,
    required bool isFeatured,
    required int availableSlots,
    required int maxSlots,
    required int usedSlots,
    required String imageUrl,
  }) {
    double imageHeight = 200;

    return Container(
      width: double.infinity,
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
        border: isFeatured
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
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: imageHeight,
                    width: double.infinity,
                    color: AppColors.lightColor,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: imageHeight,
                    width: double.infinity,
                    color: AppColors.lightColor,
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: AppColors.grayColor,
                    ),
                  ),
                ),
              ),

              // Badge مميز
              if (isFeatured)
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // العنوان
                Container(
                  width: double.infinity,
                  alignment: Alignment.topRight,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(height: 8),

                // النص التوضيحي
                Container(
                  width: double.infinity,
                  alignment: Alignment.topRight,
                  child: Text(
                    'يتم وضع عنوان الإعلان هنا',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grayColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(height: 12),

                // السعر والتاريخ
                Container(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          price,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          timeAgo,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // عدد الإعلانات المتاحة
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: availableSlots > 0
                        ? AppColors.lightColor
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: availableSlots > 0
                          ? AppColors.grayColor.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        availableSlots > 0 ? Icons.check_circle : Icons.info,
                        color:
                        availableSlots > 0 ? Colors.green : Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          availableSlots > 0
                              ? 'لديك $availableSlots إعلان${availableSlots > 1 ? 'ات' : ''} متاحة ${isFeatured ? 'مميزة' : 'عادية'}'
                              : 'لقد نفذت إعلاناتك ${isFeatured ? 'المميزة' : 'العادية'}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: availableSlots > 0
                                ? AppColors.grayColor
                                : Colors.orange,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
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
        children: [
          // Loading placeholder for image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.lightColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            ),
          ),
          // Loading placeholder for content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  height: 20,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.lightColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 15,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.lightColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 30,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.lightColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNoSlotsDialog(String adType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'لا توجد أماكن متاحة',
          style: TextStyle(color: AppColors.featuredBadge),
        ),
        content: Text('لقد نفذت إعلاناتك من النوع $adType'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً',
                style: TextStyle(color: AppColors.primaryColor)),
          ),
        ],
      ),
    );
  }
}