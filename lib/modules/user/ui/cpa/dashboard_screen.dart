import 'package:booksmart/modules/user/ui/cpa/cpa_list_screen.dart';
import 'package:flutter/material.dart';

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
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText("Active Orders", fontSize: 14, fontWeight: FontWeight.bold),
            SizedBox(height: 10),

            ...List.generate(
              2,
              (index) => Column(children: [OrderCard(), SizedBox(height: 15)]),
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
            ...List.generate(3, (index) => CpaCard()),
          ],
        ),
      ),
    );
  }
}
