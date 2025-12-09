import 'dart:convert';

class UserModel {
  final String? id; // DB primary (optional) — if you stored numeric id
  final String? authId; // auth_id (supabase uuid)
  final String? email;
  final String? role;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? imgUrl; // Added: Profile image URL
  final DateTime? createdAt;

  // CPA-specific fields
  final String? middleName;
  final List<String>?
  certifications; // List of certifications like ["CPA", "EA"]
  final String? licenseNumber;
  final int? yearsOfExperience;
  final String? professionalBio;
  final List<String>? specialties; // List of selected specialties
  final List<String>? stateFocuses; // List of state codes like ["CA", "NY"]
  final String? certificationProofUrl; // URL to uploaded document
  final String? licenseCopyUrl; // URL to uploaded license copy
  final bool? termsAgreed;
  final String? status; // e.g., "pending", "approved", "rejected"
  final DateTime? updatedAt;

  UserModel({
    this.id,
    this.authId,
    this.email,
    this.role,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.imgUrl, // Added
    this.createdAt,

    // CPA fields
    this.middleName,
    this.certifications,
    this.licenseNumber,
    this.yearsOfExperience,
    this.professionalBio,
    this.specialties,
    this.stateFocuses,
    this.certificationProofUrl,
    this.licenseCopyUrl,
    this.termsAgreed,
    this.status,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString(),
      authId: json['auth_id'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      imgUrl: json['img_url'] as String?, // Added
      createdAt: _parseDateTime(json['created_at']),

      // CPA fields
      middleName: json['middle_name'] as String?,
      certifications: _parseStringList(json['certifications']),
      licenseNumber: json['license_number'] as String?,
      yearsOfExperience: _parseInt(json['years_of_experience']),
      professionalBio: json['professional_bio'] as String?,
      specialties: _parseStringList(json['specialties']),
      stateFocuses: _parseStringList(json['state_focuses']),
      certificationProofUrl: json['certification_proof_url'] as String?,
      licenseCopyUrl: json['license_copy_url'] as String?,
      termsAgreed: json['terms_agreed'] as bool?,
      status: json['status'] as String?,
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (authId != null) 'auth_id': authId,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (imgUrl != null) 'img_url': imgUrl, // Added
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),

      // CPA fields
      if (middleName != null) 'middle_name': middleName,
      if (certifications != null) 'certifications': certifications,
      if (licenseNumber != null) 'license_number': licenseNumber,
      if (yearsOfExperience != null) 'years_of_experience': yearsOfExperience,
      if (professionalBio != null) 'professional_bio': professionalBio,
      if (specialties != null) 'specialties': specialties,
      if (stateFocuses != null) 'state_focuses': stateFocuses,
      if (certificationProofUrl != null)
        'certification_proof_url': certificationProofUrl,
      if (licenseCopyUrl != null) 'license_copy_url': licenseCopyUrl,
      if (termsAgreed != null) 'terms_agreed': termsAgreed,
      if (status != null) 'status': status,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String) {
      try {
        // Assuming it's stored as JSON string
        final parsed = jsonDecode(value) as List;
        return parsed.map((item) => item.toString()).toList();
      } catch (_) {
        return [value];
      }
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  UserModel copyWith({
    String? id,
    String? authId,
    String? email,
    String? role,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? imgUrl, // Added
    DateTime? createdAt,

    // CPA fields
    String? middleName,
    List<String>? certifications,
    String? licenseNumber,
    int? yearsOfExperience,
    String? professionalBio,
    List<String>? specialties,
    List<String>? stateFocuses,
    String? certificationProofUrl,
    String? licenseCopyUrl,
    bool? termsAgreed,
    String? status,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      email: email ?? this.email,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      imgUrl: imgUrl ?? this.imgUrl, // Added
      createdAt: createdAt ?? this.createdAt,

      // CPA fields
      middleName: middleName ?? this.middleName,
      certifications: certifications ?? this.certifications,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      professionalBio: professionalBio ?? this.professionalBio,
      specialties: specialties ?? this.specialties,
      stateFocuses: stateFocuses ?? this.stateFocuses,
      certificationProofUrl:
          certificationProofUrl ?? this.certificationProofUrl,
      licenseCopyUrl: licenseCopyUrl ?? this.licenseCopyUrl,
      termsAgreed: termsAgreed ?? this.termsAgreed,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to create a new CPA profile with default values
  static UserModel createDefaultCPAProfile({required String authId}) {
    return UserModel(
      authId: authId,
      certifications: [],
      specialties: [],
      stateFocuses: [],
      status: 'pending',
      termsAgreed: false,
      createdAt: DateTime.now(),
    );
  }

  // Check if CPA profile is complete (for validation)
  bool get isCPAProfileComplete {
    return role == 'cpa' &&
        middleName?.isNotEmpty == true &&
        certifications?.isNotEmpty == true &&
        licenseNumber?.isNotEmpty == true &&
        yearsOfExperience != null &&
        professionalBio?.isNotEmpty == true &&
        specialties?.isNotEmpty == true &&
        stateFocuses?.isNotEmpty == true &&
        termsAgreed == true;
  }

  // Get full name including middle name
  String get fullName {
    final parts = [
      firstName,
      middleName,
      lastName,
    ].where((part) => part?.isNotEmpty == true);
    return parts.join(' ');
  }

  // Get display name (first + last)
  String get displayName {
    final parts = [
      firstName,
      lastName,
    ].where((part) => part?.isNotEmpty == true);
    return parts.join(' ');
  }

  // Get experience level based on years
  String get experienceLevel {
    if (yearsOfExperience == null) return 'Not specified';
    if (yearsOfExperience! < 2) return 'Entry Level';
    if (yearsOfExperience! < 5) return 'Mid Level';
    if (yearsOfExperience! < 10) return 'Senior';
    return 'Expert';
  }

  // Check if user is a CPA
  bool get isCPA => role == 'cpa';

  // Check if CPA profile is approved
  bool get isCPAApproved => role == 'cpa' && status == 'approved';

  // Get profile image URL or default
  String get profileImageUrl {
    return imgUrl ??
        'assets/images/default_avatar.png'; // Add your default asset
  }
}
