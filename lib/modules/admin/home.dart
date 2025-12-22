import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/controllers/category_controler.dart';
import 'package:booksmart/modules/admin/category_dialogs.dart';
import 'package:get/get.dart';

class TempAdmin extends StatelessWidget {
  TempAdmin({super.key});

  final controller = Get.put(CategoryAdminController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showSaveCategoryDialog(controller: controller),
          ),
        ],
      ),
      body: Obx(() {
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
                    showSubCategoryListDialog(controller, cat.id!, cat.name),
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
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => showConfirmDeleteDialog(
                        title: 'Delete Category?',
                        onConfirm: () => controller.deleteCategory(cat.id!),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
