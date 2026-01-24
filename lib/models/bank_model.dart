class BankModel {
  final int id;
  final int userId;
  final int orgId;

  /// item_id = One bank connection
  ///
  /// When a user connects a bank via Plaid, Plaid creates an Item.
  ///
  /// Item = user ↔ institution ↔ credentials
  final String itemId;
  final String institutionId;
  final String institutionName;

  final List<BankAccountModel> accounts;
  final String? transactionsCursor;

  final DateTime createdAt;
  final DateTime? lastSyncAt;

  BankModel({
    required this.id,
    required this.userId,
    required this.orgId,
    required this.itemId,
    required this.institutionId,
    required this.institutionName,
    required this.accounts,
    this.transactionsCursor,
    required this.createdAt,
    required this.lastSyncAt,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json['id'],
      userId: json['user_id'],
      orgId: json['org_id'],
      itemId: json['item_id'],
      institutionId: json['institution_id'],
      institutionName: json['institution_name'],
      accounts: (json['accounts'] as List)
          .map((e) => BankAccountModel.fromJson(e))
          .toList(),
      transactionsCursor: json['transactions_cursor'],
      createdAt: DateTime.parse(json['created_at']),
      lastSyncAt: DateTime.tryParse(json['last_synced_at'] ?? "")?.toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'org_id': orgId,
      'item_id': itemId,
      'institution_id': institutionId,
      'institution_name': institutionName,
      'accounts': accounts.map((e) => e.toJson()).toList(),
      'transactions_cursor': transactionsCursor,
      'created_at': createdAt.toIso8601String(),
      'last_synced_at': lastSyncAt?.toUtc().toIso8601String(),
    };
  }
}

class BankAccountModel {
  final String id;
  final String? mask;
  final String name;
  final String type;
  final String? subtype;
  final String? officialName;
  final String? holderCategory;

  BankAccountModel({
    required this.id,
    required this.mask,
    required this.name,
    required this.type,
    required this.subtype,
    required this.officialName,
    required this.holderCategory,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) =>
      BankAccountModel(
        id: json["id"],
        mask: json["mask"],
        name: json["name"],
        type: json["type"],
        subtype: json["subtype"],
        officialName: json["official_name"],
        holderCategory: json["holder_category"],
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "mask": mask,
    "name": name,
    "type": type,
    "subtype": subtype,
    "official_name": officialName,
    "holder_category": holderCategory,
  };
}
