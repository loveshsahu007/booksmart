import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/helpers/map_indexed_extension.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:booksmart/modules/user/ui/transaction/receipt_scanning_output_screen.dart';

import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'package:booksmart/modules/user/controllers/financial_report_controller.dart';
import 'package:intl/intl.dart';

import '../financial_statement.dart';

class FinancialDashboardTab extends StatelessWidget {
  const FinancialDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = colorScheme.surfaceContainerHighest;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;

    double thisScreenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: colorScheme.primary.withValues(alpha: 0.7),
        tooltip: "Snap Receipt",
        onPressed: openReceiptScanner,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
      body: GetBuilder<FinancialReportController>(
        tag: getCurrentOrganization!.id.toString(),
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final numFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
          final profitStr = numFormat.format(controller.netIncome.value);
          final expenseStr = numFormat.format(controller.totalExpenses.value);
          final cashflowStr = numFormat.format(controller.netIncome.value);
          
          double opMargin = 0;
          if (controller.totalIncome.value > 0) {
             opMargin = (controller.netOperatingIncome.value / controller.totalIncome.value) * 100;
          }
          final opMarginStr = "${opMargin.toStringAsFixed(1)}%";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Gauge Section
                SizedBox(height: 220, child: _getRadialGauge(isDark, controller.businessStrengthScore.value)),

                AppText(
                  "Business Strength",
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    runSpacing: thisScreenWidth > 1000
                        ? thisScreenWidth * 0.02
                        : thisScreenWidth * 0.04,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      metricCard(
                        context,
                        title: "Profit (Net Income)",
                        value: profitStr,
                        icon: Icons.arrow_upward_rounded,
                        iconColor: Colors.green,
                        trendText: "Calculated from Plaid",
                        sparklineData: controller.monthlyData.map((e) => (e["income"] ?? 0.0) - (e["expense"] ?? 0.0)).toList(),
                        onTap: () {
                          if (Get.isRegistered<FinincialTabController>()) {
                            Get.find<FinincialTabController>().changeTab(1);
                          }
                        },
                      ),
                      metricCard(
                        context,
                        title: "Expenses",
                        value: expenseStr,
                        icon: Icons.arrow_downward,
                        iconColor: Colors.red,
                        trendText: "Total outflows",
                        sparklineData: controller.monthlyData.map((e) => e["expense"] ?? 0.0).toList(),
                        onTap: () {
                          showSnackBar("Need Discussion");
                        },
                      ),
                      metricCard(
                        context,
                        title: "Cashflow",
                        value: cashflowStr,
                        icon: Icons.thumb_up_outlined,
                        iconColor: Colors.green,
                        trendText: "Based on net balance",
                        sparklineData: controller.monthlyData.map((e) => (e["income"] ?? 0.0) - (e["expense"] ?? 0.0)).toList(),
                        onTap: () {
                          if (Get.isRegistered<FinincialTabController>()) {
                            Get.find<FinincialTabController>().changeTab(3);
                          }
                        },
                      ),
                      metricCard(
                        context,
                        title: "Debt-to-Equity",
                        value: controller.debtToEquity.toStringAsFixed(2),
                        icon: Icons.account_balance_outlined,
                        iconColor: controller.debtToEquity > 2 ? Colors.red : Colors.green,
                        trendText: "Ratio (Liab/Equity)",
                        onTap: () {
                          if (Get.isRegistered<FinincialTabController>()) {
                             Get.find<FinincialTabController>().changeTab(3);
                          }
                        },
                      ),
                         metricCard(
                        context,
                        title: "Tax Deduction",
                        value: numFormat.format(controller.totalTaxDeductions.value),
                        icon: Icons.trending_up,
                        iconColor: Colors.orange,
                        trendText: "Deductible transactions",
                        onTap: () {},
                      ),
                      metricCard(
                        context,
                        title: "Operating Margin",
                        value: opMarginStr,
                        icon: Icons.arrow_upward,
                        iconColor: Colors.green,
                        trendText: "Derived metric",
                        onTap: () {
                          showSnackBar("Need Discussion");
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                /// Quick Insights
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      AppText(
                        'Quick AI Insights',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      ...controller.aiInsights.mapIndexed(
                        (e, index) => _insightText(e, textSecondary, index + 1),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// Options Grid
                _optionsGrid(cardColor, textPrimary),
                const SizedBox(height: 60),
              ],
            ),
          );
        }
      ),
    );
  }

  // =======================
  // Components and Widgets
  // =======================

  Widget _insightText(String title, Color color, int index) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedText('$index.', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 5),
                  Expanded(
                    child: AppText(
                      title,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(5),
          width: 70,
          decoration: BoxDecoration(
            color: Get.theme.primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: AppText(
            "Action",
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _optionsGrid(Color cardColor, Color textColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 4 / 1.6,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _menuCard(
              Icons.credit_card,
              "Transactions",
              cardColor,
              textColor,
              () {
                if (Get.isRegistered<FinincialTabController>()) {
                  Get.find<FinincialTabController>().changeTab(1);
                }
              },
            ),
            _menuCard(
              Icons.security,
              "Dun & Bradstreet",
              cardColor,
              textColor,
              () {
                // navigate to
              },
            ),
            _menuCard(Icons.pie_chart, "Reports", cardColor, textColor, () {
              if (Get.isRegistered<FinincialTabController>()) {
                Get.find<FinincialTabController>().changeTab(2);
              }
            }),
            _menuCard(
              Icons.account_balance,
              "Accounts",
              cardColor,
              textColor,
              () {
                if (Get.isRegistered<FinincialTabController>()) {
                   Get.find<FinincialTabController>().changeTab(3);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _menuCard(
    IconData icon,
    String title,
    Color cardColor,
    Color textColor,
    Function()? onTap,
  ) {
    return InkWell(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30),
                const SizedBox(width: 6),
                Expanded(
                  child: AppText(
                    title,
                    textAlign: TextAlign.center,
                    fontSize: 14,

                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getRadialGauge(bool isDark, double pointerValue) {
    String status = "Weak";
    if (pointerValue > 80) {
      status = "Excellent";
    } else if (pointerValue > 60) status = "Good";
    else if (pointerValue > 40) status = "Fair";
    else if (pointerValue > 20) status = "Medium";

    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 100,
          radiusFactor: 1,
          axisLineStyle: AxisLineStyle(
            thickness: 15,
            cornerStyle: CornerStyle.bothCurve,
            gradient: SweepGradient(
              colors: const [
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.greenAccent,
                Colors.green,
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),

          annotations: [
            GaugeAnnotation(
              verticalAlignment: GaugeAlignment.center,
              widget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedText(
                    '${pointerValue.toInt()}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  AppText(status, fontSize: 16, fontWeight: FontWeight.w500),
                ],
              ),
            ),
            GaugeAnnotation(
              verticalAlignment: GaugeAlignment.near,
              widget: Column(
                children: [
                  SizedBox(height: 50),
                  AppText(DateFormat('MMM dd, yyyy').format(DateTime.now()), fontSize: 10, color: Colors.grey),
                ],
              ),
              // angle: 45,

              // angle: pointerValue,
            ),
          ],
        ),
      ],
    );
  }
}

Widget metricCard(
  BuildContext context, {
  required String title,
  required String value,
  required IconData icon,
  required Color iconColor,
  required String trendText,
  List<double>? sparklineData,
  void Function()? onTap,
}) {
  double thisScreenWidth = MediaQuery.sizeOf(context).width;

  final colorScheme = Theme.of(context).colorScheme;
  return FractionallySizedBox(
    widthFactor: thisScreenWidth > 1000 ? 0.32 : 0.48,
    child: Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText(
                title,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              const SizedBox(height: 7),
              AppText(
                value,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              const SizedBox(height: 10),
              if (sparklineData != null && sparklineData.isNotEmpty)
                SizedBox(
                  height: 30,
                  width: double.infinity,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: sparklineData
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          color: iconColor,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: iconColor.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 7),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 16),
                  const SizedBox(width: 3),
                  AppText(
                    trendText,
                    fontSize: 13,
                    color: Get.isDarkMode ? Colors.grey : Colors.black54,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
