import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:get/get.dart';

import '../../../../widgets/custom_drop_down.dart';

void showUploadTaxDocumentDialog() {
  Get.generalDialog(
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Get.isDarkMode
                ? Get.theme.colorScheme.surface
                : Colors.white,
          ),
          constraints: BoxConstraints(maxWidth: 400),
          child: Material(
            color: Colors.transparent,
            child: UploadTaxDocWidget(),
          ),
        ),
      );
    },

    barrierDismissible: false,
    barrierLabel: "showUploadTaxDocumentDialog",
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
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            "Upload Tax Document",
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 15),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: SizedBox(
                  height: 150,

                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 40),
                            const SizedBox(height: 10),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AppText("Scan From Camera", fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 150,
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file, size: 40),
                            const SizedBox(height: 10),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AppText(
                                "Upload From Device",
                                fontSize: 16,
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
          const SizedBox(height: 10),
          AppTextField(hintText: "Name", keyboardType: TextInputType.name),
          const SizedBox(height: 10),
          CustomDropDownWidget<String>(
            dropDownKey: yearDropdownKey,
            label: "Tax Year",

            items: ["2025", "2024", "2023"],
          ),

          const SizedBox(height: 15),

          CustomDropDownWidget<String>(
            dropDownKey: categoryDropdownKey,
            label: 'Category',

            items: categories,
          ),

          const SizedBox(height: 15),

          Row(
            spacing: 10,
            children: [
              Expanded(
                child: AppButton(
                  buttonText: "Cancel",

                  onTapFunction: () {
                    Get.back();
                  },
                ),
              ),

              Expanded(
                child: AppButton(
                  buttonText: "Save",
                  onTapFunction: () {
                    Get.back();
                    showSnackBar("Document Uploaded Successfully");
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
