import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/admin/controllers/users_controller.dart';
import 'package:booksmart/modules/admin/user_list.dart';
import 'package:get/get.dart';

import 'controllers/category_controler.dart';
import 'category_dialogs.dart';

class AdminDashboard extends StatelessWidget {
  AdminDashboard({super.key});

  final CategoryAdminController categoryController = Get.put(
    CategoryAdminController(),
  );

  final AdminUsersController usersController = Get.put(AdminUsersController());

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = context.screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () =>
                showSaveCategoryDialog(controller: categoryController),
          ),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                Expanded(child: const AdminUsersList()),

                const VerticalDivider(width: 1),
                Expanded(child: _buildCategories()),
              ],
            )
          : Column(
              children: [
                Expanded(child: const AdminUsersList()),

                const Divider(height: 1),
                Expanded(child: _buildCategories()),
              ],
            ),
    );
  }

  Widget _buildCategories() {
    return GetBuilder<CategoryAdminController>(
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
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => showConfirmDeleteDialog(
                        title: 'Delete Category?',
                        onConfirm: () => controller.deleteCategory(cat.id),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
