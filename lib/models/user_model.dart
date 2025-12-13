part of './user_base_model.dart';

class UserModel extends Core {
  UserModel({required super.data});

  bool get isProfileCompleted =>
      data.firstName.isNotEmpty && data.lastName.isNotEmpty;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(data: PersonModel.fromJson(json));
  }

  Map<String, dynamic> toJson() {
    return super.data.toJson()..addAll({
      // add other fields from UserModel
    });
  }
}
