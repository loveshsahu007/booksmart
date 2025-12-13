part of './user_base_model.dart';

class CpaModel extends Core {
  final List<String> certifications;
  final String licenseNumber;
  final DateTime careerStartDate;
  final String professionalBio;
  final List<String> specialties;
  final List<String> stateFocuses;
  final String certificationProofUrl;
  final String licenseCopyUrl;
  final bool termsAgreed;
  final String status;

  bool get isProfileCompleted =>
      data.firstName.isNotEmpty && data.lastName.isNotEmpty;

  int get getExperienceInYears {
    int difference = DateTime.now().year - (careerStartDate.year);

    if (difference == 0) {
      return 1;
    } else {
      return difference;
    }
  }

  CpaModel({
    required super.data,
    required this.certifications,
    required this.licenseNumber,
    required this.careerStartDate,
    required this.professionalBio,
    required this.specialties,
    required this.stateFocuses,
    required this.certificationProofUrl,
    required this.licenseCopyUrl,
    required this.termsAgreed,
    required this.status,
  });

  factory CpaModel.fromJson(Map<String, dynamic> json) {
    return CpaModel(
      data: PersonModel.fromJson(json),

      certifications: ((json["certifications"] as List?) ?? [])
          .map((x) => x.toString())
          .toList(),
      licenseNumber:
          handleResponseFromJson<String>(json, "license_number") ?? "",
      careerStartDate: DateTime.parse(
        handleResponseFromJson<String>(json, "career_start_date") ?? "",
      ),
      professionalBio:
          handleResponseFromJson<String>(json, "professional_bio") ?? "",
      specialties: (handleResponseFromJson<List>(json, "specialties") ?? [])
          .map((e) => e.toString())
          .toList(),
      stateFocuses: (handleResponseFromJson<List>(json, "state_focuses") ?? [])
          .map((e) => e.toString())
          .toList(),
      certificationProofUrl:
          handleResponseFromJson<String>(json, "certification_proof_url") ?? "",
      licenseCopyUrl:
          handleResponseFromJson<String>(json, "license_copy_url") ?? "",
      termsAgreed: handleResponseFromJson<bool>(json, "terms_agreed") ?? false,
      status: handleResponseFromJson<String>(json, "status") ?? "pending",
    );
  }

  Map<String, dynamic> toJson() {
    return super.data.toJson()..addAll({
      "certifications": certifications,
      "license_number": licenseNumber,
      "career_start_date": careerStartDate.toIso8601String(),
      "professional_bio": professionalBio,
      "specialties": specialties,
      "state_focuses": stateFocuses,
      "certification_proof_url": certificationProofUrl,
      "license_copy_url": licenseCopyUrl,
      "terms_agreed": termsAgreed,
      "status": status,
    });
  }
}
