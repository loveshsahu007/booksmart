part of './user_base_model.dart';

class UserModel extends Core {
  UserModel({required super.data});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(data: PersonModel.fromJson(json));
  }

  Map<String, dynamic> toJson() {
    return super.data.toJson()..addAll({
      // add other fields from UserModel
    });
  }
}
