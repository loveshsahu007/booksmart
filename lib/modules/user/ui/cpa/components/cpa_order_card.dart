import 'package:flutter/material.dart';

import '../../../../../widgets/app_text.dart';
import '../order/detail_screen.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key});

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dummy data
    const orderId = "12345";
    const clientName = "John Doe";
    const clientEmail = "john.doe@example.com";

    const status = "Completed";

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          goToCpaOrderDetailScreen();
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
                      'Order #$orderId',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Client Info
                    Row(
                      children: const [
                        Icon(Icons.person, size: 18),
                        SizedBox(width: 6),
                        AppText("$clientName • $clientEmail", fontSize: 14),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Dates
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 6),
                        AppText(
                          'Start: ${_formatDate(DateTime(2025, 10, 1))}',
                          fontSize: 12,
                        ),
                        const SizedBox(width: 10),
                        AppText(
                          'End: ${_formatDate(DateTime(2025, 10, 5))}',
                          fontSize: 12,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Price
                    Row(
                      children: const [
                        Icon(Icons.attach_money, size: 18, color: Colors.grey),
                        SizedBox(width: 6),
                        AppText(
                          'Price: \$249.99',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                spacing: 10,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    width: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: getStatusColor(status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FittedText(status, style: TextStyle(fontSize: 8)),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.chat_bubble_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
