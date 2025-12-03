import 'package:booksmart/constant/exports.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:get/get.dart';
import '../../../widgets/multiple_selection_dropdown_widget.dart';

class ProfileScreenCPA extends StatefulWidget {
  const ProfileScreenCPA({super.key});

  @override
  State<ProfileScreenCPA> createState() => _ProfileScreenCPAState();
}

class _ProfileScreenCPAState extends State<ProfileScreenCPA> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController middleNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController certCtrl = TextEditingController();
  final TextEditingController licenseCtrl = TextEditingController();
  final TextEditingController expCtrl = TextEditingController();
  final TextEditingController bioCtrl = TextEditingController();

  final _specialtiesKey = GlobalKey<DropdownSearchState<String>>();
  final _statesKey = GlobalKey<DropdownSearchState<String>>();

  // List to store added certificates
  List<String> certificates = [];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 768;
    final isTablet = width > 600 && width <= 768;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            AppText("Set-up your profile", fontSize: 14),
            Stepper(
              currentStep: _currentStep,
              onStepContinue: _nextStep,
              onStepTapped: (value) {
                setState(() {
                  _currentStep = value;
                });
              },
              onStepCancel: _previousStep,
              controlsBuilder: (context, details) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentStep != 0)
                      OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text("Back"),
                      ),
                    SizedBox(width: 10),
                    _currentStep == 2
                        ? SizedBox()
                        : AppButton(
                            buttonText: _currentStep == 2
                                ? "Create Account"
                                : "Next Step",
                            onTapFunction: details.onStepContinue!,
                            radius: 8,
                            fontSize: 14,
                          ),
                  ],
                );
              },
              steps: [
                Step(
                  title: const AppText(
                    "Personal Information",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  isActive: _currentStep >= 0,
                  content: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade300,
                          child: Icon(Icons.file_upload_outlined),
                        ),
                        SizedBox(height: 15),

                        // Responsive Name Fields
                        if (isDesktop)
                          _buildDesktopNameFields()
                        else if (isTablet)
                          _buildTabletNameFields()
                        else
                          _buildMobileNameFields(),

                        SizedBox(height: 15),
                        AppTextField(
                          hintText: "Certification (e.g. CPA)",
                          controller: certCtrl,
                          suffixWidget: IconButton(
                            onPressed: _addCertificate,
                            icon: Icon(Icons.add),
                          ),
                        ),

                        // Display added certificates
                        if (certificates.isNotEmpty) ...[
                          SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                "Added Certifications:",
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              SizedBox(height: 8),
                              ...certificates.asMap().entries.map((entry) {
                                final index = entry.key;
                                final certificate = entry.value;
                                return _buildCertificateItem(
                                  certificate,
                                  index,
                                );
                              }),
                            ],
                          ),
                        ],

                        SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const AppText(
                    "Professional Details",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  isActive: _currentStep >= 1,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Responsive License and Experience fields
                      if (isDesktop || isTablet)
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                hintText: "License Number",
                                controller: licenseCtrl,
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: AppTextField(
                                hintText: "Years of Experience",
                                controller: expCtrl,
                                textInputAction: TextInputAction.done,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            AppTextField(
                              hintText: "License Number",
                              controller: licenseCtrl,
                            ),
                            SizedBox(height: 15),
                            AppTextField(
                              hintText: "Years of Experience",
                              controller: expCtrl,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),

                      SizedBox(height: 10),
                      const AppText(
                        "Professional Bio",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      SizedBox(height: 5),

                      AppTextField(
                        hintText:
                            "Tell us about your experience and expertise...",
                        controller: bioCtrl,
                        maxLines: 4,
                      ),
                      SizedBox(height: 15),
                      const AppText(
                        "Specialties",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      SizedBox(height: 5),
                      CustomMultiDropDownWidget<String>(
                        dropDownKey: _specialtiesKey,
                        showSearchBox: true,
                        hint: "Select Specialties",
                        items: [
                          "Individual Income Tax",
                          "Small Business Tax",
                          "Corporate Tax",
                          "Partnership & LLC Tax",
                          "Multi-State Taxation",
                          "International Tax",
                          "Trusts & Estates",
                          "Cryptocurrency Taxation",
                          "Sales & Use Tax",
                          "Payroll Tax Compliance",
                          "Tax Strategy & Planning",
                          "Bookkeeping Clean-up",
                        ],
                      ),
                      SizedBox(height: 10),
                      const AppText(
                        "State Focuses",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      SizedBox(height: 5),
                      CustomMultiDropDownWidget<String>(
                        dropDownKey: _statesKey,
                        hint: "Select States",
                        items: ["CA", "NY", "TX"],
                      ),
                      SizedBox(height: 15),
                    ],
                  ),
                ),
                Step(
                  title: const AppText(
                    "Verification & Agreement",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  isActive: _currentStep >= 2,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Material(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: AppColorsLight.divider),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              spacing: 10,
                              children: [
                                Icon(Icons.file_upload_outlined),
                                Expanded(
                                  child: Text(
                                    "Upload Certification Proof or License Copy",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),

                      CheckboxListTile.adaptive(
                        title: Transform.translate(
                          offset: const Offset(-15, 0),
                          child: Text(
                            "By joining BookSmart, I confirm my credentials are accurate and I agree to the CPA Network Terms of Service.",
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                        value: true,
                        onChanged: (_) {},
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,

                        contentPadding: EdgeInsets.only(right: 10),
                      ),
                      SizedBox(height: 25),

                      SizedBox(
                        width: isDesktop ? 200 : double.infinity,
                        child: AppButton(
                          buttonText: "Create Account",
                          onTapFunction: _submitProfile,
                          radius: 8,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 15),
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

  // Desktop: 3 fields in a row
  Widget _buildDesktopNameFields() {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            hintText: "First Name",
            controller: firstNameCtrl,
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: AppTextField(
            hintText: "Middle Name",
            controller: middleNameCtrl,
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: AppTextField(hintText: "Last Name", controller: lastNameCtrl),
        ),
      ],
    );
  }

  // Tablet: 2 fields in first row, 1 field in second row
  Widget _buildTabletNameFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                hintText: "First Name",
                controller: firstNameCtrl,
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: AppTextField(
                hintText: "Middle Name",
                controller: middleNameCtrl,
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        AppTextField(hintText: "Last Name", controller: lastNameCtrl),
      ],
    );
  }

  // Mobile: All fields in column
  Widget _buildMobileNameFields() {
    return Column(
      children: [
        AppTextField(hintText: "First Name", controller: firstNameCtrl),
        SizedBox(height: 15),
        AppTextField(hintText: "Middle Name", controller: middleNameCtrl),
        SizedBox(height: 15),
        AppTextField(hintText: "Last Name", controller: lastNameCtrl),
      ],
    );
  }

  // Function to add certificate
  void _addCertificate() {
    if (certCtrl.text.trim().isNotEmpty) {
      setState(() {
        certificates.add(certCtrl.text.trim());
        certCtrl.clear(); // Clear the text field
      });
    }
  }

  // Function to remove certificate
  void _removeCertificate(int index) {
    setState(() {
      certificates.removeAt(index);
    });
  }

  // Widget to display certificate item
  Widget _buildCertificateItem(String certificate, int index) {
    return Card(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.card_membership, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: AppText(
                certificate,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              onPressed: () => _removeCertificate(index),
              icon: Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ),
      ),
    );
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

  void _submitProfile() {
    Get.offAllNamed(Routes.profileUnderReviewCPA);
  }
}
