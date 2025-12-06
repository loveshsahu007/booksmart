import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:booksmart/modules/user/ui/transaction/receipt_scanning_output_screen.dart';

import '../financial_statement/financial_statement.dart';
import '../home/home_screen.dart';
import '../tax_filling/tax_filling.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
        backgroundColor: colorScheme.primary,
        tooltip: "Snap Receipt",
        onPressed: openReceiptScanner,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Gauge Section
            SizedBox(height: 220, child: _getRadialGauge(isDark)),

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
                    title: "Profit",
                    value: "\$255,000",
                    icon: Icons.arrow_upward_rounded,
                    iconColor: Colors.green,
                    trendText: "12% vs last month",
                    onTap: () {
                      if (kIsWeb) {
                        Get.toNamed(Routes.report);
                      } else {
                        Get.find<BottomNavController>().changePage(2);
                      }
                      if (Get.isRegistered<FinincialTabController>()) {
                        Get.find<FinincialTabController>().changeTab(1);
                      }
                    },
                  ),
                  metricCard(
                    context,
                    title: "Expenses",
                    value: "\$5,000",
                    icon: Icons.arrow_downward,
                    iconColor: Colors.red,
                    trendText: "-5% vs last quarter",
                    onTap: () {
                      showSnackBar("Need Discussion");
                    },
                  ),
                  metricCard(
                    context,
                    title: "Cashflow",
                    value: "\$15,000",
                    icon: Icons.thumb_up_outlined,
                    iconColor: Colors.green,
                    trendText: "Looking good",
                    onTap: () {
                      if (kIsWeb) {
                        Get.toNamed(Routes.report);
                      } else {
                        Get.find<BottomNavController>().changePage(2);
                      }
                      if (Get.isRegistered<FinincialTabController>()) {
                        Get.find<FinincialTabController>().changeTab(3);
                      }
                    },
                  ),
                  // green for down
                  // red for up
                  metricCard(
                    context,
                    title: "Debt-to-Equity",
                    value: "0.5%",
                    icon: Icons.arrow_downward,
                    iconColor: Colors.green,
                    trendText: "Low risk",
                    onTap: () {
                      showSnackBar("Need Discussion");
                    },
                  ),
                  // increase -> green
                  // in-betwen -> orange
                  // decrese -> red
                  metricCard(
                    context,
                    title: "Tax Deduction",
                    value: "\$10,000",
                    icon: Icons.trending_up,
                    iconColor: Colors.orange,
                    trendText: "Stable trend",
                    onTap: () {
                      if (kIsWeb) {
                        Get.toNamed(Routes.tax);
                      } else {
                        Get.find<BottomNavController>().changePage(3);
                      }
                      if (Get.isRegistered<TaxTabController>()) {
                        Get.find<TaxTabController>().changeTab(1);
                      }
                    },
                  ),
                  // strong - green
                  // medium - orange
                  // weak - red
                  metricCard(
                    context,
                    title: "Operating Margin",
                    value: "18%",
                    icon: Icons.arrow_upward,
                    iconColor: Colors.green,
                    trendText: "Strong",
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
                spacing: 8,
                children: [
                  AppText(
                    'Quick Insights',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  ...[
                    Strings.insight1,
                    Strings.insight2,
                  ].map((e) => _insightText(e, textSecondary)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Options Grid
            _optionsGrid(cardColor, textPrimary),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // =======================
  // Components and Widgets
  // =======================

  Widget _insightText(String text, Color color) => AppText(
    text,
    fontSize: 15,
    color: color,
    fontWeight: FontWeight.w400,
    textAlign: TextAlign.left,
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
              "Credit Card",
              cardColor,
              textColor,
              () {
                // navigate to
              },
            ),
            _menuCard(
              Icons.security,
              "Your Coverage",
              cardColor,
              textColor,
              () {
                // navigate to
              },
            ),
            _menuCard(Icons.pie_chart, "Reports", cardColor, textColor, () {
              // navigate to
            }),
            _menuCard(
              Icons.account_balance,
              "Accounts",
              cardColor,
              textColor,
              () {
                // navigate to
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

  Widget _getRadialGauge(bool isDark) {
    const double pointerValue = 80;

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
                  AppText('Good', fontSize: 16, fontWeight: FontWeight.w500),
                ],
              ),
            ),
            GaugeAnnotation(
              verticalAlignment: GaugeAlignment.near,
              widget: Column(
                children: [
                  SizedBox(height: 50),
                  AppText('Feb 25, 2024', fontSize: 10, color: Colors.grey),
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
              const SizedBox(height: 3),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 16),
                  const SizedBox(width: 3),
                  AppText(
                    trendText,
                    fontSize: 14,
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
