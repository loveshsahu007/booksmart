import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../widgets/custom_drop_down.dart';

void goToAddOrganizationScreen({bool shouldCloseBefore = false}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back(); // close previous dialog
    }
    customDialog(
      child: const AddOrganizationScreen(),
      title: 'Add Organization',
      barrierDismissible: true,
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => const AddOrganizationScreen());
    } else {
      Get.to(() => const AddOrganizationScreen());
    }
  }
}

class AddOrganizationScreen extends StatefulWidget {
  const AddOrganizationScreen({super.key});

  @override
  State<AddOrganizationScreen> createState() => _AddOrganizationScreenState();
}

class _AddOrganizationScreenState extends State<AddOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _organizationNameController = TextEditingController();

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

  final ScrollController _scrollController = ScrollController();

  final stateDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final industryDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final orgDropdownKey = GlobalKey<DropdownSearchState<String>>();

  @override
  void dispose() {
    _scrollController.dispose();
    _organizationNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: kIsWeb ? null : AppBar(),
      body: Scrollbar(
        thumbVisibility: true,
        radius: const Radius.circular(10),
        thickness: 6,
        controller: _scrollController,
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// 🔹 Title
                    AppText(
                      "Set Up Your Organization Profile",
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),

                    0.05.verticalSpace,

                    /// 🔹 Organization Name
                    AppTextField(
                      controller: _organizationNameController,
                      hintText: "Organization Name *",
                      labelText: "Organization Name *",
                      keyboardType: TextInputType.name,
                      maxLines: 1,
                      fieldValidator: (v) => (v == null || v.isEmpty)
                          ? "Enter organization name"
                          : null,
                    ),
                    0.02.verticalSpace,
                    AppTextField(
                      hintText: "Website (URL)",
                      labelText: "Website (URL)",
                      keyboardType: TextInputType.url,
                      maxLines: 1,
                    ),
                    0.02.verticalSpace,
                    AppTextField(
                      hintText: "EIN/TIN (9 digits)",
                      labelText: "EIN/TIN *",
                      keyboardType: TextInputType.number,
                      maxLines: 1,
                      fieldValidator: (v) =>
                          (v == null || v.isEmpty) ? "Enter EIN/TIN" : null,
                    ),
                    0.02.verticalSpace,

                    /// 🔹 Type of Organization
                    _buildFilterDropdown(
                      dropDownKey: orgDropdownKey,
                      label: "Type of Organization *",
                      items: _orgTypes,
                    ),
                    0.02.verticalSpace,

                    _buildFilterDropdown(
                      label: "Industry *",
                      items: _industries,
                      dropDownKey: industryDropdownKey,
                    ),

                    0.02.verticalSpace,

                    /// 🔹 State / Territory
                    _buildFilterDropdown(
                      dropDownKey: stateDropdownKey,
                      label: "State / Territory *",
                      items: _states,
                    ),

                    0.02.verticalSpace,
                    AppTextField(
                      hintText: "Street Address *",
                      labelText: "Street Address *",
                      keyboardType: TextInputType.streetAddress,
                      maxLines: 1,
                      fieldValidator: (v) => null,
                    ),
                    0.02.verticalSpace,
                    AppTextField(
                      hintText: "City *",
                      labelText: "City *",
                      maxLines: 1,
                      keyboardType: TextInputType.text,
                      fieldValidator: (v) => null,
                    ),
                    0.02.verticalSpace,
                    AppTextField(
                      hintText: "ZIP Code*",
                      labelText: "ZIP Code*",
                      maxLines: 1,
                      keyboardType: TextInputType.number,
                      fieldValidator: (v) => null,
                    ),
                    0.02.verticalSpace,
                    AppTextField(
                      controller: _organizationNameController,
                      hintText: "Phone Number",
                      labelText: "Phone Number",
                      keyboardType: TextInputType.phone,
                    ),
                    0.02.verticalSpace,
                    AppTextField(
                      controller: _organizationNameController,
                      hintText: "Business Email",
                      labelText: "Business Email",
                      keyboardType: TextInputType.phone,
                    ),
                    0.06.verticalSpace,

                    /// 🔹 Save & Cancel Buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            buttonText: "Add Organization",
                            fontSize: 16,
                            radius: 8,
                            onTapFunction: _saveOrganization,
                          ),
                        ),
                        0.02.horizontalSpace,
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: scheme.onSurface,
                              side: BorderSide(color: scheme.outline),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                            onPressed: () => Get.back(),
                            child: const Text("Cancel"),
                          ),
                        ),
                      ],
                    ),

                    0.05.verticalSpace,
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
        ),
      ],
    );
  }

  void _saveOrganization() {
    if (_formKey.currentState!.validate()) {
      // Here you would typically save the organization data
      Get.back();
      Get.snackbar(
        "Success",
        "Organization saved successfully",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
