import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/user/ui/bank/add_bank_screen.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

void goToBanksListScreen({bool shouldCloseBefore = false}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      // Get.back(); // close previous dialog
    }
    customDialog(
      child: const BanksListScreen(),
      title: 'Bank Accounts',
      barrierDismissible: true,
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => const BanksListScreen());
    } else {
      Get.to(() => const BanksListScreen());
    }
  }
}

class BanksListScreen extends StatefulWidget {
  const BanksListScreen({super.key});

  @override
  State<BanksListScreen> createState() => _BanksListScreenState();
}

class _BanksListScreenState extends State<BanksListScreen> {
  List<Bank> banks = [
    Bank(
      name: 'Chase Bank',
      accountHolder: 'John Doe',
      accountNumber: '**** 1234',
      iban: 'US64 1234 5678 9012',
    ),
    Bank(
      name: 'Bank of America',
      accountHolder: 'John Doe',
      accountNumber: '**** 5678',
      iban: 'US64 5678 1234 9012',
    ),
    Bank(
      name: 'Wells Fargo',
      accountHolder: 'John Doe',
      accountNumber: '**** 9012',
      iban: 'US64 9012 5678 1234',
    ),
  ];

  void _addBank(Bank newBank) {
    setState(() {
      banks.add(newBank);
    });
    Get.back(); // Close the add bank dialog
  }

  void _showAddBankDialog() {
    if (kIsWeb) {
      customDialog(
        child: AddBankDialog(onBankAdded: _addBank),
        title: 'Connect Bank Account',
        barrierDismissible: true,
      );
    } else {
      Get.dialog(Dialog(child: AddBankDialog(onBankAdded: _addBank)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("Bank Accounts")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          0.1.verticalSpace,

          if (banks.isEmpty) ...[
            Expanded(child: Image.asset(gifBank)),
            AppText(
              "Filler text is text that shares some characteristics of a real\n written text, but is random or otherwise generated.",
              themeStyle: Theme.of(context).textTheme.bodyMedium,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: banks.length,
                itemBuilder: (context, index) {
                  final bank = banks[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.account_balance,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      title: Text(
                        bank.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Account: ${bank.accountNumber}'),
                          Text('Holder: ${bank.accountHolder}'),
                        ],
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade600,
                      ),
                      onTap: () {
                        // Handle bank item tap if needed
                      },
                    ),
                  );
                },
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: AppButton(
              buttonText: "Connect bank Account",
              fontSize: 14,
              onTapFunction: _showAddBankDialog,
              radius: 0,
              isRight: true,
              iconWidget: Container(
                color: Colors.white,
                child: const Icon(Icons.add),
              ),
            ),
          ),
          0.04.verticalSpace,
        ],
      ),
    );
  }
}
