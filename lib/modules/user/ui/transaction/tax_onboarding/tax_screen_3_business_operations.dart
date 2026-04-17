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
import 'tax_onboarding_widgets.dart';
import 'tax_screen_4_vehicle.dart';

void goToTaxScreen3({int? transactionId, int? organizationId}) {
  if (kIsWeb) {
    customDialog(
      child: TaxScreen3BusinessOperations(
        transactionId: transactionId,
        organizationId: organizationId,
      ),
      title: 'Tax Strategy — Step 3 of 8',
      barrierDismissible: false,
    );
  } else {
    Get.to(
      () => TaxScreen3BusinessOperations(
        transactionId: transactionId,
        organizationId: organizationId,
      ),
    );
  }
}

class TaxScreen3BusinessOperations extends StatefulWidget {
  final int? transactionId;
  final int? organizationId;
  const TaxScreen3BusinessOperations({
    super.key,
    this.transactionId,
    this.organizationId,
  });

  @override
  State<TaxScreen3BusinessOperations> createState() =>
      _TaxScreen3BusinessOperationsState();
}

class _TaxScreen3BusinessOperationsState
    extends State<TaxScreen3BusinessOperations> {
  final _teamKey = GlobalKey<DropdownSearchState<String>>();
  final _methodKey = GlobalKey<DropdownSearchState<String>>();

  List<String> _teamStructure = [];
  String? _accountingMethod;
  bool? _majorEquipment;

  Future<void> _saveAndNext() async {
    final data = {
      'team_structure': _teamStructure.isEmpty ? null : _teamStructure,
      'accounting_method': _accountingMethod,
      'major_equipment': _majorEquipment,
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
      goToTaxScreen4(
        transactionId: widget.transactionId,
        organizationId: widget.organizationId,
      );
    } else {
      Get.off(() => TaxScreen4Vehicle(
            transactionId: widget.transactionId,
            organizationId: widget.organizationId,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(title: const Text('Tax Strategy — Step 3 of 8')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TaxProgressBar(current: 3),
          const SizedBox(height: 20),
          TaxSectionTitle(
            icon: Icons.business_center_rounded,
            title: 'Operational Footprint',
            subtitle:
                'Audit-proof your business by documenting your team & accounting setup.',
          ),
          const SizedBox(height: 24),

          AppText('Team & Payroll', fontSize: 14, fontWeight: FontWeight.w600),
          const SizedBox(height: 4),
          AppText(
            'Select all that apply',
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          CustomMultiDropDownWidget<String>(
            dropDownKey: _teamKey,
            hint: 'Select team structure',
            items: teamStructureOptions,
            selectedItems: _teamStructure,
            onChanged: (v) => setState(() => _teamStructure = v),
          ),
          const SizedBox(height: 16),

          AppText(
            'Accounting Method',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          CustomDropDownWidget<String>(
            dropDownKey: _methodKey,
            hint: 'Select accounting method',
            items: accountingMethodOptions,
            selectedItem: _accountingMethod,
            onChanged: (v) => setState(() => _accountingMethod = v),
          ),
          const SizedBox(height: 16),

          AppText('Major Equipment', fontSize: 14, fontWeight: FontWeight.w600),
          const SizedBox(height: 4),
          AppText(
            'Did you purchase machinery, heavy tech, or equipment over \$2,500 this year?',
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          YesNoToggle(
            value: _majorEquipment,
            onChanged: (v) => setState(() => _majorEquipment = v),
          ),
          TaxInsightChip(
            text:
                'AI Insight: This triggers Section 179 or Bonus Depreciation strategies.',
          ),
          const SizedBox(height: 32),

          TaxNavButtons(onSkip: _navigateNext, onNext: _saveAndNext),
        ],
      ),
    );
  }
}
