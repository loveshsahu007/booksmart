import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/user/ui/tax_filling/upload_tax_doc_dialog.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';

import '../../../../../widgets/custom_drop_down.dart';

class TaxFillingScreen extends StatefulWidget {
  const TaxFillingScreen({super.key});

  @override
  State<TaxFillingScreen> createState() => _TaxFillingScreenState();
}

Color getTaxDocStatusColor(String status, bool isDark) {
  switch (status) {
    case 'Ready':
      return isDark ? Colors.greenAccent : Colors.green;
    case 'Review':
      return isDark ? Colors.orangeAccent : Colors.orange;
    case 'Missing':
      return isDark ? Colors.redAccent : Colors.red;
    default:
      return isDark ? Colors.grey[400]! : Colors.grey[700]!;
  }
}

class _TaxFillingScreenState extends State<TaxFillingScreen> {
  final yearDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final docTypeDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final statusDropdownKey = GlobalKey<DropdownSearchState<String>>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: Text("Tax Filling")),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              spacing: 10,
              children: [
                Expanded(
                  flex: 4,
                  child: AppTextField(
                    hintText: "Search documents...",
                    keyboardType: TextInputType.text,

                    suffixWidget: Icon(Icons.search),
                  ),
                ),
                Expanded(
                  child: AppButton(
                    radius: 8,
                    buttonText: "Upload",
                    fontSize: 16,
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 6,
                    ),
                    onTapFunction: showUploadTaxDocumentDialog,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 📅 Filters
            Row(
              spacing: 5,
              children: [
                _filterDropdown(
                  dropDownKey: yearDropdownKey,
                  label: "Tax Year",
                  items: ["2025", "2024", "2023"],
                ),
                _filterDropdown(
                  dropDownKey: docTypeDropdownKey,
                  label: "Doc Type",
                  items: ["All", "1040", "Schedule C"],
                ),
                _filterDropdown(
                  dropDownKey: statusDropdownKey,
                  label: "Status",
                  items: ["All", "Ready", "Review", "Missing"],
                ),
              ],
            ),

            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return TaxDocumentCard();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown({
    required GlobalKey<DropdownSearchState<String>> dropDownKey,
    required String label,
    required List<String> items,
  }) {
    return Expanded(
      child: CustomDropDownWidget<String>(
        dropDownKey: dropDownKey,
        label: label,
        hint: "Select $label",
        items: items,
      ),
    );
  }
}

class TaxDocumentCard extends StatelessWidget {
  const TaxDocumentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.black54;

    final color = getTaxDocStatusColor("Ready", isDark);
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(Icons.insert_drive_file),
        title: Text("1040.pdf", style: TextStyle(color: textColor)),
        subtitle: Text(
          "2.34 MB",
          style: TextStyle(color: subTextColor, fontSize: 12),
        ),
        visualDensity: VisualDensity.compact,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "Ready",
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(width: 12),
                Text(
                  "2024",
                  style: TextStyle(
                    color: subTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            PopupMenuButton(
              icon: Icon(Icons.more_vert),
              itemBuilder: (context) {
                return [
                  const PopupMenuItem(value: "Edit", child: Text("Edit")),
                  const PopupMenuItem(value: "Share", child: Text("Share")),
                  const PopupMenuItem(value: "Delete", child: Text("Delete")),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}
