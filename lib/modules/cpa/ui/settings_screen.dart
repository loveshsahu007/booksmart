import 'package:booksmart/controllers/user_controller.dart';
import 'package:booksmart/routes/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../widgets/app_text.dart';

class SettingsScreenCPA extends StatefulWidget {
  const SettingsScreenCPA({super.key});

  @override
  State<SettingsScreenCPA> createState() => _SettingsScreenCPAState();
}

class _SettingsScreenCPAState extends State<SettingsScreenCPA> {
  bool _isDarkMode = Get.isDarkMode;
  late final UserController _userCtrl;

  @override
  void initState() {
    super.initState();
    _userCtrl = Get.put(UserController());
    _userCtrl.loadCurrentUser(); // load current CPA user info
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
                  Get.toNamed(Routes.profileScreenCPA);
                },
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
                                : "CPA Name",
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          AppText(
                            user?.email ?? "cpa@email.com",
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
            trailing: Icon(Icons.chevron_right, size: 14),
            onTap: () {},
          ),

          const SizedBox(height: 10),

          SwitchListTile.adaptive(
            title: AppText("Dark Mode", fontSize: 14),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() => _isDarkMode = value);
              Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
            activeThumbColor: colorScheme.primary,
          ),

          const SizedBox(height: 10),

          buildTile("Delete Account", () {}, isDestructive: true),
          const SizedBox(height: 10),

          buildTile("Logout", () {
            final userCtrl = Get.find<UserController>();
            userCtrl.user.value = null; // clear user data
            Get.offAllNamed(Routes.login);
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
    trailing: Icon(Icons.chevron_right, size: 20),
    onTap: onTap,
  );
}
