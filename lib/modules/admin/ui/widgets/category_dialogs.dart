import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/admin/controllers/category_controler.dart';
import 'package:booksmart/models/category.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:get/get.dart';

void showSaveCategoryDialog({
  required CategoryAdminController controller,
  CategoryModel? category,
}) {
  final textController = TextEditingController(text: category?.name ?? '');

  customDialog(
    title: category == null ? 'Add Category' : 'Edit Category',
    maxWidth: 350,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: textController,
            labelText: 'Category Name',
            hintText: 'Category Name',
          ),
          0.06.verticalSpace,
          AppButton(
            buttonText: category == null ? 'Add' : 'Update',
            onTapFunction: () {
              final name = textController.text.trim();
              if (name.isEmpty) return;

              controller.saveCategory(id: category?.id, name: name);
              Get.back();
            },
          ),
        ],
      ),
    ),
  );
}

void showSubCategoryListDialog(
  CategoryAdminController controller,
  int categoryId,
  String categoryName,
) {
  customDialog(
    title: categoryName,
    maxWidth: 450,
    child: GetBuilder<CategoryAdminController>(
      builder: (_) {
        final subCategories = controller.getSubCategoriesByCategory(categoryId);

        if (subCategories.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppText('No sub-categories found'),
                0.06.verticalSpace,
                AppButton(
                  buttonText: 'Add Sub-Category',
                  onTapFunction: () => showSaveSubCategoryDialog(
                    controller: controller,
                    categoryId: categoryId,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...subCategories.map(
                (sub) => ListTile(
                  onTap: () {},
                  title: AppText(sub.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => showSaveSubCategoryDialog(
                          controller: controller,
                          categoryId: categoryId,
                          subCategory: sub,
                        ),
                      ),

                      IconButton(
                        icon: Icon(
                          sub.isDeleted
                              ? Icons.cancel_rounded
                              : Icons.check_circle_rounded,
                          color: sub.isDeleted ? Colors.red : Colors.green,
                        ),
                        tooltip: sub.isDeleted ? "Inactive" : "Active",
                        onPressed: () => showConfirmDeleteDialog(
                          title: sub.isDeleted
                              ? 'Restore Sub-Category'
                              : 'Delete Sub-Category',
                          description: sub.isDeleted
                              ? 'Are you sure you want to restore this sub-category?'
                              : 'Are you sure you want to delete this sub-category?',
                          onConfirm: () =>
                              controller.toggleSubCategoryStatus(sub),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              0.06.verticalSpace,
              AppButton(
                buttonText: 'Add Sub-Category',
                onTapFunction: () => showSaveSubCategoryDialog(
                  controller: controller,
                  categoryId: categoryId,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

void showSaveSubCategoryDialog({
  required CategoryAdminController controller,
  required int categoryId,
  SubCategoryModel? subCategory,
}) {
  final textController = TextEditingController(text: subCategory?.name ?? '');

  customDialog(
    title: subCategory == null ? 'Add Sub-Category' : 'Edit Sub-Category',
    maxWidth: 350,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: textController,
            labelText: 'Sub-Category Name',
            hintText: 'Sub-Category Name',
          ),
          0.06.verticalSpace,
          AppButton(
            buttonText: subCategory == null ? 'Add' : 'Update',
            onTapFunction: () {
              final name = textController.text.trim();
              if (name.isEmpty) return;

              controller.saveSubCategory(
                id: subCategory?.id,
                categoryId: categoryId,
                name: name,
              );
              Get.back();
            },
          ),
        ],
      ),
    ),
  );
}

void showConfirmDeleteDialog({
  required String title,
  String? description,
  required VoidCallback onConfirm,
  double cardWidth = 300,
}) {
  customDialog(
    title: title,
    maxWidth: cardWidth,
    child: SingleChildScrollView(
      padding: EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (description != null) ...[
            AppText(description, textAlign: TextAlign.center),
            0.03.verticalSpace,
          ],
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: Get.back,
                  child: const Text('Cancel'),
                ),
              ),
              Expanded(
                child: AppButton(
                  buttonText: title.contains("Restore") ? "Restore" : 'Delete',
                  onTapFunction: () {
                    onConfirm();
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
