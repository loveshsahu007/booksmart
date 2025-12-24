import 'dart:developer';
import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'package:booksmart/models/transaction_model.dart';
import 'package:booksmart/services/crud_service.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:get/get.dart';

TransactionController transactionControllerInstance =
    Get.find<TransactionController>(tag: getCurrentOrganization!.id.toString());

/// TAG: currentOrganizationID
class TransactionController extends GetxController {
  final String table = SupabaseTable.transaction;

  RxBool isLoading = false.obs;
  RxList<TransactionModel> transactions = <TransactionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    getAllTransactions();
  }

  Future<void> getAllTransactions() async {
    try {
      isLoading.value = true;

      final res = await SupabaseCrudService.read(
        table: table,
        filters: {'organization_id': getCurrentOrganization!.id},
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
      update();
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      Map<String, dynamic> json = transaction.toJson();
      json.remove("id");
      await SupabaseCrudService.create(table: table, data: json);
      getAllTransactions();
      Get.back();
      showSnackBar("Transaction added successfully");
    } catch (e, s) {
      log("❌ addTransaction ERROR");
      log(e.toString());
      log(s.toString());
      somethingWentWrongSnackbar();
    }
    update();
  }

  Future<void> updateTransaction({
    required int id,
    required TransactionModel data,
  }) async {
    try {
      log("📤 UPDATE TRANSACTION DATA: $data");
      Map<String, dynamic> json = data.toJson();
      json.remove('id'); // remove id before sending to Supabase
      await SupabaseCrudService.update(
        table: table,
        data: json,
        filters: {'id': id},
      );
      getAllTransactions();
      Get.back();
      showSnackBar("Transaction updated successfully");
    } catch (e, s) {
      log("❌ updateTransaction ERROR");
      log(e.toString());
      log(s.toString());
      somethingWentWrongSnackbar();
    }
    update();
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await SupabaseCrudService.delete(table: table, filters: {'id': id});
      transactions.removeWhere((tx) => tx.id == id);
      update();
      showSnackBar("Transaction deleted");
    } catch (e, s) {
      log("❌ deleteTransaction ERROR");
      log(e.toString());
      log(s.toString());
      somethingWentWrongSnackbar();
    }
  }
}
