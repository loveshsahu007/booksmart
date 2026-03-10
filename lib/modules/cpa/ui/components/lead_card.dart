import 'package:booksmart/models/lead_model.dart';
import 'package:booksmart/modules/common/controllers/chat_controller.dart';
import 'package:booksmart/modules/user/ui/cpa/order/user_documents_dialog.dart';
import 'package:booksmart/widgets/app_text.dart';
import 'package:booksmart/widgets/custom_circle_avatar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';

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
                    AppText(name, fontSize: 14, fontWeight: FontWeight.bold),
                    AppText(
                      'Received: ${Jiffy.parseFromDateTime(widget.lead.createdAt.toLocal()).fromNow()}',
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
                      showUserDocumentsDialog(lead: widget.lead),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () async {
                  await Get.find<ChatController>().loadChat(widget.lead.userId);
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
}
