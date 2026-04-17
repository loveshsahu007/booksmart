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
import 'tax_screen_6_real_estate.dart';

void goToTaxScreen5({int? transactionId, int? organizationId}) {
  if (kIsWeb) {
    customDialog(
      child: TaxScreen5HomeOffice(
        transactionId: transactionId,
        organizationId: organizationId,
      ),
      title: 'Tax Strategy — Step 5 of 8',
      barrierDismissible: false,
    );
  } else {
    Get.to(() => TaxScreen5HomeOffice(
          transactionId: transactionId,
          organizationId: organizationId,
        ));
  }
}

class TaxScreen5HomeOffice extends StatefulWidget {
  final int? transactionId;
  final int? organizationId;
  const TaxScreen5HomeOffice({
    super.key,
    this.transactionId,
    this.organizationId,
  });

  @override
  State<TaxScreen5HomeOffice> createState() => _TaxScreen5HomeOfficeState();
}

class _TaxScreen5HomeOfficeState extends State<TaxScreen5HomeOffice> {
  final _officeKey = GlobalKey<DropdownSearchState<String>>();
  final _homeKey = GlobalKey<DropdownSearchState<String>>();
  final _techKey = GlobalKey<DropdownSearchState<String>>();

  String? _homeOfficeType;
  String? _homeStatus;
  List<String> _techUsage = [];

  Future<void> _saveAndNext() async {
    final data = {
      'home_office_type': _homeOfficeType,
      'home_status': _homeStatus,
      'tech_usage': _techUsage.isEmpty ? null : _techUsage,
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
      goToTaxScreen6(
        transactionId: widget.transactionId,
        organizationId: widget.organizationId,
      );
    } else {
      Get.off(() => TaxScreen6RealEstate(
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
          : AppBar(title: const Text('Tax Strategy — Step 5 of 8')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TaxProgressBar(current: 5),
          const SizedBox(height: 20),
          TaxSectionTitle(
            icon: Icons.home_work_rounded,
            title: 'Workspace & Infrastructure',
            subtitle:
                'Your home office and tech setup could be fully deductible.',
          ),
          const SizedBox(height: 24),

          AppText('Home Office Setup', fontSize: 14, fontWeight: FontWeight.w600),
          const SizedBox(height: 8),
          CustomDropDownWidget<String>(
            dropDownKey: _officeKey,
            hint: 'Select home office type',
            items: homeOfficeTypeOptions,
            selectedItem: _homeOfficeType,
            onChanged: (v) => setState(() => _homeOfficeType = v),
          ),
          const SizedBox(height: 16),

          AppText(
            'Home Ownership Status',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          CustomDropDownWidget<String>(
            dropDownKey: _homeKey,
            hint: 'Select home status',
            items: homeStatusOptions,
            selectedItem: _homeStatus,
            onChanged: (v) => setState(() => _homeStatus = v),
          ),
          const SizedBox(height: 16),

          AppText(
            'Tech & Digital Usage',
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
            dropDownKey: _techKey,
            hint: 'Select tech usage',
            items: techUsageOptions,
            selectedItems: _techUsage,
            onChanged: (v) => setState(() => _techUsage = v),
          ),
          const SizedBox(height: 32),

          TaxNavButtons(onSkip: _navigateNext, onNext: _saveAndNext),
        ],
      ),
    );
  }
}
