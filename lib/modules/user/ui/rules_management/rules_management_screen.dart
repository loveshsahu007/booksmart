import 'package:flutter/material.dart';
import 'package:booksmart/widgets/app_text.dart';
import 'package:booksmart/widgets/app_text_field.dart';
import 'package:get/get.dart';

class RulesManagementScreen extends StatefulWidget {
  const RulesManagementScreen({super.key});

  @override
  State<RulesManagementScreen> createState() => _RulesManagementScreenState();
}

class _RulesManagementScreenState extends State<RulesManagementScreen> {
  final List<Map<String, dynamic>> rules = [
    {"memo": "Uber", "category": "Travel", "enabled": true},
    {"memo": "Lyft", "category": "Travel", "enabled": true},
    {"memo": "Banner Sign", "category": "Advertising", "enabled": true},
    {
      "memo": "McDonald's",
      "category": "Meals & Entertainment",
      "enabled": true,
    },
  ];

  final TextEditingController memoController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  void _showAddRuleSheet() {
    final colorScheme = Theme.of(context).colorScheme;
    //final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final padding = MediaQuery.of(context).viewInsets.bottom + 20;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: padding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                "Add New Rule",
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 16),
              AppTextField(
                hintText: "Memo Contains...",
                controller: memoController,
                keyboardType: TextInputType.text,
                maxLines: 1,
                fieldValidator: (val) => null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                hintText: "Category...",
                controller: categoryController,
                keyboardType: TextInputType.text,
                maxLines: 1,
                fieldValidator: (val) => null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (memoController.text.isNotEmpty &&
                        categoryController.text.isNotEmpty) {
                      setState(() {
                        rules.add({
                          "memo": memoController.text,
                          "category": categoryController.text,
                          "enabled": true,
                        });
                      });
                      memoController.clear();
                      categoryController.clear();
                      Navigator.pop(context);
                    }
                  },
                  child: const AppText(
                    "Save Rule",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(title: Text("Rules Management")),
      backgroundColor: Get.theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 600,
            ),
            child: ListView.builder(
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    // color: isDark ? cardDarkColor : cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black12,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              "If memo contains ${rule["memo"]}",
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            const SizedBox(height: 4),
                            AppText(
                              "→ ${rule["category"]}",
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color.fromARGB(255, 54, 139, 136),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: rule["enabled"],
                        activeThumbColor: const Color.fromARGB(
                          255,
                          54,
                          139,
                          136,
                        ),
                        onChanged: (val) {
                          setState(() {
                            rules[index]["enabled"] = val;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRuleSheet,

        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }
}
