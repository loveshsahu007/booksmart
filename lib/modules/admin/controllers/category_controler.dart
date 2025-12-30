import 'package:booksmart/services/crud_service.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:get/get.dart';
import '../../../models/category.dart';
import '../../../widgets/snackbar.dart';
import '../../common/controllers/auth_controller.dart';

class CategoryAdminController extends GetxController {
  final categories = <CategoryModel>[];
  final subCategories = <SubCategoryModel>[];

  bool isLoading = false;

  @override
  void onInit() {
    fetchAll();
    super.onInit();
  }

  // ================= LOADING HANDLER =================

  void _setLoading(bool value) {
    isLoading = value;
    update();
  }

  // ================= FETCH ALL =================

  Future<void> fetchAll() async {
    try {
      _setLoading(true);

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
    } finally {
      _setLoading(false);
    }
  }

  // ================= CATEGORY =================

  Future<void> saveCategory({int? id, required String name}) async {
    try {
      _setLoading(true);

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

      await fetchAll();
    } catch (e) {
      somethingWentWrongSnackbar();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      _setLoading(true);

      await SupabaseCrudService.delete(
        table: SupabaseTable.category,
        filters: {'id': id},
      );

      showSnackBar('Category deleted');
      await fetchAll();
    } catch (e) {
      somethingWentWrongSnackbar();
    } finally {
      _setLoading(false);
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
      _setLoading(true);

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

      await fetchAll();
    } catch (e) {
      somethingWentWrongSnackbar();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteSubCategory(int id) async {
    try {
      _setLoading(true);

      await SupabaseCrudService.delete(
        table: SupabaseTable.subCategory,
        filters: {'id': id},
      );

      showSnackBar('Sub-category deleted');
      await fetchAll();
    } catch (e) {
      somethingWentWrongSnackbar();
    } finally {
      _setLoading(false);
    }
  }

  // ================= HELPERS =================

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

  Future<void> toggleCategoryStatus(CategoryModel category) async {
  try {
    _setLoading(true);

    await SupabaseCrudService.update(
      table: SupabaseTable.category,
      data: {'is_deleted': !category.isDeleted},
      filters: {'id': category.id},
    );

    showSnackBar(
      category.isDeleted ? 'Category restored' : 'Category marked deleted',
    );

    await fetchAll();
  } catch (e) {
    somethingWentWrongSnackbar();
  } finally {
    _setLoading(false);
  }
}
Future<void> toggleSubCategoryStatus(SubCategoryModel sub) async {
  try {
    _setLoading(true);

    await SupabaseCrudService.update(
      table: SupabaseTable.subCategory,
      data: {'is_deleted': !sub.isDeleted},
      filters: {'id': sub.id},
    );

    showSnackBar(
      sub.isDeleted
          ? 'Sub-category restored'
          : 'Sub-category marked deleted',
    );

    await fetchAll();
  } catch (e) {
    somethingWentWrongSnackbar();
  } finally {
    _setLoading(false);
  }
}

}
