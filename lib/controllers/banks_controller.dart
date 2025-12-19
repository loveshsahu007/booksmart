import 'dart:developer';

import 'package:booksmart/controllers/organization_controller.dart';
import 'package:booksmart/models/bank_model.dart';
import 'package:booksmart/services/crud_service.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/widgets/loading.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:get/get.dart';

class BankController extends GetxController {
  final String table = SupabaseTable.bank;

  RxBool isLoading = false.obs;
  RxList<BankModel> banks = <BankModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    getAllBanks();
  }

  // ===============================
  // GET ALL BANKS
  // ===============================
  Future<void> getAllBanks() async {
    try {
      isLoading.value = true;

      final res = await SupabaseCrudService.read(
        table: table,
        filters: {'organization_id': getCurrentOrganization!.id},
      );

      banks.value = (res as List).map((e) => BankModel.fromJson(e)).toList();
    } catch (e, s) {
      log("❌ getAllBanks ERROR");
      log(e.toString());
      log(s.toString());
      somethingWentWrongSnackbar();
    } finally {
      isLoading.value = false;
    }
  }

  // ===============================
  // ADD BANK
  // ===============================
  Future<void> addBank(BankModel model) async {
    showLoading();
    try {
      Map<String, dynamic> result = model.toJson();
      result.remove("id");
      await SupabaseCrudService.create(table: table, data: result);
      dismissLoadingWidget();
      Get.back();
      showSnackBar("Bank added successfully");
      await getAllBanks();
    } catch (e, s) {
      log("❌ addBank ERROR");
      log(e.toString());
      log(s.toString());
      somethingWentWrongSnackbar();
    }
  }

  // ===============================
  // UPDATE BANK
  // ===============================
  Future<void> updateBank({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    showLoading();
    try {
      await SupabaseCrudService.update(
        table: table,
        data: data,
        filters: {'id': id},
      );
      dismissLoadingWidget();
      Get.back();
      showSnackBar("Bank updated successfully");
      await getAllBanks();
    } catch (e, s) {
      log("❌ updateBank ERROR");
      log(e.toString());
      log(s.toString());
      somethingWentWrongSnackbar();
    }
  }

  // ===============================
  // DELETE BANK
  // ===============================
  Future<void> deleteBank(int id) async {
    try {
      await SupabaseCrudService.delete(table: table, filters: {'id': id});

      showSnackBar("Bank deleted");
      await getAllBanks();
    } catch (e, s) {
      log("❌ deleteBank ERROR");
      log(e.toString());
      log(s.toString());
      somethingWentWrongSnackbar();
    }
  }
}
