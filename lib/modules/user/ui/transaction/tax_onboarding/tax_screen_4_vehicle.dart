import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/constant/data.dart';
import 'package:booksmart/modules/user/controllers/transaction_controller.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:booksmart/widgets/custom_drop_down.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'tax_onboarding_widgets.dart';
import 'tax_screen_5_home_office.dart';

void goToTaxScreen4({int? transactionId, int? organizationId}) {
  if (kIsWeb) {
    customDialog(
      child: TaxScreen4Vehicle(
        transactionId: transactionId,
        organizationId: organizationId,
      ),
      title: 'Tax Strategy — Step 4 of 8',
      barrierDismissible: false,
    );
  } else {
    Get.to(() => TaxScreen4Vehicle(
          transactionId: transactionId,
          organizationId: organizationId,
        ));
  }
}

class TaxScreen4Vehicle extends StatefulWidget {
  final int? transactionId;
  final int? organizationId;
  const TaxScreen4Vehicle({
    super.key,
    this.transactionId,
    this.organizationId,
  });

  @override
  State<TaxScreen4Vehicle> createState() => _TaxScreen4VehicleState();
}

class _TaxScreen4VehicleState extends State<TaxScreen4Vehicle> {
  final _ownershipKey = GlobalKey<DropdownSearchState<String>>();
  final _usageKey = GlobalKey<DropdownSearchState<String>>();

  String? _vehicleOwnership;
  String? _vehicleUsage;
  bool? _vehicleOver6kLbs;

  Future<void> _saveAndNext() async {
    final data = {
      'vehicle_ownership': _vehicleOwnership,
      'vehicle_usage': _vehicleUsage,
      'vehicle_over_6k_lbs': _vehicleOver6kLbs,
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
      goToTaxScreen5(
        transactionId: widget.transactionId,
        organizationId: widget.organizationId,
      );
    } else {
      Get.off(() => TaxScreen5HomeOffice(
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
          : AppBar(title: const Text('Tax Strategy — Step 4 of 8')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TaxProgressBar(current: 4),
          const SizedBox(height: 20),
          TaxSectionTitle(
            icon: Icons.directions_car_rounded,
            title: 'Vehicle & Logistics',
            subtitle:
                "Vehicle deductions can be significant — let's capture every dollar.",
          ),
          const SizedBox(height: 24),

          AppText(
            'Vehicle Ownership',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          CustomDropDownWidget<String>(
            dropDownKey: _ownershipKey,
            hint: 'Select ownership type',
            items: vehicleOwnershipOptions,
            selectedItem: _vehicleOwnership,
            onChanged: (v) => setState(() => _vehicleOwnership = v),
          ),
          const SizedBox(height: 16),

          AppText(
            'Primary Usage Method',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          CustomDropDownWidget<String>(
            dropDownKey: _usageKey,
            hint: 'Select usage method',
            items: vehicleUsageOptions,
            selectedItem: _vehicleUsage,
            onChanged: (v) => setState(() => _vehicleUsage = v),
          ),
          const SizedBox(height: 16),

          AppText('Vehicle Weight', fontSize: 14, fontWeight: FontWeight.w600),
          const SizedBox(height: 4),
          AppText(
            'Is the vehicle over 6,000 lbs? (SUV/Truck)',
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          YesNoToggle(
            value: _vehicleOver6kLbs,
            onChanged: (v) => setState(() => _vehicleOver6kLbs = v),
          ),
          TaxInsightChip(
            text:
                'AI Insight: This triggers the "Hummer Tax Loophole" — heavy vehicle depreciation under Section 179.',
          ),
          const SizedBox(height: 32),

          TaxNavButtons(onSkip: _navigateNext, onNext: _saveAndNext),
        ],
      ),
    );
  }
}
