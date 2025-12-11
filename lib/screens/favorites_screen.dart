import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart'; // تأكد من استيراد ApiService
import '../widgets/ad_card.dart';
import '../models/ad_model.dart';
import 'home_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Ad> featuredFavorites = [];
  List<Ad> regularFavorites = [];
  bool isLoading = true;
  bool isLoggedIn = false;

  // إضافة FocusNode لتتبع التركيز على الصفحة
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  // عندما تظهر الصفحة أو تعود للتركيز
  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _reloadFavorites();
    }
  }

  // عندما تدخل الصفحة (Navigator.push)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحديث التركيز عند دخول الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _reloadFavorites();
    });
  }

  // دالة لإعادة تحميل المفضلة
  Future<void> _reloadFavorites() async {
    if (isLoggedIn) {
      await _loadFavorites();
    }
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await AuthService.isLoggedIn();
    setState(() {
      isLoggedIn = loggedIn;
    });

    if (loggedIn) {
      await _loadFavorites();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    setState(() => isLoading = true);

    try {
      // استخدام الدالة الجديدة من ApiService
      final List<Ad> allFavorites = await ApiService.getFavoritesFromServer();

      // فصل الإعلانات المميزة عن العادية
      final featured = allFavorites.where((ad) => ad.isFeatured || ad.adType == 'مميز').toList();
      final regular = allFavorites.where((ad) => !ad.isFeatured && ad.adType != 'مميز').toList();

      // ترتيب حسب التاريخ (الأحدث أولاً)
      featured.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      regular.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        featuredFavorites = featured;
        regularFavorites = regular;
        isLoading = false;
      });

      print('✅ تم تحميل ${allFavorites.length} إعلان من المفضلة');
      print('  - مميزة: ${featured.length}');
      print('  - عادية: ${regular.length}');
    } catch (e) {
      print('❌ خطأ في تحميل المفضلة: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _refreshFavorites() async {
    if (isLoggedIn) {
      await _loadFavorites();
    }
  }

  void _removeFromFavorites(Ad ad) {
    setState(() {
      featuredFavorites.removeWhere((a) => a.adID == ad.adID);
      regularFavorites.removeWhere((a) => a.adID == ad.adID);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen())
                );
              },
              child: const Row(
                children: [
                  Text(
                    'العودة للرئيسية',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'المفضله',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      // إضافة Focus لإعادة تحميل عند العودة للصفحة
      body: FocusScope(
        node: FocusScopeNode(),
        child: Focus(
          focusNode: _focusNode,
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!isLoggedIn) {
      return _buildGuestView();
    }

    if (featuredFavorites.isEmpty && regularFavorites.isEmpty) {
      return _buildEmptyView();
    }

    return _buildFavoritesList();
  }

  Widget _buildGuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite_outline,
            size: 80,
            color: AppColors.grayColor,
          ),
          const SizedBox(height: 20),
          const Text(
            'يرجى تسجيل الدخول',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.darkColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'لتتمكن من عرض المفضلة',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grayColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              // الانتقال لصفحة تسجيل الدخول
              final result = await Navigator.of(context).pushNamed('/login');

              // إذا عدنا من صفحة تسجيل الدخول، تحقق من حالة الدخول
              if (result == true) {
                await _checkLoginStatus();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite_outline,
            size: 80,
            color: AppColors.grayColor,
          ),
          const SizedBox(height: 20),
          const Text(
            'لا توجد إعلانات في المفضلة',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.darkColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'يمكنك إضافة إعلانات إلى المفضلة بالضغط على ♡',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grayColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _buildFavoritesList() {
    return RefreshIndicator(
      onRefresh: _refreshFavorites,
      color: AppColors.primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (featuredFavorites.isNotEmpty) ...[
            _buildSectionHeader('الإعلانات المميزة', featuredFavorites.length),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: Directionality(
                textDirection: TextDirection.rtl, // إضافة هذا السطر
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true, // هذا السطر مهم لبدء العرض من اليمين
                  itemCount: featuredFavorites.length,
                  itemBuilder: (context, index) {
                    final ad = featuredFavorites[index];
                    return Padding(
                      padding: const EdgeInsets.only(left: 12), // تغيير right إلى left
                      child: SizedBox(
                        width: 160,
                        child: _buildFavoriteAdCard(ad),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (regularFavorites.isNotEmpty) ...[
            _buildSectionHeader('الإعلانات العادية', regularFavorites.length),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: Directionality(
                textDirection: TextDirection.ltr, // إضافة هذا السطر
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true, // هذا السطر مهم لبدء العرض من اليمين
                  itemCount: regularFavorites.length,
                  itemBuilder: (context, index) {
                    final ad = regularFavorites[index];
                    return Padding(
                      padding: const EdgeInsets.only(left: 12), // تغيير right إلى left
                      child: SizedBox(
                        width: 160,
                        child: _buildFavoriteAdCard(ad),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.darkColor,
            ),
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteAdCard(Ad ad) {
    return Stack(
      children: [
        AdCard(ad: ad, isGridItem: true),
        // زر إزالة من المفضلة
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _showRemoveDialog(ad),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite,
                size: 20,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showRemoveDialog(Ad ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إزالة من المفضلة'),
        content: const Text('هل تريد إزالة هذا الإعلان من المفضلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeFavoriteFromServer(ad.adID);
              _removeFromFavorites(ad);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFavoriteFromServer(int adId) async {
    try {
      final success = await ApiService.removeFavoriteFromServer(adId);
      if (success) {
        print('✅ تمت إزالة الإعلان $adId من المفضلة');
      } else {
        print('❌ فشلت إزالة الإعلان $adId من المفضلة');
      }
    } catch (e) {
      print('❌ خطأ في إزالة من المفضلة: $e');
    }
  }
}