import 'package:booksmart/models/ai_tax_strategy_model.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../../constant/exports.dart';
import '../../../../../models/ai_message_model.dart';
import '../../../../../widgets/custom_dialog.dart';
import '../../../controllers/ai_chat_controller.dart';

void goToAiChatScreen({
  bool shouldCloseBefore = false,
  required AiTaxStrategyModel strategy,
}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back();
    }
    customDialog(
      child: AiChatScreen(strategy: strategy),
      title: strategy.title,
      barrierDismissible: true,
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => AiChatScreen(strategy: strategy));
    } else {
      Get.to(() => AiChatScreen(strategy: strategy));
    }
  }
}

class AiChatScreen extends StatefulWidget {
  final AiTaxStrategyModel strategy;

  const AiChatScreen({super.key, required this.strategy});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  late AiChatController controller;
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(AiChatController(widget.strategy.id));
  }

  void sendMessage() {
    final text = textController.text;
    textController.clear();
    controller.sendMessage(text, widget.strategy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: Text(widget.strategy.title)),
      body: Column(
        children: [
          /// ---------- CHAT LIST ----------
          Expanded(
            child: Obx(() {
              return ListView.builder(
                controller: controller.scrollController,
                reverse: true,
                itemCount:
                    controller.messages.length + (controller.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == controller.messages.length) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final msg = controller
                      .messages[controller.messages.length - 1 - index];

                  return _buildMessageBubble(msg);
                },
              );
            }),
          ),

          /// ---------- INPUT ----------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: textController,
                      onFieldSubmitted: (_) => sendMessage(),
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: "Ask about this strategy...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() {
                    return controller.isSending.value
                        ? const CircularProgressIndicator()
                        : IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () {
                              sendMessage();
                            },
                          );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ---------- MESSAGE BUBBLE ----------
  Widget _buildMessageBubble(AiMessageModel msg) {
    final isUser = msg.role == AiChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          msg.message,
          style: TextStyle(color: isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
