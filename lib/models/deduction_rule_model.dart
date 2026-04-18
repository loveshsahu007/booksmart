import '../helpers/json_helper.dart';

enum RuleType { percentage, fixed }

class DeductionRuleModel {
  final int id;

  // if state-id is null then it is for FEDERAL
  final int? stateId;

  final int categoryId;
  final int subCategoryId;

  final RuleType ruleType;

  /// percentage (0.5 = 50%) OR fixed amount depending on ruleType
  final double value;

  final DateTime createdAt;
  final DateTime updatedAt;

  DeductionRuleModel({
    required this.id,
    required this.ruleType,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
    required this.stateId,
    required this.categoryId,
    required this.subCategoryId,
  });

  factory DeductionRuleModel.fromJson(Map<String, dynamic> json) {
    return DeductionRuleModel(
      id: handleResponseFromJson<int>(json, 'id') ?? 0,

      ruleType: RuleType.values.byName(
        handleResponseFromJson<String?>(json, 'rule_type') ??
            RuleType.percentage.name,
      ),
      value: (handleResponseFromJson<num>(json, 'value') ?? 0).toDouble(),
      stateId: handleResponseFromJson<int>(json, 'state_id'),
      categoryId: handleResponseFromJson<int>(json, 'category_id') ?? -1,
      subCategoryId: handleResponseFromJson<int>(json, 'sub_category_id') ?? -1,
      createdAt:
          DateTime.tryParse(
            handleResponseFromJson<String>(json, 'created_at') ?? '',
          ) ??
          DateTime.now(),

      updatedAt:
          DateTime.tryParse(
            handleResponseFromJson<String>(json, 'updated_at') ?? '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rule_type': ruleType.name,
      'value': value,
      'state_id': stateId,
      'category_id': categoryId,
      'sub_category_id': subCategoryId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
