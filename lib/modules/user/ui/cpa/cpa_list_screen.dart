import 'dart:developer';

import 'package:booksmart/widgets/app_text.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/custom_dialog.dart';
import '../../../../widgets/custom_drop_down.dart';
import 'components/cpa_card.dart';

void goToCpaListScreen({bool shouldCloseBefore = false}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back(); // close previous dialog
    }
    customDialog(
      child: const CpaListScreen(),
      title: 'CPA List',
      barrierDismissible: true,
      maxWidth: 800,
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => const CpaListScreen());
    } else {
      Get.to(() => const CpaListScreen());
    }
  }
}

class CpaListScreen extends StatefulWidget {
  const CpaListScreen({super.key});

  @override
  State<CpaListScreen> createState() => _CpaListScreenState();
}

class _CpaListScreenState extends State<CpaListScreen> {
  final stateDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final specialityDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final ratingDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final experienceDropdownKey = GlobalKey<DropdownSearchState<String>>();

  final pricingDropdownKey = GlobalKey<DropdownSearchState<String>>();

  void clearFilters() {
    stateDropdownKey.currentState?.clear();
    specialityDropdownKey.currentState?.clear();
    ratingDropdownKey.currentState?.clear();
    experienceDropdownKey.currentState?.clear();
    pricingDropdownKey.currentState?.clear();
  }

  Future<void> _showFilterDialog() async {
    await customDialog(
      title: "Filter CPAs",
      child: ListView(
        padding: EdgeInsets.all(15),
        shrinkWrap: true,
        children: [
          // State Filter
          _buildFilterDropdown(
            label: "State",
            items: ['CA', 'NY', 'TX', 'FL', 'IL'],

            dropDownKey: stateDropdownKey,
          ),
          const SizedBox(height: 16),

          // Specialty Filter
          _buildFilterDropdown(
            label: "Specialty",
            items: [
              'Tax Strategy',
              'Tax Deductions',
              'Business Taxation',
              'Small Business',
              'IRS Audit',
              'Tax Planning',
              'Corporate Tax',
              'International Tax',
              'Estate Planning',
            ],
            dropDownKey: specialityDropdownKey,
          ),
          const SizedBox(height: 16),

          // Rating Filter
          _buildFilterDropdown(
            label: "Rating",
            items: ['4.5+', '4.0+', '3.5+'],
            dropDownKey: ratingDropdownKey,
          ),
          const SizedBox(height: 16),

          // Experience Filter
          _buildFilterDropdown(
            label: "Experience",
            items: ['10+ years', '5+ years', '3+ years'],
            dropDownKey: experienceDropdownKey,
          ),
          const SizedBox(height: 16),

          // Pricing Filter
          _buildFilterDropdown(
            label: "Pricing",
            items: ['Budget', 'Moderate', 'Premium'],
            dropDownKey: pricingDropdownKey,
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  clearFilters();
                  Get.back();
                },
                child: AppText("Reset", color: Colors.red, fontSize: 14),
              ),
              SizedBox(width: 10),
              TextButton(
                onPressed: () => Get.back(),
                child: AppText("Apply", fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    ).then((value) {
      setState(() {});
    });
  }

  Widget _buildFilterDropdown({
    required String label,
    required List<String> items,
    required GlobalKey<DropdownSearchState<String>> dropDownKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, fontWeight: FontWeight.w600, fontSize: 14),
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

  bool get isAnyActiveFilter =>
      stateDropdownKey.currentState?.getSelectedItem != null ||
      specialityDropdownKey.currentState?.getSelectedItem != null ||
      ratingDropdownKey.currentState?.getSelectedItem != null ||
      experienceDropdownKey.currentState?.getSelectedItem != null ||
      pricingDropdownKey.currentState?.getSelectedItem != null;

  Widget _buildActiveFilters() {
    log("isAnyActiveFilter: $isAnyActiveFilter");
    if (!isAnyActiveFilter) return const SizedBox();

    final List<GlobalKey<DropdownSearchState<String>>> activeFiltersKeys = [
      if (stateDropdownKey.currentState?.getSelectedItem != null)
        stateDropdownKey,
      if (specialityDropdownKey.currentState?.getSelectedItem != null)
        specialityDropdownKey,
      if (ratingDropdownKey.currentState?.getSelectedItem != null)
        ratingDropdownKey,
      if (experienceDropdownKey.currentState?.getSelectedItem != null)
        experienceDropdownKey,
      if (pricingDropdownKey.currentState?.getSelectedItem != null)
        pricingDropdownKey,
    ];

    log("activeFiltersKeys: $activeFiltersKeys");

    return StatefulBuilder(
      builder: (context, innerState) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          width: double.infinity,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activeFiltersKeys.map((filterKey) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Get.theme.colorScheme.primary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      filterKey.currentState?.getSelectedItem ?? "---",
                      fontSize: 12,
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        filterKey.currentState?.clear();
                        // need to handle it seperately
                      },
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Get.theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("CPAs")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      "Top CPA Matches",
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      isAnyActiveFilter
                          ? "Showing ${1} of ${5} verified CPAs that fit your preferences."
                          : "We found ${5} verified CPAs that fit your preferences.",
                      fontSize: 12,
                    ),
                  ],
                ),
                IconButton(
                  icon: Badge(
                    isLabelVisible: isAnyActiveFilter,
                    child: Icon(Icons.filter_list),
                  ),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ),
          _buildActiveFilters(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return CpaCard();
              },
            ),
          ),
        ],
      ),
    );
  }
}
