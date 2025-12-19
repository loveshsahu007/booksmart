class TransactionModel {
  final int id;
  final String title;
  final double amount;
  final String category;
  final String subcategory;
  final String type; // Personal / Business
  final bool deductible;
  final String notes;
  final String date;
  final String? filePath; // Optional attachment
  final int ownerId;
  final int organizationId;

  TransactionModel({
    required this.id,
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
    required this.organizationId,
  });

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
    'organization_id': organizationId,
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'],
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        subcategory: json['subcategory'] as String,
        type: json['type'] as String,
        deductible: json['deductible'] as bool,
        notes: json['notes'] as String? ?? '',
        date: json['date'] as String,
        filePath: json['file_path'] as String?,
        ownerId: json['owner_id'] as int,
        organizationId: json['organization_id'] as int,
      );
}
