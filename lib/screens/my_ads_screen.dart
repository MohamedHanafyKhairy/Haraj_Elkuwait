import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_haraj/screens/home_screen.dart';
import 'dart:convert';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../widgets/ad_card.dart';
import '../models/ad_model.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  _MyAdsScreenState createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  List<Ad> myAds = [];
  List<Ad> featuredAds = [];
  List<Ad> regularAds = [];
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await AuthService.isLoggedIn();
    setState(() {
      isLoggedIn = loggedIn;
    });

    if (loggedIn) {
      await _loadMyAds();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadMyAds() async {
    setState(() => isLoading = true);

    try {
      final user = await AuthService.getUserData();
      final userId = user?['userID'];

      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse('${AuthService.apiBaseUrl}/api/Ads/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // تحويل البيانات إلى قائمة من Ad
        final List<Ad> ads = data.map((item) => Ad.fromJson(item)).toList();

        // فصل الإعلانات المميزة عن العادية
        final featured = ads.where((ad) => ad.isFeatured || ad.adType == 'مميز').toList();
        final regular = ads.where((ad) => !ad.isFeatured && ad.adType != 'مميز').toList();

        // ترتيب حسب التاريخ (الأحدث أولاً)
        featured.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        regular.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        setState(() {
          myAds = ads;
          featuredAds = featured;
          regularAds = regular;
          isLoading = false;
        });
      } else {
        throw Exception('فشل في جلب الإعلانات: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading my ads: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _refreshAds() async {
    if (isLoggedIn) {
      await _loadMyAds();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // كلمة "العودة للرئيسية" على اليسار (البداية)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
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
            // كلمة "إعلاناتي" على اليمين (النهاية)
            const Text(
              'إعلاناتي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (!isLoggedIn) {
      return _buildGuestView();
    }

    if (myAds.isEmpty) {
      return _buildEmptyView();
    }

    return _buildAdsList();
  }

  Widget _buildGuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
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
            'لتتمكن من عرض إعلاناتك',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grayColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/login');
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
            Icons.chat_bubble_outline,
            size: 80,
            color: AppColors.grayColor,
          ),
          const SizedBox(height: 20),
          const Text(
            'ليس لديك إعلانات',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.darkColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'يمكنك إضافة إعلان جديد بالضغط على زر "+"',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grayColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/add-ad');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('إضافة إعلان جديد'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdsList() {
    return RefreshIndicator(
      onRefresh: _refreshAds,
      color: AppColors.primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // عرض الإعلانات المميزة أولاً
          if (featuredAds.isNotEmpty) ...[
            _buildSectionHeader('الإعلانات المميزة', featuredAds.length),
            const SizedBox(height: 10),
            _buildFeaturedAdsGrid(),
            const SizedBox(height: 20),
          ],

          // ثم الإعلانات العادية
          if (regularAds.isNotEmpty) ...[
            _buildSectionHeader('الإعلانات العادية', regularAds.length),
            const SizedBox(height: 10),
            _buildRegularAdsGrid(),
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

  Widget _buildFeaturedAdsGrid() {
    return SizedBox(
      height: 250,
      child: Directionality(
        textDirection: TextDirection.ltr, // إضافة هذا السطر
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          reverse: true, // هذا السطر مهم لبدء العرض من اليمين
          itemCount: featuredAds.length,
          itemBuilder: (context, index) {
            final ad = featuredAds[index];
            return Padding(
              padding: const EdgeInsets.only(left: 12), // تغيير right إلى left
              child: SizedBox(
                width: 160,
                child: AdCard(ad: ad, isGridItem: true),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRegularAdsGrid() {
    return SizedBox(
      height: 250,
      child: Directionality(
        textDirection: TextDirection.ltr, // إضافة هذا السطر
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          reverse: true, // هذا السطر مهم لبدء العرض من اليمين
          itemCount: regularAds.length,
          itemBuilder: (context, index) {
            final ad = regularAds[index];
            return Padding(
              padding: const EdgeInsets.only(left: 12), // تغيير right إلى left
              child: SizedBox(
                width: 160,
                child: AdCard(ad: ad, isGridItem: true),
              ),
            );
          },
        ),
      ),
    );
  }
}