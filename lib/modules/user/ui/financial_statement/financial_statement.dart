import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/user/ui/financial_statement/subpages/balance_sheet_tab.dart';
import 'package:booksmart/modules/user/ui/financial_statement/subpages/cash_flow_tab.dart';
import 'package:booksmart/modules/user/ui/financial_statement/subpages/profit_and_loss_tab.dart';

import '../transaction/transaction_list_screen.dart';

import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:booksmart/modules/user/controllers/financial_report_controller.dart';
import 'package:booksmart/modules/user/controllers/organization_controller.dart';

import 'subpages/financial_dashboard_tab.dart';

class FinincialTabController extends GetxController
    with GetTickerProviderStateMixin {
  late TabController tabController;

  RxInt currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 5, vsync: this);

    tabController.addListener(() {
      currentIndex.value = tabController.index;
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

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  FinincialTabController finincialTabController = Get.put(
    FinincialTabController(),
  );

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 89));
  DateTime _endDate = DateTime.now();

  FinancialReportController get _reportController => Get.find<FinancialReportController>(
        tag: getCurrentOrganization!.id.toString(),
      );

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<FinancialReportController>(tag: getCurrentOrganization!.id.toString())) {
      Get.put(FinancialReportController(), tag: getCurrentOrganization!.id.toString());
    }
    final ctrl = _reportController;
    if (ctrl.lastStartDate != null && ctrl.lastEndDate != null) {
      _startDate = ctrl.lastStartDate!;
      _endDate = ctrl.lastEndDate!;
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFC72B),
              onPrimary: Colors.black,
              surface: Color(0xFF0F1E37),
              onSurface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F1E37),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
      });
      await _reportController.fetchAndAggregateData(
        startDate: _startDate,
        endDate: _endDate,
      );
    }
  }

  void _openExportMenu() {
    final selected = finincialTabController.currentIndex.value;
    final initialIndex = selected >= 2 && selected <= 4 ? selected : 2;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F1E37),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Export Report',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Open the report you want to export — each report has its own export options.',
                  style: TextStyle(color: Color(0xFF8AA3C8), fontSize: 12),
                ),
                const SizedBox(height: 12),
                _exportListItem('Profit & Loss', 'PDF / Excel / Template', Icons.description_outlined, () {
                  Navigator.of(ctx).pop();
                  finincialTabController.changeTab(2);
                }, highlight: initialIndex == 2),
                _exportListItem('Balance Sheet', 'PDF / Excel', Icons.account_balance_outlined, () {
                  Navigator.of(ctx).pop();
                  finincialTabController.changeTab(3);
                }, highlight: initialIndex == 3),
                _exportListItem('Cash Flow', 'PDF / Excel / CSV', Icons.swap_vert_rounded, () {
                  Navigator.of(ctx).pop();
                  finincialTabController.changeTab(4);
                }, highlight: initialIndex == 4),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _exportListItem(String title, String subtitle, IconData icon, VoidCallback onTap, {bool highlight = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFF0E2A56) : const Color(0xFF0A1F3F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: highlight ? const Color(0xFFFFC72B).withValues(alpha: 0.6) : const Color(0xFF1B3A6C),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFC72B), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF8AA3C8), fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8AA3C8), size: 18),
          ],
        ),
      ),
    );
  }

  String get _dateRangeLabel {
    final ctrl = _reportController;
    final start = ctrl.lastStartDate ?? _startDate;
    final end = ctrl.lastEndDate ?? _endDate;
    final df = DateFormat('MMM d');
    return '${df.format(start)} - ${df.format(end)}, ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width <= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFF020E2C),
      body: Column(
        children: [
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF020E2C),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    isScrollable: isNarrow,
                    tabAlignment: isNarrow ? TabAlignment.start : TabAlignment.fill,
                    controller: finincialTabController.tabController,
                    dividerColor: Colors.transparent,
                    indicatorSize: isNarrow
                        ? TabBarIndicatorSize.label
                        : TabBarIndicatorSize.tab,
                    indicatorColor: const Color(0xFFFFC72B),
                    indicatorWeight: 2,
                    labelPadding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 6),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF7F96BA),
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'Dashboard'),
                      Tab(text: 'Transactions'),
                      Tab(text: 'Profit & Loss'),
                      Tab(text: 'Balance Sheet'),
                      Tab(text: 'Cash Flow'),
                    ],
                  ),
                ),
                Obx(() {
                  final isDashboard = finincialTabController.currentIndex.value == 0;
                  if (!isDashboard) return const SizedBox.shrink();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _pickDateRange,
                        child: Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF061D45),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF153B73)),
                          ),
                          child: GetBuilder<FinancialReportController>(
                            tag: getCurrentOrganization!.id.toString(),
                            builder: (_) => Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFFB2C4E5)),
                                const SizedBox(width: 6),
                                Text(
                                  _dateRangeLabel,
                                  style: const TextStyle(
                                    color: Color(0xFFD7E5FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFFB2C4E5)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _openExportMenu,
                        child: Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF061D45),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFC72B).withValues(alpha: 0.55)),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Export',
                                style: TextStyle(
                                  color: Color(0xFFFFD766),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFFFFD766)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: finincialTabController.tabController,
              children: const [
                FinancialDashboardTab(),
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
