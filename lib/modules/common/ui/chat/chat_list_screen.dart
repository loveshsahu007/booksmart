import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/common/ui/chat/chat_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:booksmart/modules/common/controllers/chat_controller.dart';
import 'package:booksmart/models/chat_model.dart';
import 'package:booksmart/modules/common/controllers/auth_controller.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chatController = Get.put(ChatController());
    final currentUserId = Get.find<AuthController>().person?.id;

    // Fetch chats on init
    chatController.fetchMyChats();

    return GetX<ChatController>(
      init: chatController,
      builder: (controller) {
        if (controller.isLoading.value) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final chats = controller.myChats;

        return Scaffold(
          appBar: kIsWeb ? null : AppBar(title: const Text('Chats')),
          body: chats.isEmpty
              ? const Center(child: Text("No recent chats"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final ChatModel chat = chats[index];

                    // Determine the "other" user
                    final isSenderMe = chat.senderId == currentUserId;
                    final otherUser = isSenderMe ? chat.receiver : chat.sender;

                    if (otherUser == null) return const SizedBox();

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withValues(
                            alpha: .2,
                          ),
                          backgroundImage: otherUser.imgUrl.isNotEmpty
                              ? NetworkImage(otherUser.imgUrl)
                              : null,
                          child: otherUser.imgUrl.isEmpty
                              ? AppText(
                                  otherUser.firstName.isNotEmpty
                                      ? otherUser.firstName[0]
                                      : "?",
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )
                              : null,
                        ),
                        title: AppText(
                          "${otherUser.firstName} ${otherUser.lastName}",
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        subtitle: AppText(
                          chat.lastMessage.isNotEmpty
                              ? chat.lastMessage
                              : "Start chatting...",
                          fontSize: 13,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: AppText(
                          _formatTime(chat.lastMessageTime),
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          goToChatScreen(otherUser, shouldCloseBefore: false);
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      return "${time.month}/${time.day}";
    }
  }
}
