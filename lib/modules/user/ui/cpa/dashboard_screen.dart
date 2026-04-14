import 'package:booksmart/models/order_model.dart';
import 'package:booksmart/modules/user/ui/cpa/cpa_list_screen.dart';
import 'package:booksmart/modules/user/controllers/order_controller.dart';
import '../../../admin/controllers/cpa_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../widgets/app_text.dart';
import 'components/cpa_card.dart';
import 'components/cpa_order_card.dart';

class CpaNetworkScreen extends StatefulWidget {
  const CpaNetworkScreen({super.key});

  @override
  State<CpaNetworkScreen> createState() => _CpaNetworkScreenState();
}

class _CpaNetworkScreenState extends State<CpaNetworkScreen> {
  // State variable to track the selected filter
  OrderStatus? selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              "Active Orders",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 12),

            // --- FILTER TOP BAR ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(null, "All"),
                  ...OrderStatus.values.map((status) {
                    return _buildFilterChip(
                      status,
                      status.name.capitalizeFirst!,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            GetX<OrderController>(
              init: OrderController(),
              initState: (_) {
                Get.find<OrderController>().fetchActiveOrders();
              },
              builder: (controller) {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                // FIXED: Type-safe filtering logic
                final filteredOrders = selectedFilter == null
                    ? controller.activeOrders
                    : controller.activeOrders.where((order) {
                        // Convert the order's status string to OrderStatus enum
                        final orderStatusEnum = OrderStatus.fromString(
                          order.status.name,
                        );
                        // Now comparing Enum == Enum (Type-safe)
                        return orderStatusEnum == selectedFilter;
                      }).toList();

                if (filteredOrders.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        "No orders found for this status",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filteredOrders
                      .map(
                        (order) => Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: OrderCard(order: order),
                        ),
                      )
                      .toList(),
                );
              },
            ),

            // --- TOP CPA SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppText(
                  "Top CPA",
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                TextButton(
                  onPressed: () => goToCpaListScreen(),
                  child: const Text("View all"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GetBuilder<AdminCpaController>(
              init: AdminCpaController(),
              builder: (controller) {
                if (controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.approvedCpas.isEmpty) {
                  return const Center(child: Text("No CPAs available"));
                }
                final cpas = controller.approvedCpas.take(3).toList();
                return Column(
                  children: cpas.map((cpa) => CpaCard(cpa: cpa)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget to build the Filter Chips
  Widget _buildFilterChip(OrderStatus? status, String label) {
    final bool isSelected = selectedFilter == status;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            // If selecting the already selected chip, we toggle to null (All)
            selectedFilter = selected ? status : null;
          });
        },
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
        checkmarkColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
          ),
        ),
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }
}
