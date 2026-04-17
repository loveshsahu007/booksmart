import 'package:booksmart/helpers/json_helper.dart';

class TransactionModel {
  final int id;
  final String title;
  final double amount;
  final int? category;
  final int? subcategory;
  final String type; // Personal / Business
  final bool deductible;
  final String description;
  final DateTime dateTime;
  final String? filePath; // Optional attachment
  final int userId;
  final int orgId;

  /// {
  ///   "primary": "GENERAL_MERCHANDISE",
  ///   "detailed": "GENERAL_MERCHANDISE_SUPERSTORES",
  ///   "confidence_level": "VERY_HIGH"
  /// }
  ///
  final Map<String, dynamic>? plaidCategory;
  final int? bankId;
  final String? bankAccountId;
  final String? plaidTransactionId;

  final bool isAiVerified;

  // ─── Tax Strategy Onboarding Fields ───────────────────────────────────────
  // Screen 1 – Legal & Tax Identity
  final String? filingStatus;
  final String? primaryState;
  final String? residencyStatus;
  final bool? multiStateActivity;

  // Screen 2 – Income Architecture
  final List<String>? primaryIncomeTypes;
  final String? industryNiche;
  final List<String>? passiveIncome;

  // Screen 3 – Business Operations
  final List<String>? teamStructure;
  final String? accountingMethod;
  final bool? majorEquipment;

  // Screen 4 – Vehicle & Logistics
  final String? vehicleOwnership;
  final String? vehicleUsage;
  final bool? vehicleOver6kLbs;

  // Screen 5 – Workspace & Infrastructure
  final String? homeOfficeType;
  final String? homeStatus;
  final List<String>? techUsage;

  // Screen 6 – Real Estate Strategy
  final List<String>? realEstateInterests;
  final bool? hostsBusinessMeetings;

  // Screen 7 – Household & Benefits
  final String? healthInsurance;
  final List<String>? healthSavings;
  final List<String>? familyEducation;

