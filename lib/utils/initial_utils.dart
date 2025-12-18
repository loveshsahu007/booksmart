import 'package:booksmart/models/user_base_model.dart';
import 'package:booksmart/modules/common/providers/user_profile_provider.dart';
import 'package:booksmart/routes/pages.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/organization_controller.dart';
import '../models/organization_model.dart';
import '../modules/common/providers/auth_provider.dart';
import '../modules/user/providers/organization_provider.dart';
import '../routes/routes.dart';

Future<String> getInitialRoute() async {
  if (!isUserLoggedIn) {
    return Routes.login;
  }

  if (!isEmailVerified) {
    return Routes.verifyEmail;
  }

  final UserRole? role = getUserRoleFromSession;

  final futures = <Future<dynamic>>[
    getUserProfile(),
    if (role == UserRole.user) getOrganizations(),
  ];

  final results = await Future.wait(futures);

  final Map<String, dynamic>? userData = results[0];
  final List<OrganizationModel>? organizations = role == UserRole.user
      ? results[1] as List<OrganizationModel>?
      : null;

  if (userData == null) {
    return Routes.login;
  }

  /// -----------------------------
  /// AUTH CONTROLLER
  /// -----------------------------
  Get.put(AuthController(userJson: userData), permanent: true);

  /// -----------------------------
  /// USER FLOW
  /// -----------------------------
  if (authPerson?.role == UserRole.user) {
    final orgController = Get.put(OrganizationController(), permanent: true);

    if (organizations != null) {
      orgController.organizations.assignAll(organizations);
      orgController.update();
    }

    if (!isUserProfileCompleted(authUser!)) {
      return Routes.userProfile;
    }

    if (organizations == null || organizations.isEmpty) {
      return Routes.userOrganizations;
    }
  }

  /// -----------------------------
  /// CPA FLOW
  /// -----------------------------
  if (authPerson?.role == UserRole.cpa) {
    if (!isCPAProfileCompleted(authCpa!)) {
      return Routes.cpaProfile;
    }
  }

  return getHomeScreenRoute();
}

bool isUserProfileCompleted(UserModel user) {
  return user.firstName.isNotEmpty && user.lastName.isNotEmpty;
}

bool isCPAProfileCompleted(CpaModel cpa) {
  return cpa.firstName.isNotEmpty && cpa.lastName.isNotEmpty;
}
