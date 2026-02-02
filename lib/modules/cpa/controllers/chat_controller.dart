import 'dart:developer';

import 'package:booksmart/modules/common/controllers/auth_controller.dart';
import 'package:booksmart/services/crud_service.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:get/get.dart';

import '../../../models/chat_model.dart';
import '../../../models/message_model.dart';
import '../../../models/user_base_model.dart';
import '../../../utils/supabase.dart';

class ChatController extends GetxController {
  final messages = <MessageModel>[].obs;
  final isLoading = false.obs;
  Rx<ChatModel?> currentChat = Rx<ChatModel?>(null);

  // Get current user ID (int)
  int get currentUserId => Get.find<AuthController>().person?.id ?? -1;
  UserRole get currentUserRole =>
      Get.find<AuthController>().person?.role ?? UserRole.user;

  @override
  void onClose() {
    // unsubscribe handling if needed
    super.onClose();
  }

  Future<void> loadChat(int otherUserId) async {
    try {
      isLoading.value = true;
      messages.clear();

      ChatModel? chat = await _getChat(otherUserId);

      if (chat == null) {
        // Create new chat
        chat = await _createChat(otherUserId);
      }

      if (chat != null) {
        currentChat.value = chat;
        await fetchMessages(chat.id);
        _subscribeToMessages(chat.id);
      }
    } catch (e) {
      log("Error loading chat: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<ChatModel?> _getChat(int otherUserId) async {
    try {
      Map<String, dynamic> filters = {};

      // Assumption: Current user is User, Other is CPA.
      // Or we can query both combinations to be safe if roles are fluid.
      // But based on schema: user_id (User) and cpa_id (Cpa).

      if (currentUserRole == UserRole.cpa) {
        filters = {'cpa_id': currentUserId, 'user_id': otherUserId};
      } else {
        filters = {'user_id': currentUserId, 'cpa_id': otherUserId};
      }

      final result = await SupabaseCrudService.read(
        table: SupabaseTable.chats,
        filters: filters,
        single: true,
      );

      if (result != null) {
        return ChatModel.fromJson(result);
      }
      return null;
    } catch (e) {
      log("Error getting chat: $e");
      return null;
    }
  }

  Future<ChatModel?> _createChat(int otherUserId) async {
    try {
      Map<String, dynamic> data = {};
      if (currentUserRole == UserRole.cpa) {
        data = {'cpa_id': currentUserId, 'user_id': otherUserId};
      } else {
        data = {'user_id': currentUserId, 'cpa_id': otherUserId};
      }

      final result = await SupabaseCrudService.insert(
        table: SupabaseTable.chats,
        data: data,
      );

      if (result is List && result.isNotEmpty) {
        return ChatModel.fromJson(result.first);
      }
      return null;
    } catch (e) {
      log("Error creating chat: $e");
      return null;
    }
  }

  Future<void> fetchMessages(int chatId) async {
    try {
      final result = await supabase
          .from(SupabaseTable.messages)
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false); // Newest first

      messages.value = (result as List)
          .map((e) => MessageModel.fromJson(e))
          .toList();
    } catch (e) {
      log("Error fetching messages: $e");
    }
  }

  void _subscribeToMessages(int chatId) {
    supabase
        .from(SupabaseTable.messages)
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> data) {
          messages.value = data.map((e) => MessageModel.fromJson(e)).toList();
        });
  }

  Future<void> sendMessage(String content) async {
    if (currentChat.value == null || content.trim().isEmpty) return;

    try {
      final messageData = {
        'chat_id': currentChat.value!.id,
        'sender_id': currentUserId,
        'content': content,
        'type': MessageType.text.name,
        'is_read': false,
      };

      await SupabaseCrudService.insert(
        table: SupabaseTable.messages,
        data: messageData,
      );

      // Reload messages to show instantly
      await fetchMessages(currentChat.value!.id);
    } catch (e) {
      log("Error sending message: $e");
    }
  }
}
