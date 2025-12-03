import 'package:booksmart/constant/strings.dart';
import 'package:booksmart/widgets/app_text.dart';
import 'package:booksmart/widgets/date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CashFlowTab extends StatefulWidget {
  const CashFlowTab({super.key});

  @override
  State<CashFlowTab> createState() => _CashFlowTabState();
}

class _CashFlowTabState extends State<CashFlowTab> {
  bool showOperating = true;
  bool showInvesting = true;
  bool showFinancing = true;

  final data = [
    {"month": "Jan", "in": 16000, "out": 9000, "isForecast": false},
    {"month": "Feb", "in": 14000, "out": 8000, "isForecast": false},
    {"month": "Mar", "in": 18000, "out": 12000, "isForecast": false},
    {"month": "Apr", "in": 15000, "out": 9000, "isForecast": false},
    {"month": "May", "in": 13000, "out": 11000, "isForecast": false},
    {"month": "Jun", "in": 12000, "out": 10000, "isForecast": false},
    {"month": "Jul", "in": 17000, "out": 13000, "isForecast": false},
    {"month": "Aug", "in": 19000, "out": 14000, "isForecast": false},
    {"month": "Sep", "in": 21000, "out": 16000, "isForecast": false},
    {"month": "Oct", "in": 20000, "out": 15000, "isForecast": true},
    {"month": "Nov", "in": 18000, "out": 13000, "isForecast": true},
    {"month": "Dec", "in": 15000, "out": 11000, "isForecast": true},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const moneyInColor = Color(0xFF19C37D);
    const moneyOutColor = Color(0xFF3B82F6);
    const accentColor = Color(0xFFF2C94C);
    //final panelColor = isDark ? Color(0xFF0F1E37) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    final asOfDate = DateTime(2025, 9, 30);
    final totalIn = data.fold<int>(0, (sum, e) => sum + (e["in"] as int));
    final totalOut = data.fold<int>(0, (sum, e) => sum + (e["out"] as int));
    final totalCashFlow = totalIn - totalOut;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Header (Date range + Export)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DateRangePickerWidget(
                onDateRangeSelected: (start, end) {},
                initialText: "Custom Range",
                initialStartDate: DateTime(2024, 1, 1),
                initialEndDate: DateTime(2024, 12, 31),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: accentColor),
                ),
                onPressed: () {},
                child: const AppText(
                  "Export CSV",
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// 🔹 KPI Row + Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                "Cash Flow as of ${asOfDate.day}-${asOfDate.month}-${asOfDate.year}",
                color: textPrimary,
                fontSize: 16,
              ),
              Row(
                children: const [
                  _LegendDot(color: moneyInColor, label: "Money In"),
                  SizedBox(width: 12),
                  _LegendDot(color: moneyOutColor, label: "Money Out"),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// 🔹 Bar Chart
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, meta) => AppText(
                        "${v ~/ 1000}K",
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final index = v.toInt();
                        if (index >= 0 && index < data.length) {
                          return AppText(
                            data[index]["month"].toString(),
                            color: textSecondary,
                            fontSize: 12,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(data.length, (i) {
                  final e = data[i];
                  final isForecast = e["isForecast"] as bool;
                  final moneyIn = (e["in"] as int).toDouble();
                  final moneyOut = (e["out"] as int).toDouble();

                  return BarChartGroupData(
                    x: i,
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                        toY: moneyIn,
                        color: isForecast
                            ? moneyInColor.withValues(alpha: 0.4)
                            : moneyInColor,
                        width: 7,
                      ),
                      BarChartRodData(
                        toY: moneyOut,
                        color: isForecast
                            ? moneyOutColor.withValues(alpha: 0.4)
                            : moneyOutColor,
                        width: 7,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 24),

          /// 🔹 Collapsible Sections
          buildCollapsibleSection(
            title: Strings.operating,
            color: moneyInColor,
            expanded: showOperating,
            onTap: () => setState(() => showOperating = !showOperating),
            rows: [
              buildRow("Net Income", 47000, textSecondary),
              buildRow("Adjustments", -6000, textSecondary),
              buildRow("Changes in Working Capital", -10000, textSecondary),
              buildTotalRow("Operating Cash Flow", 31000, moneyInColor),
            ],
          ),
          buildCollapsibleSection(
            title: Strings.investing,
            color: moneyOutColor,
            expanded: showInvesting,
            onTap: () => setState(() => showInvesting = !showInvesting),
            rows: [
              buildRow("Fixed Asset Purchases", -8000, textSecondary),
              buildRow("Other Investments", 0, textSecondary),
              buildTotalRow("Investing Cash Flow", -8000, moneyOutColor),
            ],
          ),
          buildCollapsibleSection(
            title: Strings.financing,
            color: accentColor,
            expanded: showFinancing,
            onTap: () => setState(() => showFinancing = !showFinancing),
            rows: [
              buildRow("Owner’s Contributions", 5000, textSecondary),
              buildRow("Loan Payments", 0, textSecondary),
              buildTotalRow("Financing Cash Flow", 5000, accentColor),
            ],
          ),

          const SizedBox(height: 16),

          /// 🔹 Total Cash Flow Summary
          buildTotalRow(
            "Total Cash Flow",
            totalCashFlow,
            totalCashFlow >= 0 ? moneyInColor : moneyOutColor,
          ),
        ],
      ),
    );
  }

  Widget buildCollapsibleSection({
    required String title,
    required Color color,
    required bool expanded,
    required VoidCallback onTap,
    required List<Widget> rows,
  }) {
    return Card(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F1E37)
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          ListTile(
            title: AppText(
              title,
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            trailing: Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: color,
            ),
            onTap: onTap,
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: rows),
            ),
        ],
      ),
    );
  }

  Widget buildRow(String label, int value, Color textSecondary) {
    final textColor = value < 0 ? const Color(0xFF3B82F6) : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(label, color: textSecondary, fontSize: 14),
          AppText(_formatCurrency(value), color: textColor),
        ],
      ),
    );
  }

  Widget buildTotalRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            label,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          AppText(
            _formatCurrency(value),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int value) {
    final absValue = value.abs();
    final formatted = absValue.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return value < 0 ? '-\$$formatted' : '\$$formatted';
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        AppText(
          label,
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 12,
        ),
      ],
    );
  }
}
