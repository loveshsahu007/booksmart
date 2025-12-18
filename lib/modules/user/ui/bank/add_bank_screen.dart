import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/controllers/auth_controller.dart';
import 'package:booksmart/controllers/banks_controller.dart';
import 'package:booksmart/models/bank_model.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../controllers/organization_controller.dart';

class AddBankDialog extends StatefulWidget {
  final BankModel? bankToEdit;

  const AddBankDialog({super.key, this.bankToEdit});

  @override
  State<AddBankDialog> createState() => _AddBankDialogState();
}

class _AddBankDialogState extends State<AddBankDialog> {
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ibanController = TextEditingController();

  final BankController controller = Get.find<BankController>();
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();

    _isEditMode = widget.bankToEdit != null;

    if (_isEditMode) {
      _bankNameController.text = widget.bankToEdit!.name;
      _accountHolderController.text = widget.bankToEdit!.accountHolder;
      _accountNumberController.text = widget.bankToEdit!.accountNumber;
      _ibanController.text = widget.bankToEdit!.iban;
    }
  }

  void _saveBank() async {
    if (_bankNameController.text.isEmpty ||
        _accountHolderController.text.isEmpty ||
        _accountNumberController.text.isEmpty ||
        _ibanController.text.isEmpty) {
      showSnackBar("Please fill all fields", isError: true);
      return;
    }

    final bank = BankModel(
      name: _bankNameController.text,
      accountHolder: _accountHolderController.text,
      accountNumber: _accountNumberController.text,
      iban: _ibanController.text,
      ownerId: authPerson!.authId,
      organizationId: getCurrentOrganization!.id!,
    );

    if (_isEditMode && widget.bankToEdit?.id != null) {
      await controller.updateBank(
        id: widget.bankToEdit!.id!,
        data: bank.toJson(),
      );
    } else {
      await controller.addBank(bank);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: kIsWeb ? 500 : double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText(
                _isEditMode ? "Edit Bank Account" : "Connect bank account",
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              0.02.verticalSpace,
              AppText(
                _isEditMode
                    ? "Update your bank details below"
                    : "Enter your bank details below",
                fontSize: 14,
                textAlign: TextAlign.center,
              ),
              0.04.verticalSpace,
              AppTextField(
                controller: _bankNameController,
                hintText: "Bank name",
                keyboardType: TextInputType.text,
              ),
              0.02.verticalSpace,
              AppTextField(
                controller: _accountHolderController,
                hintText: "Account holder name",
                keyboardType: TextInputType.text,
              ),
              0.02.verticalSpace,
              AppTextField(
                controller: _accountNumberController,
                hintText: "Account Number",
                keyboardType: TextInputType.text,
              ),
              0.02.verticalSpace,
              AppTextField(
                controller: _ibanController,
                hintText: "IBAN",
                keyboardType: TextInputType.text,
              ),
              0.04.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      fontSize: 16,
                      buttonText: _isEditMode ? "Update" : "Connect",
                      onTapFunction: _saveBank,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      fontSize: 16,
                      buttonText: "Cancel",
                      onTapFunction: () => Get.back(),
                      buttonColor: Colors.grey,
                    ),
                  ),
                ],
              ),
              0.02.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _ibanController.dispose();
    super.dispose();
  }
}
