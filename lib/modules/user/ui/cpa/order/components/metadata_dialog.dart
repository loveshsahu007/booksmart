import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/custom_drop_down.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class DocumentMetadata {
  final String name;
  final String? year;
  final String? category;
  final XFile file;

  DocumentMetadata({
    required this.name,
    this.year,
    this.category,
    required this.file,
  });
}

Future<DocumentMetadata?> showDocumentMetadataDialog({
  required XFile file,
}) async {
  return await Get.generalDialog<DocumentMetadata>(
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
          child: Material(
            color: Colors.transparent,
            child: _MetadataDialogContent(file: file),
          ),
        ),
      );
    },
    barrierDismissible: false,
    barrierLabel: 'showDocumentMetadataDialog',
  );
}

class _MetadataDialogContent extends StatefulWidget {
  final XFile file;
  const _MetadataDialogContent({required this.file});

  @override
  State<_MetadataDialogContent> createState() => _MetadataDialogContentState();
}

class _MetadataDialogContentState extends State<_MetadataDialogContent> {
  final List<String> categories = [
    'Income',
    'Expenses',
    'Forms',
    'Education',
    'Other',
  ];

  final yearDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final categoryDropdownKey = GlobalKey<DropdownSearchState<String>>();
  late final TextEditingController nameCtrl;

  String? selectedYear;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: path.basenameWithoutExtension(widget.file.name));
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppText(
            'Document Details',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 15),
          
          // File Name Display
          Row(
            children: [
              const Icon(Icons.attach_file, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.file.name,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

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
              '2029', '2028', '2027', '2026', '2025', '2024', '2023', '2022',
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

          Row(
            spacing: 10,
            children: [
              Expanded(
                child: AppButton(
                  buttonText: 'Cancel',
                  onTapFunction: () => Get.back(),
                ),
              ),
              Expanded(
                child: AppButton(
                  buttonText: 'Proceed',
                  onTapFunction: () {
                    if (nameCtrl.text.trim().isEmpty) {
                      Get.snackbar('Error', 'Please enter a document name');
                      return;
                    }
                    Get.back(
                      result: DocumentMetadata(
                        name: nameCtrl.text.trim(),
                        year: selectedYear,
                        category: selectedCategory,
                        file: widget.file,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
