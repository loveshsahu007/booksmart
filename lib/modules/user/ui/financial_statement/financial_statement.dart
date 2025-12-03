import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/user/ui/financial_statement/subpages/balance_sheet_tab.dart';
import 'package:booksmart/modules/user/ui/financial_statement/subpages/cash_flow_tab.dart';
import 'package:booksmart/modules/user/ui/financial_statement/subpages/profit_and_loss_tab.dart';

import '../transaction/transaction_list_screen.dart';

import 'package:get/get.dart';

import 'package:flutter/material.dart';

class FinincialTabController extends GetxController
    with GetTickerProviderStateMixin {
  late TabController tabController;

  RxInt currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 4, vsync: this);

    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        currentIndex.value = tabController.index;
      }
    });
  }

  void changeTab(int index) {
    tabController.animateTo(index);
    currentIndex.value = index;
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}

class FinancialReportPage extends StatefulWidget {
  const FinancialReportPage({super.key});

  @override
  State<FinancialReportPage> createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage> {
  FinincialTabController finincialTabController = Get.put(
    FinincialTabController(),
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: finincialTabController.tabController,
            dividerColor: Colors.transparent,
            labelPadding: const EdgeInsets.symmetric(horizontal: 5),
            indicatorColor: Get.theme.colorScheme.primary,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            tabs: const [
              Tab(text: 'Transactions'),
              Tab(text: 'Profit & Loss'),
              Tab(text: 'Balance Sheet'),
              Tab(text: 'Cash Flow'),
            ],
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: finincialTabController.tabController,
              children: [
                TransactionListScreen(),
                ProfitLossScreen(),
                BalanceSheetTab(),
                CashFlowTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
