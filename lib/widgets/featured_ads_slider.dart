// import 'package:flutter/material.dart';
// import '../models/ad_model.dart';
// import 'ad_card.dart';
//
// class FeaturedAdsSlider extends StatelessWidget {
//   final List<Ad> ads;
//
//   const FeaturedAdsSlider({
//     super.key,
//     required this.ads,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 260,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         reverse: true,
//
//         padding: const EdgeInsets.symmetric(horizontal: 10),
//         itemCount: ads.length > 10 ? 10 : ads.length,
//         itemBuilder: (context, index) {
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 5),
//             child: AdCard(
//               ad: ads[index],
//               width: MediaQuery.of(context).size.width * 0.45,
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../models/ad_model.dart';
import 'ad_card.dart';

class FeaturedAdsSlider extends StatelessWidget {
  final List<Ad> ads;

  const FeaturedAdsSlider({
    super.key,
    required this.ads,
  });

  @override
  Widget build(BuildContext context) {
    // 1. التغيير الأول: إضافة Directionality للتحكم في الاتجاه
    return Directionality(
      textDirection: TextDirection.rtl, // تحديد الاتجاه من اليمين لليسار
      child: SizedBox(
        height: 260,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          // 2. التغيير الثاني: إزالة reverse: true (أصبحت false افتراضياً)
          // لأن الاتجاه العربي (RTL) يبدأ طبيعياً من اليمين
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: ads.length > 10 ? 10 : ads.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: AdCard(
                ad: ads[index],
                width: MediaQuery.of(context).size.width * 0.45,
              ),
            );
          },
        ),
      ),
    );
  }
}