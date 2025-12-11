import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _tokenKey = 'haraj_token';
  static const String _userDataKey = 'haraj_user';
  static const String _isLoggedInKey = 'is_logged_in';

  static final String apiBaseUrl = 'http://haraj.runasp.net';
// في AuthService
  static Future<String?> getTokenDirectly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token == null || token.isEmpty) {
        print('❌ التوكن غير موجود أو فارغ');
        return null;
      }

      // التحقق من صحة التوكن (اختياري)
      print('🔑 التوكن المستلم: ${token.substring(0, 20)}...');
      return token;
    } catch (e) {
      print('❌ خطأ في جلب التوكن: $e');
      return null;
    }
  }
  // حفظ بيانات المستخدم
  static Future<void> saveUserData(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userDataKey, json.encode(userData));
    await prefs.setBool(_isLoggedInKey, true);

    // حفظ بيانات إضافية لتطابق الويب
    if (userData['email'] != null) {
      await prefs.setString('user_email', userData['email']);
    }
    if (userData['phone'] != null) {
      await prefs.setString('user_phone', userData['phone']);
    }
    if (userData['fullName'] != null) {
      await prefs.setString('user_fullName', userData['fullName']);
    }
    if (userData['userID'] != null) {
      await prefs.setInt('user_id', userData['userID']);
    }
  }

  // جلب التوكن
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // جلب بيانات المستخدم
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      try {
        return json.decode(userDataString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // التحقق من حالة تسجيل الدخول
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // جلب معلومات المستخدم من الخادم
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final userData = await getUserData();
      final userId = userData?['userID'];

      if (userId == null) return null;

      // جلب بيانات الحصص
      final quotaResponse = await http.get(
        Uri.parse('$apiBaseUrl/api/Quota/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (quotaResponse.statusCode == 200) {
        final quotaData = json.decode(quotaResponse.body);

        // جلب معلومات المستخدم الأساسية
        final response = await http.get(
          Uri.parse('$apiBaseUrl/api/UserController_Edit_/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        Map<String, dynamic> userInfo = {};
        if (response.statusCode == 200) {
          userInfo = json.decode(response.body);
        } else {
          // استخدام البيانات المخزنة محلياً
          userInfo = userData ?? {};
        }

        // دمج البيانات
        return {
          ...userInfo,
          ...quotaData,
        };
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
    return null;
  }

  // تسجيل الخروج
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('user_fullName');
    await prefs.remove('user_id');
    await prefs.setBool(_isLoggedInKey, false);
  }

  // جلب بيانات إضافية
  static Future<Map<String, dynamic>> getLocalUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('user_email') ?? '',
      'phone': prefs.getString('user_phone') ?? '',
      'fullName': prefs.getString('user_fullName') ?? '',
      'userID': prefs.getInt('user_id') ?? 0,
    };
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);

      if (userDataString != null) {
        return json.decode(userDataString);
      }
    } catch (e) {
      print('Error getting user info: $e');
    }
    return null;
  }
}