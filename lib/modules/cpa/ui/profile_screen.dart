import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/controllers/user_controller.dart';
import 'package:booksmart/models/user_data_model.dart';
import 'package:booksmart/modules/common/providers/supabase_crud.dart';
import 'package:booksmart/widgets/multiple_selection_dropdown_widget.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class ProfileScreenCPA extends StatefulWidget {
  const ProfileScreenCPA({super.key});

  @override
  State<ProfileScreenCPA> createState() => _ProfileScreenCPAState();
}

class _ProfileScreenCPAState extends State<ProfileScreenCPA> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController middleNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController certCtrl = TextEditingController();
  final TextEditingController licenseCtrl = TextEditingController();
  final TextEditingController expCtrl = TextEditingController();
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
  XFile? _profileImage;
  XFile? _certificationProofFile;
  XFile? _licenseCopyFile;
  String? _profileImageUrl;
  String? _certificationProofUrl;
  String? _licenseCopyUrl;

  bool _loading = false;
  bool _initialLoading = true;
  bool _termsAgreed = false;
  final _crud = SupabaseCrudService();
  final _supabase = Supabase.instance.client;

  // List of US states for dropdown
  final List<String> usStates = [
    'AL',
    'AK',
    'AZ',
    'AR',
    'CA',
    'CO',
    'CT',
    'DE',
    'FL',
    'GA',
    'HI',
    'ID',
    'IL',
    'IN',
    'IA',
    'KS',
    'KY',
    'LA',
    'ME',
    'MD',
    'MA',
    'MI',
    'MN',
    'MS',
    'MO',
    'MT',
    'NE',
    'NV',
    'NH',
    'NJ',
    'NM',
    'NY',
    'NC',
    'ND',
    'OH',
    'OK',
    'OR',
    'PA',
    'RI',
    'SC',
    'SD',
    'TN',
    'TX',
    'UT',
    'VT',
    'VA',
    'WA',
    'WV',
    'WI',
    'WY',
  ];

  // Certification options
  final List<String> certificationOptions = [
    'CPA',
    'EA',
    'CFP',
    'CMA',
    'CIA',
    'CGMA',
    'ChFC',
    'PFS',
    'Other',
  ];

  // Specialty options
  final List<String> specialtyOptions = [
    'Individual Income Tax',
    'Small Business Tax',
    'Corporate Tax',
    'Partnership & LLC Tax',
    'Multi-State Taxation',
    'International Tax',
    'Trusts & Estates',
    'Cryptocurrency Taxation',
    'Sales & Use Tax',
    'Payroll Tax Compliance',
    'Tax Strategy & Planning',
    'Bookkeeping Clean-up',
    'Audit & Assurance',
    'Financial Planning',
    'Estate Planning',
    'Business Valuation',
    'IRS Representation',
    'Non-Profit Accounting',
  ];

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
    expCtrl.dispose();
    bioCtrl.dispose();
    super.dispose();
  }

  String? get _currentAuthId => _supabase.auth.currentUser?.id;
  String? get _currentUserEmail => _supabase.auth.currentUser?.email;

  Future<void> _loadProfile() async {
    setState(() => _initialLoading = true);

    final authId = _currentAuthId;
    if (authId == null) {
      setState(() => _initialLoading = false);
      Get.snackbar(
        'Not signed in',
        'Please sign in to edit your profile.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final res = await _crud.read(
        table: 'users',
        filters: {'auth_id': authId},
        single: true,
      );

      if (res != null) {
        final Map<String, dynamic> row = res is Map<String, dynamic>
            ? res
            : (res is List && res.isNotEmpty
                  ? res.first as Map<String, dynamic>
                  : {});

        // Basic info
        firstNameCtrl.text = (row['first_name'] ?? '') as String;
        lastNameCtrl.text = (row['last_name'] ?? '') as String;
        middleNameCtrl.text = (row['middle_name'] ?? '') as String;
        emailCtrl.text = (row['email'] ?? _currentUserEmail ?? '') as String;
        phoneCtrl.text = (row['phone_number'] ?? '') as String;
        _profileImageUrl = row['img_url'] as String?;

        // CPA fields
        licenseCtrl.text = (row['license_number'] ?? '') as String;
        expCtrl.text = (row['years_of_experience']?.toString() ?? '');
        bioCtrl.text = (row['professional_bio'] ?? '') as String;

        // Arrays (handle both List and JSON string)
        selectedCertifications = _parseArrayField(row['certifications']);
        selectedSpecialties = _parseArrayField(row['specialties']);
        selectedStates = _parseArrayField(row['state_focuses']);

        // Files
        _certificationProofUrl = row['certification_proof_url'] as String?;
        _licenseCopyUrl = row['license_copy_url'] as String?;

        // Booleans
        _termsAgreed = (row['terms_agreed'] ?? false) as bool;

        // Update UserController
        final userCtrl = Get.find<UserController>();
        if (userCtrl.hasUser) {
          final updatedUser = userCtrl.user.value!.copyWith(
            firstName: firstNameCtrl.text,
            lastName: lastNameCtrl.text,
            email: emailCtrl.text,
            phoneNumber: phoneCtrl.text,
            imgUrl: _profileImageUrl,
            middleName: middleNameCtrl.text,
            certifications: selectedCertifications,
            licenseNumber: licenseCtrl.text,
            yearsOfExperience: int.tryParse(expCtrl.text),
            professionalBio: bioCtrl.text,
            specialties: selectedSpecialties,
            stateFocuses: selectedStates,
            certificationProofUrl: _certificationProofUrl,
            licenseCopyUrl: _licenseCopyUrl,
            termsAgreed: _termsAgreed,
            status: (row['status'] ?? 'pending') as String,
            role: (row['role'] ?? 'cpa') as String,
          );
          userCtrl.user.value = updatedUser;
        }
      } else {
        // New user - set email if available
        emailCtrl.text = _currentUserEmail ?? '';
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      Get.snackbar(
        'Error',
        'Failed to load profile data',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _initialLoading = false);
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

  // FIXED: Proper file upload method for Supabase with Uint8List
  Future<String?> _uploadFile(XFile file, String bucketName) async {
    try {
      final fileBytes = await file.readAsBytes();
      final fileName =
          '${_currentAuthId}_${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';

      // Upload binary data (Uint8List)
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _getMimeType(file.path),
            ),
          );

      // Get public URL
      final url = _supabase.storage.from(bucketName).getPublicUrl(fileName);
      return url;
    } catch (e) {
      debugPrint('File upload failed: $e');
      Get.snackbar(
        'Upload Error',
        'Failed to upload file: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  // Helper to get MIME type from file extension
  String _getMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _pickImage(ImageSource source, {bool isProfile = true}) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if (isProfile) {
            _profileImage = pickedFile;
          } else if (_currentStep == 2) {
            // Determine which document to upload based on context
            if (_certificationProofFile == null) {
              _certificationProofFile = pickedFile;
            } else {
              _licenseCopyFile = pickedFile;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    }
  }

  Future<void> _saveToSupabase() async {
    final authId = _currentAuthId;
    if (authId == null) {
      Get.snackbar(
        'Not signed in',
        'Please sign in to update profile.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Upload files if they exist
      if (_profileImage != null) {
        _profileImageUrl = await _uploadFile(_profileImage!, 'profile-images');
      }
      if (_certificationProofFile != null) {
        _certificationProofUrl = await _uploadFile(
          _certificationProofFile!,
          'documents',
        );
      }
      if (_licenseCopyFile != null) {
        _licenseCopyUrl = await _uploadFile(_licenseCopyFile!, 'documents');
      }

      // Prepare payload
      final payload = <String, dynamic>{
        'auth_id': authId,
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
        'years_of_experience': expCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(expCtrl.text.trim()),
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
        'status': 'pending', // Set to pending for admin review
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Remove null values from payload
      payload.removeWhere((key, value) => value == null);

      // Update existing user
      await _crud.update(
        table: 'users',
        data: payload,
        filters: {'auth_id': authId},
      );

      // Update UserController
      final userCtrl = Get.find<UserController>();
      if (userCtrl.hasUser) {
        final updatedUser = userCtrl.user.value!.copyWith(
          authId: authId,
          email: emailCtrl.text.trim(),
          role: 'cpa',
          firstName: firstNameCtrl.text.trim(),
          lastName: lastNameCtrl.text.trim(),
          middleName: middleNameCtrl.text.trim().isEmpty
              ? null
              : middleNameCtrl.text.trim(),
          phoneNumber: phoneCtrl.text.trim().isEmpty
              ? null
              : phoneCtrl.text.trim(),
          imgUrl: _profileImageUrl,
          certifications: selectedCertifications,
          licenseNumber: licenseCtrl.text.trim().isEmpty
              ? null
              : licenseCtrl.text.trim(),
          yearsOfExperience: expCtrl.text.trim().isEmpty
              ? null
              : int.tryParse(expCtrl.text.trim()),
          professionalBio: bioCtrl.text.trim().isEmpty
              ? null
              : bioCtrl.text.trim(),
          specialties: selectedSpecialties,
          stateFocuses: selectedStates,
          certificationProofUrl: _certificationProofUrl,
          licenseCopyUrl: _licenseCopyUrl,
          termsAgreed: _termsAgreed,
          status: 'pending',
          updatedAt: DateTime.now(),
        );
        userCtrl.user.value = updatedUser;
      } else {
        // Create new user in controller
        final newUser = UserModel(
          authId: authId,
          email: emailCtrl.text.trim(),
          role: 'cpa',
          firstName: firstNameCtrl.text.trim(),
          lastName: lastNameCtrl.text.trim(),
          middleName: middleNameCtrl.text.trim().isEmpty
              ? null
              : middleNameCtrl.text.trim(),
          phoneNumber: phoneCtrl.text.trim().isEmpty
              ? null
              : phoneCtrl.text.trim(),
          imgUrl: _profileImageUrl,
          certifications: selectedCertifications,
          licenseNumber: licenseCtrl.text.trim().isEmpty
              ? null
              : licenseCtrl.text.trim(),
          yearsOfExperience: expCtrl.text.trim().isEmpty
              ? null
              : int.tryParse(expCtrl.text.trim()),
          professionalBio: bioCtrl.text.trim().isEmpty
              ? null
              : bioCtrl.text.trim(),
          specialties: selectedSpecialties,
          stateFocuses: selectedStates,
          certificationProofUrl: _certificationProofUrl,
          licenseCopyUrl: _licenseCopyUrl,
          termsAgreed: _termsAgreed,
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        userCtrl.user.value = newUser;
      }

      debugPrint('Successfully saved CPA profile to Supabase');
      Get.snackbar(
        'Success',
        'Profile saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Profile update failed: $e');
      Get.snackbar(
        'Error',
        'Failed to save profile: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      setState(() => _loading = false);
    }
  }

  void _nextStep() {
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
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAgreed) {
      Get.snackbar(
        'Agreement Required',
        'Please agree to the terms and conditions',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      await _saveToSupabase();
      Get.offAllNamed(Routes.profileUnderReviewCPA);
    } catch (e) {
      debugPrint('Profile submission failed: $e');
    }
  }

  // FIXED: Profile image section - The key fix is here
  Widget _buildProfileImageSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickImage(ImageSource.gallery, isProfile: true),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            // FIX: Convert XFile to File for FileImage
            backgroundImage: _profileImage != null
                ? FileImage(File(_profileImage!.path))
                : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? NetworkImage(_profileImageUrl!) as ImageProvider
                      : null),
            child:
                _profileImage == null &&
                    (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                ? const Icon(Icons.camera_alt, size: 30)
                : null,
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => _pickImage(ImageSource.gallery, isProfile: true),
          child: const Text('Upload Profile Picture'),
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
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    onStepTapped: (value) =>
                        setState(() => _currentStep = value),
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
                            buttonText: _loading
                                ? "Saving..."
                                : (_currentStep == 2
                                      ? "Submit for Review"
                                      : "Next Step"),
                            onTapFunction: _loading
                                ? null
                                : details.onStepContinue!,
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
                          key: _formKey,
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
                                            v?.isEmpty == true
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
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: AppTextField(
                                        hintText: "Last Name *",
                                        controller: lastNameCtrl,
                                        fieldValidator: (v) =>
                                            v?.isEmpty == true
                                            ? 'Required'
                                            : null,
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
                                            fieldValidator: (v) =>
                                                v?.isEmpty == true
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
                                      fieldValidator: (v) => v?.isEmpty == true
                                          ? 'Required'
                                          : null,
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    AppTextField(
                                      hintText: "First Name *",
                                      controller: firstNameCtrl,
                                      fieldValidator: (v) => v?.isEmpty == true
                                          ? 'Required'
                                          : null,
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
                                      fieldValidator: (v) => v?.isEmpty == true
                                          ? 'Required'
                                          : null,
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
                            ],
                          ),
                        ),
                      ),

                      Step(
                        title: const Text("Professional Details"),
                        isActive: _currentStep >= 1,
                        content: Column(
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
                              items: certificationOptions,
                              selectedItems: selectedCertifications,
                            ),

                            const SizedBox(height: 15),

                            if (isDesktop || isTablet)
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      hintText: "License Number *",
                                      controller: licenseCtrl,
                                      fieldValidator: (v) => v?.isEmpty == true
                                          ? 'Required for CPA'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: AppTextField(
                                      hintText: "Years of Experience *",
                                      controller: expCtrl,
                                      keyboardType: TextInputType.number,
                                      fieldValidator: (v) => v?.isEmpty == true
                                          ? 'Required'
                                          : null,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  AppTextField(
                                    hintText: "License Number *",
                                    controller: licenseCtrl,
                                    fieldValidator: (v) => v?.isEmpty == true
                                        ? 'Required for CPA'
                                        : null,
                                  ),
                                  const SizedBox(height: 15),
                                  AppTextField(
                                    hintText: "Years of Experience *",
                                    controller: expCtrl,
                                    keyboardType: TextInputType.number,
                                    fieldValidator: (v) =>
                                        v?.isEmpty == true ? 'Required' : null,
                                  ),
                                ],
                              ),

                            const SizedBox(height: 15),

                            const AppText(
                              "Professional Bio *",
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            const SizedBox(height: 5),
                            AppTextField(
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
                              items: specialtyOptions,
                              selectedItems: selectedSpecialties,
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
                            ),
                          ],
                        ),
                      ),

                      Step(
                        title: const Text("Verification & Agreement"),
                        isActive: _currentStep >= 2,
                        content: Column(
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

                            Center(
                              child: SizedBox(
                                width: isDesktop ? 300 : double.infinity,
                                child: AppButton(
                                  buttonText: _loading
                                      ? "Submitting..."
                                      : "Submit Profile for Review",
                                  onTapFunction: _loading
                                      ? null
                                      : _submitProfile,
                                  radius: 8,
                                  fontSize: 16,
                                  buttonColor: _termsAgreed
                                      ? null
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
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
