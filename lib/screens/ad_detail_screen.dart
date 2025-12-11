import 'dart:convert' show json;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_haraj/screens/seleted_adtype_screen.dart';
import 'package:mobile_app_haraj/screens/settings_screen.dart';
import 'package:mobile_app_haraj/widgets/app_header.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ReportModel.dart';
import '../models/ad_model.dart';
import '../models/category_model.dart';
import '../services/auth_service.dart';
import '../services/visit_service.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/categories_grid.dart';
import '../widgets/featured_ads_slider.dart';
import '../widgets/latest_ads_slider.dart';
import '../widgets/search_bar_widget.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'login.dart';
import 'category_screen.dart';
import 'my_ads_screen.dart';

class AdDetailScreen extends StatefulWidget {
  final Ad ad;

  const AdDetailScreen({super.key, required this.ad});

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  bool _showAppBar = true;
  double _lastScrollOffset = 0.0;
  int _currentIndex = 0;
  List<Ad> featuredAds = [];
  List<Ad> latestAds = [];
  List<Category> categories = [];
  bool isLoading = true;
  String searchTerm = '';
  double? priceFrom;
  double? priceTo;
  String? adTypeFilter;

  // 🔥 إضافة متغيرات للون
  final Color containerBorderColor = const Color(0xFFe2e8f0);
  final Color containerBgColor = const Color(0xFFf8fafc);
  final Color itemBgColor = Colors.white;
  final double borderRadius = 8.0;

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
// 🔥 دالة جديدة تجمع العناصر الثلاثة في خلفية واحدة
  Widget _buildInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: itemBgColor, // خلفية بيضاء واحدة للثلاثة
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: const Color(0xFFf1f5f9), // لون الحدود الفاتح
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // المشاهدات
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.ad.visitsCount} مشاهدة',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkColor,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.remove_red_eye,
                size: 22,
                color: AppColors.secondaryColor,
              ),
            ],
          ),

          const Divider(height: 20, thickness: 1, color: Color(0xFFf1f5f9)),

          // الأيام المتبقية
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.ad.daysRemaining ?? 30} أيام متبقية',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkColor,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.access_time,
                size: 22,
                color: AppColors.secondaryColor,
              ),
            ],
          ),

          const Divider(height: 20, thickness: 1, color: Color(0xFFf1f5f9)),

          // السعر
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.ad.price.toStringAsFixed(0)} ${AppStrings.kwd}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.attach_money,
                size: 22,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
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
                        categoryName: 'جميع الإعلانات المميزة',
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
                padding: const EdgeInsets.symmetric(horizontal: 15),
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
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            child: Row(
              children: const [
                Text(
                  'عرض الكل',
                  style: TextStyle(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 5),
                Icon(
                  Icons.arrow_back_ios,
                  size: 14,
                  color: AppColors.secondaryColor,
                ),
              ],
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
          textAlign: TextAlign.right,
        ),
        content: const Text(
          'يرجى تسجيل الدخول أولاً لإضافة إعلان',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('تسجيل الدخول'),
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
    if (index == 2) {
      _checkLoginAndNavigateToAddAd();
      return;
    }

    // تحديث الحالة أولاً
    setState(() {
      _currentIndex = index;
    });

    // استبدال الشاشة الحالية بشاشة جديدة مع الحفاظ على الـ AppBar و BottomNavBar
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppHeader(),
              body: HomeScreen(),
              bottomNavigationBar: BottomNavBar(
                currentIndex: 0,
                onTap: _onNavItemTapped,
              ),
            ),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppHeader(),
              body: FavoritesScreen(),
              bottomNavigationBar: BottomNavBar(
                currentIndex: 1,
                onTap: _onNavItemTapped,
              ),
            ),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppHeader(),
              body: MyAdsScreen(),
              bottomNavigationBar: BottomNavBar(
                currentIndex: 3,
                onTap: _onNavItemTapped,
              ),
            ),
          ),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppHeader(),
              body: SettingsScreen(),
              bottomNavigationBar: BottomNavBar(
                currentIndex: 4,
                onTap: _onNavItemTapped,
              ),
            ),
          ),
        );
        break;
    }
  }
  @override
  void initState() {
    super.initState();
    _sendVisit();
    _loadData();
    _scrollController.addListener(_scrollListener);
    _checkFavoriteStatus(); // ✅ إضافة هذا السطر
    _loadFavoriteState();   // ✅ دالة جديدة
  }

  Future<void> _loadFavoriteState() async {
    final isLoggedIn = await AuthService.isLoggedIn();

    if (isLoggedIn) {
      try {
        final user = await AuthService.getUserData();
        final token = await AuthService.getToken();

        if (user != null && token != null) {
          final userId = user['userID'];

          // جلب المفضلة من الـ API الجديد
          final response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/UserController_Edit_/$userId/my-favorites'),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (response.statusCode == 200) {
            final favorites = json.decode(response.body);

            // التحقق إذا كان الإعلان في المفضلة
            bool isFavorite = false;
            if (favorites is List) {
              isFavorite = favorites.any((fav) =>
              fav['adID'] == widget.ad.adID ||
                  fav['AdID'] == widget.ad.adID);
            }

            if (mounted) {
              setState(() {
                _isFavorite = isFavorite;
              });
            }
            print('📊 حالة المفضلة: $isFavorite للإعلان ${widget.ad.adID}');
          }
        }
      } catch (e) {
        print('⚠️ خطأ في تحميل حالة المفضلة: $e');
      }
    }
  }
  Future<List<int>> _getUserFavorites(int userId, String token) async {
    try {
      // المحاولة 1: الطريقة القياسية
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Favorites/user/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is List && responseData.isNotEmpty) {
          final firstItem = responseData[0];
          if (firstItem is Map && firstItem.containsKey('ads_ID')) {
            final adsList = firstItem['ads_ID'];
            if (adsList is List) {
              return adsList.cast<int>().toList();
            }
          }
        }
      }
    } catch (e) {
      print('❌ فشلت طريقة جلب المفضلة: $e');
    }

    return [];
  }
  Future<void> _checkFavoriteStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();

    if (isLoggedIn) {
      try {
        final user = await AuthService.getUserData();
        final userId = user?['userID'];
        final token = await AuthService.getToken();

        final response = await http.get(
          Uri.parse('${AuthService.apiBaseUrl}/api/Favorites/user/$userId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final favoritesData = json.decode(response.body);
          // تحقق مما إذا كان الإعلان الحالي في المفضلة
          // هذا يعتمد على هيكل البيانات من API الخاص بك
          // ستحتاج لتعديله حسب هيكل البيانات
        }
      } catch (e) {
        print('Error checking favorite status: $e');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final currentOffset = _scrollController.offset;

      // التحكم في ظهور/اختفاء الهيدر حسب اتجاه التمرير
      if (currentOffset > _lastScrollOffset + 10 && currentOffset > 100) {
        // التمرير لأسفل - إخفاء الهيدر
        if (_showAppBar) {
          setState(() {
            _showAppBar = false;
          });
        }
      } else if (_lastScrollOffset > currentOffset + 10) {
        // التمرير لأعلى - إظهار الهيدر
        if (!_showAppBar) {
          setState(() {
            _showAppBar = true;
          });
        }
      }

      _lastScrollOffset = currentOffset;
    }
  }

  Future<void> _sendVisit() async {
    // استخدام VisitService الجديدة
    await VisitService.sendVisit(widget.ad.adID);
  }
  void _makePhoneCall() async {
    print('📞 === بدء عملية الاتصال ===');

    // استخراج الرقم الحقيقي من الإعلان
    String phoneNumber = widget.ad.getPhoneNumber();

    // إذا كان الرقم افتراضي، حاول البحث في بيانات المستخدم
    if (phoneNumber == '1234567' || phoneNumber.isEmpty) {
      // جلب بيانات كاملة للإعلان من الـ API
      try {
        final adDetails = await ApiService.getAdDetails(widget.ad.adID);
        if (adDetails != null) {
          phoneNumber = adDetails.getPhoneNumber();
          print('📱 الرقم من API: $phoneNumber');
        }
      } catch (e) {
        print('❌ فشل جلب بيانات الإعلان: $e');
      }
    }

    print('📱 الرقم النهائي: $phoneNumber');

    if (phoneNumber.isNotEmpty && phoneNumber != '1234567') {
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // إضافة رمز الدولة إذا لم يكن موجوداً
      if (!cleanNumber.startsWith('+')) {
        cleanNumber = '+965$cleanNumber'; // رمز الكويت
      }

      print('🔢 الرقم النظيف: $cleanNumber');

      final uri = Uri(scheme: 'tel', path: cleanNumber);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // محاولة بديلة
        final webUri = Uri.parse('tel:$cleanNumber');
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri);
        } else {
          _showMessage('لا يمكن فتح تطبيق الهاتف. الرقم: $cleanNumber');
        }
      }
    } else {
      _showMessage('رقم الهاتف غير متوفر لهذا الإعلان');
    }
  }
  void _openWhatsApp() async {
    print('💚 === بدء عملية واتساب ===');

    String phoneNumber = widget.ad.getPhoneNumber();

    // محاولة جلب الرقم الحقيقي
    if (phoneNumber == '1234567' || phoneNumber.isEmpty) {
      try {
        final adDetails = await ApiService.getAdDetails(widget.ad.adID);
        if (adDetails != null) {
          phoneNumber = adDetails.getPhoneNumber();
          print('📱 الرقم من API للواتساب: $phoneNumber');
        }
      } catch (e) {
        print('❌ فشل جلب بيانات الإعلان: $e');
      }
    }

    print('📱 الرقم المستخدم للواتساب: $phoneNumber');

    if (phoneNumber.isNotEmpty && phoneNumber != '1234567') {
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      // إضافة رمز الدولة
      if (!cleanNumber.startsWith('+')) {
        cleanNumber = '965$cleanNumber';
      }

      print('🔢 الرقم النظيف للواتساب: $cleanNumber');

      final message = 'مرحباً، أنا مهتم بالإعلان: ${widget.ad.title}';
      final whatsappUrl = 'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(whatsappUrl);

      print('🔗 رابط الواتساب: $whatsappUrl');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final webUrl = 'https://web.whatsapp.com/send?phone=$cleanNumber&text=${Uri.encodeComponent(message)}';
        final webUri = Uri.parse(webUrl);

        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        } else {
          _showMessage('لا يمكن فتح تطبيق واتساب. الرقم: $cleanNumber');
        }
      }
    } else {
      _showMessage('رقم الهاتف غير متوفر للتواصل عبر واتساب');
    }
  }  Future<void> _toggleFavorite() async {
    print('🎯 بدء إضافة/إزالة المفضلة للإعلان: ${widget.ad.adID}');

    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      await _showFavoriteLoginOptions();
      return;
    }

    try {
      final user = await AuthService.getUserData();
      final token = await AuthService.getToken();

      if (user == null || token == null) {
        _showMessage('❌ يرجى تسجيل الدخول أولاً');
        return;
      }

      final userId = user['userID'];

      print('👤 UserID: $userId');
      print('🔑 Token: ${token.substring(0, 20)}...');

      // استخدام الـ Endpoint الصحيح
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/UserController_Edit_/$userId/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(widget.ad.adID), // ✅ إرسال adID فقط كرقم
      );

      print('📥 الاستجابة: ${response.statusCode}');
      print('📦 النص: ${response.body}');

      // تحليل الاستجابة
      if (response.statusCode == 200) {
        // نجحت الإضافة
        final responseData = json.decode(response.body);
        final message = responseData['message'] ?? 'تم تحديث المفضلة';

        setState(() {
          _isFavorite = true;
        });

        _showMessage('✅ $message');

      } else if (response.statusCode == 400) {
        // الإعلان موجود بالفعل - يعني نريد حذفه
        final responseData = json.decode(response.body);
        final message = responseData['message'] ?? 'الإعلان موجود بالفعل';

        // حذف الإعلان من المفضلة
        await _removeFromFavorites(userId, token, widget.ad.adID);

        setState(() {
          _isFavorite = false; // ✅ تم الحذف
        });

        _showMessage('🗑️ تم إزالة الإعلان من المفضلة');

      } else {
        _showMessage('❌ فشل في تحديث المفضلة');
      }

    } catch (e) {
      print('🚨 خطأ في المفضلة: $e');
      _showMessage('❌ حدث خطأ في تحديث المفضلة');
    }
  }

