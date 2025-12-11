import 'package:flutter/material.dart';
import 'package:mobile_app_haraj/screens/seleted_adtype_screen.dart';
import '../models/ad_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/app_header.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/featured_ads_slider.dart';
import '../widgets/categories_grid.dart';
import '../widgets/latest_ads_slider.dart';
import '../widgets/bottom_nav_bar.dart';
import 'ad_detail_screen.dart';
import 'favorites_screen.dart';
import 'my_ads_screen.dart';
import 'settings_screen.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Ad> featuredAds = [];
  List<Ad> latestAds = [];
  List<Category> categories = [];
  bool isLoading = true;
  String searchTerm = '';
  double? priceFrom;
  double? priceTo;
  String? adTypeFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final results = await Future.wait([
      ApiService.getFeaturedAds(),
      ApiService.getRegularAds(),
      ApiService.getCategories(),
    ]);

    setState(() {
      featuredAds = results[0] as List<Ad>;
      latestAds = results[1] as List<Ad>;
      categories = results[2] as List<Category>;
      isLoading = false;
    });
  }

  void _applyFilters({
    String? search,
    double? fromPrice,
    double? toPrice,
    String? type,
  }) {
    setState(() {
      searchTerm = search ?? searchTerm;
      priceFrom = fromPrice ?? priceFrom;
      priceTo = toPrice ?? priceTo;
      adTypeFilter = type ?? adTypeFilter;
    });
  }

  void _resetFilters() {
    setState(() {
      searchTerm = '';
      priceFrom = null;
      priceTo = null;
      adTypeFilter = null;
    });
  }

  List<Ad> _getFilteredAds(List<Ad> ads) {
    return ads.where((ad) {
      bool matchesSearch = searchTerm.isEmpty ||
          ad.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
          ad.description.toLowerCase().contains(searchTerm.toLowerCase());

      bool matchesPrice = (priceFrom == null || ad.price >= priceFrom!) &&
          (priceTo == null || ad.price <= priceTo!);

      bool matchesType = adTypeFilter == null ||
          (adTypeFilter == 'مميز' && ad.isFeatured) ||
          (adTypeFilter == 'عادي' && !ad.isFeatured);

      return matchesSearch && matchesPrice && matchesType;
    }).toList();
  }

  Widget _buildHomeContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      );
    }

    final filteredFeaturedAds = _getFilteredAds(featuredAds);
    final filteredLatestAds = _getFilteredAds(latestAds);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [

            SearchBarWidget(
              onSearch: (term) => _applyFilters(search: term),
              onFilterApplied: ({fromPrice, toPrice, type}) {
                _applyFilters(
                  fromPrice: fromPrice,
                  toPrice: toPrice,
                  type: type,
                );
              },
              onResetFilters: _resetFilters,
            ),
            const SizedBox(height: 20),

            if (filteredFeaturedAds.isNotEmpty) ...[
              _buildSectionHeader(
                'إعلانات مميزة',
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryScreen(
                        categoryName: 'جميع الاقسام',
                        ads: filteredFeaturedAds,
                      ),
                    ),
                  );
                },
              ),
              FeaturedAdsSlider(ads: filteredFeaturedAds),
              const SizedBox(height: 30),
            ],

            if (categories.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'الأقسام',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              CategoriesGrid(
                categories: categories,
                onCategoryTap: (category) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryScreen(
                        category: category,
                        categoryId: category.categoryID,
                        categoryName: category.name,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],

            if (filteredLatestAds.isNotEmpty) ...[
              _buildSectionHeader(
                'أحدث الإعلانات',
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryScreen(
                        categoryName: 'أحدث الإعلانات',
                        ads: filteredLatestAds,
                      ),
                    ),
                  );
                },
              ),
              LatestAdsSlider(ads: filteredLatestAds),
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsetsGeometry.fromLTRB(15, 15, 15, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onViewAll,
            child: Row(
              children: const [

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

  void _showAddAdDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'إضافة إعلان',
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
  void _checkLoginAndNavigateToAddAd() async {
    // التحقق من حالة تسجيل الدخول أولاً
    final isLoggedIn = await AuthService.isLoggedIn();

    if (!isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    // جلب بيانات المستخدم من الـ API
    final userProfile = await AuthService.fetchUserProfile();

    if (userProfile == null) {
      _showErrorDialog('فشل في تحميل بيانات المستخدم');
      return;
    }

    // استخراج بيانات الحصص المتاحة
    final availableNormalSlots = userProfile['availableNormalSlots'] ?? 0;
    final availablePrimeSlots = userProfile['availablePrimeSlots'] ?? 0;

    // فتح صفحة تحديد نوع الإعلان
    final selectedType = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectAdTypeScreen(
          categoryId: '0', // يمكنك تمرير categoryId مناسب
        ),
      ),
    );

    // إذا كان هناك نوع مختار
    if (selectedType != null && selectedType is String) {
      _handleAdTypeSelection(selectedType, userProfile);
    }
  }

  void _handleAdTypeSelection(String adType, Map<String, dynamic> userProfile) {
    print('تم اختيار نوع الإعلان: $adType');

    // يمكنك الآن:
    // 1. تنفيذ الإجراء المناسب بناءً على نوع الإعلان
    // 2. فتح شاشة إضافة الإعلان مع تحديد النوع
    // 3. أي عملية أخرى تحتاجها

    // مثال: فتح شاشة إضافة الإعلان مع نوع محدد
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
    if (index == 2) { // زر إضافة إعلان
      // التحقق من تسجيل الدخول أولاً
      _checkLoginAndNavigateToAddAd();
    } else {
      setState(() => _currentIndex = index);
    }
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    // التنقل بين الصفحات حسب الفهرس
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
      appBar:  AppHeader(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          const FavoritesScreen(),
          Container(),
          const MyAdsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}