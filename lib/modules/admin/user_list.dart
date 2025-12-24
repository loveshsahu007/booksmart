import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/admin/controllers/users_controller.dart';
import 'package:get/get.dart';

import '../../models/user_base_model.dart';

class AdminUsersList extends StatelessWidget {
  const AdminUsersList({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminUsersController>(
      builder: (controller) {
        if (controller.isLoading) {
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

            return Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: AppText(
                  '${user.firstName} ${user.lastName}',
                  fontWeight: FontWeight.w600,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(user.email, fontSize: 12),
                    const SizedBox(height: 4),
                    AppText(
                      'Role: ${user.role.name.toUpperCase()}',
                      fontSize: 12,
                    ),
                  ],
                ),
                trailing: _buildStatusChip(user),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(PersonModel user) {
    // if (user.role == UserRole.cpa) {
    //   return const Chip(
    //     label: Text('CPA'),
    //     backgroundColor: Colors.orangeAccent,
    //   );
    // }

    return Chip(
      label: Text(user.role.name),
      backgroundColor: Colors.greenAccent,
    );
  }
}
