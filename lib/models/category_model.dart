import '../utils/constants.dart';

class Category {
  final int categoryID;
  final String name;
  final List<String>? images;
  final List<Category>? subCategories;
  final int? parentID;
  final String? iconUrl;
  final int? level;

  Category({
    required this.categoryID,
    required this.name,
    this.images,
    this.subCategories,
    this.parentID,
    this.iconUrl,
    this.level,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryID: json['categoryID'] ?? json['CategoryID'] ?? 0,
      name: json['name'] ?? json['Name'] ?? '',
      images: (json['images'] as List?)?.map((e) => e.toString()).toList(),
      subCategories: (json['subCategories'] as List?)
          ?.map((e) => Category.fromJson(e))
          .toList(),
      parentID: json['parentID'] ?? json['ParentID'],
      iconUrl: json['iconUrl'] ?? json['IconUrl'],
      level: json['level'],
    );
  }

  String get imageUrl {
    if (images == null || images!.isEmpty) return '';
    return images![0].startsWith('http')
        ? images![0]
        : '${ApiConfig.baseUrl}/Images/categories/${images![0]}';
  }
}