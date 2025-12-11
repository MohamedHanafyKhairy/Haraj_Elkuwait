import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app_haraj/screens/login.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const HarajKuwaitApp());
}

class HarajKuwaitApp extends StatelessWidget {
  const HarajKuwaitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حراج الكويت',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        secondaryHeaderColor: AppColors.secondaryColor,
        hintColor: AppColors.accentColor,
        scaffoldBackgroundColor: AppColors.lightColor,
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.darkColor,
          elevation: 2,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.darkColor,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: AppColors.grayColor,
          ),
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/login': (context) =>  LoginPage(),
      },
    );
  }
}