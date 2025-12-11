import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/ad_model.dart';
import '../models/category_model.dart';
import '../utils/constants.dart';

class ApiService {
  static const String _tokenKey = 'haraj_token';
  static const String _userKey = 'haraj_user';
  static const String _favoritesKey = 'haraj_favorites';

  // ==================== إدارة المصادقة والمستخدمين ====================

  // حفظ بيانات المستخدم بعد تسجيل الدخول
  static Future<void> saveUserData(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    final userJson = jsonEncode(userData);
    await prefs.setString(_userKey, userJson);
  }

  // جلب التوكن المحفوظ
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // جلب بيانات المستخدم المحفوظة
  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      } catch (e) {
        print('خطأ في تحليل بيانات المستخدم: $e');
        return null;
      }
    }
    return null;
  }

  // التحقق من حالة تسجيل الدخول
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // تسجيل الخروج
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // تحديث بيانات المستخدم
  static Future<void> updateUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }

  // ==================== الإعلانات ====================

  static Future<bool> createAd({
    required String title,
    required String description,
    required double price,
    required int categoryId,
    required String adType,
    required int userId,
    List<File>? images,
    List<Uint8List>? imagesBytes,
    required DateTime expiresAt,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      // 1. إنشاء multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.apiUrl}/ads'),
      );

      // 2. إضافة headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // 3. إضافة الحقول النصية كـ fields
      request.fields['UserID'] = userId.toString();
      request.fields['CategoryID'] = categoryId.toString();
      request.fields['Title'] = title;
      request.fields['Description'] = description;
      request.fields['Price'] = price.toString();
      request.fields['AdType'] = adType;
      request.fields['ExpiresAt'] = expiresAt.toIso8601String();

      // 4. إضافة الصور (إذا كانت موجودة)
      if (kIsWeb) {
        // حالة الويب: استخدام imagesBytes
        if (imagesBytes != null && imagesBytes.isNotEmpty) {
          for (int i = 0; i < imagesBytes.length; i++) {
            final bytes = imagesBytes[i];
            final multipartFile = http.MultipartFile.fromBytes(
              'Images', // اسم الحقل كما يتوقعه السيرفر
              bytes,
              filename: 'image_$i.jpg',
              contentType: MediaType('image', 'jpeg'),
            );
            request.files.add(multipartFile);
          }
        }
      } else {
        // حالة الجوال: استخدام images (File)
        if (images != null && images.isNotEmpty) {
          for (int i = 0; i < images.length; i++) {
            final image = images[i];
            final multipartFile = await http.MultipartFile.fromPath(
              'Images', // اسم الحقل كما يتوقعه السيرفر
              image.path,
              filename: 'image_$i.jpg',
              contentType: MediaType('image', 'jpeg'),
            );
            request.files.add(multipartFile);
          }
        }
      }

      print('📤 إرسال الطلب إلى: ${request.url}');
      print('🔑 التوكن: ${token.substring(0, 20)}...');
      print('📝 الحقول: ${request.fields}');
      print('🖼️ عدد الصور: ${request.files.length}');

      // 5. إرسال الطلب
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 استجابة السيرفر:');
      print('  - Status Code: ${response.statusCode}');
      print('  - Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('❌ خطأ في السيرفر: ${response.statusCode}');
        print('❌ تفاصيل الخطأ: ${response.body}');
        return false;
      }
    } catch (e) {
      print('🚨 خطأ في الاتصال: $e');
      rethrow;
    }
  }
  // جلب جميع الإعلانات
  static Future<List<Ad>> getAllAds() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/Ads'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ad.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('خطأ في جلب جميع الإعلانات: $e');
      return [];
    }
  }

  // جلب تفاصيل إعلان محدد
  static Future<Ad?> getAdDetails(int adId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/Ads/$adId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Ad.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('خطأ في جلب تفاصيل الإعلان: $e');
      return null;
    }
  }

  // جلب الإعلانات المميزة
  static Future<List<Ad>> getFeaturedAds() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/Ads/featured'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ad.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('خطأ في جلب الإعلانات المميزة: $e');
      return [];
    }
  }

  // جلب الإعلانات العادية
  static Future<List<Ad>> getRegularAds() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/Ads/regular'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ad.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('خطأ في جلب الإعلانات العادية: $e');
      return [];
    }
  }

  // جلب الإعلانات حسب الفئة
  static Future<List<Ad>> getAdsByCategory(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/Ads/category/$categoryId/with-subcategories'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ad.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('خطأ في جلب إعلانات الفئة: $e');
      return [];
    }
  }

  // جلب الإعلانات المميزة حسب الفئة
  static Future<List<Ad>> getFeaturedCategoryAds(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/Ads/featured/category/$categoryId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ad.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('خطأ في جلب الإعلانات المميزة للفئة: $e');
      return [];
    }
  }

  // جلب إعلانات المستخدم
  static Future<List<Ad>> getUserAds(int userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('خطأ: المستخدم غير مسجل الدخول');
        return [];
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/Ads/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ad.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('خطأ في جلب إعلانات المستخدم: $e');
      return [];
    }
  }

  // حذف إعلان
  static Future<bool> deleteAd(int adId) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('خطأ: المستخدم غير مسجل الدخول');
        return false;
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.apiUrl}/Ads/$adId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('خطأ في حذف الإعلان: $e');
      return false;
    }
  }

  // ==================== الفئات ====================

  // جلب جميع الفئات مع الفئات الفرعية
  static Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/SystemManagement/categories-with-subcategories-recursive'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('خطأ في جلب الفئات: $e');
      return [];
    }
  }

  // جلب فئة محددة حسب ID
  static Future<Category?> getCategoryById(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/SystemManagement/categories-with-subcategories-recursive'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return _findCategoryWithParents(data, categoryId);
      }
      return null;
    } catch (e) {
      print('خطأ في جلب الفئة: $e');
      return null;
    }
  }

  // دالة مساعدة للبحث عن فئة مع الوالدين
  static Category? _findCategoryWithParents(List<dynamic> categories, int categoryId, {List<String>? parentNames}) {
    for (var cat in categories) {
      if (cat['categoryID'] == categoryId) {
        if (parentNames != null && parentNames.isNotEmpty) {
          cat['parentPath'] = parentNames.join(' / ');
        }
        return Category.fromJson(cat);
      }
      if (cat['subCategories'] != null) {
        final newParentNames = parentNames != null
            ? List<String>.from(parentNames)
            : <String>[];
        newParentNames.add(cat['name']);

        final found = _findCategoryWithParents(cat['subCategories'], categoryId, parentNames: newParentNames);
        if (found != null) return found;
      }
    }
    return null;
  }

  // جلب مسار الفئة (Breadcrumb)
  static Future<List<String>> getCategoryBreadcrumb(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/SystemManagement/categories-with-subcategories-recursive'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return _findCategoryPath(data, categoryId);
      }
      return ['الرئيسية'];
    } catch (e) {
      print('خطأ في جلب مسار الفئة: $e');
      return ['الرئيسية'];
    }
  }

  // دالة مساعدة للبحث عن مسار الفئة
  static List<String> _findCategoryPath(List<dynamic> categories, int categoryId, {List<String> currentPath = const []}) {
    for (var cat in categories) {
      final newPath = List<String>.from(currentPath)..add(cat['name']);

      if (cat['categoryID'] == categoryId) {
        return ['الرئيسية', ...newPath];
      }

      if (cat['subCategories'] != null) {
        final found = _findCategoryPath(cat['subCategories'], categoryId, currentPath: newPath);
        if (found.isNotEmpty) return found;
      }
    }
    return [];
  }
  static Future<List<Ad>> getFavoritesFromServer() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('خطأ: المستخدم غير مسجل الدخول');
        return [];
      }

      final user = await AuthService.getUserData();
      final userId = user?['userID'];

      if (userId == null) {
        print('خطأ: لا يوجد معرف للمستخدم');
        return [];
      }

      final response = await http.get(
        Uri.parse('${AuthService.apiBaseUrl}/api/UserController_Edit_/$userId/my-favorites'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('جلب المفضلة من السيرفر - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Ad> ads = data.map((item) => Ad.fromJson(item)).toList();
        print('تم جلب ${ads.length} إعلان من المفضلة');
        return ads;
      } else {
        print('خطأ في جلب المفضلة: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('خطأ في الاتصال للسيرفر: $e');
      return [];
    }
  }

  // إزالة من المفضلة في السيرفر
  static Future<bool> removeFavoriteFromServer(int adId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('خطأ: المستخدم غير مسجل الدخول');
        return false;
      }

      final user = await AuthService.getUserData();
      final userId = user?['userID'];

      if (userId == null) {
        print('خطأ: لا يوجد معرف للمستخدم');
        return false;
      }

      final response = await http.delete(
        Uri.parse('${AuthService.apiBaseUrl}/api/UserController_Edit_/$userId/remove'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(adId),
      );

      print('إزالة من المفضلة - Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('خطأ في إزالة من المفضلة: $e');
      return false;
    }
  }
  // ==================== المفضلة ====================

  // إضافة إعلان إلى المفضلة
  static Future<void> addToFavorites(int adId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();

      if (!favorites.contains(adId)) {
        favorites.add(adId);
        await prefs.setStringList(_favoritesKey, favorites.map((id) => id.toString()).toList());
      }
    } catch (e) {
      print('خطأ في إضافة الإعلان إلى المفضلة: $e');
    }
  }

  // إزالة إعلان من المفضلة
  static Future<void> removeFromFavorites(int adId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();

      favorites.remove(adId);
      await prefs.setStringList(_favoritesKey, favorites.map((id) => id.toString()).toList());
    } catch (e) {
      print('خطأ في إزالة الإعلان من المفضلة: $e');
    }
  }

  // جلب قائمة المفضلة
  static Future<List<int>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_favoritesKey) ?? [];
      return favorites.map((id) => int.tryParse(id) ?? 0).where((id) => id > 0).toList();
    } catch (e) {
      print('خطأ في جلب المفضلة: $e');
      return [];
    }
  }

  // التحقق مما إذا كان الإعلان مفضل
  static Future<bool> isFavorite(int adId) async {
    final favorites = await getFavorites();
    return favorites.contains(adId);
  }

  // جلب إعلانات المفضلة
  static Future<List<Ad>> getFavoriteAds() async {
    try {
      final favorites = await getFavorites();
      if (favorites.isEmpty) return [];

      final List<Ad> favoriteAds = [];

      for (final adId in favorites) {
        final ad = await getAdDetails(adId);
        if (ad != null) {
          favoriteAds.add(ad);
        }
      }

      return favoriteAds;
    } catch (e) {
      print('خطأ في جلب إعلانات المفضلة: $e');
      return [];
    }
  }

  // ==================== الزيارات والإحصائيات ====================

  // تسجيل زيارة للإعلان
  static Future<bool> sendVisit(int adId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/Visits'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'adID': adId}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('خطأ في تسجيل الزيارة: $e');
      return false;
    }
  }

  // ==================== البحث ====================

  // البحث في الإعلانات
  static Future<List<Ad>> searchAds(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/Ads/search?query=${Uri.encodeQueryComponent(query)}'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Ad.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('خطأ في البحث: $e');
      return [];
    }
  }

  // ==================== التطبيق ====================

  // حفظ إعدادات المستخدم
  static Future<void> saveUserSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
  }

  // جلب إعدادات المستخدم
  static Future<dynamic> getUserSetting(String key, {dynamic defaultValue}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(key) ?? defaultValue;
  }

  // ==================== الخدمات المساعدة ====================

  // التحقق من اتصال الإنترنت
  static Future<bool> checkInternetConnection() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // جلب الصورة كاملة URL
  static String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty || imagePath == 'null' || imagePath == 'undefined') {
      return '${ApiConfig.baseUrl}/Images/Brojen_image.png';
    }

    // إذا كان المسار يحتوي على http بالفعل
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // تنظيف المسار
    String cleanPath = imagePath.trim();

    // إذا كان المسار يبدأ بـ "/" (مثل الأقسام)
    if (cleanPath.startsWith('/')) {
      // إزالة الـ / الزائدة
      if (cleanPath.startsWith('//')) {
        cleanPath = cleanPath.substring(1);
      }
      return '${ApiConfig.baseUrl}$cleanPath';
    }

    // إذا كان المسار يحتوي على "ads/" بالفعل
    if (cleanPath.contains('ads/')) {
      return '${ApiConfig.baseUrl}/$cleanPath';
    }

    // إذا كان المسار يحتوي على "categories/"
    if (cleanPath.contains('categories/')) {
      return '${ApiConfig.baseUrl}/Images/$cleanPath';
    }

    // إذا كان المسار لا يحتوي على "ads/" أضفه
    if (!cleanPath.startsWith('ads/')) {
      cleanPath = 'ads/' + cleanPath;
    }

    return '${ApiConfig.baseUrl}/$cleanPath';
  }
}