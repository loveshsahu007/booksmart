import 'package:booksmart/models/user_base_model.dart';
import '../helpers/json_helper.dart';

enum OrderStatus {
  pending,
  accepted,
  rejected,
  completed,
  cancelled;

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (element) => element.name == status,
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderModel {
  final int id;
  final int cpaId;
  final int userId;
  final String title;
  final String? description;
  final double amount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startDate;
  final DateTime? dueDate;
  final PersonModel? cpa;
  final PersonModel? user;

  OrderModel({
    required this.id,
    required this.cpaId,
    required this.userId,
    required this.title,
    this.description,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.startDate,
    this.dueDate,
    this.cpa,
    this.user,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: handleResponseFromJson<int>(json, "id") ?? -1,
      cpaId: handleResponseFromJson<int>(json, "cpa_id") ?? -1,
      userId: handleResponseFromJson<int>(json, "user_id") ?? -1,
      title: handleResponseFromJson<String>(json, "title") ?? "",
      description: handleResponseFromJson<String>(json, "description"),
      amount: (handleResponseFromJson<num>(json, "amount") ?? 0).toDouble(),
      status: OrderStatus.fromString(
        handleResponseFromJson<String>(json, "status") ?? "pending",
      ),
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
      startDate: DateTime.tryParse(
        handleResponseFromJson<String>(json, "start_date") ?? "",
      ),
      dueDate: DateTime.tryParse(
        handleResponseFromJson<String>(json, "due_date") ?? "",
      ),
      cpa: json['cpa'] != null ? PersonModel.fromJson(json['cpa']) : null,
      user: json['user'] != null ? PersonModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "cpa_id": cpaId,
      "user_id": userId,
      "title": title,
      "description": description,
      "amount": amount,
      "status": status.name,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
      "start_date": startDate?.toIso8601String(),
      "due_date": dueDate?.toIso8601String(),
    };
  }
}
