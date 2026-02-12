import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/common/ui/chat/chat_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:booksmart/modules/common/controllers/chat_controller.dart';
import 'package:booksmart/models/chat_model.dart';
import 'package:booksmart/modules/common/controllers/auth_controller.dart';
import 'package:jiffy/jiffy.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late ChatController chatController;

  @override
  void initState() {
    if (Get.isRegistered<ChatController>()) {
      chatController = Get.find<ChatController>();
    } else {
      chatController = Get.put(ChatController());
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final currentUserId = Get.find<AuthController>().person?.id;

    return GetBuilder<ChatController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final chats = controller.myChats;

        return Scaffold(
          appBar: kIsWeb ? null : AppBar(title: const Text('Chats')),
          body: controller.isLoading.value
              ? Center(child: CircularProgressIndicator())
              : chats.isEmpty
              ? const Center(child: Text("No recent chats"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final ChatModel chat = chats[index];
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
                          Jiffy.parseFromDateTime(
                            chat.lastMessageTime,
                          ).fromNow(),

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
}
