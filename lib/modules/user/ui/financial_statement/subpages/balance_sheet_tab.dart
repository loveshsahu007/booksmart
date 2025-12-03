import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/custom_drop_down.dart';
import 'package:booksmart/widgets/date_range_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class BalanceSheetTab extends StatefulWidget {
  const BalanceSheetTab({super.key});

  @override
  State<BalanceSheetTab> createState() => _BalanceSheetTabState();
}

class _BalanceSheetTabState extends State<BalanceSheetTab> {
  DateTime selectedDate = DateTime(2025, 9, 30);
  String selectedFilter = "All Accounts";

  // For collapsible sections
  final Map<String, bool> expandedSections = {
    "Assets": true,
    "Liabilities": true,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Header Row (Filter + Export + Upload)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Filter icon button
              IconButton(
                onPressed: () => _openFilters(context),
                icon: const Icon(Icons.filter_list, color: orangeColor),
              ),
              Row(
                children: [
                  _outlineButton("Export CSV", onPressed: () {}),
                  const SizedBox(width: 8),
                  _fillButton("Upload Balance Sheet", onPressed: () {}),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// 🔹 Central Summary
          Center(
            child: Column(
              children: [
                AppText(
                  "As of ${_formatDate(selectedDate)}",
                  fontSize: 14,
                  color: Colors.white70,
                ),
                const SizedBox(height: 8),
                const AppText(
                  "Assets: \$10,000  |  Liabilities: \$10,000",
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// 🔹 Ratio Visualization (Gauge)
          SizedBox(
            height: 180,
            child: SfRadialGauge(
              axes: [
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: AxisLineStyle(
                    thickness: 15,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  ranges: [
                    GaugeRange(startValue: 0, endValue: 50, color: greenColor),
                    GaugeRange(
                      startValue: 50,
                      endValue: 100,
                      color: Color(0xFFE53935),
                    ),
                  ],
                  pointers: const [
                    NeedlePointer(
                      value: 50,
                      needleColor: orangeColor,
                      knobStyle: KnobStyle(color: orangeColor),
                    ),
                  ],
                  annotations: const [
                    GaugeAnnotation(
                      widget: AppText(
                        "50%",
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: orangeColor,
                      ),
                      angle: 90,
                      positionFactor: 0.8,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// 🔹 Expandable Assets Section
          _collapsibleSection("Assets", isDark, [
            _item("Cash & Bank Accounts", "\$3,000", [
              {"title": "Main Bank", "amount": "\$1,800"},
              {"title": "Savings Account", "amount": "\$1,200"},
            ]),
            _item("Investments", "\$2,000", [
              {"title": "Stocks", "amount": "\$1,200"},
              {"title": "Mutual Funds", "amount": "\$800"},
            ]),
            _item("Accounts Receivable", "\$1,000", [
              {"title": "Client A", "amount": "\$600"},
              {"title": "Client B", "amount": "\$400"},
            ]),
            _item("Property & Equipment", "\$4,000", [
              {"title": "Office Equipment", "amount": "\$1,200"},
              {"title": "Building", "amount": "\$2,800"},
            ]),
          ], color: greenColor),

          const SizedBox(height: 16),

          /// 🔹 Expandable Liabilities Section
          _collapsibleSection("Liabilities", isDark, [
            _item("Credit Card", "\$1,000", [
              {"title": "Business Visa", "amount": "\$1,000"},
            ]),
            _item("Business Loans", "\$2,000", [
              {"title": "Loan 1", "amount": "\$1,200"},
              {"title": "Loan 2", "amount": "\$800"},
            ]),
            _item("Taxes Owed", "\$1,500", [
              {"title": "Quarterly Taxes", "amount": "\$1,500"},
            ]),
          ], color: Color(0xFFE53935)),
        ],
      ),
    );
  }

  /// 🔹 Collapsible Section (Assets / Liabilities)
  Widget _collapsibleSection(
    String title,
    bool isDark,
    List<Widget> children, {
    required Color color,
  }) {
    final isExpanded = expandedSections[title] ?? false;
    return Card(
      child: ExpansionTile(
        shape: RoundedRectangleBorder(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        initiallyExpanded: isExpanded,
        iconColor: color,
        collapsedIconColor: color,
        title: AppText(
          title,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        onExpansionChanged: (expanded) {
          setState(() => expandedSections[title] = expanded);
        },
        children: children,
      ),
    );
  }

  /// 🔹 Item Row + Optional Children
  Widget _item(
    String title,
    String amount,
    List<Map<String, String>> children,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(title, fontSize: 15, fontWeight: FontWeight.w500),
              AppText(amount, fontSize: 15, fontWeight: FontWeight.w600),
            ],
          ),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(child['title']!, fontSize: 13),
                  AppText(child['amount']!, fontSize: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Yellow Outline Button
  Widget _outlineButton(String text, {required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: orangeColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        foregroundColor: orangeColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: AppText(
        text.toUpperCase(),
        color: orangeColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// 🔹 Yellow Fill Button
  Widget _fillButton(String text, {required VoidCallback onPressed}) {
    return AppButton(
      buttonText: text.toUpperCase(),
      onTapFunction: onPressed,
      fontSize: 12,
      radius: 8,
    );
  }

  /// 🔹 Custom Filter Bottom Sheet
  void _openFilters(BuildContext context) {
    final accountTypeDropdownKey = GlobalKey<DropdownSearchState<String>>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppText(
              "Filter Balance Sheet",
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 16),
            DateRangePickerWidget(
              onDateRangeSelected: (start, end) {},
              initialText: "Select Date Range",
            ),
            const SizedBox(height: 16),
             
            CustomDropDownWidget<String>(
              selectedItem: selectedFilter,
              dropDownKey: accountTypeDropdownKey,
              label: "Account Type",
              items: ["All Accounts", "Cash", "Investments", "Loans"],
            ),
            const SizedBox(height: 20),
            _fillButton(
              "Apply Filters",
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// 🔹 Format date (e.g. Sep 30, 2025)
  String _formatDate(DateTime date) {
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }
}
