import 'package:booksmart/services/crud_service.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:get/get.dart';
import '../../../models/category.dart';
import '../../../widgets/snackbar.dart';
import '../../common/controllers/auth_controller.dart';

class CategoryAdminController extends GetxController {
  final categories = <CategoryModel>[];
  final subCategories = <SubCategoryModel>[];

  @override
  void onInit() {
    fetchAll();
    super.onInit();
  }

  // ================= FETCH ALL =================

  Future<void> fetchAll() async {
    try {
      final categoryRes = await SupabaseCrudService.read(
        table: SupabaseTable.category,
      );

      final subCategoryRes = await SupabaseCrudService.read(
        table: SupabaseTable.subCategory,
      );

      categories
        ..clear()
        ..addAll((categoryRes as List).map((e) => CategoryModel.fromJson(e)));

      subCategories
        ..clear()
        ..addAll(
          (subCategoryRes as List).map((e) => SubCategoryModel.fromJson(e)),
        );
    } catch (e) {
      somethingWentWrongSnackbar();
    }
    update();
  }

  // ================= CATEGORY =================

  Future<void> saveCategory({int? id, required String name}) async {
    try {
      if (id == null) {
        await SupabaseCrudService.insert(
          table: SupabaseTable.category,
          data: {'name': name, 'added_by': authAdmin?.id},
        );
        showSnackBar('Category added');
      } else {
        await SupabaseCrudService.update(
          table: SupabaseTable.category,
          data: {'name': name},
          filters: {'id': id},
        );
        showSnackBar('Category updated');
      }
      fetchAll();
    } catch (e) {
      somethingWentWrongSnackbar();
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await SupabaseCrudService.delete(
        table: SupabaseTable.category,
        filters: {'id': id},
      );
      showSnackBar('Category deleted');
      fetchAll();
    } catch (e) {
      somethingWentWrongSnackbar();
    }
  }

  // ================= SUB CATEGORY =================

  List<SubCategoryModel> getSubCategoriesByCategory(int categoryId) {
    return subCategories.where((e) => e.categoryId == categoryId).toList();
  }

  Future<void> saveSubCategory({
    int? id,
    required int categoryId,
    required String name,
  }) async {
    try {
      if (id == null) {
        await SupabaseCrudService.insert(
          table: SupabaseTable.subCategory,
          data: {
            'category_id': categoryId,
            'name': name,
            'added_by': authAdmin?.id,
          },
        );
        showSnackBar('Sub-category added');
      } else {
        await SupabaseCrudService.update(
          table: SupabaseTable.subCategory,
          data: {'name': name},
          filters: {'id': id},
        );
        showSnackBar('Sub-category updated');
      }
      fetchAll();
    } catch (e) {
      somethingWentWrongSnackbar();
    }
  }

  Future<void> deleteSubCategory(int id) async {
    try {
      await SupabaseCrudService.delete(
        table: SupabaseTable.subCategory,
        filters: {'id': id},
      );
      showSnackBar('Sub-category deleted');
      fetchAll();
    } catch (e) {
      somethingWentWrongSnackbar();
    }
  }

  String getCategoryName(int id) {
    try {
      return categories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return '-';
    }
  }

  String getSubCategoryName(int? id) {
    if (id == null) return '-';
    try {
      return subCategories.firstWhere((s) => s.id == id).name;
    } catch (_) {
      return '-';
    }
  }
}
