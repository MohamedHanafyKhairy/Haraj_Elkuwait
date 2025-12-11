import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final Function({
  double? fromPrice,
  double? toPrice,
  String? type,
  }) onFilterApplied;
  final VoidCallback onResetFilters;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    required this.onFilterApplied,
    required this.onResetFilters,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _priceFromController = TextEditingController();
  final TextEditingController _priceToController = TextEditingController();
  String? _selectedAdType;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(15),

      child: Column(

        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryColor, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() => _showFilters = !_showFilters);
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    decoration: BoxDecoration(
                      color: _showFilters
                          ? AppColors.secondaryColor
                          : AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.filter_list,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                        Expanded(
                  child: TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: AppStrings.search,
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 14),
                    ),
                    onChanged: (value) {
                      widget.onSearch(value);
                    },
                  ),
                ),  const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Icon(
                    Icons.search,
                    color: AppColors.grayColor,
                    size: 20,
                  ),
                ),

              ],
            ),
          ),

          if (_showFilters) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceFromController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: 'السعر من',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _priceToController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: 'السعر إلى',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    hint: const Text('نوع الإعلان'),
                    value: _selectedAdType,
                    items: [
                      'جميع الإعلانات',
                      'مميز',
                      'عادي',
                    ].map((e) => DropdownMenuItem(
                      value: e == 'جميع الإعلانات' ? null : e,
                      child: Text(e),
                    )).toList(),
                    onChanged: (value) {
                      setState(() => _selectedAdType = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onFilterApplied(
                              fromPrice: _priceFromController.text.isNotEmpty
                                  ? double.parse(_priceFromController.text)
                                  : null,
                              toPrice: _priceToController.text.isNotEmpty
                                  ? double.parse(_priceToController.text)
                                  : null,
                              type: _selectedAdType,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('تطبيق الفلاتر',style: TextStyle(color: Colors.white),),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          _priceFromController.clear();
                          _priceToController.clear();
                          setState(() => _selectedAdType = null);
                          widget.onResetFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.grayColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('إعادة تعيين',style: TextStyle(color: Colors.white),),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}