import 'package:booksmart/models/user_base_model.dart';
import 'package:booksmart/modules/admin/controllers/users_controller.dart';
import 'package:booksmart/widgets/app_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late AdminUsersController usersController;

  @override
  void initState() {
    if (Get.isRegistered<AdminUsersController>()) {
      usersController = Get.find<AdminUsersController>();
    } else {
      usersController = Get.put(AdminUsersController(), permanent: true);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Users"),

        automaticallyImplyLeading: !kIsWeb,
      ),
      body: GetBuilder<AdminUsersController>(
        builder: (controller) {
          if (controller.isLoading.isTrue) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.users.isEmpty) {
            return const Center(child: AppText('No users found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.users.length,
            itemBuilder: (_, index) {
              final PersonModel user = controller.users[index];

              final String fullName = '${user.firstName} ${user.lastName}'
                  .trim();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: AppText(
                    fullName.isEmpty ? 'Unnamed User' : fullName,
                    fontWeight: FontWeight.w600,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [AppText(user.email, fontSize: 12)],
                  ),
                  trailing: _buildRoleChip(user),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ================= ROLE CHIP =================

  Widget _buildRoleChip(PersonModel user) {
    final role = user.role;

    Color bgColor;

    switch (role) {
      case UserRole.admin:
        bgColor = Colors.blueAccent;
        break;
      case UserRole.cpa:
        bgColor = Colors.orangeAccent;
        break;
      case UserRole.user:
        bgColor = Colors.greenAccent;
        break;
    }

    return Chip(label: Text(role.name.toUpperCase()), backgroundColor: bgColor);
  }
}
