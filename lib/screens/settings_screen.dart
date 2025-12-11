import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app_haraj/screens/home_screen.dart';
import 'package:mobile_app_haraj/screens/policy_screen.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import 'Police_after_login.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? quotaData;
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
      await _loadUserData();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);

    try {
      // جلب بيانات المستخدم المحلية
      final user = await AuthService.getUserData();
      final localInfo = await AuthService.getLocalUserInfo();

      // جلب بيانات الحصص من API
      await _loadQuotaData(user?['userID'] ?? localInfo['userID']);

      setState(() {
        userData = {
          ...?user,
          ...localInfo,
        };
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadQuotaData(int userId) async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse('${AuthService.apiBaseUrl}/api/Quota/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          quotaData = data;
        });
      } else {
        print('Failed to load quota: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading quota data: $e');
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    setState(() {
      isLoggedIn = false;
      userData = null;
      quotaData = null;
    });
    Navigator.of(context).pushReplacementNamed('/');
  }

  // دالة جديدة للتعامل مع تسجيل الدخول وعرض Policy أولاً
  Future<void> _handleLogin() async {
    // عرض شاشة Policy أولاً
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PolicyPage(),
      ),
    );

    // إذا وافق المستخدم على الشروط (result == true)
    if (result == true) {
      // الانتقال إلى صفحة Login
      Navigator.pushNamed(context, '/login');
    }
    // إذا رفض أو أغلق، لا نفعل شيئاً (يظل في صفحة الإعدادات)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (!isLoggedIn) {
      return _buildGuestView();
    }

    return _buildAccountInfoView();
  }

  Widget _buildGuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // أيقونة تسجيل الدخول
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.lightColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.grayColor, width: 2),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 60,
              color: AppColors.grayColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'يرجى تسجيل الدخول',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkColor,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'للعرض أو التعديل على بيانات حسابك',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.grayColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _handleLogin, // استخدام الدالة الجديدة
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'تسجيل الدخول',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // زر العودة للرئيسية
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  },
                  child: const Text(
                    'العودة للرئيسية',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const Text(
                  'بيانات حسابي',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkColor,
                  ),
                ),
              ],
            ),
          ),

          // محتوى بيانات الحساب
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // البيانات الشخصية
                _buildSectionTitle('البيانات الشخصية'),

                _buildInfoItem(
                  label: 'البريد الإلكتروني',
                  value: userData?['email'] ?? 'غير متوفر',
                ),

                _buildInfoItem(
                  label: 'رقم الهاتف',
                  value: userData?['phone'] ?? 'غير متوفر',
                ),

                const SizedBox(height: 20),

                // حصتي في الإعلانات
                _buildSectionTitle('حصتي في الإعلانات'),

                _buildQuotaItem(
                  label: 'الإعلانات العادية المسموح بها',
                  value: quotaData?['maxNormalAds']?.toString() ?? '0',
                ),

                _buildQuotaItem(
                  label: 'الإعلانات المميزة المسموح بها',
                  value: quotaData?['maxPrimeAds']?.toString() ?? '0',
                ),

                _buildQuotaItem(
                  label: 'إعلانات عادية نشطة',
                  value: quotaData?['activeNormalAds']?.toString() ?? '0',
                ),

                _buildQuotaItem(
                  label: 'إعلانات مميزة نشطة',
                  value: quotaData?['activePrimeAds']?.toString() ?? '0',
                ),

                _buildQuotaItem(
                  label: 'الإعلانات المنتهية',
                  value: quotaData?['expiredAdsCount']?.toString() ?? '0',
                ),

                _buildQuotaItem(
                  label: 'مدة الإعلان العادي (أيام)',
                  value: quotaData?['systemNormalDays']?.toString() ?? '0',
                ),

                _buildQuotaItem(
                  label: 'مدة الإعلان المميز (أيام)',
                  value: quotaData?['systemPrimeDays']?.toString() ?? '0',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // أزرار الإعدادات
          _buildSettingsOptions(),

          const SizedBox(height: 30),

          // زر تسجيل الخروج
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildInfoItem({required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.darkColor,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.darkColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaItem({required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.darkColor,
            ),
          ),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.darkColor,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOptions() {
    return Column(
      children: [


        _buildSettingCard(
          icon: Icons.info_outline,
          title: 'عن التطبيق',
          subtitle: 'الإصدار 1.0.0',
          onTap: () {
            _showAboutDialog();
          },
        ),
        const SizedBox(height: 10,),
        _buildSettingCard(
          icon: Icons.security_outlined,
          title: 'الشروط و الاحكام',
          subtitle: 'الإصدار 1.0.0',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PoliceAfterLogin(),));
          },
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.lightColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkColor,
          ),
          textAlign: TextAlign.right,
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.grayColor,
          ),
          textAlign: TextAlign.right,
        ),
        trailing: const Icon(
          Icons.arrow_back_ios,
          size: 16,
          color: AppColors.grayColor,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: _logout,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.featuredBadge,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout, size: 20),
          SizedBox(width: 10),
          Text(
            'تسجيل الخروج',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // دوال الحوارات
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير اللغة'),
        content: const Text('حالياً التطبيق يدعم اللغة العربية فقط'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('عن التطبيق'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('حراج الكويت'),
            SizedBox(height: 5),
            Text('الإصدار: 1.0.0'),
            SizedBox(height: 5),
            Text('سريع • بسيط • مجاني'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}