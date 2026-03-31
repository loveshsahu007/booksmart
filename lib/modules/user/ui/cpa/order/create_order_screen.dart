import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/user/controllers/order_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../../widgets/custom_dialog.dart';
import 'package:booksmart/widgets/multiple_selection_dropdown_widget.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:booksmart/constant/data.dart';

void goToCreateOrderCPAScreen({
  required int userId,
  required String userName,
  bool shouldCloseBefore = false,
}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back(); // close previous dialog
    }
    customDialog(
      child: CreateOrderScreen(userId: userId, userName: userName),
      title: 'Create Order',
      barrierDismissible: true,
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => CreateOrderScreen(userId: userId, userName: userName));
    } else {
      Get.to(() => CreateOrderScreen(userId: userId, userName: userName));
    }
  }
}

class CreateOrderScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const CreateOrderScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final OrderController controller = Get.put(OrderController());
  final _servicesDropDownKey = GlobalKey<DropdownSearchState<String>>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("Create Order Request")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  "Sending request to: ${widget.userName}",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                // IconButton(
                //   onPressed: () => Get.back(),
                //   icon: const Icon(Icons.close),
                //   tooltip: 'Close',
                // ),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: controller.titleController,
              hintText: "Order Title (e.g. Tax Return 2024)",
              labelText: "Title",
            ),
            AppTextField(
              controller: controller.descriptionController,
              hintText: "Description/Scope of work...",
              labelText: "Description",
              maxLines: 3,
            ),
            AppTextField(
              controller: controller.amountController,
              hintText: "Amount (\$)",
              labelText: "Amount",
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text(
              "Select CPA Services",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Obx(
              () => CustomMultiDropDownWidget<String>(
                dropDownKey: _servicesDropDownKey,
                items: cpaServices,
                selectedItems: controller.selectedServices.toList(),
                onChanged: (values) {
                  controller.selectedServices.value = values;
                },
                hint: "Select services",
                showSearchBox: true,
              ),
            ),
            const SizedBox(height: 16),
            _buildDatePicker(
              context,
              label: "Start Date",
              selectedDate: controller.startDate,
            ),
            const SizedBox(height: 10),
            _buildDatePicker(
              context,
              label: "Due Date",
              selectedDate: controller.dueDate,
            ),
            const SizedBox(height: 30),
            Obx(
              () => AppButton(
                buttonText: "Send Order Request",
                isLoading: controller.isLoading.value,
                onTapFunction: () async {
                  final success = await controller.createOrder(
                    userId: widget.userId,
                  );
                  if (success) {
                    Get.back(); // Close dialog/screen
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context, {
    required String label,
    required Rx<DateTime?> selectedDate,
  }) {
    return Obx(() {
      final date = selectedDate.value;
      return InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) {
            selectedDate.value = picked;
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date != null
                    ? "${date.month}/${date.day}/${date.year}"
                    : "Select $label",
              ),
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
            ],
          ),
        ),
      );
    });
  }
}
