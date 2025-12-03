import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

Future<dynamic> goToCategorySelectionScreen({
  String? selectedCategory,
  String? selectedSubcategory,
}) async {
  if (kIsWeb) {
    return customDialog(
      child: CategorySelectionScreen(
        selectedCategory: selectedCategory,
        selectedSubcategory: selectedSubcategory,
      ),
      title: 'Select Category',
    );
  } else {
    return Get.to(
      () => CategorySelectionScreen(
        selectedCategory: selectedCategory,
        selectedSubcategory: selectedSubcategory,
      ),
    );
  }
}

class CategorySelectionScreen extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedSubcategory;

  const CategorySelectionScreen({
    super.key,
    this.selectedCategory,
    this.selectedSubcategory,
  });

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  String? _selectedSubcategory;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _selectedSubcategory = widget.selectedSubcategory;
    _filteredCategories = CategoryData.categories;
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = CategoryData.categories;
      } else {
        _filteredCategories = CategoryData.categories.where((category) {
          final categoryName = category['name'] as String;
          final subcategories = category['subcategories'] as List<String>;

          return categoryName.toLowerCase().contains(query.toLowerCase()) ||
              subcategories.any(
                (subcat) => subcat.toLowerCase().contains(query.toLowerCase()),
              );
        }).toList();
      }
    });
  }

  void _selectSubcategory(String category, String subcategory) {
    final result = <String, String>{category: subcategory};
    Get.back(result: result);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text('Select Category')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              onChanged: _filterCategories,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCategories.length,
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 50),
              itemBuilder: (context, index) {
                final category = _filteredCategories[index];
                final categoryName = category['name'] as String;
                final subcategories = category['subcategories'] as List<String>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildCategorySection(
                    categoryName,
                    subcategories,
                    colorScheme,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    String categoryName,
    List<String> subcategories,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Icon(
          _getCategoryIcon(categoryName),
          color: colorScheme.primary,
          size: 20,
        ),
        title: AppText(categoryName, fontSize: 14),
        tilePadding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
        initiallyExpanded: true,
        dense: true,
        shape: RoundedRectangleBorder(),
        collapsedShape: RoundedRectangleBorder(),
        collapsedBackgroundColor: Colors.transparent,
        children: subcategories.map((subcategory) {
          final isSelected = _selectedSubcategory == subcategory;
          return Padding(
            padding: EdgeInsetsGeometry.all(2),
            child: ListTile(
              leading: const SizedBox(width: 40),
              shape: RoundedRectangleBorder(),
              title: AppText(
                subcategory,
                fontSize: 14,
                color: isSelected ? colorScheme.primary : Colors.grey,
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              dense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 0),
              onTap: () => _selectSubcategory(categoryName, subcategory),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Expense':
        return Icons.money_off;
      case 'Income':
        return Icons.attach_money_outlined;
      case 'Cost of Goods Sold (COS)':
        return Icons.inventory_outlined;
      case 'Other Current Asset':
        return Icons.account_balance_wallet_outlined;
      case 'Equity':
        return Icons.balance_outlined;
      case 'Other Expense':
        return Icons.warning_amber_sharp;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
