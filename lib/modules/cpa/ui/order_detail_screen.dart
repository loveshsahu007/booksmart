import 'package:booksmart/constant/exports.dart';
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
      appBar: kIsWeb
          ? null
          : AppBar(
              title: const Text("Order Details"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // Share order details
                    Get.snackbar("Shared", "Order details shared successfully");
                  },
                ),
              ],
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header with Status
            _buildOrderHeader(context),
            const SizedBox(height: 24),

            // Order Information
            _buildOrderInfoSection(context),
            const SizedBox(height: 24),

            // Client Information
            _buildClientInfoSection(context),
            const SizedBox(height: 24),

            // Deliverables Section
            _buildDeliverablesSection(context),
            const SizedBox(height: 24),

            // Timeline Section
            _buildTimelineSection(context),
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
        // decoration: BoxDecoration(
        //   color: colorScheme.primary.withValues(alpha:0.1),
        //   borderRadius: BorderRadius.circular(12),
        //   border: Border.all(color: colorScheme.primary.withValues(alpha:0.3)),
        // ),
        child: Column(
          children: [
            AppText(
              "Order #ORD-2024-001",
              fontSize: 18,
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
                "Pending Acceptance",
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
                _buildInfoRow("Order Date", "December 15, 2024"),
                _buildInfoRow("Due Date", "April 15, 2025"),
                _buildInfoRow("Service Type", "Tax Preparation"),
                _buildInfoRow("Complexity", "Medium"),
                _buildInfoRow("Estimated Hours", "8-10 hours"),
                _buildInfoRow("Budget", "\$750 - \$1,000"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          " Client Information",
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 16),
        Card(
          child: Container(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [
                _buildInfoRow("Client Name", "John Smith"),
                _buildInfoRow("Email", "john.smith@email.com"),
                _buildInfoRow("Phone", "+1 (555) 123-4567"),
                _buildInfoRow("Location", "New York, NY"),
                _buildInfoRow("Business Type", "Freelancer"),
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
        AppText(" Required Deliverables"),
        const SizedBox(height: 16),
        Column(
          children: [
            _buildDeliverableItem("W-2 Forms", "All W-2 forms for 2024", true),
            _buildDeliverableItem(
              "1099 Forms",
              "1099-INT, 1099-DIV, etc.",
              true,
            ),
            _buildDeliverableItem(
              "Expense Receipts",
              "Business expense documentation",
              true,
            ),
            _buildDeliverableItem(
              "Investment Statements",
              "Brokerage account statements",
              false,
            ),
            _buildDeliverableItem(
              "Previous Year Return",
              "2023 Tax Return for reference",
              false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(" Project Timeline", fontSize: 16, fontWeight: FontWeight.bold),
        const SizedBox(height: 16),
        Card(
          child: Container(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [
                _buildTimelineItem("Order Received", "Today", true),
                _buildTimelineItem("CPA Acceptance", "Within 48 hours", false),
                _buildTimelineItem(
                  "Document Collection",
                  "By Jan 30, 2025",
                  false,
                ),
                _buildTimelineItem(
                  "Tax Preparation",
                  "Feb 1 - Mar 15, 2025",
                  false,
                ),
                _buildTimelineItem(
                  "Client Review",
                  "Mar 16 - Mar 25, 2025",
                  false,
                ),
                _buildTimelineItem(
                  "Filing Completed",
                  "By Apr 15, 2025",
                  false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: AppButton(
            buttonText: "Accept Order Request",
            fontSize: 16,
            onTapFunction: () {
              // Handle order acceptance
              Get.back();
              Get.snackbar(
                "Order Accepted",
                "You have successfully accepted this order!",
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Decline order
                  showDeclineReasonDialog(context);
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
              child: OutlinedButton(
                onPressed: () {
                  // Request modification
                  Get.snackbar(
                    "Modification Requested",
                    "Client will be notified of your requested changes",
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const AppText("Request Changes"),
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

  Widget _buildDeliverableItem(
    String title,
    String description,
    bool isRequired,
  ) {
    return Card(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),

        child: Row(
          children: [
            Icon(
              isRequired ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isRequired ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(title, fontSize: 14, fontWeight: FontWeight.w600),
                  AppText(description, fontSize: 12, color: Colors.grey[600]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String step, String date, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppText(
              step,
              fontSize: 14,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          AppText(date, fontSize: 12, color: Colors.grey[600]),
        ],
      ),
    );
  }
}
