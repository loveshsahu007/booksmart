import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/custom_circle_avatar.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import '../../common/controllers/chat_controller.dart';
import '../controllers/leads_controller.dart';
import '../../user/ui/cpa/order/user_documents_dialog.dart';

class LeadsScreenCPA extends StatelessWidget {
  const LeadsScreenCPA({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: AppText("Leads", fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(child: _buildLeadsTab()),
        ],
      ),
    );
  }

  // ---------------- LEADS TAB -----------------
  Widget _buildLeadsTab() {
    // ColorScheme colorScheme = Get.theme.colorScheme;
    return GetX<LeadsController>(
      init: LeadsController(),
      builder: (controller) {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.leads.isEmpty) {
          return const Center(child: AppText("No leads yet"));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.leads.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final lead = controller.leads[index];
            final user = lead.userWrapper;

            final name = user != null
                ? "${user['first_name']} ${user['last_name']}"
                : "Unknown User";

            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  // Navigate to lead details
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CustomCircleAvatar(
                        radius: 25,
                        imgUrl: user!['img_url'],
                        alternateText: user['first_name'],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              name,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            AppText(
                              'Received: ${Jiffy.parseFromDateTime(lead.createdAt.toLocal()).fromNow()}',
                              fontSize: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 35,
                        width: 100,
                        child: AppButton(
                          buttonText: "Documents",
                          fontSize: 12,
                          onTapFunction: () =>
                              showUserDocumentsDialog(lead: lead),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          Get.find<ChatController>().loadChat(lead.userId);
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        tooltip: 'Chat',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