  // Screen 8 – AI Strategy Alignment
  final String? taxGoal;
  final List<String>? retirementCurrent;
  final String? auditAppetite;
  // ──────────────────────────────────────────────────────────────────────────

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.subcategory,
    required this.type,
    required this.deductible,
    required this.description,
    required this.dateTime,
    this.filePath,
    required this.userId,
    required this.orgId,
    this.plaidCategory,
    this.bankId,
    this.bankAccountId,
    this.plaidTransactionId,
    this.isAiVerified = true,
    // Tax fields
    this.filingStatus,
    this.primaryState,
    this.residencyStatus,
    this.multiStateActivity,
    this.primaryIncomeTypes,
    this.industryNiche,
    this.passiveIncome,
    this.teamStructure,
    this.accountingMethod,
    this.majorEquipment,
    this.vehicleOwnership,
    this.vehicleUsage,
    this.vehicleOver6kLbs,
    this.homeOfficeType,
    this.homeStatus,
    this.techUsage,
    this.realEstateInterests,
    this.hostsBusinessMeetings,
    this.healthInsurance,
    this.healthSavings,
    this.familyEducation,
    this.taxGoal,
    this.retirementCurrent,
    this.auditAppetite,
  });

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.map((e) => e.toString()).toList();
    return null;
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: handleResponseFromJson<int?>(json, 'id')!,
        title: handleResponseFromJson<String?>(json, 'title') ?? '---',
        amount: handleResponseFromJson<double?>(json, 'amount') ?? 0,
        category: handleResponseFromJson<int?>(json, 'category_id'),
        subcategory: handleResponseFromJson<int?>(json, 'sub_category_id'),
        type: handleResponseFromJson<String?>(json, 'type') ?? '---',
        deductible: handleResponseFromJson<bool?>(json, 'deductible') ?? false,
        description: handleResponseFromJson<String?>(json, 'description') ?? "",
        dateTime: DateTime.parse(json['date_time']),
        filePath: handleResponseFromJson<String?>(json, 'file_path'),
        userId: handleResponseFromJson<int?>(json, 'user_id')!,
        orgId: handleResponseFromJson<int?>(json, 'org_id')!,
        plaidCategory: json['plaid_category'] as Map<String, dynamic>?,
        bankId: handleResponseFromJson<int?>(json, 'bank_id'),
        bankAccountId: handleResponseFromJson<String?>(json, 'bank_account_id'),
        plaidTransactionId: handleResponseFromJson<String?>(
          json,
          'plaid_transaction_id',
        ),
        isAiVerified:
            handleResponseFromJson<bool?>(json, 'is_ai_verified') ?? true,
        // Tax fields
        filingStatus: handleResponseFromJson<String?>(json, 'filing_status'),
        primaryState: handleResponseFromJson<String?>(json, 'primary_state'),
        residencyStatus:
            handleResponseFromJson<String?>(json, 'residency_status'),
        multiStateActivity:
            handleResponseFromJson<bool?>(json, 'multi_state_activity'),
        primaryIncomeTypes: _parseStringList(json['primary_income_types']),
        industryNiche: handleResponseFromJson<String?>(json, 'industry_niche'),
        passiveIncome: _parseStringList(json['passive_income']),
        teamStructure: _parseStringList(json['team_structure']),
        accountingMethod:
            handleResponseFromJson<String?>(json, 'accounting_method'),
        majorEquipment: handleResponseFromJson<bool?>(json, 'major_equipment'),
        vehicleOwnership:
            handleResponseFromJson<String?>(json, 'vehicle_ownership'),
        vehicleUsage: handleResponseFromJson<String?>(json, 'vehicle_usage'),
        vehicleOver6kLbs:
            handleResponseFromJson<bool?>(json, 'vehicle_over_6k_lbs'),
        homeOfficeType: handleResponseFromJson<String?>(json, 'home_office_type'),
        homeStatus: handleResponseFromJson<String?>(json, 'home_status'),
        techUsage: _parseStringList(json['tech_usage']),
        realEstateInterests: _parseStringList(json['real_estate_interests']),
        hostsBusinessMeetings:
            handleResponseFromJson<bool?>(json, 'hosts_business_meetings'),
        healthInsurance:
            handleResponseFromJson<String?>(json, 'health_insurance'),
        healthSavings: _parseStringList(json['health_savings']),
        familyEducation: _parseStringList(json['family_education']),
        taxGoal: handleResponseFromJson<String?>(json, 'tax_goal'),
        retirementCurrent: _parseStringList(json['retirement_current']),
        auditAppetite: handleResponseFromJson<String?>(json, 'audit_appetite'),
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'org_id': orgId,
      'title': title,
      'amount': amount,
      'category_id': category,
      'sub_category_id': subcategory,
      'type': type,
      'deductible': deductible,
      'description': description,
      'date_time': dateTime.toIso8601String(),
      'file_path': filePath,
      'plaid_category': plaidCategory,
      'bank_id': bankId,
      'bank_account_id': bankAccountId,
      'plaid_transaction_id': plaidTransactionId,
      'is_ai_verified': isAiVerified,
      // Tax fields
      'filing_status': filingStatus,
      'primary_state': primaryState,
      'residency_status': residencyStatus,
      'multi_state_activity': multiStateActivity,
      'primary_income_types': primaryIncomeTypes,
      'industry_niche': industryNiche,
      'passive_income': passiveIncome,
      'team_structure': teamStructure,
      'accounting_method': accountingMethod,
      'major_equipment': majorEquipment,
      'vehicle_ownership': vehicleOwnership,
      'vehicle_usage': vehicleUsage,
      'vehicle_over_6k_lbs': vehicleOver6kLbs,
      'home_office_type': homeOfficeType,
      'home_status': homeStatus,
      'tech_usage': techUsage,
      'real_estate_interests': realEstateInterests,
      'hosts_business_meetings': hostsBusinessMeetings,
      'health_insurance': healthInsurance,
      'health_savings': healthSavings,
      'family_education': familyEducation,
      'tax_goal': taxGoal,
      'retirement_current': retirementCurrent,
      'audit_appetite': auditAppetite,
    }..removeWhere((key, value) => value == null);
  }

  bool get isFromBank => bankId != null;
}
