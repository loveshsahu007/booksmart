import 'package:booksmart/constant/exports.dart';
import 'package:flutter/foundation.dart';

class AIChatingScreen extends StatefulWidget {
  const AIChatingScreen({super.key});

  @override
  State<AIChatingScreen> createState() => _AIChatingScreenState();
}

class _AIChatingScreenState extends State<AIChatingScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> _messages = [
    {
      "sender": "Me",
      "text": "Hey there! How can I use Booksmart for tax tracking?",
      "time": "5 min ago",
    },
    {
      "sender": "Booksmart Sync",
      "text":
          "You can upload your receipts and we’ll categorize them automatically!",
      "time": "4 min ago",
    },
    {
      "sender": "Me",
      "text": "That’s awesome. Can it sync with my bank account too?",
      "time": "2 min ago",
    },
    {
      "sender": "Booksmart Sync",
      "text":
          "Yes! You can connect your bank under Settings → Connected Accounts.",
      "time": "Just now",
    },
  ];

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "Me", "text": text, "time": "Now"});
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bubbleColorMe = isDark
        ? const Color(0xFF1E2A44)
        : colorScheme.primary.withValues(alpha: 0.15);
    final bubbleColorBot = isDark
        ? const Color(0xFF24344D)
        : colorScheme.surfaceVariant;

    final textColor = colorScheme.onSurface;

    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("AI Chat")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          final isMe = msg["sender"] == "Me";

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.primary,
                    child: AppText(
                      msg["sender"][0],
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      AppText(
                        msg["sender"],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: isMe ? bubbleColorMe : bubbleColorBot,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AppText(
                          msg["text"],
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        msg["time"],
                        fontSize: 11,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.primary,
                    child: AppText(
                      msg["sender"][0],
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          children: [
            Expanded(
              child: AppTextField(
                hintText: "Ask anything here...",
                controller: _messageController,
                keyboardType: TextInputType.text,
                maxLines: 1,
                fieldValidator: (_) => null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.send, color: colorScheme.primary),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
