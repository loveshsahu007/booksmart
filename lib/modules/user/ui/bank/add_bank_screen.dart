import 'package:booksmart/constant/exports.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AddBankDialog extends StatefulWidget {
  final Function(Bank) onBankAdded;

  const AddBankDialog({super.key, required this.onBankAdded});

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

  void _connectBank() {
    if (_bankNameController.text.isEmpty ||
        _accountHolderController.text.isEmpty ||
        _accountNumberController.text.isEmpty ||
        _ibanController.text.isEmpty) {
      // Show error message or validation
      return;
    }

    final newBank = Bank(
      name: _bankNameController.text,
      accountHolder: _accountHolderController.text,
      accountNumber: _accountNumberController.text,
      iban: _ibanController.text,
    );

    widget.onBankAdded(newBank);
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
                "Connect bank account",
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              0.02.verticalSpace,
              AppText(
                "Filler text is text that shares some characteristics of a real written text, but is random or otherwise generated.",
                fontSize: 14,
                textAlign: TextAlign.center,
              ),
              0.04.verticalSpace,
              SizedBox(
                width: double.infinity,
                child: AppTextField(
                  controller: _bankNameController,
                  hintText: "Bank name",
                  keyboardType: TextInputType.text,
                  maxLines: 1,
                  fieldValidator: (v) => null,
                ),
              ),
              0.02.verticalSpace,
              SizedBox(
                width: double.infinity,
                child: AppTextField(
                  controller: _accountHolderController,
                  hintText: "Account holder name",
                  keyboardType: TextInputType.text,
                  maxLines: 1,
                  fieldValidator: (v) => null,
                ),
              ),
              0.02.verticalSpace,
              SizedBox(
                width: double.infinity,
                child: AppTextField(
                  controller: _accountNumberController,
                  hintText: "Account Number",
                  keyboardType: TextInputType.text,
                  maxLines: 1,
                  fieldValidator: (v) => null,
                ),
              ),
              0.02.verticalSpace,
              SizedBox(
                width: double.infinity,
                child: AppTextField(
                  controller: _ibanController,
                  hintText: "IBAN",
                  keyboardType: TextInputType.text,
                  maxLines: 1,
                  fieldValidator: (v) => null,
                ),
              ),
              0.04.verticalSpace,
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  fontSize: 16,
                  buttonText: "Connect",
                  onTapFunction: _connectBank,
                  radius: 0,
                ),
              ),
              0.02.verticalSpace,
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  fontSize: 16,
                  buttonText: "Cancel",
                  onTapFunction: () => Get.back(),
                  radius: 0,
                  buttonColor: Colors.grey,
                ),
              ),
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

class Bank {
  final String name;
  final String accountHolder;
  final String accountNumber;
  final String iban;

  Bank({
    required this.name,
    required this.accountHolder,
    required this.accountNumber,
    required this.iban,
  });
}
