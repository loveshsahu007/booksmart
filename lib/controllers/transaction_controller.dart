import 'dart:developer';
import 'package:booksmart/models/transaction_model.dart';
import 'package:booksmart/services/crud_service.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:get/get.dart';
import '../utils/supabase.dart';

class TransactionController extends GetxController {
  final String table = SupabaseTable.transaction;

  RxBool isLoading = false.obs;
  RxList<TransactionModel> transactions = <TransactionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    getAllTransactions();
  }

  // ===============================
  // GET ALL TRANSACTIONS
  // ===============================
  Future<void> getAllTransactions() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      isLoading.value = true;

      final res = await SupabaseCrudService.read(
        table: table,
        filters: {'owner_id': user.id},
      );

      transactions.value = (res as List)
          .map((e) => TransactionModel.fromJson(e))
          .toList();
    } catch (e, s) {
      log("❌ getAllTransactions ERROR");
      log(e.toString());
      log(s.toString());
      somethingWentWrongSnackbar();
    } finally {
      isLoading.value = false;
    }
  }

  // ===============================
  // ADD TRANSACTION
  // ===============================
  Future<void> addTransaction(TransactionModel model) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = model.toJson();
      data['owner_id'] = user.id;

      log("📤 ADD TRANSACTION PAYLOAD: $data");

      await SupabaseCrudService.create(table: table, data: data);
      Get.back();
      showSnackBar("Transaction added successfully");
      await getAllTransactions();
    } catch (e, s) {
      log("❌ addTransaction ERROR");
      log(e.toString());
      log(s.toString());
      somethingWentWrongSnackbar();
    }
  }

  // ===============================
  // UPDATE TRANSACTION
  // ===============================
  Future<void> updateTransaction({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      log("📤 UPDATE TRANSACTION DATA: $data");

      await SupabaseCrudService.update(
        table: table,
        data: data,
        filters: {'id': id},
      );

      showSnackBar("Transaction updated successfully");
      await getAllTransactions();
    } catch (e, s) {
      log("❌ updateTransaction ERROR");
      log(e.toString());
      log(s.toString());
      somethingWentWrongSnackbar();
    }
  }

  // ===============================
  // DELETE TRANSACTION
  // ===============================
  Future<void> deleteTransaction(String id) async {
    try {
      await SupabaseCrudService.delete(table: table, filters: {'id': id});
      showSnackBar("Transaction deleted");
      await getAllTransactions();
    } catch (e, s) {
      log("❌ deleteTransaction ERROR");
      log(e.toString());
      log(s.toString());
      somethingWentWrongSnackbar();
    }
  }
}
