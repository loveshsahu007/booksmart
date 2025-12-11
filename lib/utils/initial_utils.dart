import 'package:booksmart/modules/common/providers/user_profile_provider.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../modules/common/providers/auth_provider.dart';
import '../routes/routes.dart';

Future<String> getInitialRoute() async {
  if (isUserLoggedIn) {
    if (isEmailVerified) {
      Map<String, dynamic>? userData = await getUserProfile();

      if (userData == null) {
        return "---/error/---";
      } else {
        Get.put(AuthController(userJson: userData), permanent: true);
      }
      return Routes.home;
    }
    return Routes.verifyEmail;
  } else {
    return Routes.login;
  }
}
