import 'package:flutter/material.dart';
import 'package:mobile_app_haraj/screens/seleted_adtype_screen.dart';
import 'package:mobile_app_haraj/widgets/app_header.dart';
import '../models/ad_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/ad_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/featured_ads_slider.dart';
import '../widgets/latest_ads_slider.dart';
import 'ad_detail_screen.dart';
import 'home_screen.dart';

class CategoryScreen extends StatefulWidget {
  final Category? category;
  final int? categoryId;
  final String categoryName;
  final List<Ad>? ads;
  final List<String>? breadcrumbHistory;

  const CategoryScreen({
    super.key,
    this.category,
    this.categoryId,
    required this.categoryName,
    this.ads,
    this.breadcrumbHistory,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Ad> categoryAds = [];
  List<Ad> featuredAds = [];
  List<Ad> latestAds = [];
  List<Category> subCategories = [];
  List<Category> parentCategories = [];
  bool isLoading = true;
  int _currentIndex = 0;
  List<String> breadcrumbPath = ['الرئيسية'];

  // لتخزين معلومات الشاشات السابقة
  List<Map<String, dynamic>> breadcrumbNavigationStack = [];

  @override
  void initState() {
    super.initState();
    _initializeBreadcrumbPath();
    _loadCategoryData();
  }

  void _initializeBreadcrumbPath() {
    if (widget.breadcrumbHistory != null && widget.breadcrumbHistory!.isNotEmpty) {
      breadcrumbPath = List.from(widget.breadcrumbHistory!);
      // تأكد من عدم تكرار الاسم
      if (breadcrumbPath.isEmpty || breadcrumbPath.last != widget.categoryName) {
        breadcrumbPath.add(widget.categoryName);
      }
    } else {
      breadcrumbPath = ['الرئيسية', widget.categoryName];
    }

    // تهيئة الستاك للتنقل
    _initializeNavigationStack();
  }

  void _initializeNavigationStack() {
    // يمكنك هنا تحميل معلومات الشاشات السابقة من الـ breadcrumbPath
    // أو استخدام متغير منفصل لحفظ حالة التنقل
    breadcrumbNavigationStack = [];
  }

  Future<void> _loadCategoryData() async {
    setState(() => isLoading = true);

    try {
      if (widget.ads != null) {
        // إذا تم تمرير إعلانات مباشرة
        categoryAds = widget.ads!;
        featuredAds = categoryAds.where((ad) => ad.isFeatured).toList();
        latestAds = categoryAds.where((ad) => !ad.isFeatured).toList();
      } else if (widget.categoryId != null) {
        // جلب إعلانات القسم
        final ads = await ApiService.getAdsByCategory(widget.categoryId!);
        categoryAds = ads;
        featuredAds = ads.where((ad) => ad.isFeatured).toList();
        latestAds = ads.where((ad) => !ad.isFeatured).toList();

        // جلب الأقسام الفرعية
        if (widget.category != null) {
          subCategories = widget.category!.subCategories ?? [];
        } else {
          final category = await ApiService.getCategoryById(widget.categoryId!);
          if (category != null) {
            subCategories = category.subCategories ?? [];
          }
        }

        // جلب الأقسام الرئيسية إذا كان هناك قسم أب
        if (widget.category?.parentID != null) {
          final parentCategory = await ApiService.getCategoryById(widget.category!.parentID!);
          if (parentCategory != null && parentCategory.subCategories != null) {
            parentCategories = parentCategory.subCategories!
                .where((cat) => cat.categoryID != widget.categoryId)
                .toList();
          }
        }
      }
    } catch (e) {
      print('Error loading category data: $e');
    }

    setState(() => isLoading = false);
  }

  Widget _buildBreadcrumb() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // العنوان الحالي (آخر عنصر في المسار)
          Text(
            breadcrumbPath.isNotEmpty ? breadcrumbPath.last : widget.categoryName,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.darkColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),

          const SizedBox(height: 8),

          // المسار الكامل (Breadcrumb)
          Container(
            width: double.infinity,
            child: Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // بناء المسار من الأخير إلى الأول
                for (int i = breadcrumbPath.length - 1; i >= 0; i--)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // إضافة سهم للفصل بين العناصر (ما عدا الأول)
                      if (i != breadcrumbPath.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: AppColors.grayColor,
                          ),
                        ),

                      // العنصر النقر
                      GestureDetector(
                        onTap: () {
                          _handleBreadcrumbTap(i);
                        },
                        child: Text(
                          breadcrumbPath[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: i == breadcrumbPath.length - 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: i == breadcrumbPath.length - 1
                                ? AppColors.darkColor
                                : AppColors.primaryColor,
                            decoration: i < breadcrumbPath.length - 1
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),

                // أيقونة الرئيسية
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                          (route) => false,
                    );
                  },
                  child: const Icon(
                    Icons.home_outlined,
                    size: 18,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleBreadcrumbTap(int index) {
    if (index == 0) {
      // العودة للرئيسية
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
            (route) => false,
      );
    } else if (index < breadcrumbPath.length - 1) {
      // الذهاب للمستوى المطلوب مباشرة
      _navigateToBreadcrumbLevel(index);
    }
  }

  void _navigateToBreadcrumbLevel(int levelIndex) {
    // تحديد كم مرة يجب العودة
    int popCount = breadcrumbPath.length - 1 - levelIndex;

    // تحديث المسار
    if (levelIndex < breadcrumbPath.length) {
      breadcrumbPath = breadcrumbPath.sublist(0, levelIndex + 1);
    }

    // محاولة العودة للشاشة السابقة
    if (popCount > 0) {
      // إذا كان المستوى السابق هو الرئيسية
      if (levelIndex == 0) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
              (route) => false,
        );
      } else {
        // العودة للشاشة السابقة
        for (int i = 0; i < popCount && Navigator.of(context).canPop(); i++) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Widget _buildFeaturedAds() {
    if (featuredAds.isEmpty) return const SizedBox();

    return Column(
      children: [
        _buildSectionHeader(
          'إعلانات مميزة',
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryScreen(
                  categoryName: 'الإعلانات المميزة',
                  ads: featuredAds,
                  breadcrumbHistory: breadcrumbPath,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        FeaturedAdsSlider(ads: featuredAds),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildLatestAds() {
    if (latestAds.isEmpty) return const SizedBox();

    return Column(
      children: [
        _buildSectionHeader(
          'أحدث الإعلانات',
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryScreen(
                  categoryName: 'أحدث الإعلانات',
                  ads: latestAds,
                  breadcrumbHistory: breadcrumbPath,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        LatestAdsSlider(ads: latestAds),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onViewAll,
            child: Row(
              children: const [
                Icon(Icons.arrow_back_ios, size: 14, color: AppColors.secondaryColor),
                SizedBox(width: 5),
                Text(
                  'عرض الكل',
                  style: TextStyle(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentCategories() {
    if (parentCategories.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text(
            'الأقسام الرئيسية',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        Directionality(
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
            itemCount: parentCategories.length,
            itemBuilder: (context, index) {
              final category = parentCategories[index];
              return _buildCategoryCard(category, isParent: true);
            },
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSubCategories() {
    if (subCategories.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text(
            'الأقسام الفرعية',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        Directionality(
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
            itemCount: subCategories.length,
            itemBuilder: (context, index) {
              final category = subCategories[index];
              return _buildCategoryCard(category, isParent: false);
            },
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildCategoryCard(Category category, {bool isParent = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(
              category: category,
              categoryId: category.categoryID,
              categoryName: category.name,
              breadcrumbHistory: breadcrumbPath,
            ),
          ),
        );
      },
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // صورة القسم
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildCategoryImage(category),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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

  Widget _buildCategoryImage(Category category) {
    if (category.imageUrl.isEmpty || category.imageUrl == 'null') {
      return Container(
        color: AppColors.lightColor,
        child: const Center(
          child: Icon(
            Icons.category,
            size: 40,
            color: AppColors.grayColor,
          ),
        ),
      );
    }

    String imageUrl = category.imageUrl;

    // معالجة مسار الصورة
    if (imageUrl.contains('categories/')) {
      imageUrl = imageUrl.replaceAll('\\', '/').trim();

      if (imageUrl.startsWith('/')) {
        imageUrl = '${ApiConfig.baseUrl}$imageUrl';
      } else if (imageUrl.startsWith('categories/')) {
        imageUrl = '${ApiConfig.baseUrl}/Images/$imageUrl';
      } else if (!imageUrl.startsWith('http')) {
        if (!imageUrl.contains('categories/')) {
          imageUrl = '${ApiConfig.baseUrl}/Images/categories/$imageUrl';
        } else {
          imageUrl = '${ApiConfig.baseUrl}/$imageUrl';
        }
      }
    } else {
      imageUrl = '${ApiConfig.baseUrl}/Images/categories/$imageUrl';
    }

    imageUrl = imageUrl.replaceAll(' ', '%20');

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColors.lightColor,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: AppColors.primaryColor,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.lightColor,
          child: const Center(
            child: Icon(
              Icons.category,
              size: 40,
              color: AppColors.grayColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllAdsGrid() {
    if (categoryAds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.image_search,
                size: 80,
                color: AppColors.grayColor,
              ),
              SizedBox(height: 20),
              Text(
                'لا توجد إعلانات',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.grayColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.85,
        ),
        itemCount: categoryAds.length,
        itemBuilder: (context, index) {
          final ad = categoryAds[index];
          return AdCard(ad: ad);
        },
      ),
    );
  }

  void _checkLoginAndNavigateToAddAd() async {
    final isLoggedIn = await AuthService.isLoggedIn();

    if (!isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    final userProfile = await AuthService.fetchUserProfile();

    if (userProfile == null) {
      _showErrorDialog('فشل في تحميل بيانات المستخدم');
      return;
    }

    final selectedType = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectAdTypeScreen(
          categoryId: '0',
        ),
      ),
    );

    if (selectedType != null && selectedType is String) {
      _handleAdTypeSelection(selectedType, userProfile);
    }
  }

  void _handleAdTypeSelection(String adType, Map<String, dynamic> userProfile) {
    Navigator.pushNamed(
      context,
      '/add-ad',
      arguments: {
        'adType': adType,
        'userProfile': userProfile,
      },
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تسجيل الدخول مطلوب',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'يرجى تسجيل الدخول أولاً لإضافة إعلان',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('تسجيل الدخول'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'خطأ',
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == 2) {
      _checkLoginAndNavigateToAddAd();
    } else {
      setState(() => _currentIndex = index);
    }
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, '/favorites', (route) => false);
        break;
      case 2:
        Navigator.pushNamed(context, '/add-ad');
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(context, '/my-ads', (route) => false);
        break;
      case 4:
        Navigator.pushNamedAndRemoveUntil(context, '/settings', (route) => false);
        break;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Breadcrumb Path
            _buildBreadcrumb(),
            const SizedBox(height: 10),

            // === التعديل هنا: تغيير منطق العرض ===
            if (widget.ads == null) ...[
              // الحالة العادية (لديك قسم محدد)
              // الإعلانات المميزة
              _buildFeaturedAds(),

              // الأقسام الرئيسية (إذا كانت موجودة)
              _buildParentCategories(),

              // الأقسام الفرعية
              _buildSubCategories(),

              // أحدث الإعلانات
              _buildLatestAds(),
            ] else ...[
              // الحالة: عرض الكل (widget.ads != null)
              // عرض grid جميع الإعلانات مباشرة
              _buildAllAdsGrid(),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}