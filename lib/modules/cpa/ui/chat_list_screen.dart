import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/cpa/ui/chat_screen.dart';
import 'package:flutter/foundation.dart';

class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

  // Dummy chat list
  final List<Map<String, dynamic>> chatUsers = [
    {
      'name': 'John Smith',
      'lastMessage': 'Hey, how are you?',
      'time': '9:15 AM',
    },
    {'name': 'Emily Johnson', 'lastMessage': 'Can we talk?', 'time': '8:44 AM'},
    {
      'name': 'Michael Brown',
      'lastMessage': 'Sure! I will send it.',
      'time': 'Yesterday',
    },
    {'name': 'Sarah Ahmed', 'lastMessage': 'Thanks!', 'time': 'Yesterday'},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: Text('Chats')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        itemCount: chatUsers.length,
        itemBuilder: (context, index) {
          final chat = chatUsers[index];

          return Container(
            margin: EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primary.withValues(alpha: .2),
                child: AppText(
                  chat['name'][0],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              title: AppText(
                chat['name'],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),

              subtitle: AppText(chat['lastMessage'], fontSize: 13),

              trailing: AppText(chat['time'], fontSize: 11, color: Colors.grey),

              onTap: () {
                goToChatScreen(shouldCloseBefore: false);
              },
            ),
          );
        },
      ),
    );
  }
}
