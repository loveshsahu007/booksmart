import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/cpa/ui/chat_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:booksmart/models/user_base_model.dart';
import '../../admin/controllers/cpa_controller.dart';

class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GetBuilder<AdminCpaController>(
      init: AdminCpaController(),
      builder: (controller) {
        if (controller.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final approvedCpas = controller.approvedCpas;

        return Scaffold(
          appBar: kIsWeb ? null : AppBar(title: const Text('Chats')),
          body: approvedCpas.isEmpty
              ? const Center(child: Text("No approved CPAs found"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  itemCount: approvedCpas.length,
                  itemBuilder: (context, index) {
                    final CpaModel cpa = approvedCpas[index];

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withValues(
                            alpha: .2,
                          ),
                          backgroundImage: cpa.imgUrl.isNotEmpty
                              ? NetworkImage(cpa.imgUrl)
                              : null,
                          child: cpa.imgUrl.isEmpty
                              ? AppText(
                                  cpa.firstName.isNotEmpty
                                      ? cpa.firstName[0]
                                      : "?",
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )
                              : null,
                        ),
                        title: AppText(
                          "${cpa.firstName} ${cpa.lastName}",
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        subtitle: AppText(
                          cpa.professionalBio.isNotEmpty
                              ? cpa.professionalBio
                              : "Certified Public Accountant",
                          fontSize: 13,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          goToChatScreen(cpa.data, shouldCloseBefore: false);
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
