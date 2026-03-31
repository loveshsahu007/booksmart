import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/models/user_base_model.dart';
import 'package:booksmart/services/edge_functions.dart';
import 'package:booksmart/widgets/confirmation_dialog.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:booksmart/widgets/loading.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:booksmart/models/order_model.dart';
import 'package:booksmart/modules/user/controllers/order_controller.dart';

import '../../../../common/controllers/auth_controller.dart';
import '../../../../common/ui/chat/chat_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

void goToCpaOrderDetailScreen({
  bool shouldCloseBefore = false,
  required OrderModel order,
}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back(); // close previous dialog
    }
    customDialog(
      child: CpaOrderDetailScreen(order: order),
      title: 'Order Details',
      barrierDismissible: true,
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => CpaOrderDetailScreen(order: order));
    } else {
      Get.to(() => CpaOrderDetailScreen(order: order));
    }
  }
}

class CpaOrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  const CpaOrderDetailScreen({super.key, required this.order});

  @override
  State<CpaOrderDetailScreen> createState() => _CpaOrderDetailScreenState();
}

class _CpaOrderDetailScreenState extends State<CpaOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<OrderController>()) {
      Get.put(OrderController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("Order Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header with Status
            _buildOrderHeader(context),
            const SizedBox(height: 24),
            // CPA Info
            if (widget.order.cpa != null)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  "${widget.order.cpa!.firstName} ${widget.order.cpa!.lastName}",
                ),
                subtitle: Text(widget.order.cpa!.email),
                trailing: IconButton(
                  onPressed: () {
                    goToChatScreen(widget.order.cpa!);
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
              ),
            const SizedBox(height: 24),
            // Order Information
            _buildOrderInfoSection(context),
            const SizedBox(height: 24),
            // Description Section (was Deliverables, but Description is more generic for now)
            if (widget.order.description != null &&
                widget.order.description!.isNotEmpty)
              _buildDescriptionSection(context),
            const SizedBox(height: 24),
            // Delivery Details Section
            if ((widget.order.deliverMessage != null &&
                    widget.order.deliverMessage!.isNotEmpty) ||
                (widget.order.deliveryFiles != null &&
                    widget.order.deliveryFiles!.isNotEmpty))
              _buildDeliveryDetailsSection(context),
            // Action Buttons
            if (widget.order.status == OrderStatus.pending) ...[
              if (authPerson?.role != UserRole.cpa)
                _buildActionButtons(context),
              const SizedBox(height: 20),
            ],
            if ((widget.order.status == OrderStatus.accepted ||
                    widget.order.status == OrderStatus.revision) &&
                authPerson?.role == UserRole.cpa) ...[
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  buttonText: widget.order.status == OrderStatus.revision
                      ? "Re-Deliver Order"
                      : "Deliver Order",
                  onTapFunction: () {
                    _showDeliverOrderDialog(
                      context,
                      isReDelivery: widget.order.status == OrderStatus.revision,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (widget.order.status == OrderStatus.delivered &&
                authPerson?.role != UserRole.cpa) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // User rejects delivery
                        showConfirmationDialog(
                          title: "Reject Delivery",
                          description:
                              "Are you sure you want to reject this delivery and ask for revision?",
                          onYes: () async {
                            Get.back(); // close dialog
                            await Get.find<OrderController>().updateOrderStatus(
                              widget.order.id,
                              OrderStatus.revision,
                            );
                          },
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const AppText("Reject Delivery", fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // User accepts delivery
                        showConfirmationDialog(
                          title: "Accept Delivery",
                          description:
                              "Are you sure you want to accept this delivery? The order will be marked as completed.",
                          onYes: () async {
                            Get.back(); // close dialog
                            await Get.find<OrderController>().updateOrderStatus(
                              widget.order.id,
                              OrderStatus.completed,
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const AppText(
                        "Accept Delivery",
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color statusColor = Colors.grey;
    if (widget.order.status == OrderStatus.completed) {
      statusColor = Colors.green;
    }
    if (widget.order.status == OrderStatus.pending) statusColor = Colors.orange;
    if (widget.order.status == OrderStatus.rejected ||
        widget.order.status == OrderStatus.cancelled) {
      statusColor = Colors.red;
    }

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),

        child: Column(
          children: [
            AppText(
              "Order #${widget.order.id}",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor),
              ),
              child: AppText(
                widget.order.status.name.toUpperCase(),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            AppText(
              widget.order.title,
              fontSize: 16,
              color: colorScheme.onSurface,
              textAlign: TextAlign.center,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          " Order Information",
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [
                if (widget.order.startDate != null)
                  _buildInfoRow(
                    "Start Date",
                    _formatDate(widget.order.startDate!),
                  ),
                if (widget.order.dueDate != null)
                  _buildInfoRow("Due Date", _formatDate(widget.order.dueDate!)),
                _buildInfoRow("Cost", "\$${widget.order.amount}"),
                if (widget.order.services.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(
                    height: 10,
                  ), // changed to 10 to be safe before too, but brackets fix it
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        "Services",
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 4,
                          runSpacing: 4,
                          children: widget.order.services.map((e) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                e,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText("  Description", fontSize: 14, fontWeight: FontWeight.bold),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.order.description!),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          "  Delivery Details",
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.order.deliverMessage != null &&
                    widget.order.deliverMessage!.isNotEmpty) ...[
                  Text(widget.order.deliverMessage!),
                  const SizedBox(height: 16),
                ],
                if (widget.order.deliveryFiles != null &&
                    widget.order.deliveryFiles!.isNotEmpty) ...[
                  AppText(
                    "Attached Files",
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.order.deliveryFiles!.map((url) {
                      final uri = Uri.tryParse(url);
                      final filename =
                          uri?.pathSegments.last.split('_').last ?? "Document";
                      return ActionChip(
                        label: Text(
                          filename,
                          style: const TextStyle(fontSize: 12),
                        ),
                        avatar: const Icon(Icons.download, size: 16),
                        onPressed: () async {
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            Get.snackbar("Error", "Could not open file link.");
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = Get.find<OrderController>();
    return Column(
      children: [
        Obx(() {
          if (authUser?.role != UserRole.cpa) {
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Decline order
                      _showDeclineReasonDialog(context, controller);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const AppText("Decline Order", fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      showConfirmationDialog(
                        title: "Are you sure!",
                        description:
                            "Please review all order details carefully. By clicking Accept, your default payment method will be charged. You can manage or update your payment details in Settings > Cards.",
                        onYes: () async {
                          Get.close(2); // confirmation dialog & order-detail
                          showLoading();
                          await processCpaOrderPayment(
                            orderId: widget.order.id,
                          ).then((value) {
                            dismissLoadingWidget();
                            if (value == null) {
                              showSnackBar(
                                "Please wait while we process your payment. You can refresh the screen if the status doesn't update in a few moments, or wait for our notification.",
                              );
                              controller.fetchActiveOrders();
                            } else {
                              showSnackBar(value, isError: true);
                            }
                          });
                        },
                      );

                      // await controller.updateOrderStatus(
                      //   order.id,
                      //   OrderStatus.accepted,
                      // );
                      // if (kIsWeb) {
                      //   Get.back();
                      // } else {
                      //   Get.back();
                      // }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const AppText(
                      "Accept Order",
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            label,
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          AppText(value, fontSize: 14, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }

  void _showDeclineReasonDialog(
    BuildContext context,
    OrderController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText("Decline Order", fontSize: 18, fontWeight: FontWeight.bold),
            const SizedBox(height: 16),
            const Text("Are you sure you want to decline this order?"),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const AppText("Cancel", fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    buttonText: "Decline",
                    buttonColor: Colors.red,
                    textColor: Colors.white,
                    onTapFunction: () async {
                      await controller.updateOrderStatus(
                        widget.order.id,
                        OrderStatus.rejected,
                      );
                      Get.back(); // Close sheet
                      Get.back(); // Close screen
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showDeliverOrderDialog(
    BuildContext context, {
    bool isReDelivery = false,
  }) {
    if (kIsWeb) {
      customDialog(
        child: DeliverOrderWidget(
          orderId: widget.order.id,
          isReDelivery: isReDelivery,
        ),
        title: isReDelivery ? "Re-Deliver Order" : "Deliver Order",
        barrierDismissible: true,
      );
    } else {
      Get.to(
        () => Scaffold(
          appBar: AppBar(
            title: Text(isReDelivery ? "Re-Deliver Order" : "Deliver Order"),
          ),
          body: SingleChildScrollView(
            child: DeliverOrderWidget(
              orderId: widget.order.id,
              isReDelivery: isReDelivery,
            ),
          ),
        ),
      );
    }
  }
}

class DeliverOrderWidget extends StatefulWidget {
  final int orderId;
  final bool isReDelivery;

  const DeliverOrderWidget({
    super.key,
    required this.orderId,
    this.isReDelivery = false,
  });

  @override
  State<DeliverOrderWidget> createState() => _DeliverOrderWidgetState();
}

class _DeliverOrderWidgetState extends State<DeliverOrderWidget> {
  final _messageController = TextEditingController();
  final List<XFile> _selectedFiles = [];

  void _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true, // Need bytes for web upload!
      );
      if (result != null) {
        setState(() {
          _selectedFiles.addAll(
            result.files.map((f) {
              return XFile.fromData(f.bytes!, name: f.name, path: f.path);
            }),
          );
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Error picking files: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderController>();
    return Container(
      padding: const EdgeInsets.all(20),
      width: kIsWeb ? 500 : double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _messageController,
            hintText: "Add a description or message...",
            labelText: "Delivery Message",
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          const Text(
            "Attachments",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_selectedFiles.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedFiles.map((file) {
                return Chip(
                  label: Text(file.name),
                  onDeleted: () {
                    setState(() {
                      _selectedFiles.remove(file);
                    });
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.attach_file),
            label: const Text("Select Files"),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Obx(
              () => AppButton(
                buttonText: "Deliver",
                isLoading: controller.isLoading.value,
                onTapFunction: () async {
                  if (_messageController.text.trim().isEmpty) {
                    Get.snackbar("Error", "Please add a delivery message");
                    return;
                  }
                  await controller.deliverOrder(
                    orderId: widget.orderId,
                    message: _messageController.text.trim(),
                    files: _selectedFiles,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
