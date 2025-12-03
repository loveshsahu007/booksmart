import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

// Add this function to open chat as dialog on web
void goToChatScreen({bool shouldCloseBefore = false}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back(); // close previous dialog
    }
    customDialog(
      child: const ChatScreen(),
      title: 'Messaging',
      barrierDismissible: true,
      maxWidth: 600, // Adjusted for better chat experience
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => const ChatScreen());
    } else {
      Get.to(() => const ChatScreen());
    }
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatListScreenCPAState();
}

class _ChatListScreenCPAState extends State<ChatScreen> {
  final List<Map<String, dynamic>> messages = [
    {
      'text':
          "I'd like to connect and discuss how I can support your tax planning needs.",
      'isMe': false,
      'time': '9:15 AM',
    },
    {
      'text': "Sure, I'd be happy to assist you with that.",
      'isMe': true,
      'time': '9:16 AM',
    },
    {
      'text': "Great! When are you available to get started?",
      'isMe': false,
      'time': '9:21 AM',
    },
    {
      'text': "Let's schedule an initial meeting next week.",
      'isMe': true,
      'time': '9:22 AM',
    },
    {
      'text': "Got it! Let's schedule a 15-minute intro call",
      'isMe': false,
      'time': '9:23 AM',
    },
    {
      'text': "Let's schedule an initial meeting next week.",
      'isMe': true,
      'time': '9:22 AM',
    },
    {
      'text': "Got it! Let's schedule a 15-minute intro call",
      'isMe': false,
      'time': '9:23 AM',
    },
    {
      'text': "Let's schedule an initial meeting next week.",
      'isMe': true,
      'time': '9:22 AM',
    },
    {
      'text': "Got it! Let's schedule a 15-minute intro call",
      'isMe': false,
      'time': '9:23 AM',
    },
    {
      'text': "Let's schedule an initial meeting next week.",
      'isMe': true,
      'time': '9:22 AM',
    },
    {
      'text': "Got it! Let's schedule a 15-minute intro call",
      'isMe': false,
      'time': '9:23 AM',
    },
    {
      'text': "Let's schedule an initial meeting next week.",
      'isMe': true,
      'time': '9:22 AM',
    },
    {
      'text': "Got it! Let's schedule a 15-minute intro call",
      'isMe': false,
      'time': '9:23 AM',
    },
  ];

  final TextEditingController _controller = TextEditingController();
  bool autoSync = true;

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        'text': _controller.text,
        'isMe': true,
        'time': _formatTime(DateTime.now()),
      });
      _controller.clear();
    });

    // Auto-scroll to bottom would be nice here
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Only show app bar on mobile, dialog handles title on web
      appBar: kIsWeb
          ? null
          : AppBar(
              title: const AppText(
                "Messaging",
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              centerTitle: true,
            ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              reverse: true,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['isMe'] as bool;
                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
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
                      color: isMe
                          ? colorScheme.primary.withValues(alpha: 0.9)
                          : colorScheme.surfaceVariant.withValues(alpha: 0.2),
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
                          msg['text'],
                          fontSize: 14,
                          color: isMe ? Colors.white : null,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          msg['time'],
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
    super.dispose();
  }
}
