import 'dart:developer';

import 'package:booksmart/models/user_model.dart';
import 'package:booksmart/utils/initial_utils.dart';
import 'package:booksmart/widgets/confirmation_dialog.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../routes/routes.dart';
import '../../../utils/supabase.dart';
import '../../../widgets/loading.dart';
import '../../../widgets/snackbar.dart';

bool get isUserLoggedIn => supabase.auth.currentSession != null;

bool get isEmailVerified =>
    supabase.auth.currentSession?.user.emailConfirmedAt != null;

Future<void> signUpWithEmailPassword({
  required String email,
  required String password,
  required UserRole role,
}) async {
  showLoading();
  try {
    await supabase.auth
        .signUp(
          email: email,
          password: password,
          data: <String, String>{'role': role.name},
        )
        .then((AuthResponse response) {
          dismissLoadingWidget();
          if (response.user != null) {
            Get.offAndToNamed(Routes.verifyEmail);
          } else {
            somethingWentWrongSnackbar();
          }
        });
  } on AuthApiException catch (e, x) {
    log(e.toString());
    log(x.toString());
    dismissLoadingWidget();
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
    await supabase.auth
        .signInWithPassword(email: email, password: password)
        .then((AuthResponse response) async {
          if (response.user != null) {
            String initialRoute = await getInitialRoute();
            dismissLoadingWidget();
            Get.offAndToNamed(initialRoute);
          } else {
            dismissLoadingWidget();
            somethingWentWrongSnackbar();
          }
        });
  } on AuthApiException catch (e, x) {
    log(e.toString());
    log(x.toString());
    dismissLoadingWidget();
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
      Get.back(); // close the dialog
      showLoading();
      try {
        await supabase.auth.signOut();
        dismissLoadingWidget();
        Get.offAllNamed(Routes.login);
      } catch (e) {
        dismissLoadingWidget();
        showSnackBar(e.toString());
      }
    },
  );
}
