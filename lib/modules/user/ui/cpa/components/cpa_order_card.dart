import 'package:booksmart/helpers/currency_formatter.dart';
import 'package:booksmart/models/order_model.dart';
import 'package:booksmart/models/user_base_model.dart';
import 'package:booksmart/modules/common/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../helpers/date_formatter.dart';
import '../../../../../widgets/app_text.dart';
import '../order/detail_screen.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  const OrderCard({super.key, required this.order});

  Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isCpa = authController.person?.role == UserRole.cpa;
    final target = isCpa ? order.user : order.cpa;
    final defaultLabel = isCpa ? "User" : "CPA";

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          goToCpaOrderDetailScreen(order: order);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID and Status Row
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Client Info - Show CPA name if user viewing, or User name if CPA viewing
                    Row(
                      children: [
                        const Icon(Icons.person, size: 18),
                        const SizedBox(width: 6),
                        AppText(
                          target != null
                              ? "${target.firstName} ${target.lastName}"
                              : defaultLabel,
                          fontSize: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Dates
                    if (order.startDate != null || order.dueDate != null)
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 6),
                          if (order.startDate != null)
                            AppText(
                              'Start: ${formatDate(order.startDate!)}',
                              fontSize: 12,
                            ),
                          if (order.startDate != null && order.dueDate != null)
                            const SizedBox(width: 10),
                          if (order.dueDate != null)
                            AppText(
                              'Due: ${formatDate(order.dueDate!)}',
                              fontSize: 12,
                            ),
                        ],
                      ),
                    const SizedBox(height: 6),

                    // Price
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        AppText(
                          'Price: \$${formatNumber(order.amount)}',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: getStatusColor(
                        order.status,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: getStatusColor(order.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // const SizedBox(height: 20),
                  // IconButton(
                  //   onPressed: () {}, // Open chat maybe?
                  //   icon: const Icon(Icons.chat_bubble_outline),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
