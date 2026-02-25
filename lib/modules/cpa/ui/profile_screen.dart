import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/common/providers/user_profile_provider.dart';
import 'package:booksmart/services/storage_service.dart';
import 'package:booksmart/supabase/buckets.dart';
import 'package:booksmart/widgets/loading.dart';
import 'package:booksmart/widgets/multiple_selection_dropdown_widget.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:jiffy/jiffy.dart';

import '../../../constant/data.dart';
import '../../common/controllers/auth_controller.dart';
import '../../../models/user_base_model.dart';

class ProfileScreenCPA extends StatefulWidget {
  const ProfileScreenCPA({super.key});

  @override
  State<ProfileScreenCPA> createState() => _ProfileScreenCPAState();
}

class _ProfileScreenCPAState extends State<ProfileScreenCPA> {
  int _currentStep = 0;
  final _personalFormKey = GlobalKey<FormState>();
  final _professionalFormKey = GlobalKey<FormState>();
  final _verificationFormKey = GlobalKey<FormState>();

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _personalFormKey.currentState?.validate() ?? false;
      case 1:
        return _professionalFormKey.currentState?.validate() ?? false;
      case 2:
        return _verificationFormKey.currentState?.validate() ?? false;
      default:
        return false;
    }
  }

  // Text controllers
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController middleNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController certCtrl = TextEditingController();
  final TextEditingController licenseCtrl = TextEditingController();

  final TextEditingController carrerStartDateController =
      TextEditingController();
  DateTime? startDate;

  final TextEditingController bioCtrl = TextEditingController();

  // Dropdown keys
  final _specialtiesKey = GlobalKey<DropdownSearchState<String>>();
  final _statesKey = GlobalKey<DropdownSearchState<String>>();
  final _certificationsKey = GlobalKey<DropdownSearchState<String>>();

  // Selected values
  List<String> selectedCertifications = [];
  List<String> selectedSpecialties = [];
  List<String> selectedStates = [];

  // File uploads
  XFile? _profileImage; // keep for upload
  Uint8List? _profileImageBytes; // preview bytes (works on web + mobile)

  XFile? _certificationProofFile;
  XFile? _licenseCopyFile;
  String? _profileImageUrl;
  String? _certificationProofUrl;
  String? _licenseCopyUrl;

  bool _termsAgreed = false;

  CpaModel? cpa = authCpa;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    middleNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    certCtrl.dispose();
    licenseCtrl.dispose();
    carrerStartDateController.dispose();
    bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (cpa != null) {
      // Basic info
      firstNameCtrl.text = cpa!.firstName;
      lastNameCtrl.text = cpa!.lastName;
      middleNameCtrl.text = cpa!.middleName;
      emailCtrl.text = cpa!.email;
      phoneCtrl.text = cpa!.phoneNumber;
      _profileImageUrl = cpa!.imgUrl;

      // CPA fields
      licenseCtrl.text = cpa!.licenseNumber;
      carrerStartDateController.text = cpa!.careerStartDate == null
          ? ""
          : Jiffy.parseFromDateTime(cpa!.careerStartDate!).yMMMd;
      startDate = cpa!.careerStartDate;
      bioCtrl.text = cpa!.professionalBio;

      // Arrays (handle both List and JSON string)
      selectedCertifications = _parseArrayField(cpa!.certifications);
      selectedSpecialties = _parseArrayField(cpa!.specialties);
      selectedStates = _parseArrayField(cpa!.stateFocuses);

      // Files
      _certificationProofUrl = cpa!.certificationProofUrl;
      _licenseCopyUrl = cpa!.licenseCopyUrl;

      // Booleans
      _termsAgreed = cpa!.termsAgreed;
    }
  }

  List<String> _parseArrayField(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String) {
      try {
        final parsed = jsonDecode(value) as List;
        return parsed.map((item) => item.toString()).toList();
      } catch (_) {
        return [value];
      }
    }
    return [];
  }

  /// Picks images for profile or documents.
  /// For profile images, also read bytes for preview (works on web + mobile).
  Future<void> _pickImage(ImageSource source, {bool isProfile = true}) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        if (isProfile) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _profileImage = pickedFile;
            _profileImageBytes = bytes;
          });
        } else {
          setState(() {
            if (_certificationProofFile == null) {
              _certificationProofFile = pickedFile;
            } else if (_licenseCopyFile == null) {
              _licenseCopyFile = pickedFile;
            } else {
              _certificationProofFile = pickedFile;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _saveToSupabase() async {
    try {
      showLoading();
      // Upload files if they exist
      if (_profileImage != null) {
        final url = await uploadFileToSupabaseStorage(
          _profileImage!,
          SupabaseStorageBucket.userImages,
        );
        if (url != null && url.isNotEmpty) {
          _profileImageUrl = url;
          _profileImage = null;
          _profileImageBytes = null;
        }
      }
      if (_certificationProofFile != null) {
        final url = await uploadFileToSupabaseStorage(
          _certificationProofFile!,
          SupabaseStorageBucket.documents,
        );
        if (url != null && url.isNotEmpty) {
          _certificationProofUrl = url;
          _certificationProofFile = null;
        }
      }
      if (_licenseCopyFile != null) {
        _licenseCopyUrl = await uploadFileToSupabaseStorage(
          _licenseCopyFile!,
          SupabaseStorageBucket.documents,
        );
      }

      final payload = <String, dynamic>{
        'email': emailCtrl.text.trim(),
        'role': 'cpa',
        'first_name': firstNameCtrl.text.trim(),
        'last_name': lastNameCtrl.text.trim(),
        'middle_name': middleNameCtrl.text.trim().isEmpty
            ? null
            : middleNameCtrl.text.trim(),
        'phone_number': phoneCtrl.text.trim().isEmpty
            ? null
            : phoneCtrl.text.trim(),
        if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
          'img_url': _profileImageUrl,

        // CPA-specific fields
        'certifications': selectedCertifications.isNotEmpty
            ? selectedCertifications
            : null,
        'license_number': licenseCtrl.text.trim().isEmpty
            ? null
            : licenseCtrl.text.trim(),
        "career_start_date": startDate?.toIso8601String(),
        'professional_bio': bioCtrl.text.trim().isEmpty
            ? null
            : bioCtrl.text.trim(),
        'specialties': selectedSpecialties.isNotEmpty
            ? selectedSpecialties
            : null,
        'state_focuses': selectedStates.isNotEmpty ? selectedStates : null,
        if (_certificationProofUrl != null &&
            _certificationProofUrl!.isNotEmpty)
          'certification_proof_url': _certificationProofUrl,
        if (_licenseCopyUrl != null && _licenseCopyUrl!.isNotEmpty)
          'license_copy_url': _licenseCopyUrl,
        'terms_agreed': _termsAgreed,
        //TODO: change status to verification_status in db as well, and in profile_screen json
        'verification_status': CpaVerificationStatus
            .pending
            .name, // Set to pending for admin review
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Remove null values from payload
      payload.removeWhere((key, value) => value == null);

      await updateUserProfile(data: payload).then((value) {
        dismissLoadingWidget();
        if (authCpa!.verificationStatus != CpaVerificationStatus.approved) {
          Get.toNamed(Routes.cpaProfileUnderReview);
        }
        showSnackBar('Profile saved successfully');
      });
    } catch (e) {
      dismissLoadingWidget();
      debugPrint('Profile update failed: $e');
      showSnackBar('Failed to save profile: ${e.toString()}');
    }
  }

  void _nextStep() {
    final isValid = _validateStep(_currentStep);

    if (!isValid) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submitProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _submitProfile() async {
    // Validate all steps
    for (int step = 0; step < 3; step++) {
      final valid = _validateStep(step);
      if (!valid) {
        setState(() => _currentStep = step);
        return;
      }
    }

    if (!_termsAgreed) {
      setState(() => _currentStep = 2);
      showSnackBar(
        'Please agree to the terms and conditions',
        title: 'Agreement Required',
      );
      return;
    }

    await _saveToSupabase();
  }

  Widget _buildProfileImageSection() {
    ImageProvider? avatarImage;

    if (_profileImageBytes != null) {
      avatarImage = MemoryImage(_profileImageBytes!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      avatarImage = NetworkImage(_profileImageUrl!);
    } else {
      avatarImage = null;
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickImage(ImageSource.gallery, isProfile: true),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? const Icon(Icons.camera_alt, size: 30)
                : null,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _pickImage(ImageSource.gallery, isProfile: true),
              child: const Text('Upload Profile Picture'),
            ),
            if (avatarImage != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _profileImage = null;
                    _profileImageBytes = null;
                    _profileImageUrl = null;
                  });
                },
                child: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          "Upload Verification Documents",
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 10),
        const AppText(
          "Please upload copies of your certifications and license for verification:",
          fontSize: 14,
        ),
        const SizedBox(height: 20),

        // Certification Proof
        Card(
          child: ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Certification Proof'),
            subtitle: _certificationProofFile != null
                ? Text(path.basename(_certificationProofFile!.path))
                : _certificationProofUrl != null
                ? const Text('Already uploaded')
                : const Text('Upload PDF or image'),
            trailing:
                _certificationProofFile != null ||
                    _certificationProofUrl != null
                ? IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _certificationProofFile = null;
                        _certificationProofUrl = null;
                      });
                    },
                  )
                : null,
            onTap: () => _pickImage(ImageSource.gallery, isProfile: false),
          ),
        ),

        const SizedBox(height: 10),

        // License Copy
        Card(
          child: ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('License Copy'),
            subtitle: _licenseCopyFile != null
                ? Text(path.basename(_licenseCopyFile!.path))
                : _licenseCopyUrl != null
                ? const Text('Already uploaded')
                : const Text('Upload PDF or image'),
            trailing: _licenseCopyFile != null || _licenseCopyUrl != null
                ? IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _licenseCopyFile = null;
                        _licenseCopyUrl = null;
                      });
                    },
                  )
                : null,
            onTap: () => _pickImage(ImageSource.gallery, isProfile: false),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 768;
    final isTablet = width > 600 && width <= 768;

    return Scaffold(
      appBar: AppBar(title: const Text('CPA Profile Setup'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const AppText(
              "Complete your CPA profile to join our network",
              fontSize: 14,
            ),
            const SizedBox(height: 20),

            Stepper(
              currentStep: _currentStep,
              onStepContinue: _nextStep,
              onStepTapped: (value) => setState(() => _currentStep = value),
              onStepCancel: _previousStep,
              controlsBuilder: (context, details) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentStep != 0)
                      OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Back"),
                      ),
                    const SizedBox(width: 10),
                    AppButton(
                      buttonText: (_currentStep == 2
                          ? "Submit for Review"
                          : "Next Step"),
                      onTapFunction: details.onStepContinue!,
                      radius: 8,
                      fontSize: 14,
                    ),
                  ],
                );
              },
              steps: [
                Step(
                  title: const Text("Personal Information"),
                  isActive: _currentStep >= 0,
                  content: Form(
                    key: _personalFormKey,
                    child: Column(
                      children: [
                        _buildProfileImageSection(),
                        const SizedBox(height: 20),

                        if (isDesktop)
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  hintText: "First Name *",
                                  controller: firstNameCtrl,
                                  fieldValidator: (v) =>
                                      v?.isEmpty == true ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: AppTextField(
                                  hintText: "Middle Name",
                                  controller: middleNameCtrl,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: AppTextField(
                                  hintText: "Last Name *",
                                  controller: lastNameCtrl,
                                  fieldValidator: (v) =>
                                      v?.isEmpty == true ? 'Required' : null,
                                ),
                              ),
                            ],
                          )
                        else if (isTablet)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      hintText: "First Name *",
                                      controller: firstNameCtrl,
                                      fieldValidator: (v) => v?.isEmpty == true
                                          ? 'Required'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: AppTextField(
                                      hintText: "Middle Name",
                                      controller: middleNameCtrl,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              AppTextField(
                                hintText: "Last Name *",
                                controller: lastNameCtrl,
                                fieldValidator: (v) =>
                                    v?.isEmpty == true ? 'Required' : null,
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              AppTextField(
                                hintText: "First Name *",
                                controller: firstNameCtrl,
                                fieldValidator: (v) =>
                                    v?.isEmpty == true ? 'Required' : null,
                              ),
                              const SizedBox(height: 15),
                              AppTextField(
                                hintText: "Middle Name",
                                controller: middleNameCtrl,
                              ),
                              const SizedBox(height: 15),
                              AppTextField(
                                hintText: "Last Name *",
                                controller: lastNameCtrl,
                                fieldValidator: (v) =>
                                    v?.isEmpty == true ? 'Required' : null,
                              ),
                            ],
                          ),

                        const SizedBox(height: 15),

                        AppTextField(
                          hintText: "Email *",
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          fieldValidator: (v) =>
                              v?.isNotEmpty == true && v!.contains('@')
                              ? null
                              : 'Valid email required',
                        ),

                        const SizedBox(height: 15),

                        AppTextField(
                          hintText: "Phone Number",
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),

                Step(
                  title: const Text("Professional Details"),
                  isActive: _currentStep >= 1,
                  content: Form(
                    key: _professionalFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText(
                          "Certifications",
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 5),
                        CustomMultiDropDownWidget<String>(
                          dropDownKey: _certificationsKey,
                          showSearchBox: true,
                          hint: "Select Certifications",
                          items: cpaCertificationOptions,
                          selectedItems: selectedCertifications,
                          onChanged: (newList) {
                            setState(() => selectedCertifications = newList);
                          },
                        ),

                        const SizedBox(height: 15),

                        AppTextField(
                          hintText: "License Number *",
                          controller: licenseCtrl,
                          fieldValidator: (v) =>
                              v?.isEmpty == true ? 'Required for CPA' : null,
                        ),
                        const SizedBox(height: 15),

                        InkWell(
                          onTap: () async {
                            await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            ).then((DateTime? pickedDate) async {
                              if (pickedDate != null) {
                                DateTime finalPickedDate = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                );
                                carrerStartDateController.text =
                                    Jiffy.parseFromDateTime(
                                      finalPickedDate,
                                    ).yMMMd;
                                startDate = finalPickedDate;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AbsorbPointer(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: AppTextField(
                                labelText: "Years of Experience *",
                                hintText: "Years of Experience *",
                                controller: carrerStartDateController,
                                fieldValidator: (v) =>
                                    v?.isEmpty == true ? 'Required' : null,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        const AppText(
                          "Professional Bio *",
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 5),
                        AppTextField(
                          labelText: "Professional Bio",
                          hintText:
                              "Tell us about your experience and expertise...",
                          controller: bioCtrl,
                          maxLines: 5,
                          fieldValidator: (v) =>
                              v?.isEmpty == true ? 'Required' : null,
                        ),

                        const SizedBox(height: 15),

                        const AppText(
                          "Specialties",
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 5),
                        CustomMultiDropDownWidget<String>(
                          dropDownKey: _specialtiesKey,
                          showSearchBox: true,
                          hint: "Select Specialties",
                          items: cpaSpecialtyOptions,
                          selectedItems: selectedSpecialties,
                          onChanged: (newList) {
                            setState(() => selectedSpecialties = newList);
                          },
                        ),

                        const SizedBox(height: 10),

                        const AppText(
                          "State Focuses",
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 5),
                        CustomMultiDropDownWidget<String>(
                          dropDownKey: _statesKey,
                          showSearchBox: true,
                          hint: "Select States Where Licensed",
                          items: usStates,
                          selectedItems: selectedStates,
                          onChanged: (newList) {
                            setState(() => selectedStates = newList);
                          },
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),

                Step(
                  title: const Text("Verification & Agreement"),
                  isActive: _currentStep >= 2,
                  content: Form(
                    key: _verificationFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDocumentUploadSection(),

                        const SizedBox(height: 20),

                        const Divider(),

                        const SizedBox(height: 20),

                        CheckboxListTile(
                          title: const Text(
                            "I certify that all information provided is accurate and complete. I agree to the CPA Network Terms of Service and Privacy Policy.",
                            style: TextStyle(fontSize: 14),
                          ),
                          value: _termsAgreed,
                          onChanged: (value) {
                            setState(() {
                              _termsAgreed = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),

                        const SizedBox(height: 30),

                        // Center(
                        //   child: SizedBox(
                        //     width: isDesktop ? 300 : double.infinity,
                        //     child: AppButton(
                        //       buttonText: "Submit Profile for Review",
                        //       onTapFunction: _submitProfile,
                        //       radius: 8,
                        //       fontSize: 16,
                        //       buttonColor: _termsAgreed ? null : Colors.grey,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
