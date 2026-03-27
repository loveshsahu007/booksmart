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
            // Action Buttons
            if (widget.order.status == OrderStatus.pending) ...{
              if (authPerson?.role != UserRole.cpa)
                _buildActionButtons(context),
              const SizedBox(height: 20),
            },
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.order.description!),
          ),
        ),
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
}
