import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/user/controllers/order_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../widgets/custom_dialog.dart';
import 'package:booksmart/widgets/multiple_selection_dropdown_widget.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:booksmart/constant/data.dart';

import '../../../../../widgets/snackbar.dart';

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

  // New Controller for adding deliverables locally before submission
  final TextEditingController _deliverableInputController =
      TextEditingController();
  // Using RxList to keep it reactive with GetX or a simple List with setState
  final List<String> _deliverables = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("Create Order Request")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              "Sending request to: ${widget.userName}",
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 20),

            // --- Basic Info ---
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

            // --- Services Selection ---
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

            const SizedBox(height: 20),

            // --- DELIVERABLES SECTION ---
            _buildSectionHeader("Deliverables"),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            hintText: "Enter deliverable item...",
                            controller: _deliverableInputController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _addDeliverable,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    if (_deliverables.isNotEmpty) ...[
                      const Divider(),
                      ..._deliverables.asMap().entries.map(
                        (entry) =>
                            _buildDeliverableItem(entry.key, entry.value),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- CANCELLATION POLICY ---
            _buildSectionHeader("Cancellation Policy"),
            AppTextField(
              controller: controller
                  .cancellationController, // Add this to your OrderController
              hintText: "Define terms for order cancellation...",
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            // --- Dates ---
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    context,
                    label: "Start Date",
                    selectedDate: controller.startDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDatePicker(
                    context,
                    label: "Due Date",
                    selectedDate: controller.dueDate,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- Submit Button ---
            Obx(
              () => AppButton(
                buttonText: "Send Order Request",
                isLoading: controller.isLoading.value,
                onTapFunction: () async {
                  // Pass the local deliverables list to the controller
                  final success = await controller.createOrder(
                    userId: widget.userId,
                    deliverables: _deliverables,
                  );

                  if (success) {
                    Get.back();
                    showSnackBar(
                      "Order request sent successfully",
                      title: "Success",
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget _buildDeliverableItem(int index, String deliverable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(deliverable, style: const TextStyle(fontSize: 14)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => setState(() => _deliverables.removeAt(index)),
          ),
        ],
      ),
    );
  }

  void _addDeliverable() {
    if (_deliverableInputController.text.trim().isNotEmpty) {
      setState(() {
        _deliverables.add(_deliverableInputController.text.trim());
        _deliverableInputController.clear();
      });
    }
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
          if (picked != null) selectedDate.value = picked;
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
              Expanded(
                child: Text(
                  date != null ? DateFormat('MM/dd/yyyy').format(date) : label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            ],
          ),
        ),
      );
    });
  }
}
