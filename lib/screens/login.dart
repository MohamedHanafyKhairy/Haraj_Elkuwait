import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../widgets/bottom_nav_bar.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}
final API_BASE_URL = "http://haraj.runasp.net";

class _LoginPageState extends State<LoginPage> {
  int _currentIndex = 0;


  final List<Widget> _forms = [];

  @override
  void initState() {
    super.initState();
    _forms.addAll([
      LoginForm(
        onSwitchToRegister: () => _switchForm(1),
        onLoginSuccess: () => _onLoginSuccess(),
      ),
      RegisterForm(
        onSwitchToLogin: () => _switchForm(0),
        onVerify: (email) => _switchToVerify(email),
      ),
      VerifyForm(
        email: '',
        onBack: () => _switchForm(0),
      ),
      ForgotPasswordForm(
        onBack: () => _switchForm(0),
        onReset: (email) => _switchToReset(email),
      ),
      ResetPasswordForm(
        email: '',
        onBack: () => _switchForm(3),
      ),
    ]);
  }

  void _switchForm(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _switchToVerify(String email) {
    setState(() {
      _forms[2] = VerifyForm(email: email, onBack: () => _switchForm(0));
      _currentIndex = 2;
    });
  }

  void _switchToReset(String email) {
    setState(() {
      _forms[4] = ResetPasswordForm(email: email, onBack: () => _switchForm(3));
      _currentIndex = 4;
    });
  }

  void _onLoginSuccess() {
    // بعد نجاح تسجيل الدخول، العودة للصفحة الرئيسية
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'حراج الكويت',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e3a8a),
                        ),
                      ),
                      Text(
                        'سريع • بسيط • سهل',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748b),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form Container
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _forms[_currentIndex],
                  ),
                ),
              ),
            ),

            // في الجزء السفلي من build method في _LoginPageState
// استبدل هذا الكود:

// Botto
// بـ هذا الكود:

