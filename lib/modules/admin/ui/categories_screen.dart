import 'package:booksmart/modules/admin/ui/widgets/category_dialogs.dart';
import 'package:booksmart/modules/admin/controllers/category_controler.dart';
import 'package:booksmart/widgets/app_button.dart';
import 'package:booksmart/widgets/app_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  late CategoryAdminController categoryController;
  @override
  void initState() {
    if (Get.isRegistered<CategoryAdminController>()) {
      categoryController = Get.find<CategoryAdminController>();
    } else {
      categoryController = Get.put(CategoryAdminController(), permanent: true);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("Categories")),
      body: GetBuilder<CategoryAdminController>(
        builder: (controller) {
          if (controller.categories.isEmpty) {
            return const Center(child: AppText('No categories found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.categories.length,
            itemBuilder: (_, index) {
              final cat = controller.categories[index];

              return Card(
                child: ListTile(
                  title: AppText(cat.name, fontWeight: FontWeight.w600),
                  onTap: () =>
                      showSubCategoryListDialog(controller, cat.id, cat.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => showSaveCategoryDialog(
                          controller: controller,
                          category: cat,
                        ),
                      ),

                      AppButton(
                        buttonText: cat.isDeleted ? "Deleted" : "Live",
                        buttonColor: cat.isDeleted ? Colors.red : Colors.green,
                        onTapFunction: () => showConfirmDeleteDialog(
                          title: cat.isDeleted
                              ? 'Restore Sub-Category?'
                              : 'Mark Sub-Category as Deleted?',
                          onConfirm: () => controller.toggleCategoryStatus(cat),
                        ),
                      ),
                      // IconButton(
                      //   icon: Icon(
                      //     Icons.circle,
                      //     color: cat.isDeleted ? Colors.red : Colors.green,
                      //   ),
                      //   tooltip: cat.isDeleted ? 'Deleted' : 'Live',
                      //   onPressed: () => showConfirmDeleteDialog(
                      //     title: cat.isDeleted
                      //         ? 'Restore Category?'
                      //         : 'Mark Category as Deleted?',
                      //     onConfirm: () => controller.toggleCategoryStatus(cat),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showSaveCategoryDialog(controller: categoryController),
        tooltip: "Add Category",
        child: const Icon(Icons.add),
      ),
    );
  }
}
