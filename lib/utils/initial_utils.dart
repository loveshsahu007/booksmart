import '../modules/common/providers/auth_provider.dart';
import '../routes/routes.dart';

Future<String> getInitialRoute() async {
  if (isUserLoggedIn) {
    if (isEmailVerified) {
      /// TODO: we need to fetch user doc from the database
      /// if doc is not found or name etc is empty/null navigate user to the profile setup screen.....
      /// initilize controller
      /// & based on role we have to redirect him to the desired dashboard
      return Routes.home;
    }
    return Routes.verifyEmail;
  } else {
    return Routes.login;
  }
}
