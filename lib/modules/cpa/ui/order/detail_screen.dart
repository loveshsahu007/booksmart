import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/cpa/ui/order/delivery_screen.dart';
import 'package:booksmart/modules/user/ui/cpa/order/detail_screen.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

void goToOrderDetailScreenCPA({bool shouldCloseBefore = false}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back(); // close previous dialog
    }
    customDialog(
      child: const OrderDetailScreenCPA(),
      title: 'Order Details',
      barrierDismissible: true,
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => const OrderDetailScreenCPA());
    } else {
      Get.to(() => const OrderDetailScreenCPA());
    }
  }
}

class OrderDetailScreenCPA extends StatelessWidget {
  const OrderDetailScreenCPA({super.key});

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

            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.grey),
              title: Text("John Smith"),
              subtitle: Text("Social Agent"),
              trailing: IconButton(
                onPressed: () {},
                icon: Icon(Icons.chat_bubble_outline),
              ),
            ),
            const SizedBox(height: 24),

            // Order Information
            _buildOrderInfoSection(context),
            const SizedBox(height: 24),

            // Deliverables Section
            _buildDeliverablesSection(context),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),

        child: Column(
          children: [
            AppText(
              "Order #ORD-2024-001",
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: AppText(
                "On-going",
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            AppText(
              "Tax Preparation Services - Individual",
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              textAlign: TextAlign.center,
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
                _buildInfoRow("Start Date", "December 15, 2024"),
                _buildInfoRow("Due Date", "April 15, 2025"),
                _buildInfoRow("Service Type", "Tax Preparation"),
                _buildInfoRow("Cost", "\$1,000"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliverablesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText("  Deliverables", fontSize: 14, fontWeight: FontWeight.bold),
        const SizedBox(height: 16),
        Column(
          children: [
            _buildDeliverableItem("W-2 Forms", "All W-2 forms for 2024"),
            _buildDeliverableItem("1099 Forms", "1099-INT, 1099-DIV, etc."),
            _buildDeliverableItem(
              "Expense Receipts",
              "Business expense documentation",
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Decline order
                  //  showDeclineReasonDialog(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const AppText("Decline Order", fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  goToDeliverOrderScreen();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const AppText("Deliver", fontSize: 12),
              ),
            ),
          ],
        ),
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

  Widget _buildDeliverableItem(String title, String description) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: Text(description),
        dense: true,
      ),
    );
  }
}
