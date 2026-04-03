import 'package:booksmart/models/lead_model.dart';
import 'package:booksmart/models/user_base_model.dart';
import 'package:booksmart/modules/common/ui/chat/chat_screen.dart';
import 'package:booksmart/modules/user/ui/cpa/order/user_documents_dialog.dart';
import 'package:booksmart/widgets/app_text.dart';
import 'package:booksmart/widgets/custom_circle_avatar.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:get/get.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:booksmart/modules/cpa/ui/order/send_order_request_screen.dart';

import '../../../../widgets/app_button.dart';

class LeadCard extends StatefulWidget {
  const LeadCard({super.key, required this.lead});
  final LeadModel lead;

  @override
  State<LeadCard> createState() => _LeadCardState();
}

class _LeadCardState extends State<LeadCard> {
  @override
  Widget build(BuildContext context) {
    final user = widget.lead.userWrapper;

    final name = user != null
        ? "${user['first_name']} ${user['last_name']}"
        : "Unknown User";
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _showUserDetailDialog(context, user);
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
                    AppText(name, fontSize: 14, fontWeight: FontWeight.bold),
                    AppText(
                      'Received: ${Jiffy.parseFromDateTime(widget.lead.createdAt.toLocal()).fromNow()}',
                      fontSize: 12,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  // TODO: show order request dialog
                },
                icon: const Icon(Icons.request_quote_outlined),
                tooltip: 'Send order request',
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final personData = Map<String, dynamic>.from(user);
                  final person = PersonModel.fromJson(personData);
                  goToChatScreen(person);
                },
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Chat',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetailDialog(BuildContext context, Map<String, dynamic>? user) {
    customDialog(
      title: 'User Details',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user != null) ...[
              CustomCircleAvatar(
                radius: 40,
                imgUrl: user['img_url'],
                alternateText: user['first_name'],
              ),
              const SizedBox(height: 12),
              AppText(
                "${user['first_name']} ${user['last_name']}",
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              if (user['email'] != null) ...[
                const SizedBox(height: 4),
                AppText(user['email'], fontSize: 14, color: Colors.grey),
              ],
              const SizedBox(height: 24),
            ] else ...[
              const AppText("Unknown User"),
              const SizedBox(height: 24),
            ],
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    buttonText: "Chat",
                    fontSize: 12,
                    onTapFunction: () {
                      if (user != null) {
                        Get.back();
                        final personData = Map<String, dynamic>.from(user);
                        final person = PersonModel.fromJson(personData);
                        goToChatScreen(person);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    buttonText: "Documents",
                    fontSize: 12,
                    onTapFunction: () {
                      Get.back();
                      showUserDocumentsDialog(lead: widget.lead);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    buttonText: "Send Order Request",
                    fontSize: 12,
                    onTapFunction: () {
                      Get.back();
                      goToSendOrderRequestScreen();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
