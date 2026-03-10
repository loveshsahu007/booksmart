part of './user_base_model.dart';

class UserModel extends Core {
  UserModel({required super.data, this.stripeCustomerId});

  bool get isProfileCompleted =>
      data.firstName.isNotEmpty && data.lastName.isNotEmpty;

  final String? stripeCustomerId;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      data: PersonModel.fromJson(json),
      stripeCustomerId: json['stripe_customer_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return super.data.toJson()
      ..addAll({'stripe_customer_id': stripeCustomerId});
  }
}
