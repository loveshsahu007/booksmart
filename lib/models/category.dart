class CategoryModel {
  final int id;
  final String name;
  final int addedBy;

  CategoryModel({required this.id, required this.name, required this.addedBy});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      addedBy: json['added_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'added_by': addedBy};
  }
}

class SubCategoryModel {
  final int id;
  final int categoryId;
  final String name;
  final int addedBy;

  SubCategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.addedBy,
  });
  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      addedBy: json['added_by'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'added_by': addedBy,
    };
  }
}
