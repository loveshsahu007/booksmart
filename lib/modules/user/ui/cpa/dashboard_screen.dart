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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText("Active Orders", fontSize: 14, fontWeight: FontWeight.bold),
            SizedBox(height: 10),
            GetX<OrderController>(
              init: OrderController(),
              initState: (_) {
                Get.find<OrderController>().fetchActiveOrders();
              },
              builder: (controller) {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.activeOrders.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("No active orders")),
                  );
                }
                return Column(
                  children: controller.activeOrders
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText("Top CPA", fontSize: 14, fontWeight: FontWeight.bold),

                TextButton(
                  onPressed: () {
                    goToCpaListScreen();
                  },
                  child: Text("View all"),
                ),
              ],
            ),
            SizedBox(height: 10),
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
