import 'dart:developer';

import 'package:booksmart/models/bank_model.dart';
import 'package:booksmart/services/crud_service.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:get/get.dart';

import '../utils/supabase.dart';

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
      final user = supabase.auth.currentUser;
      if (user == null) return;

      isLoading.value = true;

      final res = await SupabaseCrudService.read(
        table: table,
        filters: {'owner_id': user.id},
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
  Future<void> addBank(Map<String, dynamic> data) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        showSnackBar("User not logged in", isError: true);
        return;
      }

      log("📤 ADD BANK PAYLOAD");
      log(data.toString());

      await SupabaseCrudService.create(table: table, data: data);
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
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      log("📤 UPDATE BANK DATA");
      log(data.toString());

      await SupabaseCrudService.update(
        table: table,
        data: data,
        filters: {'id': id},
      );
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
  Future<void> deleteBank(String id) async {
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
