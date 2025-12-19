import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/controllers/banks_controller.dart';
import 'package:booksmart/models/bank_model.dart';
import 'package:booksmart/modules/user/ui/bank/add_bank_screen.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

void goToBanksListScreen({bool shouldCloseBefore = false}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back();
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
  final BankController controller = Get.put(BankController());

  void _showAddBankDialog({BankModel? bankToEdit}) {
    if (kIsWeb) {
      customDialog(
        child: AddBankDialog(bankToEdit: bankToEdit), // Pass bank for edit
        title: bankToEdit != null
            ? 'Edit Bank Account'
            : 'Connect Bank Account',
        barrierDismissible: true,
      );
    } else {
      Get.dialog(
        Dialog(
          child: AddBankDialog(bankToEdit: bankToEdit), // Pass bank for edit
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("Bank Accounts")),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Expanded(
              child: controller.banks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: screenHeight * 0.3,
                            child: Image.asset(gifBank, fit: BoxFit.contain),
                          ),
                          0.02.verticalSpace,
                          AppText(
                            "No bank accounts added yet.",
                            themeStyle: Theme.of(context).textTheme.bodyMedium,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: controller.banks.length,
                      itemBuilder: (context, index) {
                        final bank = controller.banks[index];
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
                                Text('IBAN: ${bank.iban}'),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  // Open edit dialog with existing bank data
                                  _showAddBankDialog(bankToEdit: bank);
                                } else if (value == 'delete') {
                                  // Show confirmation dialog before deleting
                                  Get.defaultDialog(
                                    title: "Confirm Delete",
                                    middleText:
                                        "Are you sure you want to delete ${bank.name}?",
                                    textConfirm: "Delete",
                                    textCancel: "Cancel",
                                    confirmTextColor: Colors.white,
                                    onConfirm: () async {
                                      Get.back();
                                      await controller.deleteBank(bank.id);
                                    },
                                    onCancel: () => Get.back(),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Add Bank Button - always visible
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: AppButton(
                buttonText: "Connect Bank Account",
                fontSize: 14,
                onTapFunction: () => _showAddBankDialog(),
                radius: 0,
                isRight: true,
                iconWidget: Container(
                  color: Colors.white,
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
