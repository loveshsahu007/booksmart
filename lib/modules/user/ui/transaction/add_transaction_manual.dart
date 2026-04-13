import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/admin/controllers/category_controler.dart';
import 'package:booksmart/modules/common/controllers/auth_controller.dart';
import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'package:booksmart/modules/user/controllers/transaction_controller.dart';
import 'package:booksmart/models/transaction_model.dart';
import 'package:booksmart/modules/user/ui/transaction/category_selection_screen.dart';
import 'package:booksmart/widgets/confirmation_dialog.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';

import '../../../../constant/data.dart';
import '../../../../utils/date_time_input.dart';
import '../../../../widgets/custom_dialog.dart';
import '../../../../widgets/custom_drop_down.dart';
import 'receipt_scanning_output_screen.dart';

void goToAddTransactionScreen({
  TransactionModel? transaction,
  bool shouldCloseBefore = false,
}) {
  // Ensure the controller is registered before using it
  if (!Get.isRegistered<TransactionController>()) {
    Get.put(TransactionController());
  }

  if (kIsWeb) {
    if (shouldCloseBefore) Get.back();
    customDialog(
      child: AddTransactionScreenManual(transaction: transaction),
      title: transaction != null ? 'Update Transaction' : 'Add Transaction',
      barrierDismissible: true,
      actionWidgetList: [
        if (canTransactionBeDeleted(transaction))
          IconButton(
            onPressed: () {
              deleteTransaction(transaction!);
            },
            icon: const Icon(Icons.delete_forever),
          ),
      ],
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => AddTransactionScreenManual(transaction: transaction));
    } else {
      Get.to(() => AddTransactionScreenManual(transaction: transaction));
    }
  }
}

bool canTransactionBeDeleted(TransactionModel? transaction) {
  if (transaction == null) return false;
  return transaction.bankId == null;
}

