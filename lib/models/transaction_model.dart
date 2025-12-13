import 'package:uuid/uuid.dart';

class TransactionModel {
  String id;
  String title;
  double amount;
  String category;
  String subcategory;
  String type; // Personal / Business
  bool deductible;
  String notes;
  String date;
  String? filePath; // Optional attachment
  String ownerId;

  TransactionModel({
    String? id,
    required this.title,
    required this.amount,
    required this.category,
    required this.subcategory,
    required this.type,
    required this.deductible,
    required this.notes,
    required this.date,
    this.filePath,
    required this.ownerId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'subcategory': subcategory,
    'type': type,
    'deductible': deductible,
    'notes': notes,
    'date': date,
    'file_path': filePath,
    'owner_id': ownerId,
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String?,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        subcategory: json['subcategory'] as String,
        type: json['type'] as String,
        deductible: json['deductible'] as bool,
        notes: json['notes'] as String? ?? '',
        date: json['date'] as String,
        filePath: json['file_path'] as String?,
        ownerId: json['owner_id'] as String,
      );
}
