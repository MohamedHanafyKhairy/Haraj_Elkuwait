import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:mobile_app_haraj/models/category_model.dart';
import 'package:mobile_app_haraj/services/api_service.dart';
import 'package:mobile_app_haraj/services/auth_service.dart';
import 'package:mobile_app_haraj/utils/constants.dart';

class AddAdScreen extends StatefulWidget {
  final String adType;
  final Map<String, dynamic> userProfile;

  const AddAdScreen({
    super.key,
    required this.adType,
    required this.userProfile,
  });

  @override
  State<AddAdScreen> createState() => _AddAdScreenState();
}

class _AddAdScreenState extends State<AddAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  List<Category> _allCategoriesFlat = [];
  String? _selectedCategoryId;

  List<File> _selectedImages = [];
  List<Uint8List> _selectedImagesBytes = [];
  Uint8List? _mainImageBytes;

  final ImagePicker _picker = ImagePicker();
  File? _mainImage;

  bool _isLoading = false;
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await ApiService.getCategories();
      setState(() {
        _allCategoriesFlat = _flattenCategories(categories);
      });
    } catch (e) {
      print('خطأ في تحميل الفئات: $e');
      _showErrorDialog('فشل في تحميل الفئات');
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  List<Category> _flattenCategories(List<Category> categories, {int level = 0}) {
    List<Category> flatList = [];

    for (var category in categories) {
      // إنشاء نسخة من الفئة مع إضافة level
      final categoryWithLevel = Category(
        categoryID: category.categoryID,
        name: category.name,
        iconUrl: category.iconUrl,
        subCategories: category.subCategories,
        parentID: category.parentID,
        level: level,
      );
      flatList.add(categoryWithLevel);

      if (category.subCategories != null && category.subCategories!.isNotEmpty) {
        flatList.addAll(
            _flattenCategories(category.subCategories!, level: level + 1)
        );
      }
    }

    return flatList;
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 7) {
      _showErrorDialog('لا يمكن إضافة أكثر من 7 صور');
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final remainingSlots = 7 - _selectedImages.length;
        final imagesToAdd = images.take(remainingSlots).toList();

        // نخزن الصور كـ bytes للويب
        final List<Uint8List> newImageBytes = [];

        for (var image in imagesToAdd) {
          final bytes = await image.readAsBytes();
          newImageBytes.add(bytes);
        }

        setState(() {
          for (var image in imagesToAdd) {
            if (!kIsWeb) {
              _selectedImages.add(File(image.path));
            }
          }

          // نضيف bytes للويب
          _selectedImagesBytes.addAll(newImageBytes);

          if (_mainImage == null && imagesToAdd.isNotEmpty) {
            if (kIsWeb) {
              _mainImageBytes = newImageBytes.first;
            } else {
              _mainImage = File(imagesToAdd.first.path);
            }
            _mainImageBytes = newImageBytes.first;
          }
        });
      }
    } catch (e) {
      print('خطأ في اختيار الصور: $e');
      _showErrorDialog('حدث خطأ أثناء اختيار الصور');
    }
  }

  void _setMainImage(int index) {
    setState(() {
      _mainImage = _selectedImages[index];
      if (index < _selectedImagesBytes.length) {
        _mainImageBytes = _selectedImagesBytes[index];
      }
    });
  }

  void _removeImage(int index) {
    setState(() {
      if (_selectedImages[index] == _mainImage) {
        _mainImage = _selectedImages.length > 1
            ? (index > 0 ? _selectedImages[0] : _selectedImages[1])
            : null;
        _mainImageBytes = _selectedImagesBytes.length > 1
            ? (index > 0 ? _selectedImagesBytes[0] : _selectedImagesBytes[1])
            : null;
      }
      _selectedImages.removeAt(index);
      if (index < _selectedImagesBytes.length) {
        _selectedImagesBytes.removeAt(index);
      }
    });
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      _showErrorDialog('يرجى اختيار الفئة');
      return;
    }

    if (_selectedImages.isEmpty && _selectedImagesBytes.isEmpty) {
      _showErrorDialog('يرجى إضافة صورة واحدة على الأقل');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ أولاً: التحقق من الحصة
      final hasQuota = await checkAdQuota();
      if (!hasQuota) {
        _showQuotaExceededDialog();
        return;
      }

      // جلب بيانات المستخدم
      final userMap = await AuthService.getUserInfo();
      if (userMap == null) {
        _showErrorDialog('يرجى تسجيل الدخول أولاً');
        return;
      }

      final userId = userMap['userID'] ?? userMap['UserID'] ?? 0;
      if (userId == 0) {
        _showErrorDialog('معلومات المستخدم غير مكتملة');
        return;
      }

      final categoryId = int.tryParse(_selectedCategoryId!);
      if (categoryId == null) {
        _showErrorDialog('فئة غير صالحة');
        return;
      }

      final price = double.tryParse(_priceController.text);
      if (price == null || price <= 0) {
        _showErrorDialog('يرجى إدخال سعر صحيح');
        return;
      }

      // حساب تاريخ الانتهاء (30 يوم من الآن)
      final expiresAt = DateTime.now().add(const Duration(days: 30));

      // طباعة البيانات للتأكد
      print('🎯 بيانات الإعلان المراد إرساله:');
      print('  - UserID: $userId');
      print('  - CategoryID: $categoryId');
      print('  - Title: ${_titleController.text}');
      print('  - Description: ${_descriptionController.text}');
      print('  - Price: $price');
      print('  - AdType: ${widget.adType}');
      print('  - ExpiresAt: ${expiresAt.toIso8601String()}');
      print('  - Number of images: ${_selectedImages.length}');
      print('  - Number of image bytes: ${_selectedImagesBytes.length}');

      final success = await ApiService.createAd(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        categoryId: categoryId,
        adType: widget.adType,
        userId: userId,
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
        imagesBytes: _selectedImagesBytes.isNotEmpty ? _selectedImagesBytes : null,
        expiresAt: expiresAt,
      );

      if (success && mounted) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('فشل في نشر الإعلان. يرجى المحاولة مرة أخرى');
      }
    } catch (e) {
      print('🚨 خطأ في إرسال الإعلان: $e');
      _showErrorDialog('حدث خطأ أثناء نشر الإعلان: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> checkAdQuota() async {
    try {
      final user = await AuthService.getUserInfo();
      if (user == null) return false;

      final userId = user['userID'] ?? user['UserID'] ?? 0;
      final token = await AuthService.getToken();

      if (token == null || userId == 0) return false;

      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/Quota/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final quotaData = json.decode(response.body);

        // حساب الإعلانات المتاحة
        final maxNormalAds = quotaData['maxNormalAds'] ?? 0;
        final activeNormalAds = quotaData['activeNormalAds'] ?? 0;
        final availableNormalSlots = maxNormalAds - activeNormalAds;

        final maxPrimeAds = quotaData['maxPrimeAds'] ?? 0;
        final activePrimeAds = quotaData['activePrimeAds'] ?? 0;
        final availablePrimeSlots = maxPrimeAds - activePrimeAds;

        print('📊 حصة المستخدم:');
        print('  - الإعلانات العادية المسموح بها: $maxNormalAds');
        print('  - الإعلانات العادية النشطة: $activeNormalAds');
        print('  - الإعلانات العادية المتاحة: $availableNormalSlots');
        print('  - الإعلانات المميزة المسموح بها: $maxPrimeAds');
        print('  - الإعلانات المميزة النشطة: $activePrimeAds');
        print('  - الإعلانات المميزة المتاحة: $availablePrimeSlots');

        // التحقق حسب نوع الإعلان
        if (widget.adType == 'عادي') {
          return availableNormalSlots > 0;
        } else if (widget.adType == 'مميز') {
          return availablePrimeSlots > 0;
        }
      }

      return true; // في حالة الخطأ، نسمح بالمحاولة
    } catch (e) {
      print('❌ خطأ في التحقق من الحصة: $e');
      return true;
    }
  }

  void _showQuotaExceededDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تم الوصول للحد الأقصى',
          style: TextStyle(color: Colors.orange),
        ),
        content: Text(
          widget.adType == 'عادي'
              ? 'لقد وصلت للحد الأقصى من الإعلانات العادية المسموح بها.\n\nيمكنك:\n1. حذف بعض إعلاناتك السابقة\n2. ترقية حسابك\n3. اختيار نوع الإعلان "مميز"'
              : 'لقد وصلت للحد الأقصى من الإعلانات المميزة المسموح بها.\n\nيمكنك:\n1. حذف بعض إعلاناتك السابقة\n2. ترقية حسابك\n3. اختيار نوع الإعلان "عادي"',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
          if (widget.adType == 'عادي')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // الانتقال لشاشة الإعلانات المميزة
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddAdScreen(
                      adType: 'مميز',
                      userProfile: widget.userProfile,
                    ),
                  ),
                );
              },
              child: const Text('جرب إعلان مميز'),
            ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'تم النشر بنجاح',
          style: TextStyle(color: Colors.green),
        ),
        content: const Text('تم نشر إعلانك بنجاح وسيظهر قريباً'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لعرض الصور بشكل آمن على الويب والجوال
  Widget _buildWebSafeImage(File? imageFile, {double? width, double? height}) {
    if (imageFile == null) {
      return Container(
        color: Colors.grey[200],
        width: width,
        height: height,
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }

    if (kIsWeb) {
      // على الويب: استخدم FutureBuilder لتحويل File إلى bytes
      return FutureBuilder<Uint8List>(
        future: imageFile.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              width: width,
              height: height,
              fit: BoxFit.cover,
            );
          } else {
            return Container(
              color: Colors.grey[200],
              width: width,
              height: height,
              child: const CircularProgressIndicator(),
            );
          }
        },
      );
    } else {
      // على الجوال: استخدم Image.file مباشرة
      return Image.file(
        imageFile,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.primaryColor,
        child: Column(
          children: [
            Container(
              color: AppColors.primaryColor,
              padding: const EdgeInsets.only(
                top: 40,
                bottom: 20,
                right: 20,
                left: 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'إضافة إعلان - ${widget.adType == 'مميز' ? 'مميز' : 'عادي'}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBreadcrumb(),
                        const SizedBox(height: 20),
                        _buildAdForm(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                const Icon(Icons.home, size: 18, color: AppColors.primaryColor),
                const SizedBox(width: 5),
                Text(
                  'الرئيسية',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
          const SizedBox(width: 10),
          const Text(
            'إضافة إعلان',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
          const SizedBox(width: 10),
          Text(
            widget.adType == 'مميز' ? 'إعلان مميز' : 'إعلان عادي',
            style: const TextStyle(
              color: AppColors.darkColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImagesSection(),
          const SizedBox(height: 30),
          _buildTitleField(),
          const SizedBox(height: 20),
          _buildDescriptionField(),
          const SizedBox(height: 20),
          _buildAdInfoSection(),
          const SizedBox(height: 30),
          _buildPublishButton(),
          const SizedBox(height: 20),
          _buildCancelButton(),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الصور (الحد الأقصى 7 صور)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkColor,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImages,
          child: DottedBorder(
            borderType: BorderType.RRect,
            radius: const Radius.circular(12),
            padding: const EdgeInsets.all(20),
            color: AppColors.primaryColor.withOpacity(0.5),
            dashPattern: const [8, 4],
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.lightColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _mainImage != null
                  ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildWebSafeImage(
                      _mainImage,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'الصورة الرئيسية',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: AppColors.primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'انقر لرفع الصور',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.grayColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_selectedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الصور المرفوعة:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkColor,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                    _selectedImages.length + (_selectedImages.length < 7 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _selectedImages.length) {
                        return GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primaryColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.lightColor,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: AppColors.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'إضافة',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedImages[index] == _mainImage
                                ? AppColors.primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildWebSafeImage(
                                _selectedImages[index],
                                width: 80,
                                height: 80,
                              ),
                            ),
                            Positioned(
                              top: 3,
                              right: 3,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                            if (_selectedImages[index] != _mainImage)
                              Positioned(
                                bottom: 3,
                                right: 3,
                                child: GestureDetector(
                                  onTap: () => _setMainImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.star_border,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'عنوان الإعلان',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkColor,
            ),
            decoration: const InputDecoration(
              hintText: 'أدخل عنوان الإعلان',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال عنوان الإعلان';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'وصف الإعلان',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _descriptionController,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.darkColor,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              hintText: 'أدخل وصف الإعلان...',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            maxLines: 6,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال وصف الإعلان';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.monetization_on_outlined,
                color: AppColors.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'السعر (د.ك)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkColor,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال السعر';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'يرجى إدخال سعر صحيح';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                color: AppColors.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الفئة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _isLoadingCategories
                          ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      )
                          : DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                          ),
                          items: _allCategoriesFlat.map((category) {
                            final prefix =
                                '    ' * (category.level ?? 0);
                            return DropdownMenuItem<String>(
                              value: category.categoryID.toString(),
                              child: Text(
                                '$prefix${category.name}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.darkColor,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى اختيار الفئة';
                            }
                            return null;
                          },
                          hint: const Text(
                            'اختر الفئة',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                Icons.star_border,
                color: widget.adType == 'مميز'
                    ? Colors.amber
                    : AppColors.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'نوع الإعلان',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.adType == 'مميز'
                            ? Colors.amber.withOpacity(0.1)
                            : AppColors.lightColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.adType == 'مميز'
                              ? Colors.amber
                              : AppColors.primaryColor,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.adType == 'مميز' ? 'إعلان مميز' : 'إعلان عادي',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: widget.adType == 'مميز'
                                  ? Colors.amber[800]
                                  : AppColors.primaryColor,
                            ),
                          ),
                          Icon(
                            widget.adType == 'مميز'
                                ? Icons.star
                                : Icons.description,
                            color: widget.adType == 'مميز'
                                ? Colors.amber
                                : AppColors.primaryColor,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.green[700],
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.adType == 'مميز'
                        ? 'لديك ${widget.userProfile['availablePrimeSlots'] ?? 0} إعلان${(widget.userProfile['availablePrimeSlots'] ?? 0) > 1 ? 'ات' : ''} مميز${(widget.userProfile['availablePrimeSlots'] ?? 0) > 1 ? 'ة' : ''} متاحة'
                        : 'لديك ${widget.userProfile['availableNormalSlots'] ?? 0} إعلان${(widget.userProfile['availableNormalSlots'] ?? 0) > 1 ? 'ات' : ''} عادي${(widget.userProfile['availableNormalSlots'] ?? 0) > 1 ? 'ة' : ''} متاحة',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitAd,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.white,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.send, size: 20),
            SizedBox(width: 10),
            Text(
              'نشر الإعلان',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.grayColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'إلغاء',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}