import '../helpers/json_helper.dart';

class StateModel {
  final int id;
  final String name;
  final String code;
  final bool isActive;

  StateModel({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: handleResponseFromJson<int>(json, 'id') ?? -1,
      name: handleResponseFromJson<String>(json, 'name') ?? '',
      code: handleResponseFromJson<String>(json, 'code') ?? '',
      isActive: handleResponseFromJson<bool>(json, 'is_active') ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code, 'is_active': isActive};
  }
}
