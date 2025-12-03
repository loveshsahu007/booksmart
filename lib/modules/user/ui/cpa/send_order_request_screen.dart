import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../widgets/custom_drop_down.dart';

void goToSendOrderRequestScreen({bool shouldCloseBefore = false}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back(); // close previous dialog
    }
    customDialog(
      child: const SendOrderRequestScreen(),
      title: 'Send Order Request',
      barrierDismissible: true,
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => const SendOrderRequestScreen());
    } else {
      Get.to(() => const SendOrderRequestScreen());
    }
  }
}

class SendOrderRequestScreen extends StatefulWidget {
  const SendOrderRequestScreen({super.key});

  @override
  State<SendOrderRequestScreen> createState() => _SendOrderRequestScreenState();
}

class _SendOrderRequestScreenState extends State<SendOrderRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _deliverableController = TextEditingController();

  DateTime? _orderExpiryDateTime;
  DateTime? _deliveryDateTime;

  final List<String> _deliverables = [];
  final List<String> _cancellationPolicies = [
    'Flexible - Full refund 24 hours before delivery',
    'Moderate - 50% refund before work starts',
    'Strict - No refund after acceptance',
    'Custom - To be discussed',
  ];

  final _cancelationDropDownKey = GlobalKey<DropdownSearchState<String>>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(
              title: const Text("Send Order Request"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: _showHelpDialog,
                ),
              ],
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "Create Order Request",
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 8),
                      AppText(
                        "Fill in the details below to send a professional order request to your client",
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Description
              _buildSectionHeader("Project Description"),

              Padding(
                padding: const EdgeInsets.all(12),
                child: AppTextField(
                  hintText:
                      "Describe the project scope, requirements, and objectives...",
                  maxLines: 4,
                  controller: _descriptionController,
                ),
              ),

              const SizedBox(height: 8),

              // Price
              _buildSectionHeader("Pricing"),
              Padding(
                padding: const EdgeInsets.all(12),
                child: AppTextField(
                  hintText: "Enter total price (e.g., 750.00)",
                  maxLines: 1,
                  controller: _priceController,
                ),
              ),

              const SizedBox(height: 8),

              // Date & Time Selection
              Row(
                children: [
                  // Order Expiry
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Order Expiry"),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: InkWell(
                              onTap: () => _selectOrderExpiryDateTime(context),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppText(
                                      _orderExpiryDateTime != null
                                          ? DateFormat(
                                              'MMM dd, yyyy - HH:mm',
                                            ).format(_orderExpiryDateTime!)
                                          : "Select expiry date & time",
                                      fontSize: 12,
                                      color: _orderExpiryDateTime != null
                                          ? null
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Delivery Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Delivery Date"),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: InkWell(
                              onTap: () => _selectDeliveryDateTime(context),
                              child: Row(
                                children: [
                                  const Icon(Icons.event_available, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppText(
                                      _deliveryDateTime != null
                                          ? DateFormat(
                                              'MMM dd, yyyy',
                                            ).format(_deliveryDateTime!)
                                          : "Select delivery date",
                                      fontSize: 12,
                                      color: _deliveryDateTime != null
                                          ? null
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Cancellation Policy
              _buildSectionHeader("Cancellation Policy"),
              CustomDropDownWidget<String>(
                dropDownKey: _cancelationDropDownKey,
                label: 'Category',

                items: _cancellationPolicies,
              ),
              const SizedBox(height: 20),

              // Deliverables
              _buildSectionHeader("Deliverables"),
              Card(
                margin: EdgeInsets.all(0),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Add Deliverable Input
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              hintText: "Enter deliverable item...",
                              controller: _deliverableController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            color: Colors.green,
                            onPressed: _addDeliverable,
                          ),
                        ],
                      ),

                      // Deliverables List
                      if (_deliverables.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Column(
                          children: _deliverables
                              .asMap()
                              .entries
                              .map(
                                (entry) => _buildDeliverableItem(
                                  entry.key,
                                  entry.value,
                                ),
                              )
                              .toList(),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        AppText(
                          "No deliverables added yet",
                          fontSize: 14,

                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Action Buttons
              SizedBox(
                height: 35,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        child: const AppText("Cancel", fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        buttonText: "Send Order Request",
                        onTapFunction: _submitOrderRequest,
                        radius: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppText(title, fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildDeliverableItem(int index, String deliverable) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      // decoration: BoxDecoration(
      //   color: Colors.grey[50],
      //   borderRadius: BorderRadius.circular(8),
      // ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: AppText(deliverable, fontSize: 14)),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red,
            onPressed: () => _removeDeliverable(index),
          ),
        ],
      ),
    );
  }

  void _addDeliverable() {
    if (_deliverableController.text.trim().isNotEmpty) {
      setState(() {
        _deliverables.add(_deliverableController.text.trim());
        _deliverableController.clear();
      });
    }
  }

  void _removeDeliverable(int index) {
    setState(() {
      _deliverables.removeAt(index);
    });
  }

  Future<void> _selectOrderExpiryDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _orderExpiryDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _selectDeliveryDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _deliveryDateTime = pickedDate;
      });
    }
  }

  void _submitOrderRequest() {
    if (_formKey.currentState!.validate()) {
      if (_deliverables.isEmpty) {
        Get.snackbar(
          "Missing Deliverables",
          "Please add at least one deliverable",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (_orderExpiryDateTime == null) {
        Get.snackbar(
          "Missing Expiry Date",
          "Please select order expiry date and time",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (_deliveryDateTime == null) {
        Get.snackbar(
          "Missing Delivery Date",
          "Please select delivery date",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Success - Submit order request
      Get.back();
      Get.snackbar(
        "Order Request Sent!",
        "Your order request has been sent to the client successfully",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _showHelpDialog() {
    Get.dialog(
      AlertDialog(
        title: const AppText("Order Request Help"),
        content: const AppText(
          "• Description: Clearly outline project scope and requirements\n"
          "• Price: Set the total project cost\n"
          "• Order Expiry: Client must accept before this date\n"
          "• Delivery Date: When you'll complete the work\n"
          "• Cancellation Policy: Terms for order cancellation\n"
          "• Deliverables: List all items you'll provide",
          fontSize: 14,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const AppText("Got it"),
          ),
        ],
      ),
    );
  }
}
