import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/controllers/category_controler.dart';
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
) async {
  await controller.fetchSubCategories(categoryId);

  customDialog(
    title: categoryName,
    child: GetBuilder<CategoryAdminController>(
      builder: (_) {
        if (controller.subCategories.isEmpty) {
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

        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...controller.subCategories.map(
                (sub) => ListTile(
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
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            controller.deleteSubCategory(sub.id, categoryId),
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
  required VoidCallback onConfirm,
}) {
  customDialog(
    title: title,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppText('This action cannot be undone'),
        0.06.verticalSpace,
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: Get.back,
                child: const Text('Cancel'),
              ),
            ),
            0.03.horizontalSpace,
            Expanded(
              child: AppButton(
                buttonText: 'Delete',
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
  );
}