void deleteTransaction(TransactionModel transaction) {
  showConfirmationDialog(
    title: "Delete Transaction",
    description: "Are you sure you want to delete this transaction?",
    onYes: () {
      Get.back(); // pop the confirmation dialog
      Get.back(); // pop the add-transaction screen
      transactionControllerInstance.deleteTransaction(transaction.id);
    },
  );
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

  TransactionController transactionC = transactionControllerInstance;

  int? _selectedCategory;
  int? _selectedSubcategory;
  bool deductible = true;
  XFile? _selectedFile;
  String _selectedType = personalTransactionType;
  Uint8List? _selectedFileBytes;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _dateController = TextEditingController();
  DateTime? _selectedDate;

  final typeDropdownKey = GlobalKey<DropdownSearchState<String>>();
  late CategoryAdminController categoryController;

  late bool isUpdate;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CategoryAdminController>()) {
      categoryController = Get.find<CategoryAdminController>();
    } else {
      categoryController = Get.put(CategoryAdminController(), permanent: true);
    }
    isUpdate = widget.transaction != null;

    updateData();
  }

  updateData() {
    _dateController.text = Jiffy.parseFromDateTime(
      widget.transaction?.dateTime ?? DateTime.now(),
    ).yMMMdjm;
    _selectedDate = widget.transaction?.dateTime ?? DateTime.now();
    _titleController.text = widget.transaction?.title ?? '';
    _amountController.text = widget.transaction?.amount.toString() ?? '';
    _descriptionController.text = widget.transaction?.description ?? '';
    _selectedType = widget.transaction?.type ?? businessTransactionType;
    deductible = widget.transaction?.deductible ?? true;
    _selectedCategory = widget.transaction?.category;
    _selectedSubcategory = widget.transaction?.subcategory;
  }

  Future<void> _selectCategory() async {
    final result = await goToCategorySelectionScreen(
      selectedCategory: _selectedCategory,
      selectedSubcategory: _selectedSubcategory,
    );

    if (result == null) return;

    setState(() {
      _selectedCategory = result['categoryId'] as int;
      _selectedSubcategory = result['subcategoryId'] as int;
    });
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
      description: _descriptionController.text,
      dateTime: _selectedDate!,
      filePath: _selectedFile?.path,
      userId: authPerson!.id,
      orgId: getCurrentOrganization!.id,
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

    bool isTextFieldEnabled = widget.transaction == null
        ? true
        : !widget.transaction!.isFromBank;

    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Text(isUpdate ? "Update Transaction" : "Add Transaction"),
              actions: [
                if (canTransactionBeDeleted(widget.transaction))
                  IconButton(
                    onPressed: () {
                      if (canTransactionBeDeleted(widget.transaction!)) {
                        deleteTransaction(widget.transaction!);
                      } else {
                        showSnackBar(
                          "Transaction cannot be deleted",
                          isError: true,
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_forever),
                  ),
              ],
            ),
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
            InkWell(
              onTap: isTextFieldEnabled
                  ? () async {
                      await getDateTimeInput(
                        context: context,
                        firstDateTime: DateTime(1900),
                        lastDate: DateTime.now(),
                      ).then((DateTime? pickedDate) async {
                        if (pickedDate != null) {
                          _selectedDate = pickedDate;
                          _dateController.text = Jiffy.parseFromDateTime(
                            _selectedDate!,
                          ).yMMMdjm;
                        }
                      });
                    }
                  : null,
              borderRadius: BorderRadius.circular(20),
              child: AbsorbPointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: AppTextField(
                    controller: _dateController,
                    hintText: "Transaction date",
                    maxLines: 1,
                    isEnabled: isTextFieldEnabled,
                    fieldValidator: (v) =>
                        v == null || v.isEmpty ? "Required" : null,
                  ),
                ),
              ),
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
              isEnabled: isTextFieldEnabled,
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
                  border: Border.all(color: colorScheme.outline, width: 0.2),
                ),
                child: Text(
                  _selectedCategory == null
                      ? "Select Category"
                      : "${categoryController.getCategoryName(_selectedCategory ?? 1)}: ${categoryController.getSubCategoryName(_selectedSubcategory ?? 1)}",
                ),
              ),
            ),
            0.01.verticalSpace,

            AppText("Type", fontSize: 14, fontWeight: FontWeight.w500),
            0.01.verticalSpace,
            CustomDropDownWidget<String>(
              dropDownKey: typeDropdownKey,
              hint: "Select Type",
              items: transactionTypesList,
              selectedItem: _selectedType,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedType = value;
                });
              },
            ),
            0.02.verticalSpace,
            // Material(
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(8),
            //     side: const BorderSide(color: Colors.grey, width: 0.2),
            //   ),
            //   child:
            Card(
              margin: EdgeInsets.zero,
              child: StatefulBuilder(
                builder: (context, deductState) {
                  return SwitchListTile(
                    title: const AppText("Deductible"),
                    value: deductible,
                    onChanged: (val) => deductState(() => deductible = val),
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.grey, width: 0.2),
                    ),
                  );
                },
              ),
            ),
            // ),
            0.01.verticalSpace,

            AppText("Notes", fontSize: 14, fontWeight: FontWeight.w500),
            0.01.verticalSpace,
            AppTextField(
              controller: _descriptionController,
              hintText: "Notes (optional)",
              maxLines: 3,
            ),
            0.01.verticalSpace,

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
            OutlinedButton.icon(
              onPressed: _attachReceipt,
              icon: const Icon(Icons.camera_alt, color: orangeBttonColor),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: orangeBttonColor),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              label: const AppText(
                "Attach Receipt",
                color: orangeBttonColor,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            0.01.verticalSpace,

            ElevatedButton(
              onPressed: _saveTransaction,
              style: OutlinedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              child: AppText(
                isUpdate ? "Update Transaction" : "Save Transaction",
                color: primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
