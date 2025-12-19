class BankModel {
  final int id;
  final String name;
  final String accountHolder;
  final String accountNumber;
  final String iban;
  final int ownerId;
  final int organizationId;

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
      id: json['id'],
      name: json['name'],
      accountHolder: json['account_holder'],
      accountNumber: json['account_number'],
      iban: json['iban'],
      ownerId: json['owner_id'],
      organizationId: json['organization_id'],
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
