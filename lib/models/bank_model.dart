class BankModel {
  final String id;
  final String name;
  final String accountHolder;
  final String accountNumber;
  final String iban;
  final String ownerId;
  final String organizationId;

  BankModel({
    required this.id,
    required this.name,
    required this.accountHolder,
    required this.accountNumber,
    required this.iban,
    required this.ownerId,
    required this.organizationId,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json['id'] as String,
      name: json['name'] as String,
      accountHolder: json['account_holder'] as String,
      accountNumber: json['account_number'] as String,
      iban: json['iban'] as String,
      ownerId: json['owner_id'] as String,
      organizationId: json['organization_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'account_holder': accountHolder,
      'account_number': accountNumber,
      'iban': iban,
      'owner_id': ownerId,
      'organization_id': organizationId,
    };
  }
}
