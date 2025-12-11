import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class PoliceAfterLogin extends StatefulWidget {
  final bool showAgreeButton; // إضافة معامل اختياري

  const PoliceAfterLogin({Key? key, this.showAgreeButton = true}) : super(key: key);

  @override
  _PolicyPageState createState() => _PolicyPageState();
}

class _PolicyPageState extends State<PoliceAfterLogin> {
  bool isArabic = true;
  bool isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.primaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isArabic ? 'الشروط والخصوصية' : 'Terms & Privacy',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // محتوى السياسة
                    _buildPolicyCard(
                      isArabic ? '١. نظرة عامة' : '1. Overview',
                      isArabic
                          ? 'مرحباً بك في تطبيق حراج الكويت. باستخدامك للتطبيق، فإنك توافق على الالتزام بالشروط والأحكام المذكورة أدناه. نحن نلتزم بحماية خصوصيتك وبياناتك الشخصية.'
                          : 'Welcome to Kuwait Haraj app. By using our app, you agree to comply with the terms and conditions below. We are committed to protecting your privacy and personal data.',
                    ),

                    _buildPolicyCard(
                      isArabic ? '٢. المعلومات التي نجمعها' : '2. Information We Collect',
                      isArabic
                          ? '• بيانات تسجيل الدخول (البريد الإلكتروني، كلمة المرور)\n• معلومات الحساب (الاسم، رقم الهاتف)\n• الإعلانات المنشورة والتفاعلات\n• بيانات استخدام التطبيق (لتحسين الخدمة)'
                          : '• Login data (email, password)\n• Account information (name, phone number)\n• Published ads and interactions\n• App usage data (for service improvement)',
                    ),

                    _buildPolicyCard(
                      isArabic ? '٣. كيفية استخدام معلوماتك' : '3. How We Use Your Information',
                      isArabic
                          ? '• تقديم وتحسين خدمات التطبيق\n• التواصل بشأن إعلاناتك وطلباتك\n• تحليل استخدام التطبيق لتطويره\n• منع الاحتيال والمخالفات'
                          : '• Provide and improve app services\n• Communicate about your ads and requests\n• Analyze app usage for development\n• Prevent fraud and violations',
                    ),

                    _buildPolicyCard(
                      isArabic ? '٤. مسؤوليات المستخدم' : '4. User Responsibilities',
                      isArabic
                          ? '• الالتزام بالقوانين المحلية والدولية\n• عدم نشر محتوى مسيء أو غير قانوني\n• الحفاظ على سرية بيانات الحساب\n• الإبلاغ عن أي انتهاكات تراها'
                          : '• Comply with local and international laws\n• Do not post offensive or illegal content\n• Maintain account data confidentiality\n• Report any violations you encounter',
                    ),

                    _buildPolicyCard(
                      isArabic ? '٥. حقوق المستخدم' : '5. User Rights',
                      isArabic
                          ? '• الوصول إلى بياناتك الشخصية\n• طلب تصحيح أو حذف بياناتك\n• إلغاء الاشتراك في أي وقت\n• سحب الموافقة على جمع البيانات'
                          : '• Access your personal data\n• Request correction or deletion of your data\n• Unsubscribe at any time\n• Withdraw consent for data collection',
                    ),

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard(String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.darkColor,
            ),
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementBox() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: isAgreed,
                onChanged: (value) {
                  setState(() {
                    isAgreed = value ?? false;
                  });
                },
                activeColor: AppColors.primaryColor,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  isArabic
                      ? 'أوافق على الشروط والأحكام أعلاه'
                      : 'I agree to the above terms and conditions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            isArabic
                ? 'بالنقر على "موافق ومتابعة"، فإنك توافق على جميع الشروط والأحكام'
                : 'By clicking "Agree & Continue", you agree to all terms and conditions',
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

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                side: BorderSide(color: AppColors.grayColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isArabic ? 'إلغاء' : 'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.grayColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: isAgreed ? () {
                // حفظ موافقة المستخدم
                _saveAgreement();
                // الانتقال إلى صفحة تسجيل الدخول
                Navigator.pushReplacementNamed(context, '/login');
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAgreed ? AppColors.primaryColor : AppColors.grayColor,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isArabic ? 'موافق ومتابعة' : 'Agree & Continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAgreement() async {
    // حفظ موافقة المستخدم في SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('agreed_to_terms', true);
    print('User agreed to terms and conditions');
  }
}