import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/controllers/auth_controller.dart';
import 'package:booksmart/controllers/organization_controller.dart';
import 'package:booksmart/controllers/transaction_controller.dart';
import 'package:booksmart/models/transaction_model.dart';
import 'package:booksmart/modules/user/ui/transaction/category_selection_screen.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../widgets/custom_dialog.dart';
import '../../../../widgets/custom_drop_down.dart';
import 'receipt_scanning_output_screen.dart';

void goToAddTransactionScreen({
  TransactionModel? tr,
  bool shouldCloseBefore = false,
}) {
  // Ensure the controller is registered before using it
  if (!Get.isRegistered<TransactionController>()) {
    Get.put(TransactionController());
  }

  if (kIsWeb) {
    if (shouldCloseBefore) Get.back();
    customDialog(
      child: AddTransactionScreenManual(transaction: tr),
      title: tr != null ? 'Update Transaction' : 'Add Transaction',
      barrierDismissible: true,
      actionWidgetList: [
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.delete_forever),
        ),
      ],
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => AddTransactionScreenManual(transaction: tr));
    } else {
      Get.to(() => AddTransactionScreenManual(transaction: tr));
    }
  }
}

class AddTransactionScreenManual extends StatefulWidget {
  final TransactionModel? transaction;
  const AddTransactionScreenManual({super.key, this.transaction});

  @override
  State<AddTransactionScreenManual> createState() =>
      _AddTransactionScreenManualState();
}

class _AddTransactionScreenManualState
    extends State<AddTransactionScreenManual> {
  final _formKey = GlobalKey<FormState>();
  final TransactionController transactionC = Get.find();

  String? _selectedCategory;
  String? _selectedSubcategory;
  bool deductible = false;
  XFile? _selectedFile;
  String _selectedType = "Personal"; // Add this to track the selected type
  Uint8List? _selectedFileBytes; // bytes for web preview

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final typeDropdownKey = GlobalKey<DropdownSearchState<String>>();

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      updateData();
    }
  }

  updateData() {
    final now = DateTime.now();

    _dateController.text = "${now.day} ${_getMonthName(now.month)} ${now.year}";

    _titleController.text = widget.transaction?.title ?? '';
    _amountController.text = widget.transaction?.amount.toString() ?? '';
    _notesController.text = widget.transaction?.notes ?? '';
    _selectedType = widget.transaction?.type ?? 'Personal';
    deductible = widget.transaction?.deductible ?? false;
    _selectedCategory = widget.transaction?.category;
    _selectedSubcategory = widget.transaction?.subcategory;
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
    final result = await goToCategorySelectionScreen(
      selectedCategory: _selectedCategory,
      selectedSubcategory: _selectedSubcategory,
    );
    if (result != null) {
      setState(() {
        _selectedCategory = result.keys.first;
        _selectedSubcategory = result.values.first;
      });
    }
  }

  Future<void> _attachReceipt() async {
    final result = await openReceiptScanner();
    if (result != null) {
      setState(() {
        _selectedFile = result['imagePath'] != null
            ? XFile(result['imagePath'])
            : null;
        _selectedFileBytes = result['fileBytes']; // will be non-null on web
      });
    }
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedSubcategory == null) {
      showSnackBar("Please select category & subcategory", isError: true);
      return;
    }
    final model = TransactionModel(
      id: widget.transaction?.id ?? 0,
      title: _titleController.text,
      amount: double.tryParse(_amountController.text) ?? 0,
      category: _selectedCategory!,
      subcategory: _selectedSubcategory!,
      type: _selectedType,
      deductible: deductible,
      notes: _notesController.text,
      date: _dateController.text,
      filePath: _selectedFile?.path,
      ownerId: authPerson!.id,
      organizationId: getCurrentOrganization!.id,
    );

    if (widget.transaction == null) {
      transactionC.addTransaction(model);
    } else {
      transactionC.updateTransaction(
        data: model,
        id: widget.transaction?.id ?? 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("Add Transaction")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppText("Title", fontSize: 14, fontWeight: FontWeight.w500),
            0.01.verticalSpace,
            AppTextField(
              controller: _titleController,
              hintText: "Transaction title",
              maxLines: 1,
              fieldValidator: (v) => v == null || v.isEmpty ? "Required" : null,
            ),
            0.01.verticalSpace,

            AppText("Date", fontSize: 14, fontWeight: FontWeight.w500),
            0.01.verticalSpace,
            AppTextField(
              controller: _dateController,
              hintText: "Transaction date",
              maxLines: 1,
              fieldValidator: (v) => v == null || v.isEmpty ? "Required" : null,
            ),
            0.01.verticalSpace,

            AppText("Amount", fontSize: 14, fontWeight: FontWeight.w500),
            0.01.verticalSpace,
            AppTextField(
              controller: _amountController,
              hintText: "Enter amount",
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              fieldValidator: (v) => v == null || v.isEmpty ? "Required" : null,
            ),
            0.01.verticalSpace,

            AppText("Category", fontSize: 14, fontWeight: FontWeight.w500),
            0.01.verticalSpace,
            InkWell(
              onTap: _selectCategory,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Text(
                  _selectedCategory == null
                      ? "Select Category"
                      : "$_selectedCategory: $_selectedSubcategory",
                ),
              ),
            ),
            0.01.verticalSpace,

            AppText("Type", fontSize: 14, fontWeight: FontWeight.w500),
            0.01.verticalSpace,
            CustomDropDownWidget<String>(
              dropDownKey: typeDropdownKey,
              hint: "Select Type",
              items: ["Personal", "Business"],
              selectedItem: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value ?? "Personal";
                });
              },
            ),
            0.01.verticalSpace,

            SwitchListTile(
              title: const AppText("Deductible"),
              value: deductible,
              onChanged: (val) => setState(() => deductible = val),
            ),
            0.01.verticalSpace,

            AppText("Notes", fontSize: 14, fontWeight: FontWeight.w500),
            0.01.verticalSpace,
            AppTextField(
              controller: _notesController,
              hintText: "Notes (optional)",
              maxLines: 3,
            ),
            0.01.verticalSpace,

            // With this:
            if (_selectedFile != null || (_selectedFileBytes != null && kIsWeb))
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: kIsWeb
                    ? Image.memory(
                        _selectedFileBytes!,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(_selectedFile!.path),
                        height: 200,
                        fit: BoxFit.cover,
                      ),
              ),
            ElevatedButton.icon(
              onPressed: _attachReceipt,
              icon: const Icon(Icons.camera_alt, color: primaryColor),
              label: const AppText("Attach Receipt", color: primaryColor),
            ),
            0.01.verticalSpace,

            ElevatedButton(
              onPressed: _saveTransaction,
              child: const AppText("Save Transaction", color: primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
