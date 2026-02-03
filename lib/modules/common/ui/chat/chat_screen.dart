import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:booksmart/models/user_base_model.dart';
import '../../controllers/chat_controller.dart';
import 'package:booksmart/modules/common/controllers/auth_controller.dart';

// Add this function to open chat as dialog on web
void goToChatScreen(PersonModel otherUser, {bool shouldCloseBefore = false}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back(); // close previous dialog
    }
    customDialog(
      child: ChatScreen(otherUser: otherUser),
      title: 'Messaging',
      barrierDismissible: true,
      maxWidth: 600, // Adjusted for better chat experience
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => ChatScreen(otherUser: otherUser));
    } else {
      Get.to(() => ChatScreen(otherUser: otherUser));
    }
  }
}

class ChatScreen extends StatefulWidget {
  final PersonModel otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatController chatController = Get.put(ChatController());

  // To handle scrolling
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    chatController.loadChat(widget.otherUser.id);
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    chatController.sendMessage(_controller.text);
    _controller.clear();
    // Scroll to bottom is handled by list reverse normally, but if needed we can animate
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Calculate isMe helper
  // Calculate isMe helper
  bool _isMe(int senderId) {
    return senderId == (Get.find<AuthController>().person?.id ?? -1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use the other user's name
    final title = "${widget.otherUser.firstName} ${widget.otherUser.lastName}";

    return Scaffold(
      // Only show app bar on mobile, dialog handles title on web
      appBar: kIsWeb
          ? null
          : AppBar(
              title: AppText(title, fontSize: 18, fontWeight: FontWeight.bold),
              centerTitle: true,
            ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (chatController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = chatController.messages;
              if (messages.isEmpty) {
                return const Center(child: Text("Start the conversation now!"));
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                reverse:
                    true, // Show newest at bottom (requires sorted descending)
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = _isMe(msg.senderId);

                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Card(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          // color: isMe
                          //     ? colorScheme.primary.withValues(alpha: 0.9)
                          //     : colorScheme.surfaceVariant.withValues(
                          //         alpha: 0.2,
                          //       ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: isMe
                                ? const Radius.circular(14)
                                : const Radius.circular(0),
                            bottomRight: isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            AppText(
                              msg.content,
                              fontSize: 14,
                              //color: isMe ? Colors.black : null,
                            ),
                            const SizedBox(height: 4),
                            AppText(
                              _formatTime(msg.createdAt.toLocal()),
                              fontSize: 10,
                              //color: isMe ? Colors.black : Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Text Field and Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                AppTextField(
                  controller: _controller,
                  hintText: "Securely send a message...",
                  suffixWidget: IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send, color: colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
