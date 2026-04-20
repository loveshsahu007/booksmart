import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/user/controllers/tax_document_controller.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;

import '../../../../widgets/custom_drop_down.dart';

void showUploadTaxDocumentDialog({String? type}) {
  Get.generalDialog(
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Get.isDarkMode
                ? Get.theme.colorScheme.surface
                : Colors.white,
          ),
          constraints: const BoxConstraints(maxWidth: 400),
          child: const Material(
            color: Colors.transparent,
            child: UploadTaxDocWidget(),
          ),
        ),
      );
    },
    barrierDismissible: false,
    barrierLabel: 'showUploadTaxDocumentDialog_${type ?? 'general'}',
  );
}

class UploadTaxDocWidget extends StatefulWidget {
  const UploadTaxDocWidget({super.key});

  @override
  State<UploadTaxDocWidget> createState() => _UploadTaxDocWidgetState();
}

class _UploadTaxDocWidgetState extends State<UploadTaxDocWidget> {
  final List<String> categories = [
    'Income',
    'Expenses',
    'Forms',
    'Education',
    'Other',
  ];

  final yearDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final categoryDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final nameCtrl = TextEditingController();

  String? selectedYear;
  String? selectedCategory;

  late final TaxDocumentController _ctrl;

  @override
  void initState() {
    super.initState();
    // Ensure the controller is available; if already registered, find it.
    _ctrl = Get.isRegistered<TaxDocumentController>()
        ? Get.find<TaxDocumentController>()
        : Get.put(TaxDocumentController());
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final fileUrl = await _ctrl.uploadDocument(
      name: nameCtrl.text,
      taxYear: selectedYear,
      category: selectedCategory,
    );
    if (fileUrl != null) {
      Get.back();
      showSnackBar('Document Uploaded Successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaxDocumentController>(
      builder: (ctrl) {
        final pickedName = ctrl.pickedFile != null
            ? path.basename(ctrl.pickedFile!.path)
            : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Title ───────────────────────────────────────────────────
              const AppText(
                'Upload Tax Document',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 15),

              // ── Pick source ─────────────────────────────────────────────
              Row(
                spacing: 10,
                children: [
                  // Camera card — hidden on web
                  if (!kIsWeb)
                    Expanded(
                      child: SizedBox(
                        height: 130,
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: ctrl.isUploading.value
                                ? null
                                : ctrl.pickFromCamera,
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, size: 36),
                                  SizedBox(height: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: AppText(
                                      'Scan From Camera',
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Device / Gallery card
                  Expanded(
                    child: SizedBox(
                      height: 130,
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: ctrl.isUploading.value
                              ? null
                              : ctrl.pickFromDevice,
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file, size: 36),
                                SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: AppText(
                                    'Upload From Device',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Selected file label ─────────────────────────────────────
              if (pickedName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pickedName,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Clear selection
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        ctrl.pickedFile = null;
                        ctrl.update();
                      },
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),

              // ── Form fields ────────────────────────────────────────────
              AppTextField(
                controller: nameCtrl,
                hintText: 'Document Name *',
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 10),

              CustomDropDownWidget<String>(
                dropDownKey: yearDropdownKey,
                label: 'Tax Year',
                hint: 'Select Year',
                items: const [
                  '2029',
                  '2028',
                  '2027',
                  '2026',
                  '2025',
                  '2024',
                  '2023',
                  '2022',
                ],
                onChanged: (v) => setState(() => selectedYear = v),
              ),
              const SizedBox(height: 10),

              CustomDropDownWidget<String>(
                dropDownKey: categoryDropdownKey,
                label: 'Category',
                hint: 'Select Category',
                items: categories,
                onChanged: (v) => setState(() => selectedCategory = v),
              ),
              const SizedBox(height: 20),

              // ── Actions ─────────────────────────────────────────────────
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: outlineButton(
                      "Cancel",
                      onPressed: () {
                        ctrl.pickedFile = null;
                        Get.back();
                      },
                    ),
                  ),
                  Expanded(
                    child: Obx(
                      () => AppButton(
                        buttonText: ctrl.isUploading.value
                            ? 'Uploading…'
                            : 'Save',
                        onTapFunction: ctrl.isUploading.value ? null : _save,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
