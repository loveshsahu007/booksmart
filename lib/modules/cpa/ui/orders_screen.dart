import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/models/order_model.dart';
import 'package:booksmart/modules/user/controllers/order_controller.dart';
import 'package:booksmart/modules/user/ui/cpa/components/cpa_order_card.dart';
import 'package:booksmart/widgets/multiple_selection_dropdown_widget.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:get/get.dart';

class OrdersScreenCPA extends StatefulWidget {
  const OrdersScreenCPA({super.key});

  @override
  State<OrdersScreenCPA> createState() => _OrdersScreenCPAState();
}

class _OrdersScreenCPAState extends State<OrdersScreenCPA> {
  /// Multi Select Filter
  final GlobalKey<DropdownSearchState<OrderStatus>> _dropdownKey =
      GlobalKey<DropdownSearchState<OrderStatus>>();

  List<OrderStatus> selectedFilters = [];

  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<OrderController>()) {
      Get.put(OrderController(), permanent: true);
    }

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

          /// ✅ MULTI SELECT FILTER DROPDOWN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomMultiDropDownWidget<OrderStatus>(
              dropDownKey: _dropdownKey,
              label: "Filter Orders",
              hint: "Select status",
              items: OrderStatus.values,
              selectedItems: selectedFilters,
              showSearchBox: false,
              itemAsString: (status) =>
                  status.name.capitalizeFirst ?? status.name,
              onChanged: (List<OrderStatus> values) {
                setState(() {
                  selectedFilters = values;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GetX<OrderController>(
                builder: (controller) {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  /// ✅ FILTER LOGIC (MULTI SELECT)
                  final filteredOrders = selectedFilters.isEmpty
                      ? controller.activeOrders
                      : controller.activeOrders.where((order) {
                          final orderStatus = OrderStatus.fromString(
                            order.status.name,
                          );
                          return selectedFilters.contains(orderStatus);
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
}
