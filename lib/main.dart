import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/routes/pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy(); // Removes # from web URLs
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BOOKSMART',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorKey: navigatorKey,

      // ✅ Themes
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),

      // ✅ Automatically follows system theme (no controller)
      themeMode: ThemeMode.dark,

      // ✅ Routing setup
      initialRoute: Routes.loginScreen,
      getPages: AppPages.routes,
      defaultTransition: kIsWeb ? Transition.noTransition : null,

      // Optional: 404 fallback for unknown routes
      unknownRoute: GetPage(
        name: '/notfound',
        page: () => Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: AppText(
              "404 - Page Not Found",
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
