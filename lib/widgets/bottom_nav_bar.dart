import 'package:flutter/material.dart';
import '../utils/constants.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70, // ارتفاع ثابت
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // الإعدادات (كانت آخر عنصر، أصبحت أول عنصر)
          _buildNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'الإعدادات',
            index: 4,
            isActive: currentIndex == 4,
          ),

          // إعلاناتي
          _buildNavItem(
            icon: Icons.chat_outlined,
            activeIcon: Icons.chat,
            label: 'إعلاناتي',
            index: 3,
            isActive: currentIndex == 3,
          ),

          _buildNavItem(
            icon: Icons.add,          // أيقونة الخطية العادية
            activeIcon: Icons.add,    // نفس الأيقونة عند النشاط
            label: 'إضافة',
            index: 2,
            isActive: currentIndex == 2,
          ),
          // المفضلة
          _buildNavItem(
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            label: 'المفضلة',
            index: 1,
            isActive: currentIndex == 1,
          ),

          // الرئيسية (كانت أول عنصر، أصبحت آخر عنصر)
          _buildNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_filled,
            label: 'الرئيسية',
            index: 0,
            isActive: currentIndex == 0,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primaryColor : AppColors.grayColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppColors.primaryColor : AppColors.grayColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}