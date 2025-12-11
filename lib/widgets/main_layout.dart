import 'package:flutter/material.dart';
import '../screens/seleted_adtype_screen.dart';
import '../services/auth_service.dart';
import '../widgets/bottom_nav_bar.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final int initialIndex;

  const MainLayout({
    super.key,
    required this.child,
    this.initialIndex = 0,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
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
      body: Stack(
        children: [
          // المحتوى الرئيسي
          widget.child,

          // الـ Bottom Navigation Bar الثابت
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onNavItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}