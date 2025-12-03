import 'package:booksmart/modules/user/ui/bank/bank_list_screen.dart';
import 'package:booksmart/modules/user/ui/financial_statement/document_repository_screen.dart';
import 'package:booksmart/modules/user/ui/organization/organization_list_screen.dart';
import 'package:booksmart/modules/user/ui/sponsored_offers/sponsored_offers_screen.dart';
import 'package:booksmart/routes/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          Container(
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
                  child: const AppText("AC", color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      "Ashley Collins",
                      fontSize: 18,

                      color: colorScheme.onSurface,
                    ),
                    AppText(
                      "ashleycollins@email.com",
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          ListTile(
            title: AppText("Notifications", fontSize: 14),
            trailing: Icon(Icons.chevron_right, size: 22),
            onTap: () {},
          ),
          SizedBox(height: 10),
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
          SizedBox(height: 10),
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
          SizedBox(height: 10),

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
          SizedBox(height: 10),

          buildTile("Documents Repository", () {
            goToDocumentRepositoryScreen(
              shouldCloseBefore: false,
            ); // or false depending on your needs
          }),
          SizedBox(height: 10),

          buildTile("Sponsored Offers", () {
            goToSponsoredOffersScreen(
              shouldCloseBefore: false,
            ); // or false depending on your needs
          }),
          SizedBox(height: 10),

          buildTile("Organizations", () {
            goToOrganizationListScreen();
          }),
          SizedBox(height: 10),

          buildTile("Banks", () {
            goToBanksListScreen(
              shouldCloseBefore: false,
            ); // or false depending on your needs
          }),
          SizedBox(height: 10),

          buildTile("Delete Account", () {}, isDestructive: false),
          SizedBox(height: 10),

          buildTile("Logout", () {
            Get.offAllNamed(Routes.loginScreen);
          }, isDestructive: true),
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
