import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/constant/data.dart';
import 'package:booksmart/modules/user/controllers/transaction_controller.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:booksmart/widgets/custom_drop_down.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'business_details_widgets.dart';
import 'tax_screen_2_income_architecture.dart';

void goToTaxScreen1({int? transactionId, int? organizationId}) {
  if (kIsWeb) {
    customDialog(
      child: TaxScreen1LegalIdentity(
        transactionId: transactionId,
        organizationId: organizationId,
      ),
      title: 'Tax Strategy — Step 1 of 8',
      barrierDismissible: false,
    );
  } else {
    Get.to(
      () => TaxScreen1LegalIdentity(
        transactionId: transactionId,
        organizationId: organizationId,
      ),
    );
  }
}

class TaxScreen1LegalIdentity extends StatefulWidget {
  final int? transactionId;
  final int? organizationId;
  const TaxScreen1LegalIdentity({
    super.key,
    this.transactionId,
    this.organizationId,
  });

  @override
  State<TaxScreen1LegalIdentity> createState() =>
      _TaxScreen1LegalIdentityState();
}

class _TaxScreen1LegalIdentityState extends State<TaxScreen1LegalIdentity> {
  final _stateController = TextEditingController();
  final _filingKey = GlobalKey<DropdownSearchState<String>>();
  final _residencyKey = GlobalKey<DropdownSearchState<String>>();

  String? _filingStatus;
  String? _residencyStatus;
  bool? _multiStateActivity;

  Future<void> _saveAndNext() async {
    final data = {
      'filing_status': _filingStatus,
      'primary_state': _stateController.text.trim().isEmpty
          ? null
          : _stateController.text.trim(),
      'residency_status': _residencyStatus,
      'multi_state_activity': _multiStateActivity,
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
      goToTaxScreen2(
        transactionId: widget.transactionId,
        organizationId: widget.organizationId,
      );
    } else {
      Get.off(
        () => TaxScreen2IncomeArchitecture(
          transactionId: widget.transactionId,
          organizationId: widget.organizationId,
        ),
      );
    }
  }

  @override
  void dispose() {
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(title: const Text('Tax Strategy — Step 1 of 8')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TaxProgressBar(current: 1),
          const SizedBox(height: 20),
          TaxSectionTitle(
            icon: Icons.gavel_rounded,
            title: 'Legal & Tax Identity',
            subtitle:
                'Help us understand your legal standing to optimize your strategy.',
          ),
          const SizedBox(height: 24),

          // Filing Status
          AppText('Filing Status', fontSize: 14, fontWeight: FontWeight.w600),
          const SizedBox(height: 8),
          CustomDropDownWidget<String>(
            dropDownKey: _filingKey,
            hint: 'Select filing status',
            items: filingStatusOptions,
            selectedItem: _filingStatus,
            onChanged: (v) => setState(() => _filingStatus = v),
          ),
          const SizedBox(height: 16),

          // Primary State
          AppText('Primary State', fontSize: 14, fontWeight: FontWeight.w600),
          const SizedBox(height: 8),
          AppTextField(
            controller: _stateController,
            hintText: 'e.g. California, Texas',
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          // Residency Status
          AppText(
            'Residency Status',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          CustomDropDownWidget<String>(
            dropDownKey: _residencyKey,
            hint: 'Select residency status',
            items: residencyStatusOptions,
            selectedItem: _residencyStatus,
            onChanged: (v) => setState(() => _residencyStatus = v),
          ),
          const SizedBox(height: 16),

          // Multi-State Activity
          AppText(
            'Multi-State Activity',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 4),
          AppText(
            'Did you work or own property in more than one state?',
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          YesNoToggle(
            value: _multiStateActivity,
            onChanged: (v) => setState(() => _multiStateActivity = v),
          ),
          const SizedBox(height: 32),

          TaxNavButtons(onSkip: _navigateNext, onNext: _saveAndNext),
        ],
      ),
    );
  }
}
