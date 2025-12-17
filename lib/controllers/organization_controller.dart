import 'dart:developer';
import 'package:booksmart/models/organization_model.dart';
import 'package:booksmart/modules/user/providers/organization_provider.dart';
import 'package:booksmart/services/crud_service.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:get/get.dart';

import '../utils/supabase.dart';

OrganizationModel? get getCurrentOrganization {
  try {
    return Get.find<OrganizationController>().currentOrganization;
  } catch (_) {
    return null;
  }
}

bool get isAnyOrganizationAvailable {
  return getCurrentOrganization != null;
}

OrganizationController get organizationControllerInstance =>
    Get.find<OrganizationController>();

class OrganizationController extends GetxController {
  final String table = SupabaseTable.organization;

  Rx<OrganizationModel?> rxCurrentOrganization = Rx<OrganizationModel?>(null);
  OrganizationModel? get currentOrganization => rxCurrentOrganization.value;

  RxBool isLoading = false.obs;
  RxList<OrganizationModel> organizations = <OrganizationModel>[].obs;

  OrganizationController(List<OrganizationModel> organizationList) {
    initlizeOrganizations(organizationList);
  }

  void initlizeOrganizations(
    List<OrganizationModel> list, {
    bool shouldUpdate = true,
  }) {
    organizations.value = list;

    if (currentOrganization == null ||
        !organizations.any((org) => org.id == currentOrganization?.id)) {
      rxCurrentOrganization.value = organizations.first;
    }
    if (shouldUpdate) {
      update();
    }
  }

  Future<void> refreshOrganizations() async {
    isLoading.value = true;
    initlizeOrganizations(await getOrganizations());
    update();
    isLoading.value = false;
  }

  void switchOrganization(OrganizationModel org) {
    rxCurrentOrganization.value = org;
    update();
  }

  // ===============================
  // ADD ORGANIZATION
  // ===============================
  Future<void> addOrganization(Map<String, dynamic> json) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        showSnackBar("User not logged in", isError: true);
        return;
      }

      log("📤 ADD ORGANIZATION PAYLOAD");
      log(json.toString());

      await SupabaseCrudService.create(table: table, data: json);
      Get.back();
      showSnackBar("Organization added successfully");

      await refreshOrganizations();
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
      await refreshOrganizations();
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
      organizations.removeWhere((org) => org.id == id);
      update();
    } catch (e, s) {
      log("❌ deleteOrganization ERROR");
      log(e.toString());
      log(s.toString());

      showSnackBar(e.toString(), isError: true);
    }
  }
}
