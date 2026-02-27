import 'package:booksmart/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:booksmart/constant/app_colors.dart';
import 'package:booksmart/widgets/app_text.dart';
import 'package:booksmart/widgets/date_range_picker.dart';
import 'package:booksmart/constant/strings.dart';
import 'package:get/get.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  // Sample monthly income & expenses data
  final List<Map<String, double>> _monthlyData = [
    {'income': 12, 'expense': 9},
    {'income': 15, 'expense': 11},
    {'income': 18, 'expense': 15},
    {'income': 22, 'expense': 18},
    {'income': 17, 'expense': 13},
    {'income': 25, 'expense': 19},
    {'income': 23, 'expense': 16},
    {'income': 20, 'expense': 15},
    {'income': 24, 'expense': 18},
  ];

  // Collapsible sections
  final Map<String, bool> expandedSections = {
    "Income": false,
    "COGS": false,
    "Expenses": false,
    "Other Income": false,
    "Other Expenses": false,
  };

  double get maxY {
    double maxVal = 0;
    for (final item in _monthlyData) {
      maxVal = [
        maxVal,
        item['income'] ?? 0,
        item['expense'] ?? 0,
      ].reduce((a, b) => a > b ? a : b);
    }
    return (maxVal / 10).ceil() * 10; // Round up to nearest 10
  }

  @override
  Widget build(BuildContext context) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Header Row (Filter + Export + Upload)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Filter (Date Picker)
              DateRangePickerWidget(
                onDateRangeSelected: (start, end) {},
                initialText: "Filter",
              ),

              Row(
                children: [
                  _outlineButton("Export CSV", onPressed: () {}),
                  const SizedBox(width: 8),
                  _outlineButton(
                    "Upload P&L",
                    onPressed: () {
                      Get.toNamed(Routes.tax);
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 30),

          /// 🔹 Profitability Section
          Center(
            child: Column(
              children: [
                const AppText(
                  "Net Income Jan 1 – Sep 30, 2025",
                  fontSize: 14,
                  color: Colors.white70,
                ),
                const SizedBox(height: 6),
                const AppText(
                  "\$28,450",
                  fontSize: 30,
                  color: greenColor,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.arrow_upward, color: greenColor, size: 18),
                    AppText(
                      "5.3% ",
                      color: greenColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    AppText(
                      "from last month",
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// 🔹 Dual Bar Chart
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                maxY: maxY,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, _) {
                        return AppText(
                          "\$${value.toInt()}K",
                          fontSize: 10,
                          color: Colors.white70,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        final month = i < Strings.months.length
                            ? Strings.months[i]
                            : "M${i + 1}";
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: AppText(
                            month,
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups: _monthlyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final income = entry.value['income']!;
                  final expense = entry.value['expense']!;
                  return BarChartGroupData(
                    x: index,
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                        toY: income,
                        color: greenColor,
                        width: 12,
                      ),
                      BarChartRodData(
                        toY: expense,
                        color: Colors.blueAccent,
                        width: 12,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 30),

          /// 🔹 Collapsible Sections
          _collapsibleSection("Income", [
            _subItem("Sales", "\$9,500"),
            _subItem("Rental Income", "\$2,000"),
          ]),
          _collapsibleSection("COGS", [
            _subItem("Raw Materials", "\$3,500"),
            _subItem("Production Costs", "\$1,200"),
          ]),
          _staticRow("Gross Profit", "\$6,800", color: greenColor),
          _collapsibleSection("Expenses", [
            _subItem("Meals & Entertainment", "\$2,200"),
            _subItem("Travel", "\$1,800"),
          ]),
          _staticRow("Net Operating Income", "\$2,800", color: greenColor),
          _collapsibleSection("Other Income", [
            _subItem("Investments", "\$500"),
          ]),
          _collapsibleSection("Other Expenses", [
            _subItem("Miscellaneous", "\$200"),
          ]),
          _staticRow("Net Other Income", "\$300", color: greenColor),
          const Divider(color: Colors.white24),
          _staticRow("Net Income", "\$3,100", color: greenColor),
        ],
      ),
    );
  }

  /// 🔹 Outline button builder (for Filter/Export/Upload)
  Widget _outlineButton(String text, {required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: orangeColor, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: AppText(
        text.toUpperCase(),
        color: orangeColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// 🔹 Collapsible section builder
  Widget _collapsibleSection(String title, List<Widget> children) {
    //  final isExpanded = expandedSections[title] ?? false;
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        backgroundColor: Colors.transparent,
        title: AppText(title, fontSize: 14, fontWeight: FontWeight.bold),
        onExpansionChanged: (expanded) {
          setState(() => expandedSections[title] = expanded);
        },
        children: children,
      ),
    );
  }

  /// 🔹 Sub-item under collapsible section
  Widget _subItem(String title, String amount) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(title, fontSize: 13, color: Colors.white70),
          AppText(amount, fontSize: 13, color: Colors.white70),
        ],
      ),
    );
  }

  /// 🔹 Static summary row
  Widget _staticRow(String title, String amount, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            title,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          AppText(
            amount,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ],
      ),
    );
  }
}
