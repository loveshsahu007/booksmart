import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constant/env_data.dart';
import '../../../models/ai_message_model.dart';
import '../../../models/ai_tax_strategy_model.dart';
import '../../../supabase/tables.dart';
import '../../../utils/supabase.dart';
import 'package:http/http.dart' as http;

class AiChatController extends GetxController {
  final int strategyId;

  AiChatController(this.strategyId);

  final messages = <AiMessageModel>[].obs;
  final isLoading = false.obs;
  final isSending = false.obs;

  int _page = 0;
  final int _limit = 20;
  bool hasMore = true;

  final scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    loadMessages();

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent &&
          hasMore &&
          !isLoading.value) {
        loadMessages();
      }
    });
  }

  /// ---------- LOAD PAGINATED ----------
  Future<void> loadMessages() async {
    isLoading.value = true;

    final res = await supabase
        .from(SupabaseTable.aiChatMessages)
        .select()
        .eq('strategy_id', strategyId)
        .order('created_at', ascending: false)
        .range(_page * _limit, (_page + 1) * _limit - 1);

    final data = res as List;

    if (data.length < _limit) hasMore = false;

    final fetched = data
        .map((e) => AiMessageModel.fromJson(e))
        .toList()
        .reversed
        .toList();

    messages.insertAll(0, fetched);

    _page++;
    isLoading.value = false;
  }

  /// ---------- SEND MESSAGE ----------
  Future<void> sendMessage(String text, AiTaxStrategyModel strategy) async {
    if (text.trim().isEmpty) return;

    final userMsg = AiMessageModel(
      id: 0,
      strategyId: strategyId,
      role: AiChatRole.user,
      message: text,
      createdAt: DateTime.now(),
    );

    messages.add(userMsg);

    await supabase
        .from(SupabaseTable.aiChatMessages)
        .insert(userMsg.toInsertJson());

    isSending.value = true;

    final aiReply = await _callAI(strategy);

    final aiMsg = AiMessageModel(
      id: 0,
      strategyId: strategyId,
      role: AiChatRole.ai,
      message: aiReply,
      createdAt: DateTime.now(),
    );

    messages.add(aiMsg);

    await supabase
        .from(SupabaseTable.aiChatMessages)
        .insert(aiMsg.toInsertJson());

    isSending.value = false;

    scrollToBottom();
  }

  /// ---------- AI CALL ----------
  Future<String> _callAI(AiTaxStrategyModel strategy) async {
    final lastMessages = messages.reversed.take(6).toList();

    final chatHistory = lastMessages
        .map((m) => "${m.role.name}: ${m.message}")
        .join("\n");

    final prompt =
        """
You are a US tax expert.

Strategy:
${strategy.title}
${strategy.summary}

Steps:
${strategy.implementationSteps.join(", ")}

Conversation:
$chatHistory

User is asking follow-up questions. Be concise, practical, and compliant.
""";

    final response = await http.post(
      Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
      headers: {
        "Authorization": "Bearer $getOpenRouterAiTaxKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "openai/gpt-4.1-mini",
        "messages": [
          {"role": "system", "content": "You are a CPA."},
          {"role": "user", "content": prompt},
        ],
        "max_tokens": 600,
        "temperature": 0.3,
      }),
    );

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}
