import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/constant/data.dart';
import 'package:booksmart/modules/user/controllers/transaction_controller.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:booksmart/widgets/custom_drop_down.dart';
import 'package:booksmart/widgets/multiple_selection_dropdown_widget.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'business_details_widgets.dart';

void goToTaxScreen8({int? transactionId, int? organizationId}) {
  if (kIsWeb) {
    customDialog(
      child: TaxScreen8FutureGoals(
        transactionId: transactionId,
        organizationId: organizationId,
      ),
      title: 'Tax Strategy — Step 8 of 8',
      barrierDismissible: false,
    );
  } else {
    Get.to(
      () => TaxScreen8FutureGoals(
        transactionId: transactionId,
        organizationId: organizationId,
      ),
    );
  }
}

class TaxScreen8FutureGoals extends StatefulWidget {
  final int? transactionId;
  final int? organizationId;
  const TaxScreen8FutureGoals({
    super.key,
    this.transactionId,
    this.organizationId,
  });

  @override
  State<TaxScreen8FutureGoals> createState() => _TaxScreen8FutureGoalsState();
}

class _TaxScreen8FutureGoalsState extends State<TaxScreen8FutureGoals> {
  final _goalKey = GlobalKey<DropdownSearchState<String>>();
  final _retirementKey = GlobalKey<DropdownSearchState<String>>();
  final _auditKey = GlobalKey<DropdownSearchState<String>>();

  String? _taxGoal;
  List<String> _retirementCurrent = [];
  String? _auditAppetite;

  Future<void> _saveAndFinish() async {
    final data = {
      'tax_goal': _taxGoal,
      'retirement_current': _retirementCurrent.isEmpty
          ? null
          : _retirementCurrent,
      'audit_appetite': _auditAppetite,
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

    _finish();
  }

  void _finish() {
    showSnackBar('Tax profile saved! Your AI strategy is being tailored. 🎯');

    Future.delayed(const Duration(milliseconds: 500), () {
      if (kIsWeb) {
        Get.back();
      } else {
        Get.until((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(title: const Text('Tax Strategy — Step 8 of 8')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TaxProgressBar(current: 8),
          const SizedBox(height: 20),
          TaxSectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: 'AI Strategy Alignment',
            subtitle:
                'Final step — align your goals so our AI can build your personalized roadmap.',
          ),
          const SizedBox(height: 24),

          AppText(
            'Primary Tax Goal',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          CustomDropDownWidget<String>(
            dropDownKey: _goalKey,
            hint: 'Select your primary goal',
            items: taxGoalOptions,
            selectedItem: _taxGoal,
            onChanged: (v) => setState(() => _taxGoal = v),
          ),
          const SizedBox(height: 16),

          AppText(
            'Retirement Readiness',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 4),
          AppText(
            'Select all that apply',
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          CustomMultiDropDownWidget<String>(
            dropDownKey: _retirementKey,
            hint: 'Select retirement plans',
            items: retirementCurrentOptions,
            selectedItems: _retirementCurrent,
            onChanged: (v) => setState(() => _retirementCurrent = v),
          ),
          const SizedBox(height: 16),

          AppText('Audit Appetite', fontSize: 14, fontWeight: FontWeight.w600),
          const SizedBox(height: 8),
          CustomDropDownWidget<String>(
            dropDownKey: _auditKey,
            hint: 'Select your risk tolerance',
            items: auditAppetiteOptions,
            selectedItem: _auditAppetite,
            onChanged: (v) => setState(() => _auditAppetite = v),
          ),
          const SizedBox(height: 32),

          // Completion Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.15),
                  colorScheme.secondary.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.celebration_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Almost there!',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        'Once you finish, our AI will generate your personalized US tax strategy.',
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          TaxNavButtons(
            onSkip: _finish,
            onNext: _saveAndFinish,
            nextLabel: 'Save & Finish 🎯',
          ),
        ],
      ),
    );
  }
}
