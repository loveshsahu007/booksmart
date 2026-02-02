import '../helpers/json_helper.dart';

class ChatModel {
  final int id;
  final int userId;
  final int cpaId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.userId,
    required this.cpaId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: handleResponseFromJson<int>(json, "id") ?? -1,
      userId: handleResponseFromJson<int>(json, "user_id") ?? -1,
      cpaId: handleResponseFromJson<int>(json, "cpa_id") ?? -1,
      createdAt:
          DateTime.tryParse(
            handleResponseFromJson<String>(json, "created_at") ?? "",
          ) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(
            handleResponseFromJson<String>(json, "updated_at") ?? "",
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "cpa_id": cpaId,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
    };
  }
}
