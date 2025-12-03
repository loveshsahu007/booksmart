import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/user/ui/transaction/category_selection_screen.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../widgets/custom_dialog.dart';
import '../../../../widgets/custom_drop_down.dart';
import 'receipt_scanning_output_screen.dart';

void goToAddTransactionScreen({bool shouldCloseBefore = false}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back();
    }
    customDialog(
      child: AddTransactionScreenManual(),
      title: 'Add Transaction',
      barrierDismissible: true,
      actionWidgetList: [
        IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(Icons.delete_forever),
        ),
      ],
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => const AddTransactionScreenManual());
    } else {
      Get.to(() => const AddTransactionScreenManual());
    }
  }
}

class AddTransactionScreenManual extends StatefulWidget {
  const AddTransactionScreenManual({super.key});

  @override
  State<AddTransactionScreenManual> createState() =>
      _AddTransactionScreenManualState();
}

class _AddTransactionScreenManualState
    extends State<AddTransactionScreenManual> {
  final _formKey = GlobalKey<FormState>();
  String type = "Personal";
  bool deductible = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedCategory;
  String? _selectedSubcategory;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _dateController.text = "${now.day} ${_getMonthName(now.month)} ${now.year}";
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  Future<void> _selectCategory() async {
    try {
      await goToCategorySelectionScreen(
        selectedCategory: _selectedCategory,
        selectedSubcategory: _selectedSubcategory,
      ).then((result) {
        Map<String, String>? resultt = result;
        setState(() {
          _selectedCategory = resultt?.keys.first;
          _selectedSubcategory = resultt?.values.first;
          if (_selectedCategory != null && _selectedSubcategory != null) {
            _categoryController.text =
                '$_selectedCategory: $_selectedSubcategory';
          }
        });
      });
    } catch (_) {}
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null || _selectedSubcategory == null) {
        Get.snackbar(
          'Error',
          'Please select a category and subcategory',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      Get.back();
    }
  }

  final typeDropdownKey = GlobalKey<DropdownSearchState<String>>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Text("Add Transaction"),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            AppText("Title", fontSize: 14, fontWeight: FontWeight.w500),
            const SizedBox(height: 8),
            AppTextField(
              hintText: "Enter transaction title",
              controller: _titleController,
              keyboardType: TextInputType.text,
              maxLines: 1,
              fieldValidator: (value) => value == null || value.isEmpty
                  ? 'Please enter a title'
                  : null,
            ),
            const SizedBox(height: 16),

            /// Date
            AppText("Date", fontSize: 14, fontWeight: FontWeight.w500),
            const SizedBox(height: 8),
            AppTextField(
              hintText: "Enter date",
              controller: _dateController,
              keyboardType: TextInputType.text,
              maxLines: 1,
              fieldValidator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a date' : null,
            ),
            const SizedBox(height: 16),

            /// Amount
            AppText("Amount", fontSize: 14, fontWeight: FontWeight.w500),
            const SizedBox(height: 8),
            AppTextField(
              hintText: "Enter amount",
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              maxLines: 1,
              fieldValidator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),

            /// Category
            AppText("Category", fontSize: 14, fontWeight: FontWeight.w500),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectCategory,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Get.theme.colorScheme.surface,
                  border: Border.all(
                    color:
                        Theme.of(context)
                            .inputDecorationTheme
                            .enabledBorder
                            ?.borderSide
                            .color ??
                        colorScheme.outline,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCategory == null
                            ? "Select Category"
                            : "$_selectedCategory: $_selectedSubcategory",
                        style: TextStyle(
                          color: _selectedCategory == null
                              ? colorScheme.onSurface.withValues(alpha: 0.5)
                              : colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
                  ],
                ),
              ),
            ),
            if (_selectedCategory == null) ...[
              const SizedBox(height: 4),
              AppText(
                "Please select a category",
                color: colorScheme.error,
                fontSize: 12,
              ),
            ],
            const SizedBox(height: 16),

            /// Type Dropdown
            AppText("Type", fontSize: 14, fontWeight: FontWeight.w500),
            const SizedBox(height: 8),
            CustomDropDownWidget<String>(
              dropDownKey: typeDropdownKey,

              hint: "Select Tax Year",
              items: ["Personal", "Business"],
            ),
            const SizedBox(height: 16),
            Material(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(
                  color:
                      Theme.of(
                        context,
                      ).inputDecorationTheme.enabledBorder?.borderSide.color ??
                      colorScheme.outline,
                ),
              ),
              child: SwitchListTile.adaptive(
                title: AppText("Deductible", fontSize: 14),
                value: deductible,
                onChanged: (val) => setState(() => deductible = val),
                activeThumbColor: colorScheme.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity(vertical: -3),
              ),
            ),
            const SizedBox(height: 16),
            AppText("Notes", fontSize: 14, fontWeight: FontWeight.w500),
            const SizedBox(height: 8),
            AppTextField(
              hintText: "Enter notes (optional)",
              controller: _notesController,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              fieldValidator: (v) => null,
            ),
            const SizedBox(height: 20),

            /// Scan Receipt Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.camera_alt, color: Colors.black),
                label: AppText(
                  "Scan Receipt",
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                onPressed: () => openReceiptScanner(),
              ),
            ),
            const SizedBox(height: 12),

            /// Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _saveTransaction,
                child: AppText(
                  "Save Transaction",
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
