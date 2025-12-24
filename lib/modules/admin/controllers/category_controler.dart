import 'package:booksmart/services/crud_service.dart';
import 'package:get/get.dart';
import '../../../models/category.dart';
import '../../../widgets/snackbar.dart';
import '../../common/controllers/auth_controller.dart';

class CategoryAdminController extends GetxController {
  final categories = <CategoryModel>[].obs;
  final subCategories = <SubCategoryModel>[].obs;

  @override
  void onInit() {
    fetchCategories();
    super.onInit();
  }

  // ================= CATEGORY =================

  Future<void> fetchCategories() async {
    try {
      final res = await SupabaseCrudService.read(table: 'category');
      categories.value = (res as List)
          .map((e) => CategoryModel.fromJson(e))
          .toList();
    } catch (e) {
      somethingWentWrongSnackbar();
    }
    update();
  }

  Future<void> saveCategory({int? id, required String name}) async {
    try {
      if (id == null) {
        await SupabaseCrudService.insert(
          table: 'category',
          data: {'name': name, 'added_by': authUser?.id},
        );
        showSnackBar('Category added');
      } else {
        await SupabaseCrudService.update(
          table: 'category',
          data: {'name': name},
          filters: {'id': id},
        );
        showSnackBar('Category updated');
      }
      fetchCategories();
    } catch (e) {
      somethingWentWrongSnackbar();
    }
    update();
  }

  Future<void> deleteCategory(int id) async {
    try {
      await SupabaseCrudService.delete(table: 'category', filters: {'id': id});
      showSnackBar('Category deleted');
      fetchCategories();
    } catch (e) {
      somethingWentWrongSnackbar();
    }
    update();
  }

  // ================= SUB CATEGORY =================

  Future<void> fetchSubCategories(int categoryId) async {
    try {
      final res = await SupabaseCrudService.read(
        table: 'sub_category',
        filters: {'category_id': categoryId},
      );
      subCategories.value = (res as List)
          .map((e) => SubCategoryModel.fromJson(e))
          .toList();
    } catch (e) {
      somethingWentWrongSnackbar();
    }
    update();
  }

  Future<void> saveSubCategory({
    int? id,
    required int categoryId,
    required String name,
  }) async {
    try {
      if (id == null) {
        await SupabaseCrudService.insert(
          table: 'sub_category',
          data: {
            'category_id': categoryId,
            'name': name,
            'added_by': authUser?.id,
          },
        );
        showSnackBar('Sub-category added');
      } else {
        await SupabaseCrudService.update(
          table: 'sub_category',
          data: {'name': name},
          filters: {'id': id},
        );
        showSnackBar('Sub-category updated');
      }
      fetchSubCategories(categoryId);
    } catch (e) {
      somethingWentWrongSnackbar();
    }
    update();
  }

  Future<void> deleteSubCategory(int id, int categoryId) async {
    try {
      await SupabaseCrudService.delete(
        table: 'sub_category',
        filters: {'id': id},
      );
      showSnackBar('Sub-category deleted');
      fetchSubCategories(categoryId);
    } catch (e) {
      somethingWentWrongSnackbar();
    }
    update();
  }
}
