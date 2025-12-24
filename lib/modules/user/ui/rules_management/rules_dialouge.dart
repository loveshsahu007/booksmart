import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/models/category_rules_model.dart';
import 'package:booksmart/modules/admin/controllers/category_controler.dart';
import 'package:booksmart/modules/common/controllers/auth_controller.dart';
import 'package:booksmart/modules/user/controllers/rules_controller.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:get/get.dart';

void showAddEditRuleDialog({CategoryRuleModel? rule}) {
  final rulesC = Get.find<RulesController>();
  final categoryC = Get.find<CategoryAdminController>();

  final memoCtrl = TextEditingController(text: rule?.memo ?? '');

  int? selectedCategory = rule?.categoryId;
  int? selectedSubCategory = rule?.subCategoryId;

  customDialog(
    title: rule == null ? 'Add Rule' : 'Edit Rule',
    child: StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: memoCtrl,
                labelText: 'Memo contains',
                hintText: 'Memo contains',
              ),

              0.04.verticalSpace,

              /// CATEGORY DROPDOWN
              DropdownButtonFormField<int>(
                value: selectedCategory,
                hint: const Text('Select Category'),
                items: categoryC.categories
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedCategory = val;
                    selectedSubCategory = null; // reset sub
                  });
                },
              ),

              0.04.verticalSpace,

              /// SUB CATEGORY DROPDOWN
              if (selectedCategory != null)
                DropdownButtonFormField<int>(
                  value: selectedSubCategory,
                  hint: const Text('Select Sub Category'),
                  items: categoryC
                      .getSubCategoriesByCategory(selectedCategory!)
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedSubCategory = val;
                    });
                  },
                ),

              0.06.verticalSpace,

              AppButton(
                buttonText: rule == null ? 'Save Rule' : 'Update Rule',
                onTapFunction: () {
                  if (memoCtrl.text.trim().isEmpty ||
                      selectedCategory == null) {
                    return;
                  }

                  if (rule == null) {
                    rulesC.addRule(
                      CategoryRuleModel(
                        id: 0,
                        memo: memoCtrl.text.trim(),
                        categoryId: selectedCategory!,
                        subCategoryId: selectedSubCategory,
                        userId: authUser!.id,
                        status: true,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                  } else {
                    rulesC.updateRule(
                      id: rule.id,
                      data: {
                        'memo': memoCtrl.text.trim(),
                        'category_id': selectedCategory,
                        'sub_category_id': selectedSubCategory,
                      },
                    );
                  }

                  Get.back();
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}
