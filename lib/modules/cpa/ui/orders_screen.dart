import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/user/controllers/order_controller.dart';
import 'package:booksmart/modules/user/ui/cpa/components/cpa_order_card.dart';
import 'package:get/get.dart';

class OrdersScreenCPA extends StatefulWidget {
  const OrdersScreenCPA({super.key});

  @override
  State<OrdersScreenCPA> createState() => _OrdersScreenCPAState();
}

class _OrdersScreenCPAState extends State<OrdersScreenCPA> {
  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<OrderController>()) {
      Get.put(OrderController(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: AppText("Orders", fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GetX<OrderController>(
                builder: (controller) {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.activeOrders.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text("No orders")),
                    );
                  }
                  return ListView.separated(
                    itemCount: controller.activeOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final order = controller.activeOrders[index];
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
