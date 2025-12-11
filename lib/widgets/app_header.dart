import 'package:flutter/material.dart';
import 'package:mobile_app_haraj/screens/login.dart';
import '../utils/constants.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize =>  Size.fromHeight(85);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: AppBar(
          elevation: 2,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          automaticallyImplyLeading: false,

          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    AppStrings.appTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    AppStrings.appSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grayColor,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}