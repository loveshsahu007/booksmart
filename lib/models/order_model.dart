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

enum StripePaymentStatus {
  unpaid,
  paid,
  processing,
  failed,
  refunded;

  static StripePaymentStatus fromString(String status) {
    return StripePaymentStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => StripePaymentStatus.unpaid,
    );
  }
}

enum CpaPayoutStatus {
  pending,
  paid;

  static CpaPayoutStatus fromString(String status) {
    return CpaPayoutStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => CpaPayoutStatus.pending,
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

  final String? stripePaymentIntentId;
  final StripePaymentStatus paymentStatus;
  final DateTime? paidAt;

  final double? platformFee;

  final double? cpaPayoutAmount;
  final CpaPayoutStatus cpaPayoutStatus;
  final DateTime? cpaPaidAt;
  final String? stripeTransferId;

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
    this.stripePaymentIntentId,
    required this.paymentStatus,
    this.paidAt,

    this.platformFee,

    this.cpaPayoutAmount,
    required this.cpaPayoutStatus,
    this.cpaPaidAt,
    this.stripeTransferId,
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
      stripePaymentIntentId: handleResponseFromJson<String>(
        json,
        "stripe_payment_intent_id",
      ),

      paymentStatus: StripePaymentStatus.fromString(
        handleResponseFromJson<String>(json, "payment_status") ?? "unpaid",
      ),

      paidAt: DateTime.tryParse(
        handleResponseFromJson<String>(json, "paid_at") ?? "",
      ),

      platformFee: (handleResponseFromJson<num>(
        json,
        "platform_fee",
      ))?.toDouble(),

      cpaPayoutAmount: (handleResponseFromJson<num>(
        json,
        "cpa_payout_amount",
      ))?.toDouble(),

      cpaPayoutStatus: CpaPayoutStatus.fromString(
        handleResponseFromJson<String>(json, "cpa_payout_status") ?? "pending",
      ),

      cpaPaidAt: DateTime.tryParse(
        handleResponseFromJson<String>(json, "cpa_paid_at") ?? "",
      ),

      stripeTransferId: handleResponseFromJson<String>(
        json,
        "stripe_transfer_id",
      ),
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
      "stripe_payment_intent_id": stripePaymentIntentId,
      "payment_status": paymentStatus.name,
      "paid_at": paidAt?.toIso8601String(),
      "platform_fee": platformFee,
      "cpa_payout_amount": cpaPayoutAmount,
      "cpa_payout_status": cpaPayoutStatus.name,
      "cpa_paid_at": cpaPaidAt?.toIso8601String(),
      "stripe_transfer_id": stripeTransferId,
    };
  }
}
