import 'dart:developer';
import 'package:booksmart/models/organization_model.dart';
import 'package:booksmart/services/crud_service.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:get/get.dart';

import '../utils/supabase.dart'; // supabase instance

class OrganizationController extends GetxController {
  final String table = SupabaseTable.organization;

  RxBool isLoading = false.obs;
  RxList<OrganizationModel> organizations = <OrganizationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    getAllOrganizations();
  }

  // ===============================
  // GET ALL ORGANIZATIONS
  // ===============================
  Future<void> getAllOrganizations() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        log("❌ getAllOrganizations: user not logged in");
        return;
      }

      isLoading.value = true;

      final res = await SupabaseCrudService.read(
        table: table,
        filters: {
          'owner_id': user.id, // ✅ UUID
        },
      );

      organizations.value = (res as List)
          .map((e) => OrganizationModel.fromJson(e))
          .toList();
    } catch (e, s) {
      log("❌ getAllOrganizations ERROR");
      log(e.toString());
      log(s.toString());
      somethingWentWrongSnackbar();
    } finally {
      isLoading.value = false;
    }
  }

  // ===============================
  // ADD ORGANIZATION
  // ===============================
  Future<void> addOrganization(OrganizationModel model) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        showSnackBar("User not logged in", isError: true);
        return;
      }

      final data = model.toJson();

      /// 🔥 Force correct UUID owner
      data['owner_id'] = user.id;

      log("📤 ADD ORGANIZATION PAYLOAD");
      log(data.toString());

      await SupabaseCrudService.create(table: table, data: data);
      Get.back();
      showSnackBar("Organization added successfully");

      await getAllOrganizations();
    } catch (e, s) {
      log("❌ addOrganization ERROR");
      log(e.toString());
      log(s.toString());

      showSnackBar(e.toString(), isError: true, seconds: 6);
    }
  }

  // ===============================
  // UPDATE ORGANIZATION
  // ===============================
  Future<void> updateOrganization({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      log("📤 UPDATE ORGANIZATION");
      log(data.toString());

      await SupabaseCrudService.update(
        table: table,
        data: data,
        filters: {'id': id},
      );

      showSnackBar("Organization updated successfully");
      await getAllOrganizations();
    } catch (e, s) {
      log("❌ updateOrganization ERROR");
      log(e.toString());
      log(s.toString());

      showSnackBar(e.toString(), isError: true);
    }
  }

  // ===============================
  // DELETE ORGANIZATION
  // ===============================
  Future<void> deleteOrganization(String id) async {
    try {
      await SupabaseCrudService.delete(table: table, filters: {'id': id});

      showSnackBar("Organization deleted");
      await getAllOrganizations();
    } catch (e, s) {
      log("❌ deleteOrganization ERROR");
      log(e.toString());
      log(s.toString());

      showSnackBar(e.toString(), isError: true);
    }
  }
}
