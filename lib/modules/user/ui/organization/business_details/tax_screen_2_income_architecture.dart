import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/constant/data.dart';
import 'package:booksmart/modules/user/controllers/transaction_controller.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:booksmart/widgets/multiple_selection_dropdown_widget.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'business_details_widgets.dart';
import 'tax_screen_3_business_operations.dart';

void goToTaxScreen2({int? transactionId, int? organizationId}) {
  if (kIsWeb) {
    customDialog(
      child: TaxScreen2IncomeArchitecture(
        transactionId: transactionId,
        organizationId: organizationId,
      ),
      title: 'Tax Strategy — Step 2 of 8',
      barrierDismissible: false,
    );
  } else {
    Get.to(
      () => TaxScreen2IncomeArchitecture(
        transactionId: transactionId,
        organizationId: organizationId,
      ),
    );
  }
}

class TaxScreen2IncomeArchitecture extends StatefulWidget {
  final int? transactionId;
  final int? organizationId;
  const TaxScreen2IncomeArchitecture({
    super.key,
    this.transactionId,
    this.organizationId,
  });

  @override
  State<TaxScreen2IncomeArchitecture> createState() =>
      _TaxScreen2IncomeArchitectureState();
}

class _TaxScreen2IncomeArchitectureState
    extends State<TaxScreen2IncomeArchitecture> {
  final _industryController = TextEditingController();
  final _incomeKey = GlobalKey<DropdownSearchState<String>>();
  final _passiveKey = GlobalKey<DropdownSearchState<String>>();

  List<String> _primaryIncomeTypes = [];
  List<String> _passiveIncome = [];

  Future<void> _saveAndNext() async {
    final data = {
      'primary_income_types': _primaryIncomeTypes.isEmpty
          ? null
          : _primaryIncomeTypes,
      'industry_niche': _industryController.text.trim().isEmpty
          ? null
          : _industryController.text.trim(),
      'passive_income': _passiveIncome.isEmpty ? null : _passiveIncome,
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
      goToTaxScreen3(
        transactionId: widget.transactionId,
        organizationId: widget.organizationId,
      );
    } else {
      Get.off(
        () => TaxScreen3BusinessOperations(
          transactionId: widget.transactionId,
          organizationId: widget.organizationId,
        ),
      );
    }
  }

  @override
  void dispose() {
    _industryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(title: const Text('Tax Strategy — Step 2 of 8')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TaxProgressBar(current: 2),
          const SizedBox(height: 20),
          TaxSectionTitle(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Income Streams & Entity Structure',
            subtitle: 'Tell us how you earn to unlock entity-level strategies.',
          ),
          const SizedBox(height: 24),

          AppText(
            'Primary Income Type',
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
            dropDownKey: _incomeKey,
            hint: 'Select income types',
            items: incomeTypeOptions,
            selectedItems: _primaryIncomeTypes,
            onChanged: (v) => setState(() => _primaryIncomeTypes = v),
          ),
          const SizedBox(height: 16),

          AppText(
            'Industry / Niche',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _industryController,
            hintText: 'e.g. Software, Construction, Real Estate',
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          AppText('Passive Income', fontSize: 14, fontWeight: FontWeight.w600),
          const SizedBox(height: 4),
          AppText(
            'Select all that apply',
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          CustomMultiDropDownWidget<String>(
            dropDownKey: _passiveKey,
            hint: 'Select passive income sources',
            items: passiveIncomeOptions,
            selectedItems: _passiveIncome,
            onChanged: (v) => setState(() => _passiveIncome = v),
          ),
          const SizedBox(height: 32),

          TaxNavButtons(onSkip: _navigateNext, onNext: _saveAndNext),
        ],
      ),
    );
  }
}
