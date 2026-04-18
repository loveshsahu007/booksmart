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
import 'tax_screen_7_family_health.dart';

void goToTaxScreen6({int? transactionId, int? organizationId}) {
  if (kIsWeb) {
    customDialog(
      child: TaxScreen6RealEstate(
        transactionId: transactionId,
        organizationId: organizationId,
      ),
      title: 'Tax Strategy — Step 6 of 8',
      barrierDismissible: false,
    );
  } else {
    Get.to(
      () => TaxScreen6RealEstate(
        transactionId: transactionId,
        organizationId: organizationId,
      ),
    );
  }
}

class TaxScreen6RealEstate extends StatefulWidget {
  final int? transactionId;
  final int? organizationId;
  const TaxScreen6RealEstate({
    super.key,
    this.transactionId,
    this.organizationId,
  });

  @override
  State<TaxScreen6RealEstate> createState() => _TaxScreen6RealEstateState();
}

class _TaxScreen6RealEstateState extends State<TaxScreen6RealEstate> {
  final _realEstateKey = GlobalKey<DropdownSearchState<String>>();

  List<String> _realEstateInterests = [];
  bool? _hostsBusinessMeetings;

  Future<void> _saveAndNext() async {
    final data = {
      'real_estate_interests': _realEstateInterests.isEmpty
          ? null
          : _realEstateInterests,
      'hosts_business_meetings': _hostsBusinessMeetings,
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
      goToTaxScreen7(
        transactionId: widget.transactionId,
        organizationId: widget.organizationId,
      );
    } else {
      Get.off(
        () => TaxScreen7FamilyHealth(
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
          : AppBar(title: const Text('Tax Strategy — Step 6 of 8')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TaxProgressBar(current: 6),
          const SizedBox(height: 20),
          TaxSectionTitle(
            icon: Icons.house_rounded,
            title: 'Real Estate Strategy',
            subtitle:
                'Real estate holds some of the most powerful tax strategies available.',
          ),
          const SizedBox(height: 24),

          AppText(
            'Real Estate Interests',
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
            dropDownKey: _realEstateKey,
            hint: 'Select real estate interests',
            items: realEstateInterestOptions,
            selectedItems: _realEstateInterests,
            onChanged: (v) => setState(() => _realEstateInterests = v),
          ),
          const SizedBox(height: 16),

          AppText(
            'Meeting Strategy',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 4),
          AppText(
            'Do you host business meetings or "Corporate Minutes" at your home?',
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          YesNoToggle(
            value: _hostsBusinessMeetings,
            onChanged: (v) => setState(() => _hostsBusinessMeetings = v),
          ),
          TaxInsightChip(
            text:
                'AI Insight: This identifies eligibility for the Augusta Rule — up to 14 days of tax-free rental income from your home.',
          ),
          const SizedBox(height: 32),

          TaxNavButtons(onSkip: _navigateNext, onNext: _saveAndNext),
        ],
      ),
    );
  }
}
