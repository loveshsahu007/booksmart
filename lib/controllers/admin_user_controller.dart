import 'dart:developer';

import 'package:booksmart/services/crud_service.dart';
import 'package:get/get.dart';
import '../models/user_base_model.dart';

class AdminUsersController extends GetxController {
  final List<PersonModel> users = [];
  bool isLoading = false;

  static const String table = 'users'; // or profiles/persons table

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      isLoading = true;
      update();

      final result = await SupabaseCrudService.read(table: table);

      users.clear();

      if (result is List) {
        for (final json in result) {
          users.add(PersonModel.fromJson(json));
        }
      }
    } catch (e, s) {
      log('❌ fetchUsers error');
      log(e.toString());
      log(s.toString());
    } finally {
      isLoading = false;
      update();
    }
  }
}
