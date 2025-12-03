class UserDataModel {
  final String id;
  final String name;

  UserDataModel({required this.id, required this.name});

  // Factory constructor to create an instance from a JSON map
  factory UserDataModel.fromJson(Map<String, dynamic> json) {
    return UserDataModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  // Method to convert an instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