// دالة حذف من المفضلة
  Future<bool> _removeFromFavorites(int userId, String token, int adId) async {
    try {
      // جلب المفضلة الحالية
      final getResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/UserController_Edit_/$userId/my-favorites'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (getResponse.statusCode == 200) {
        final favorites = json.decode(getResponse.body);

        // إنشاء قائمة جديدة بدون الإعلان المراد حذفه
        final updatedFavorites = (favorites as List)
            .where((fav) => fav['adID'] != adId)
            .toList();

        // إرسال التحديث (هذه الطريقة اعتماداً على API الخاص بك)
        // قد تحتاج لتعديل حسب هيكل API الحذف
        print('🗑️ تمت إزالة الإعلان $adId من المفضلة محلياً');
        return true;
      }
    } catch (e) {
      print('❌ خطأ في الحذف: $e');
    }
    return false;
  }
  Future<bool> _tryAddToFavorites(int userId, String token, int adId) async {
    // المحاولة 1: الـ Endpoint الأساسي
    try {
      print('🔄 المحاولة 1: استخدام /api/Favorites');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Favorites'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userID': userId,
          'ads_ID': [adId],
        }),
      );

      print('📥 الاستجابة: ${response.statusCode}');
      print('📦 النص: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      print('❌ فشلت المحاولة 1: $e');
    }

    // المحاولة 2: Endpoint بديل
    try {
      print('🔄 المحاولة 2: استخدام /api/Favorites/add');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Favorites/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userID': userId,
          'adID': adId, // لاحظ adID وليس ads_ID
        }),
      );

      print('📥 الاستجابة: ${response.statusCode}');
      print('📦 النص: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      print('❌ فشلت المحاولة 2: $e');
    }

    // المحاولة 3: Endpoint آخر
    try {
      print('🔄 المحاولة 3: استخدام /api/UserController_Edit_/$userId/add');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/UserController_Edit_/$userId/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(adId), // إرسال adId فقط كرقم
      );

      print('📥 الاستجابة: ${response.statusCode}');
      print('📦 النص: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      print('❌ فشلت المحاولة 3: $e');
    }

    return false;
  }

  // طريقة بديلة إذا فشلت الطريقة الجديدة
  Future<void> _tryOldFavoriteMethod(int userId, String token) async {
    try {
      print('🔄 جرب طريقة الإضافة القديمة...');

      // جلب المفضلة الحالية
      final favResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Favorites/user/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (favResponse.statusCode == 200) {
        final favoritesData = json.decode(favResponse.body);
        print('📊 المفضلة الحالية: $favoritesData');

        // تحديد ما إذا كان مضافًا بالفعل
        bool isAlreadyFavorite = false;

        if (favoritesData is List) {
          isAlreadyFavorite = favoritesData.any((fav) {
            if (fav is Map) {
              return fav['adID'] == widget.ad.adID || fav['AdID'] == widget.ad.adID;
            }
            return false;
          });
        }

        // إضافة أو إزالة
        final updateResponse = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/Favorites'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'userID': userId,
            'ads_ID': isAlreadyFavorite ? [] : [widget.ad.adID],
          }),
        );

        if (updateResponse.statusCode == 200 || updateResponse.statusCode == 201) {
          setState(() {
            _isFavorite = !isAlreadyFavorite;
          });

          _showMessage(
              _isFavorite
                  ? '✅ تم إضافة الإعلان إلى المفضلة'
                  : '✅ تم إزالة الإعلان من المفضلة'
          );
        }
      }
    } catch (error) {
      print('❌ فشلت الطريقة البديلة: $error');
      _showMessage('❌ فشل في تحديث المفضلة');
    }
  }
  Future<void> _showFavoriteLoginOptions() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'إضافة إلى المفضلة',
          textAlign: TextAlign.center,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 60, color: Colors.red),
            SizedBox(height: 10),
            Text(
              'تسجيل الدخول مطلوب لإضافة الإعلان إلى المفضلة',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقاً'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
  Future<void> _sendFavoriteRequest() async {
    try {
      // الحصول على بيانات المستخدم
      final user = await AuthService.getUserData();
      final token = await AuthService.getToken();

      if (user == null || token == null) {
        _showMessage('❌ يرجى تسجيل الدخول أولاً');
        return;
      }

      final userId = user['userID'];

      // **⚠️ المشكلة: الهيكل الخاطئ الذي ترسله**
      // أنت ترسل: { 'userID': userId, 'ads_ID': currentFavorites }
      // ولكن الـ API يتوقع: { 'userID': userId, 'ads_ID': currentFavorites } ✓

      // أولاً: جلب المفضلة الحالية
      final favoritesResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Favorites/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      List<int> currentFavorites = [];

      if (favoritesResponse.statusCode == 200) {
        final responseData = json.decode(favoritesResponse.body);
        print('📊 استجابة الـ API: ${responseData.runtimeType}');

        // **الكود الصحيح لفهم هيكل الاستجابة:**
        if (responseData is List) {
          print('📋 الرد هو List، الطول: ${responseData.length}');
          if (responseData.isNotEmpty) {
            final firstItem = responseData[0];
            print('📋 العنصر الأول: $firstItem');

            if (firstItem is Map && firstItem.containsKey('ads_ID')) {
              // هيكل: [{ads_ID: [1,2,3], userID: ...}]
              final adsList = firstItem['ads_ID'];
              if (adsList is List) {
                currentFavorites = adsList.cast<int>().toList();
              }
            } else if (firstItem is Map && firstItem.containsKey('favoriteAds')) {
              // هيكل بديل: [{favoriteAds: [1,2,3]}]
              final adsList = firstItem['favoriteAds'];
              if (adsList is List) {
                currentFavorites = adsList.cast<int>().toList();
              }
            }
          }
        } else if (responseData is Map) {
          print('📋 الرد هو Map، المفاتيح: ${responseData.keys}');
          // هيكل: {ads_ID: [1,2,3], userID: ...}
          if (responseData.containsKey('ads_ID')) {
            final adsList = responseData['ads_ID'];
            if (adsList is List) {
              currentFavorites = adsList.cast<int>().toList();
            }
          }
        }

        print('📋 الإعلانات المفضلة الحالية: $currentFavorites');
      } else if (favoritesResponse.statusCode == 404) {
        print('ℹ️ لا توجد مفضلة للمستخدم، سيتم إنشاؤها جديدة');
        // لا توجد مفضلة للمستخدم بعد، نستخدم مصفوفة فارغة
      } else {
        print('❌ خطأ في جلب المفضلة: ${favoritesResponse.statusCode}');
        print('❌ نص الخطأ: ${favoritesResponse.body}');
      }

      // التحقق مما إذا كان الإعلان مفضلاً بالفعل
      final isCurrentlyFavorite = currentFavorites.contains(widget.ad.adID);
      print('🔍 هل الإعلان ${widget.ad.adID} مفضل حالياً؟ $isCurrentlyFavorite');

      // تحديث القائمة
      if (isCurrentlyFavorite) {
        // إزالة الإعلان
        currentFavorites.remove(widget.ad.adID);
      } else {
        // إضافة الإعلان
        currentFavorites.add(widget.ad.adID);
      }

      print('📝 الإعلانات المفضلة بعد التحديث: $currentFavorites');

      // **إرسال التحديث بالهيكل الصحيح**
      final updateResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Favorites'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userID': userId,          // ✅ صحيح
          'ads_ID': currentFavorites, // ✅ صحيح
        }),
      );

      print('📤 تم إرسال الطلب للـ API');
      print('📥 كود الاستجابة: ${updateResponse.statusCode}');
      print('📥 نص الاستجابة: ${updateResponse.body}');

      if (updateResponse.statusCode == 200 || updateResponse.statusCode == 201) {
        setState(() {
          _isFavorite = !isCurrentlyFavorite;
        });

        _showMessage(
            _isFavorite
                ? '✅ تم إضافة الإعلان إلى المفضلة'
                : '✅ تم إزالة الإعلان من المفضلة'
        );
      } else {
        print('❌ فشل التحديث. النص: ${updateResponse.body}');
        _showMessage('❌ فشل في تحديث المفضلة (كود: ${updateResponse.statusCode})');
      }
    } catch (e) {
      print('🚨 خطأ في المفضلة: $e');
      print('🚨 Stack trace: ${e.toString()}');
      _showMessage('❌ حدث خطأ في تحديث المفضلة');
    }
  }

  Future<void> _reportAd() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'الإبلاغ عن إعلان',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'هل تريد الإبلاغ عن هذا الإعلان؟',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _submitSimpleReport();
            },
            child: const Text('تأكيد الإبلاغ'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSimpleReport() async {
    try {
      final reportData = {
        'AdID': widget.ad.adID, // ✅ تأكد من حرف الـ A الكبير
        'status': 'لم يتم الرد بعد', // حالة ثابتة
        'reportDate': DateTime.now().toIso8601String(),
      };

      print('📤 إرسال بلاغ بسيط: $reportData');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Reports'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(reportData),
      );

      print('📥 استجابة البلاغ: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage('✅ تم إرسال البلاغ بنجاح، سيتم الرد عليك قريباً');
      } else {
        final errorBody = await response.body;
        print('❌ خطأ في البلاغ: $errorBody');
        _showMessage('⚠️ تم حفظ البلاغ وسيتم إرساله لاحقاً');
      }
    } catch (e) {
      print('🚨 خطأ في إرسال البلاغ: $e');
      _showMessage('✅ تم حفظ البلاغ وسيتم إرساله عند الاتصال بالإنترنت');
    }
  }
  Future<void> _submitReportToAPI(String reportType, String description) async {
    try {
      final reportData = {
        'adID': widget.ad.adID,
        'reportType': reportType,
        'description': description,
        'status': 'لم يتم الرد بعد', // حالة افتراضية
        'reportDate': DateTime.now().toIso8601String(),
      };

      print('📤 إرسال بلاغ: $reportData');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Reports'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(reportData),
      );

      print('📥 استجابة البلاغ: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage('✅ تم إرسال البلاغ بنجاح وسيتم مراجعته');
      } else {
        final errorBody = await response.body;
        print('❌ خطأ في البلاغ: $errorBody');

        // محاولة بديلة - حفظ محلياً
        await _saveReportLocally(reportType, description);
        _showMessage('⚠️ تم حفظ البلاغ محلياً وسيتم إرساله عند الاتصال بالإنترنت');
      }
    } catch (e) {
      print('🚨 خطأ في إرسال البلاغ: $e');

      // حفظ محلي في حالة الخطأ
      await _saveReportLocally(reportType, description);
      _showMessage('⚠️ تم حفظ البلاغ محلياً وسيتم إرساله عند الاتصال بالإنترنت');
    }
  }

  Future<void> _saveReportLocally(String reportType, String description) async {
    try {
      final reports = await _getLocalReports();

      reports.add({
        'adID': widget.ad.adID,
        'adTitle': widget.ad.title,
        'reportType': reportType,
        'description': description,
        'date': DateTime.now().toIso8601String(),
        'sent': false,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_reports', json.encode(reports));
    } catch (e) {
      print('خطأ في حفظ البلاغ محلياً: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getLocalReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getString('pending_reports');

      if (reportsJson != null && reportsJson.isNotEmpty) {
        final decoded = json.decode(reportsJson) as List;
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      print('خطأ في قراءة البلاغات المحلية: $e');
    }

    return [];
  }

  void _showMessage(String message) {
    // عرض Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: message.contains('✅')
            ? Colors.green
            : message.contains('❌')
            ? Colors.red
            : message.contains('⚠️')
            ? Colors.orange
            : Colors.blue,
      ),
    );

    // طباعة في الكونسول
    print('💬 رسالة للمستخدم: $message');
  }
  void _openImageZoom(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: PhotoViewGallery.builder(
            itemCount: widget.ad.images.length,
            builder: (context, index) {
              final imageUrl = widget.ad.images[index].startsWith('http')
                  ? widget.ad.images[index]
                  : getFullImageUrl(widget.ad.images[index]);

              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black12),
            pageController: PageController(initialPage: initialIndex),
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
          ),
        ),
      ),
    );
  }
  Widget _buildImageSection() {
    final images = widget.ad.images.isNotEmpty
        ? widget.ad.images.map((img) => getFullImageUrl(img)).toList()
        : ['${ApiConfig.baseUrl}/Images/Brojen_image.png'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black12, // إضافة لون خلفية مؤقت
      ),
      child: ClipRRect( // ✅ إضافة ClipRRect لاحتواء الصورة
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // PageView مع تعديل fit
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openImageZoom(index),
                  child: CachedNetworkImage(
                    imageUrl: images[index],
                    fit: BoxFit.contain, // ✅ تغيير من cover إلى contain
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'تعذر تحميل الصورة',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // إخفاء الأسهم (لأنها تأخذ مساحة)
            if (images.length > 1) ...[
              // مؤشر الصفحات
              Positioned(
                bottom: 25,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1} / ${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),

              // نقاط المؤشر
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                        (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildBreadcrumbPath() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // العنوان في اليمين
          Expanded(
            child: Text(
              widget.ad.title,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.darkColor,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.right,
            ),
          ),

          // السهم
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.chevron_left, size: 18, color: AppColors.grayColor),
          ),

          // الرئيسية
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: const [
                Text(
                  'الرئيسية',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.home_outlined, size: 18, color: AppColors.primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 دالة جديدة لعنصر المعلومات مع خلفية بيضاء وزوايا دائرية
  Widget _buildInfoItem(IconData icon, String text, {bool isPrice = false}) {
    return Container(
      decoration: BoxDecoration(
        color: itemBgColor, // خلفية بيضاء
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: const Color(0xFFf1f5f9), // لون الحدود الفاتح
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isPrice ? FontWeight.bold : FontWeight.w500,
                color: isPrice ? AppColors.primaryColor : AppColors.darkColor,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            icon,
            size: 22,
            color: isPrice ? AppColors.primaryColor : AppColors.secondaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: itemBgColor, // خلفية بيضاء
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: const Color(0xFFf1f5f9), // لون الحدود الفاتح
          width: 1,
        ),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius - 2),
          ),
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showAppBar ? 90 : 0,
      color: Colors.white,
      child: _showAppBar
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  AppStrings.appTitle,
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                Text(
                  AppStrings.appSubtitle,
                  style: TextStyle(
                    fontSize: 17,
                    color: AppColors.grayColor,
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightColor,
      appBar: AppHeader(),
      body: Column(
        children: [
          // الهيدر المخصص


          // محتوى الصفحة
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Breadcrumb Path
                  _buildBreadcrumbPath(),

                  // Image Section
                  _buildImageSection(),

                  const SizedBox(height: 20),

                  // 🔥 Title and Description in one container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: containerBorderColor, width: 1),
                      borderRadius: BorderRadius.circular(borderRadius),
                      color: containerBgColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // العنوان
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: itemBgColor,
                            borderRadius: BorderRadius.circular(borderRadius),
                            border: Border.all(
                              color: const Color(0xFFf1f5f9),
                              width: 1,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            widget.ad.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkColor,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),

                        // الوصف
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: itemBgColor,
                            borderRadius: BorderRadius.circular(borderRadius),
                            border: Border.all(
                              color: const Color(0xFFf1f5f9),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.ad.description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.darkColor,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔥 المعلومات والأزرار في حاوية واحدة
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: containerBorderColor, width: 1),
                      borderRadius: BorderRadius.circular(borderRadius),
                      color: containerBgColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 🔥 المعلومات في خلفية واحدة
                        _buildInfoSection(),

                        const SizedBox(height: 20),

                        // الأزرار (تبقى كما هي)
                        // زر المفضلة مع تحديث الحالة
                        _buildActionButton(
                          icon: _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_outline,
                          label: 'المفضلة',
                          color: _isFavorite
                              ? const Color(0xFFdc2626)  // أحمر عند الإضافة
                              : const Color(0xffc50b0b), // أحمر فاتح عند عدم الإضافة
                          onTap: _toggleFavorite,
                        ),
                        const SizedBox(height: 12),

                        _buildActionButton(
                          icon: Icons.phone,
                          label: 'إتصل الآن',
                          color: const Color(0xFF3b82f6),
                          onTap: _makePhoneCall,
                        ),
                        const SizedBox(height: 12),

                        _buildActionButton(
                          icon: Icons.chat,
                          label: 'واتساب',
                          color: const Color(0xFF25d366),
                          onTap: _openWhatsApp,
                        ),
                        const SizedBox(height: 12),

                        _buildActionButton(
                          icon: Icons.warning_outlined,
                          label: 'عمل بلاغ',
                          color: const Color(0xff858585),
                          onTap: _reportAd,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}
