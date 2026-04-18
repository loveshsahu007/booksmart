import 'package:booksmart/models/order_model.dart';
import 'package:booksmart/modules/user/ui/cpa/cpa_list_screen.dart';
import 'package:booksmart/modules/user/controllers/order_controller.dart';
import 'package:booksmart/widgets/custom_drop_down.dart';
import '../../../admin/controllers/cpa_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../../../widgets/app_text.dart';
import 'components/cpa_card.dart';
import 'components/cpa_order_card.dart';

class CpaNetworkScreen extends StatefulWidget {
  const CpaNetworkScreen({super.key});

  @override
  State<CpaNetworkScreen> createState() => _CpaNetworkScreenState();
}

class _CpaNetworkScreenState extends State<CpaNetworkScreen> {
  /// Selected filter
  OrderStatus? selectedFilter;

  /// Dropdown key
  final GlobalKey<DropdownSearchState<OrderStatus?>> _filterKey =
      GlobalKey<DropdownSearchState<OrderStatus?>>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ==============================
            /// ACTIVE ORDERS HEADER + FILTER
            /// ==============================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppText(
                  "Active Orders",
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),

                /// 🔽 Filter Icon
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    _filterKey.currentState?.openDropDownSearch();
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// 🔽 Dropdown Filter
            CustomDropDownWidget<OrderStatus?>(
              dropDownKey: _filterKey,
              hint: "Filter by status",
              selectedItem: selectedFilter,
              items: [null, ...OrderStatus.values],
              itemAsString: (status) {
                if (status == null) return "All";
                return status.name.capitalizeFirst!;
              },
              onChanged: (value) {
                setState(() {
                  selectedFilter = value;
                });
              },
            ),

            const SizedBox(height: 20),

            /// ==============================
            /// ACTIVE ORDERS LIST
            /// ==============================
            GetX<OrderController>(
              init: OrderController(),
              initState: (_) {
                Get.find<OrderController>().fetchActiveOrders();
              },
              builder: (controller) {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredOrders = selectedFilter == null
                    ? controller.activeOrders
                    : controller.activeOrders.where((order) {
                        final orderStatusEnum = OrderStatus.fromString(
                          order.status.name,
                        );
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

            const SizedBox(height: 25),

            /// ==============================
            /// TOP CPA SECTION
            /// ==============================
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
}
