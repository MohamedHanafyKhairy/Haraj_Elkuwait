// lib/services/visit_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VisitService {
  static const String _visitedAdsKey = 'visited_ads';
  static const String apiBaseUrl = 'http://haraj.runasp.net';

  // التحقق من زيارة الإعلان من قبل
  static Future<bool> hasAdBeenVisited(int adId) async {
    final prefs = await SharedPreferences.getInstance();
    final visitedAds = prefs.getStringList(_visitedAdsKey) ?? [];
    return visitedAds.contains(adId.toString());
  }

  // تخزين الإعلان كمزار
  static Future<void> markAdAsVisited(int adId) async {
    final prefs = await SharedPreferences.getInstance();
    final visitedAds = prefs.getStringList(_visitedAdsKey) ?? [];

    if (!visitedAds.contains(adId.toString())) {
      visitedAds.add(adId.toString());
      await prefs.setStringList(_visitedAdsKey, visitedAds);
    }
  }

  // إرسال زيارة إلى API
  static Future<bool> sendVisit(int adId) async {
    try {
      // التحقق من عدم زيارة الإعلان من قبل
      final hasVisited = await hasAdBeenVisited(adId);
      if (hasVisited) {
        print('الإعلان $adId تمت زيارته من قبل');
        return false;
      }

      // إرسال طلب الزيارة
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/Visits'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'adID': adId,
          'visitDate': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // تخزين الإعلان كمزار
        await markAdAsVisited(adId);
        print('تم تسجيل زيارة الإعلان $adId بنجاح');
        return true;
      } else {
        print('فشل إرسال الزيارة: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('خطأ في إرسال الزيارة: $e');
      return false;
    }
  }

  // إعادة تعيين الزيارات المحفوظة (للتطوير)
  static Future<void> resetVisitedAds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_visitedAdsKey);
  }
}