// استيراد BottomNavBar إذا لم يكن مستورداً
            BottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                // التعامل مع التنقل بين الصفحات
                if (index == 0) {
                  // الرئيسية
                  Navigator.of(context).pushReplacementNamed('/');
                } else if (index == 1) {
                  // المفضلة
                  Navigator.of(context).pushNamed('/favorites');
                } else if (index == 2) {
                  // إضافة إعلان
                  Navigator.of(context).pushNamed('/add-ad');
                } else if (index == 3) {
                  // إعلاناتي
                  Navigator.of(context).pushNamed('/my-ads');
                } else if (index == 4) {
                  // الإعدادات
                  Navigator.of(context).pushNamed('/settings');
                }
              },
            ),          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 24,
          color: _currentIndex == index ? Color(0xFF1e3a8a) : Color(0xFF64748b),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _currentIndex == index ? Color(0xFF1e3a8a) : Color(0xFF64748b),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF64748b)),
      ),
      child: Icon(
        Icons.add,
        color: Color(0xFF64748b),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  final VoidCallback onSwitchToRegister;
  final VoidCallback onLoginSuccess;

  LoginForm({required this.onSwitchToRegister, required this.onLoginSuccess});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${API_BASE_URL}/api/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // استخراج التوكن وبيانات المستخدم
        final token = data['token'] ?? data['access_token'];
        final userData = data['user'] ?? {
          'userID': data['userID'] ?? 0,
          'email': _emailController.text,
          'phone': data['phone'] ?? '',
          'fullName': data['fullName'] ?? '',
          'isVerified': data['isVerified'] ?? false,
        };

        if (token != null) {
          // حفظ البيانات في SharedPreferences
          await AuthService.saveUserData(token, userData);

          _showMessage('تم تسجيل الدخول بنجاح!', true);

          // الانتقال للصفحة الرئيسية بعد ثانية
          Future.delayed(Duration(seconds: 1), () {
            widget.onLoginSuccess();
          });
        } else {
          _showMessage('بيانات الدخول غير صحيحة', false);
        }
      } else {
        final errorData = json.decode(response.body);
        _showMessage(errorData['message'] ?? 'بيانات الدخول غير صحيحة', false);
      }
    } catch (e) {
      _showMessage('حدث خطأ في الاتصال', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'مرحبا بك مرة أخرى في حراج الكويت',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Email Field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال البريد الإلكتروني';
                }
                if (!value.contains('@')) {
                  return 'يرجى إدخال بريد إلكتروني صحيح';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال كلمة المرور';
                }
                if (value.length < 6) {
                  return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                }
                return null;
              },
            ),
            SizedBox(height: 8),

            // Forgot Password
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  // Navigate to forgot password
                },
                child: Text(
                  'نسيت كلمة المرور؟',
                  style: TextStyle(color: Color(0xFF3b82f6)),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1e3a8a),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'تسجيل الدخول',
                  style: TextStyle(fontSize: 16,color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 24),

            // Register Link
            Center(
              child: TextButton(
                onPressed: widget.onSwitchToRegister,
                child: Text(
                  'ليس لديك حساب؟ أنشئ حساب جديد',
                  style: TextStyle(color: Color(0xFF3b82f6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  final Function(String) onVerify;

  RegisterForm({required this.onSwitchToLogin, required this.onVerify});

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  bool _validateKuwaitiPhone(String phone) {
    final pattern = RegExp(r'^[569]\d{7}$');
    return pattern.hasMatch(phone);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://haraj.runasp.net/api/Auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'phone': _phoneController.text,
        }),
      );

      if (response.statusCode == 200) {
        _showMessage('تم إنشاء الحساب بنجاح! تم إرسال رمز التفعيل', true);
        widget.onVerify(_emailController.text);
      } else {
        final error = json.decode(response.body);
        _showMessage(error['message'] ?? 'فشل إنشاء الحساب', false);
      }
    } catch (e) {
      _showMessage('حدث خطأ في الاتصال', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            TextButton(
              onPressed: widget.onSwitchToLogin,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16),
                  SizedBox(width: 4),
                  Text('العودة لتسجيل الدخول'),
                ],
              ),
            ),

            // Header
            Center(
              child: Column(
                children: [
                  Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'انضم إلى حراج الكويت وابدأ في نشر إعلاناتك',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Email Field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال البريد الإلكتروني';
                }
                if (!value.contains('@')) {
                  return 'يرجى إدخال بريد إلكتروني صحيح';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال كلمة المرور';
                }
                if (value.length < 6) {
                  return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Phone Field
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefix: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('+965'),
                ),
                hintText: '5XXXXXXX',
              ),
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال رقم الهاتف';
                }
                if (!_validateKuwaitiPhone(value)) {
                  return 'يرجى إدخال رقم هاتف كويتي صحيح';
                }
                return null;
              },
            ),
            SizedBox(height: 8),
            Text(
              'يجب أن يبدأ الرقم بـ 5، 6 أو 9',
              style: TextStyle(color: Color(0xFF64748b), fontSize: 12),
            ),
            SizedBox(height: 24),

            // Register Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1e3a8a),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'إنشاء الحساب',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Login Link
            Center(
              child: TextButton(
                onPressed: widget.onSwitchToLogin,
                child: Text(
                  'لديك حساب بالفعل؟ سجل الدخول',
                  style: TextStyle(color: Color(0xFF3b82f6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerifyForm extends StatefulWidget {
  final String email;
  final VoidCallback onBack;

  VerifyForm({required this.email, required this.onBack});

  @override
  _VerifyFormState createState() => _VerifyFormState();
}

class _VerifyFormState extends State<VerifyForm> {
  final List<TextEditingController> _codeControllers =
  List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _codeControllers[i].addListener(() {
        if (_codeControllers[i].text.isNotEmpty && i < 5) {
          _focusNodes[i + 1].requestFocus();
        }
      });
    }
  }

  String _getCode() {
    return _codeControllers.map((c) => c.text).join();
  }

  Future<void> _verify() async {
    final code = _getCode();
    if (code.length != 6) {
      _showMessage('يرجى إدخال رمز التفعيل المكون من 6 أرقام', false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://haraj.runasp.net/api/Auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // إذا كان الرد يحتوي على بيانات المستخدم، احفظها
        if (data['token'] != null || data['user'] != null) {
          final token = data['token'] ?? data['access_token'];
          final userData = data['user'] ?? {
            'userID': data['userID'] ?? 0,
            'email': widget.email,
            'isVerified': true,
          };

          if (token != null) {
            await AuthService.saveUserData(token, userData);
          }
        }

        _showMessage('تم تفعيل الحساب بنجاح!', true);
        Future.delayed(Duration(seconds: 2), widget.onBack);
      } else {
        _showMessage('رمز التفعيل غير صحيح', false);
      }
    } catch (e) {
      _showMessage('حدث خطأ في الاتصال', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          TextButton(
            onPressed: widget.onBack,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 16),
                SizedBox(width: 4),
                Text('العودة لتسجيل الدخول'),
              ],
            ),
          ),

          // Header
          Center(
            child: Column(
              children: [
                Text(
                  'تفعيل الحساب',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'أدخل رمز التفعيل الذي استلمته على بريدك الإلكتروني',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748b),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          // Code Inputs
          Text(
            'رمز التفعيل (6 أرقام)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 40,
                child: TextField(
                  controller: _codeControllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          SizedBox(height: 24),

          // Verify Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1e3a8a),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                'تفعيل الحساب',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordForm extends StatefulWidget {
  final VoidCallback onBack;
  final Function(String) onReset;

  ForgotPasswordForm({required this.onBack, required this.onReset});

  @override
  _ForgotPasswordFormState createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://haraj.runasp.net/api/Auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
        }),
      );

      if (response.statusCode == 200) {
        _showMessage('تم إرسال رمز إعادة التعيين', true);
        widget.onReset(_emailController.text);
      } else {
        _showMessage('البريد الإلكتروني غير مسجل', false);
      }
    } catch (e) {
      _showMessage('حدث خطأ في الاتصال', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            TextButton(
              onPressed: widget.onBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16),
                  SizedBox(width: 4),
                  Text('العودة لتسجيل الدخول'),
                ],
              ),
            ),

            // Header
            Center(
              child: Column(
                children: [
                  Text(
                    'نسيت كلمة المرور',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'أدخل بريدك الإلكتروني لإرسال رمز إعادة التعيين',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Email Field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.rtl,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال البريد الإلكتروني';
                }
                if (!value.contains('@')) {
                  return 'يرجى إدخال بريد إلكتروني صحيح';
                }
                return null;
              },
            ),
            SizedBox(height: 24),

            // Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendResetCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1e3a8a),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'إرسال رمز إعادة التعيين',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordForm extends StatefulWidget {
  final String email;
  final VoidCallback onBack;

  ResetPasswordForm({required this.email, required this.onBack});

  @override
  _ResetPasswordFormState createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final List<TextEditingController> _codeControllers =
  List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _codeControllers[i].addListener(() {
        if (_codeControllers[i].text.isNotEmpty && i < 5) {
          _focusNodes[i + 1].requestFocus();
        }
      });
    }
  }

  String _getCode() {
    return _codeControllers.map((c) => c.text).join();
  }

  Future<void> _resetPassword() async {
    final code = _getCode();
    if (code.length != 6) {
      _showMessage('يرجى إدخال رمز إعادة التعيين المكون من 6 أرقام', false);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showMessage('كلمة المرور يجب أن تكون 6 أحرف على الأقل', false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://haraj.runasp.net/api/Auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'code': code,
          'newPassword': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        _showMessage('تم إعادة تعيين كلمة المرور بنجاح!', true);
        Future.delayed(Duration(seconds: 2), widget.onBack);
      } else {
        _showMessage('رمز إعادة التعيين غير صحيح', false);
      }
    } catch (e) {
      _showMessage('حدث خطأ في الاتصال', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          TextButton(
            onPressed: widget.onBack,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 16),
                SizedBox(width: 4),
                Text('العودة'),
              ],
            ),
          ),

          // Header
          Center(
            child: Column(
              children: [
                Text(
                  'إعادة تعيين كلمة المرور',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'أدخل رمز إعادة التعيين وكلمة المرور الجديدة',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748b),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          // Code Inputs
          Text(
            'رمز إعادة التعيين (6 أرقام)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 40,
                child: TextField(
                  controller: _codeControllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          SizedBox(height: 16),

          // New Password Field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الجديدة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 24),

          // Reset Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1e3a8a),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                'إعادة تعيين كلمة المرور',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}