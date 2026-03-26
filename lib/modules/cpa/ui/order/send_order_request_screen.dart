import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/helpers/currency_formatter.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:booksmart/widgets/custom_drop_down.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
      appBar: kIsWeb ? null : AppBar(title: const Text("Send Order Request")),
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
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "Create Order Request",
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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

              AppTextField(
                hintText:
                    "Describe the project scope, requirements, and objectives...",
                maxLines: 4,
                controller: _descriptionController,
              ),

              const SizedBox(height: 8),

              // Price
              _buildSectionHeader("Pricing"),
              AppTextField(
                hintText: "Enter total price (e.g., 750.00)",
                maxLines: 1,
                controller: _priceController,
                inputFormatters: [CurrencyTextInputFormatter()],
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
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            onTap: () => _selectOrderExpiryDateTime(context),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
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
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            onTap: () => _selectDeliveryDateTime(context),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
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
              // CustomDropDownWidget(
              //   dropDownKey: _cancelationDropDownKey,
              //   items: _cancellationPolicies,
              // ),
              const SizedBox(height: 20),

              // Deliverables
              _buildSectionHeader("Deliverables"),
              Card(
                margin: EdgeInsets.all(0),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          SizedBox(width: 5),
                          Material(
                            borderRadius: BorderRadius.circular(8),
                            color: Get.theme.primaryColor,
                            child: InkWell(
                              onTap: _addDeliverable,
                              child: SizedBox(
                                width: 33,
                                height: 33,
                                child: Icon(Icons.add, color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Deliverables List
                      if (_deliverables.isNotEmpty) ...[
                        SizedBox(height: 5),
                        ..._deliverables.asMap().entries.map(
                          (entry) =>
                              _buildDeliverableItem(entry.key, entry.value),
                        ),
                      ] else ...[
                        SizedBox(height: 5),
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
              const SizedBox(height: 20),

              AppButton(
                buttonText: "Send Request",
                onTapFunction: _submitOrderRequest,
                radius: 8,
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
      child: AppText(title, fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildDeliverableItem(int index, String deliverable) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(10),
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
        showSnackBar(
          "Please add at least one deliverable",
          title: "Missing Deliverables",
          isError: true,
        );
        return;
      }

      if (_orderExpiryDateTime == null) {
        showSnackBar(
          "Please select order expiry date and time",
          title: "Missing Expiry Date",
          isError: true,
        );
        return;
      }

      if (_deliveryDateTime == null) {
        showSnackBar(
          "Please select delivery date",
          title: "Missing Delivery Date",
          isError: true,
        );
        return;
      }

      // Success - Submit order request
      Get.back();
      showSnackBar(
        "Your order request has been sent to the client successfully",
        title: "Order Request Sent!",
      );
    }
  }
}
