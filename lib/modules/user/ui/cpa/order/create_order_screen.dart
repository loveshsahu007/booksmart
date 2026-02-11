import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/user/controllers/order_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

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
