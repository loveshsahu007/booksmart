import 'dart:developer';
import 'package:booksmart/models/organization_model.dart';
import 'package:booksmart/modules/user/providers/organization_provider.dart';
import 'package:booksmart/services/crud_service.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:get/get.dart';

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

    if (currentOrganization == null && organizations.isNotEmpty) {
      rxCurrentOrganization.value = organizations.first;
    }
    if (shouldUpdate) {
      update();
    }
  }

  Future<void> refreshOrganizations() async {
    isLoading.value = true;
    initlizeOrganizations(await getOrganizations());
    isLoading.value = false;
    update();
  }

  void switchOrganization(OrganizationModel org) {
    rxCurrentOrganization.value = org;
    update();
  }

  Future<void> addOrganization(OrganizationModel model) async {
    try {
      Map<String, dynamic> json = model.toJson();
      json.remove("id");
      await SupabaseCrudService.create(table: table, data: json);
      refreshOrganizations();
      Get.back();
      showSnackBar("Organization added successfully");
    } catch (e, s) {
      log("❌ addOrganization ERROR");
      log(e.toString());
      log(s.toString());
      somethingWentWrongSnackbar();
    }
  }

  // ===============================
  // UPDATE ORGANIZATION
  // ===============================
  Future<void> updateOrganization({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    try {
      await SupabaseCrudService.update(
        table: table,
        data: data,
        filters: {'id': id},
      );
      refreshOrganizations();
      showSnackBar("Organization updated successfully");
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
  Future<void> deleteOrganization(int id) async {
    try {
      await SupabaseCrudService.delete(table: table, filters: {'id': id});
      organizations.removeWhere((org) => org.id == id);
      update();
      showSnackBar("Organization deleted");
    } catch (e, s) {
      log("❌ deleteOrganization ERROR");
      log(e.toString());
      log(s.toString());
      showSnackBar(e.toString(), isError: true);
    }
  }
}
