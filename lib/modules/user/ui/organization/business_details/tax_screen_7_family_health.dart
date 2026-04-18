import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/constant/data.dart';
import 'package:booksmart/modules/user/controllers/transaction_controller.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:booksmart/widgets/custom_drop_down.dart';
import 'package:booksmart/widgets/multiple_selection_dropdown_widget.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'business_details_widgets.dart';
import 'tax_screen_8_future_goals.dart';

void goToTaxScreen7({int? transactionId, int? organizationId}) {
  if (kIsWeb) {
    customDialog(
      child: TaxScreen7FamilyHealth(
        transactionId: transactionId,
        organizationId: organizationId,
      ),
      title: 'Tax Strategy — Step 7 of 8',
      barrierDismissible: false,
    );
  } else {
    Get.to(
      () => TaxScreen7FamilyHealth(
        transactionId: transactionId,
        organizationId: organizationId,
      ),
    );
  }
}

class TaxScreen7FamilyHealth extends StatefulWidget {
  final int? transactionId;
  final int? organizationId;
  const TaxScreen7FamilyHealth({
    super.key,
    this.transactionId,
    this.organizationId,
  });

  @override
  State<TaxScreen7FamilyHealth> createState() => _TaxScreen7FamilyHealthState();
}

class _TaxScreen7FamilyHealthState extends State<TaxScreen7FamilyHealth> {
  final _insuranceKey = GlobalKey<DropdownSearchState<String>>();
  final _savingsKey = GlobalKey<DropdownSearchState<String>>();
  final _educationKey = GlobalKey<DropdownSearchState<String>>();

  String? _healthInsurance;
  List<String> _healthSavings = [];
  List<String> _familyEducation = [];

  Future<void> _saveAndNext() async {
    final data = {
      'health_insurance': _healthInsurance,
      'health_savings': _healthSavings.isEmpty ? null : _healthSavings,
      'family_education': _familyEducation.isEmpty ? null : _familyEducation,
    };

    if (widget.transactionId != null) {
      await transactionControllerInstance.updateTaxProfile(
        transactionId: widget.transactionId!,
        data: data,
      );
    } else if (widget.organizationId != null) {
      await organizationControllerInstance.updateTaxProfile(
        organizationId: widget.organizationId!,
        data: data,
      );
    }

    _navigateNext();
  }

  void _navigateNext() {
    if (kIsWeb) {
      Get.back();
      goToTaxScreen8(
        transactionId: widget.transactionId,
        organizationId: widget.organizationId,
      );
    } else {
      Get.off(
        () => TaxScreen8FutureGoals(
          transactionId: widget.transactionId,
          organizationId: widget.organizationId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(title: const Text('Tax Strategy — Step 7 of 8')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TaxProgressBar(current: 7),
          const SizedBox(height: 20),
          TaxSectionTitle(
            icon: Icons.favorite_rounded,
            title: 'Household & Benefits',
            subtitle:
                'Health and family expenses often hide significant tax opportunities.',
          ),
          const SizedBox(height: 24),

          AppText(
            'Health Insurance Type',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          CustomDropDownWidget<String>(
            dropDownKey: _insuranceKey,
            hint: 'Select health insurance type',
            items: healthInsuranceOptions,
            selectedItem: _healthInsurance,
            onChanged: (v) => setState(() => _healthInsurance = v),
          ),
          const SizedBox(height: 16),

          AppText('Health Savings', fontSize: 14, fontWeight: FontWeight.w600),
          const SizedBox(height: 4),
          AppText(
            'Select all that apply',
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          CustomMultiDropDownWidget<String>(
            dropDownKey: _savingsKey,
            hint: 'Select health savings accounts',
            items: healthSavingsOptions,
            selectedItems: _healthSavings,
            onChanged: (v) => setState(() => _healthSavings = v),
          ),
          const SizedBox(height: 16),

          AppText(
            'Education & Family',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 4),
          AppText(
            'Select all that apply',
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          CustomMultiDropDownWidget<String>(
            dropDownKey: _educationKey,
            hint: 'Select education & family expenses',
            items: familyEducationOptions,
            selectedItems: _familyEducation,
            onChanged: (v) => setState(() => _familyEducation = v),
          ),
          const SizedBox(height: 32),

          TaxNavButtons(onSkip: _navigateNext, onNext: _saveAndNext),
        ],
      ),
    );
  }
}
