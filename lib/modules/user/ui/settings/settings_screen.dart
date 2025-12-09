import 'package:booksmart/controllers/user_controller.dart';
import 'package:booksmart/modules/common/providers/auth_provider.dart';
import 'package:booksmart/modules/user/ui/bank/bank_list_screen.dart';
import 'package:booksmart/modules/user/ui/financial_statement/document_repository_screen.dart';
import 'package:booksmart/modules/user/ui/organization/organization_list_screen.dart';
import 'package:booksmart/modules/user/ui/sponsored_offers/sponsored_offers_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../routes/routes.dart';
import '../../../../widgets/app_text.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoReviewResults = true;
  bool _proTips = true;
  bool _isDarkMode = Get.isDarkMode;

  late final UserController _userCtrl;

  @override
  void initState() {
    super.initState();
    _userCtrl = Get.put(UserController());
    _userCtrl.loadCurrentUser(); // load current user info
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(title: Text("Settings"), centerTitle: false, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          Obx(() {
            final user = _userCtrl.user.value;
            final initials =
                (user != null && user.firstName != '' && user.lastName != '')
                ? "${user.firstName![0]}${user.lastName![0]}"
                : "NA";
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () {
                  Get.toNamed(Routes.profileScreen);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: colorScheme.primary,
                        child: AppText(
                          initials,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            user != null
                                ? "${user.firstName} ${user.lastName}"
                                : "Your Name",
                            fontSize: 18,
                            color: colorScheme.onSurface,
                          ),
                          AppText(
                            user?.email ?? "your@email.com",
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 10),

          ListTile(
            title: AppText("Notifications", fontSize: 14),
            trailing: Icon(Icons.chevron_right, size: 22),
            onTap: () {},
          ),
          const SizedBox(height: 10),

          SwitchListTile.adaptive(
            title: AppText(
              "Auto Review Results",
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
            value: _autoReviewResults,
            onChanged: (value) {
              setState(() => _autoReviewResults = value);
            },
            activeThumbColor: colorScheme.primary,
          ),
          const SizedBox(height: 10),

          SwitchListTile.adaptive(
            title: AppText(
              "Pro Tips",
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
            value: _proTips,
            onChanged: (value) {
              setState(() => _proTips = value);
            },
            activeThumbColor: colorScheme.primary,
          ),
          const SizedBox(height: 10),

          SwitchListTile.adaptive(
            title: AppText(
              "Dark Mode",
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
              Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
            activeThumbColor: colorScheme.primary,
          ),
          const SizedBox(height: 10),

          buildTile("Documents Repository", () {
            goToDocumentRepositoryScreen(shouldCloseBefore: false);
          }),
          const SizedBox(height: 10),

          buildTile("Sponsored Offers", () {
            goToSponsoredOffersScreen(shouldCloseBefore: false);
          }),
          const SizedBox(height: 10),

          buildTile("Organizations", () {
            goToOrganizationListScreen();
          }),
          const SizedBox(height: 10),

          buildTile("Banks", () {
            goToBanksListScreen(shouldCloseBefore: false);
          }),
          const SizedBox(height: 10),

          buildTile("Delete Account", () {}, isDestructive: false),
          const SizedBox(height: 10),

          buildTile("Logout", () {
            logOut();
          }, isDestructive: true),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

ListTile buildTile(
  String title,
  VoidCallback onTap, {
  bool isDestructive = false,
}) {
  ColorScheme colorScheme = Get.theme.colorScheme;
  return ListTile(
    title: AppText(
      title,
      fontSize: 14,
      color: isDestructive ? colorScheme.error : colorScheme.onSurface,
    ),
    trailing: Icon(
      Icons.chevron_right,
      color: isDestructive
          ? colorScheme.error
          : colorScheme.onSurface.withValues(alpha: 0.7),
      size: 20,
    ),
    onTap: onTap,
  );
}
