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
  if (isUserLoggedIn) {
    if (isEmailVerified) {
      UserRole? role = getUserRoleFromSession;
      List<Future<dynamic>> futureList = <Future>[
        getUserProfile(),
        if (role == UserRole.user) getOrganizations(),
      ];
      return Future.wait(futureList).then((value) {
        Map<String, dynamic>? userData = value[0];
        List<OrganizationModel>? organizationList = role == UserRole.user
            ? value[1]
            : null;
        if (userData == null) {
          return "---/error/---";
        } else {
          Get.put(AuthController(userJson: userData), permanent: true);
          if (authPerson?.role == UserRole.user) {
            Get.put(
              OrganizationController(organizationList ?? []),
              permanent: true,
            );
            if (!isUserProfileCompleted(authUser!)) {
              return Routes.userProfile;
            }
            if (organizationList == null) {
              return Routes.userOrganizations;
            }
          } else if (authPerson?.role == UserRole.cpa) {
            if (!isCPAProfileCompleted(authCpa!)) {
              return Routes.cpaProfile;
            }
          }
          return getHomeScreenRoute();
        }
      });
    }
    return Routes.verifyEmail;
  } else {
    return Routes.login;
  }
}

bool isUserProfileCompleted(UserModel user) {
  return user.firstName.isNotEmpty && user.lastName.isNotEmpty;
}

bool isCPAProfileCompleted(CpaModel cpa) {
  return cpa.firstName.isNotEmpty && cpa.lastName.isNotEmpty;
}
