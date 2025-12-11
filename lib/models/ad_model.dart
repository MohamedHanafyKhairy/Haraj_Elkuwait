import 'dart:convert';
import '../utils/constants.dart';

class Ad {
  final int adID;
  final String title;
  final String description;
  final double price;
  final String adType;
  final DateTime createdAt;
  final List<String> images;
  final int visitsCount;
  final int? daysRemaining;
  final String? phone;
  final String? categoryPath;
  final int? categoryID;
  final Map<String, dynamic>? user;


  Ad({
    required this.adID,
    required this.title,
    required this.description,
    required this.price,
    required this.adType,
    required this.createdAt,
    required this.images,
    this.visitsCount = 0,
    this.daysRemaining,
    this.phone,
    this.categoryPath,
    this.categoryID,
    this.user,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    List<String> images = [];

    // معالجة الصور بطرق مختلفة لأن الـ API قد يعيدها بصيغ مختلفة
    if (json['images'] != null) {
      if (json['images'] is List) {
        images = (json['images'] as List).map((e) {
          if (e is String) return e;
          if (e is Map<String, dynamic> && e['url'] != null) return e['url'].toString();
          return e.toString();
        }).toList();
      } else if (json['images'] is String) {
        try {
          // محاولة تحليل الـ JSON string
          final parsed = jsonDecode(json['images']) as List;
          images = parsed.map((e) => e.toString()).toList();
        } catch (e) {
          // إذا فشل التحليل، استخدامه كسلسلة نصية
          images = [json['images'].toString()];
        }
      }
    }

    return Ad(
      adID: json['adID'] ?? json['AdID'] ?? json['id'] ?? 0,
      title: json['title'] ?? json['Title'] ?? '',
      description: json['description'] ?? json['Description'] ?? '',
      price: (json['price'] ?? json['Price'] ?? 0).toDouble(),
      adType: json['adType'] ?? json['AdType'] ?? json['type'] ?? 'عادي',
      createdAt: DateTime.parse(
        json['createdAt'] ?? json['CreatedAt'] ?? json['createdDate'] ?? DateTime.now().toIso8601String(),
      ),
      images: images,
      visitsCount: json['visitsCount'] ?? json['VisitsCount'] ?? 0,
      daysRemaining: json['daysRemaining'] ?? json['DaysRemaining'],
      phone: json['phone'] ?? json['Phone'],
      categoryPath: json['categoryPath'] ?? json['CategoryPath'] ?? '',
      categoryID: json['categoryID'] ?? json['CategoryID'],
      user: json['user'] != null ? Map<String, dynamic>.from(json['user']) : null,
    );
  }

  bool get isFeatured => adType == 'مميز';

  String get imageUrl {
    if (images.isEmpty) return '';
    return getFullImageUrl(images[0]);
  }

  String getPhoneNumber() {
    print('📱 === بدء استخراج رقم الهاتف في التطبيق ===');
    print('🔍 بيانات الإعلان:');
    print('  - adID: $adID');
    print('  - userPhone مباشرة: $phone');
    print('  - user object: $user');

    // 1. الأولوية: الحقل المباشر phone
    if (phone != null && phone!.isNotEmpty) {
      print('✅ وجد الرقم في phone: $phone');
      return phone!;
    }

    // 2. البحث في user object
    if (user != null) {
      print('🔍 البحث في user object...');

      // 2.1 userPhone داخل user
      if (user!['userPhone'] != null) {
        final userPhone = user!['userPhone'].toString();
        print('✅ وجد الرقم في user[\'userPhone\']: $userPhone');
        return userPhone;
      }

      // 2.2 phone داخل user
      if (user!['phone'] != null) {
        final userPhone = user!['phone'].toString();
        print('✅ وجد الرقم في user[\'phone\']: $userPhone');
        return userPhone;
      }

      // 2.3 phoneNumber داخل user
      if (user!['phoneNumber'] != null) {
        final userPhone = user!['phoneNumber'].toString();
        print('✅ وجد الرقم في user[\'phoneNumber\']: $userPhone');
        return userPhone;
      }

      // 2.4 البحث في جميع مفاتيح user
      print('🔍 البحث في جميع مفاتيح user...');
      user!.forEach((key, value) {
        print('  - $key: $value (${value.runtimeType})');
        if (key.toString().toLowerCase().contains('phone') && value != null) {
          print('✅ وجد حقل هاتف: $key = $value');
        }
      });
    }

    // 3. إذا لم يجد، استخدام رقم افتراضي
    print('⚠️ استخدام رقم افتراضي: 1234567');
    return '1234567'; // الرقم الافتراضي الموجود في بياناتك
  }}

String getFullImageUrl(String imagePath) {
  if (imagePath.isEmpty || imagePath == 'null' || imagePath == 'undefined') {
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