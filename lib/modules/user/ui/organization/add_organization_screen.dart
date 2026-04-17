import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/common/controllers/auth_controller.dart';
import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'package:booksmart/models/organization_model.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../widgets/custom_drop_down.dart';
import '../transaction/tax_onboarding/tax_screen_1_legal_identity.dart';

void goToAddOrganizationScreen({
  bool shouldCloseBefore = false,
  OrganizationModel? organization,
}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back();
    }
    customDialog(
      child: AddOrganizationScreen(organization: organization),
      title: organization != null ? 'Edit Organization' : 'Add Organization',
      barrierDismissible: true,
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => AddOrganizationScreen(organization: organization));
    } else {
      Get.to(() => AddOrganizationScreen(organization: organization));
    }
  }
}

class AddOrganizationScreen extends StatefulWidget {
  final OrganizationModel? organization;
  const AddOrganizationScreen({super.key, this.organization});

  @override
  State<AddOrganizationScreen> createState() => _AddOrganizationScreenState();
}

class _AddOrganizationScreenState extends State<AddOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Controller
  final OrganizationController controller = Get.find<OrganizationController>();

  /// Text Controllers
  final nameController = TextEditingController();
  final websiteController = TextEditingController();
  final einController = TextEditingController();
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final zipController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  /// Dropdowns
  final stateDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final industryDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final orgDropdownKey = GlobalKey<DropdownSearchState<String>>();

  final List<String> _orgTypes = [
    'Sole Proprietorship',
    'Partnership',
    'Limited Liability Company (LLC)',
    'C-Corporation',
    'S-Corporation',
    'Nonprofit',
  ];

  final List<String> _industries = [
    'Agency or Sales House',
    'Agriculture',
    'Art and Design',
    'Automotive',
    'Construction',
    'Consulting',
    'Consumer Packaged Goods',
    'Education',
    'Engineering',
    'Entertainment',
    'Financial Services',
    'Food Services (Restaurants/Fast Food)',
    'Gaming',
    'Gigs',
    'Government',
    'Health Care',
    'Interior Design',
    'Internal',
    'Legal',
    'Manufacturing',
    'Marketing',
    'Mining and Logistics',
    'Non-Profit',
    'Publishing and Web Media',
    'Real Estate',
    'Retail (E-Commerce and Offline)',
    'Rideshare',
    'Services',
    'Technology',
    'Telecommunications',
    'Travel/Hospitality',
    'Venture Capital/Private Equity',
    'Web Designing',
    'Web Development',
    'Writers',
  ];

  final List<String> _states = DropdownData.stateOptions
      .map((e) => e['label'] as String)
      .toList();

  @override
  void initState() {
    super.initState();
    if (widget.organization != null) {
      nameController.text = widget.organization!.name;
      websiteController.text = widget.organization!.website ?? '';
      einController.text = widget.organization!.einTin;
      streetController.text = widget.organization!.street;
      cityController.text = widget.organization!.city;
      zipController.text = widget.organization!.zip;
      phoneController.text = widget.organization!.phone ?? '';
      emailController.text = widget.organization!.email ?? '';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    nameController.dispose();
    websiteController.dispose();
    einController.dispose();
    streetController.dispose();
    cityController.dispose();
    zipController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: kIsWeb ? null : AppBar(),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        thickness: 6,
        radius: const Radius.circular(10),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppText(
                      "Set Up Your Organization Profile",
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),
                    0.05.verticalSpace,

                    AppTextField(
                      controller: nameController,
                      labelText: "Organization Name *",
                      hintText: "Organization Name *",
                      fieldValidator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                    0.02.verticalSpace,

                    AppTextField(
                      controller: websiteController,
                      labelText: "Website",
                      hintText: "Website",
                    ),
                    0.02.verticalSpace,

                    AppTextField(
                      controller: einController,
                      labelText: "EIN/TIN *",
                      hintText: "EIN/TIN *",
                      keyboardType: TextInputType.number,
                      fieldValidator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                    0.02.verticalSpace,

                    _buildFilterDropdown(
                      label: "Type of Organization *",
                      items: _orgTypes,
                      dropDownKey: orgDropdownKey,
                      selectedItem: widget.organization?.orgType,
                    ),
                    0.02.verticalSpace,

                    _buildFilterDropdown(
                      label: "Industry *",
                      items: _industries,
                      dropDownKey: industryDropdownKey,
                      selectedItem: widget.organization?.industry,
                    ),
                    0.02.verticalSpace,

                    _buildFilterDropdown(
                      label: "State / Territory *",
                      items: _states,
                      dropDownKey: stateDropdownKey,
                      selectedItem: widget.organization?.state,
                    ),
                    0.02.verticalSpace,

                    AppTextField(
                      controller: streetController,
                      labelText: "Street Address",
                      hintText: "Street Address",
                    ),
                    0.02.verticalSpace,

                    AppTextField(
                      controller: cityController,
                      labelText: "City",
                      hintText: "City",
                    ),
                    0.02.verticalSpace,

                    AppTextField(
                      controller: zipController,
                      labelText: "ZIP Code",
                      hintText: "ZIP Code",
                    ),
                    0.02.verticalSpace,

                    AppTextField(
                      controller: phoneController,
                      labelText: "Phone Number",
                      hintText: "Phone Number",
                    ),
                    0.02.verticalSpace,

                    AppTextField(
                      controller: emailController,
                      labelText: "Business Email",
                      hintText: "Business Email",
                    ),
                    0.06.verticalSpace,

                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            buttonText: widget.organization != null
                                ? "Update Organization"
                                : "Add Organization",
                            onTapFunction: _saveOrganization,
                          ),
                        ),
                        0.02.horizontalSpace,
                        Expanded(
                          child: OutlinedButton(
                            onPressed: Get.back,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: scheme.outline),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required List<String> items,
    required GlobalKey<DropdownSearchState<String>> dropDownKey,
    String? selectedItem,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, fontWeight: FontWeight.w600),
        const SizedBox(height: 8),
        CustomDropDownWidget<String>(
          dropDownKey: dropDownKey,
          label: label,
          hint: "Select $label",
          items: items,
          selectedItem: selectedItem,
        ),
      ],
    );
  }

  Future<void> _saveOrganization() async {
    if (!_formKey.currentState!.validate()) return;

    final orgType = orgDropdownKey.currentState?.getSelectedItem;
    final industry = industryDropdownKey.currentState?.getSelectedItem;
    final state = stateDropdownKey.currentState?.getSelectedItem;

    if (orgType == null || industry == null || state == null) {
      showSnackBar("Please select all required dropdowns", isError: true);
      return;
    }

    final model = OrganizationModel(
      id: widget.organization?.id ?? 0,
      name: nameController.text.trim(),
      website: websiteController.text.trim(),
      einTin: einController.text.trim(),
      orgType: orgType,
      industry: industry,
      state: state,
      street: streetController.text.trim(),
      city: cityController.text.trim(),
      zip: zipController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
      ownerId: authPerson!.id,
    );

    if (widget.organization != null) {
      await controller.updateOrganization(id: model.id, data: model.toJson());
      // Navigate to onboarding after update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        goToTaxScreen1(organizationId: model.id);
      });
    } else {
      final newId = await controller.addOrganizationAndReturnId(model);
      if (newId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          goToTaxScreen1(organizationId: newId);
        });
      }
    }
  }
}
