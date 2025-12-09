import 'dart:developer';

import 'package:booksmart/controllers/user_controller.dart';
import 'package:booksmart/models/user_model.dart';
import 'package:booksmart/modules/common/providers/supabase_crud.dart';
import 'package:booksmart/utils/initial_utils.dart';
import 'package:booksmart/widgets/confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../routes/routes.dart';
import '../../../utils/supabase.dart';
import '../../../widgets/loading.dart';
import '../../../widgets/snackbar.dart';

bool get isUserLoggedIn => supabase.auth.currentSession != null;

bool get isEmailVerified =>
    supabase.auth.currentSession?.user.emailConfirmedAt != null;
final crud = SupabaseCrudService();
Future<void> signUpWithEmailPassword({
  required String email,
  required String password,
  required UserRole role,
}) async {
  showLoading();
  try {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: <String, String>{'role': role.name},
    );

    dismissLoadingWidget();

    if (response.user != null) {
      final userId = response.user!.id;

      // Insert new user row into Supabase table
      await crud.insert(
        table: "users",
        data: {
          "auth_id": userId,
          "email": email,
          "role": role.name,
          "first_name": "",
          "last_name": "",
          "phone_number": "",
        },
      );

      // Load user controller and store data immediately
      final userCtrl = Get.put(UserController());
      await userCtrl.loadCurrentUser();

      // Redirect based on email verification + role
      if (isEmailVerified) {
        if (role == UserRole.user) {
          Get.offAllNamed(
            Routes.profileScreen,
          ); // User Dashboard / profile setup
        } else {
          Get.offAllNamed(Routes.profileScreenCPA);
          // Get.offAllNamed(Routes.dashboardCPA); // CPA Dashboard
        }
      } else {
        Get.offAndToNamed(Routes.verifyEmail);
      }
    } else {
      somethingWentWrongSnackbar();
    }
  } on AuthApiException catch (e, x) {
    dismissLoadingWidget();
    log(e.toString());
    log(x.toString());
    showSnackBar(e.message, isError: true);
  } catch (e, x) {
    dismissLoadingWidget();
    log(e.toString());
    log(x.toString());
    somethingWentWrongSnackbar();
  }
}

Future<void> signinWithEmailPassword({
  required String email,
  required String password,
}) async {
  showLoading();
  try {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      dismissLoadingWidget();
      somethingWentWrongSnackbar();
      return;
    }

    // Load user controller and fetch user row
    // If not already put, register it:
    final userCtrl = Get.put(UserController());
    await userCtrl.loadCurrentUser();

    // Get role from metadata that you saved during signup
    final role = response.user!.userMetadata?['role'] as String?;

    dismissLoadingWidget();
    debugPrint('***********User role : $role');
    if (role == "user") {
      // Normal user → go to initial route
      String initialRoute = await getInitialRoute();
      Get.offAndToNamed(initialRoute);
    } else {
      // CPA → go to CPA dashboard
      Get.offAllNamed(Routes.dashboardCPA);
    }
  } on AuthApiException catch (e, x) {
    dismissLoadingWidget();
    log(e.toString());
    log(x.toString());
    showSnackBar(e.message, isError: true);
  } catch (e, x) {
    dismissLoadingWidget();
    log(e.toString());
    log(x.toString());
    somethingWentWrongSnackbar();
  }
}

void logOut() async {
  showConfirmationDialog(
    title: "Confirm Logout",
    description: "Are you sure you'd like to logout?",
    onYes: () async {
      Get.back(); // close the confirmation dialog
      showLoading();
      try {
        // 1️⃣ Sign out from Supabase
        await Supabase.instance.client.auth.signOut();

        // 2️⃣ Clear user data in UserController
        if (Get.isRegistered<UserController>()) {
          final userCtrl = Get.find<UserController>();
          userCtrl.user.value = null; // clears all user data
        }

        // 3️⃣ Navigate to login screen
        dismissLoadingWidget();
        Get.offAllNamed(Routes.login);
      } catch (e) {
        dismissLoadingWidget();
        showSnackBar(e.toString(), isError: true);
        debugPrint('Logout error: $e');
      }
    },
  );
}
