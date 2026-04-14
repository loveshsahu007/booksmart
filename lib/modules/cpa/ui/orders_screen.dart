import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/models/order_model.dart'; // Ensure OrderStatus is here
import 'package:booksmart/modules/user/controllers/order_controller.dart';
import 'package:booksmart/modules/user/ui/cpa/components/cpa_order_card.dart';
import 'package:get/get.dart';

class OrdersScreenCPA extends StatefulWidget {
  const OrdersScreenCPA({super.key});

  @override
  State<OrdersScreenCPA> createState() => _OrdersScreenCPAState();
}

class _OrdersScreenCPAState extends State<OrdersScreenCPA> {
  // State variable for filtering
  OrderStatus? selectedFilter;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<OrderController>()) {
      Get.put(OrderController(), permanent: true);
    }
    // Fetch orders when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<OrderController>().fetchActiveOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppText("Orders", fontSize: 18, fontWeight: FontWeight.bold),
          ),

          // --- FILTER TOP BAR ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(null, "All"),
                ...OrderStatus.values.map((status) {
                  return _buildFilterChip(status, status.name.capitalizeFirst!);
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GetX<OrderController>(
                builder: (controller) {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Apply Type-safe Filtering logic
                  final filteredOrders = selectedFilter == null
                      ? controller.activeOrders
                      : controller.activeOrders.where((order) {
                          return OrderStatus.fromString(order.status.name) ==
                              selectedFilter;
                        }).toList();

                  if (filteredOrders.isEmpty) {
                    return const Center(
                      child: Text(
                        "No orders found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: filteredOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return OrderCard(order: order);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to build the Filter Chips (consistent with CpaNetworkScreen)
  Widget _buildFilterChip(OrderStatus? status, String label) {
    final bool isSelected = selectedFilter == status;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
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
