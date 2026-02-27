import 'dart:async';
import 'package:booksmart/widgets/date_range_picker.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:booksmart/constant/exports.dart';

class AIDeductionPage extends StatefulWidget {
  const AIDeductionPage({super.key});

  @override
  State<AIDeductionPage> createState() => _AIDeductionPageState();
}

class _AIDeductionPageState extends State<AIDeductionPage> {
  final List<CategoryData> _categories = [];
  final Map<String, GlobalKey> _categoryKeys = {};
  final ScrollController _accordionScroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _search = '';
  final DateTimeRange _activeRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 90)),
    end: DateTime.now(),
  );
  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    _seedDummyData();
    _searchCtrl.addListener(_onSearchChanged);
  }

  /// Rule for business meal:

  void _seedDummyData() {
    final now = DateTime.now();
    final cats = [
      CategoryData(
        id: 'business_meals',
        name: 'Business Meals',
        transactions: [
          Tx(
            merchant: 'Central Cafe',
            date: now.subtract(const Duration(days: 12)),
            amount: 150.0,
            hasReceipt: true,
          ),
          Tx(
            merchant: 'John\'s Diner',
            date: now.subtract(const Duration(days: 27)),
            amount: 220.5,
          ),
          Tx(
            merchant: 'Italian Bistro',
            date: now.subtract(const Duration(days: 40)),
            amount: 310.0,
            hasReceipt: true,
          ),
          Tx(
            merchant: 'Foodies Hub',
            date: now.subtract(const Duration(days: 60)),
            amount: 180.0,
          ),
        ],
      ),
      CategoryData(
        id: 'utilities',
        name: 'Utilities',
        transactions: [
          Tx(
            merchant: 'Power Co',
            date: now.subtract(const Duration(days: 20)),
            amount: 120.0,
          ),
          Tx(
            merchant: 'Water Works',
            date: now.subtract(const Duration(days: 50)),
            amount: 95.5,
            hasReceipt: true,
          ),
          Tx(
            merchant: 'FiberNet',
            date: now.subtract(const Duration(days: 35)),
            amount: 60.0,
          ),
        ],
      ),
      CategoryData(
        id: 'office_supplies',
        name: 'Office Supplies',
        transactions: [
          Tx(
            merchant: 'BestBuy',
            date: now.subtract(const Duration(days: 15)),
            amount: 420.0,
          ),
          Tx(
            merchant: 'Staples',
            date: now.subtract(const Duration(days: 55)),
            amount: 150.0,
            hasReceipt: true,
          ),
        ],
      ),
      CategoryData(
        id: 'travel',
        name: 'Travel',
        transactions: [
          Tx(
            merchant: 'Uber',
            date: now.subtract(const Duration(days: 10)),
            amount: 45.0,
          ),
          Tx(
            merchant: 'Airbnb',
            date: now.subtract(const Duration(days: 30)),
            amount: 300.0,
            hasReceipt: true,
          ),
          Tx(
            merchant: 'Fuel Station',
            date: now.subtract(const Duration(days: 5)),
            amount: 80.0,
          ),
        ],
      ),
      CategoryData(
        id: 'advertising',
        name: 'Advertising',
        transactions: [
          Tx(
            merchant: 'Facebook Ads',
            date: now.subtract(const Duration(days: 25)),
            amount: 600.0,
            hasReceipt: true,
          ),
          Tx(
            merchant: 'Google Ads',
            date: now.subtract(const Duration(days: 70)),
            amount: 850.0,
          ),
        ],
      ),
      CategoryData(
        id: 'subscriptions',
        name: 'Software Subscriptions',
        transactions: [
          Tx(
            merchant: 'Adobe',
            date: now.subtract(const Duration(days: 22)),
            amount: 55.0,
          ),
          Tx(
            merchant: 'Canva Pro',
            date: now.subtract(const Duration(days: 45)),
            amount: 25.0,
          ),
          Tx(
            merchant: 'ChatGPT Plus',
            date: now.subtract(const Duration(days: 5)),
            amount: 20.0,
            hasReceipt: true,
          ),
        ],
      ),
      CategoryData(
        id: 'maintenance',
        name: 'Maintenance & Repairs',
        transactions: [
          Tx(
            merchant: 'IT Fixers',
            date: now.subtract(const Duration(days: 33)),
            amount: 270.0,
            hasReceipt: true,
          ),
          Tx(
            merchant: 'Plumber Joe',
            date: now.subtract(const Duration(days: 44)),
            amount: 180.0,
          ),
        ],
      ),
    ];
    _categories.addAll(cats);
    for (var c in _categories) {
      _categoryKeys[c.id] = GlobalKey();
      c.expanded = false;
    }
  }

  Color _colorFor(String id, ThemeData theme) {
    final palette = [
      const Color(0xFF19C37D),
      const Color(0xFF0077CC),
      const Color(0xFFF2C94C),
      const Color(0xFF6C5CE7),
      const Color(0xFF3B82F6),
      const Color(0xFFFF7A7A),
      theme.colorScheme.primary,
    ];
    final idx = id.hashCode.abs() % palette.length;
    return palette[idx];
  }

  Map<String, double> _computeTotals() {
    final Map<String, double> map = {};
    for (var c in _categories) {
      final tot = c.transactions
          .where((t) => _isInRange(t.date, _activeRange))
          .where((t) => _matchesSearch(c, t))
          .fold<double>(0.0, (s, t) => s + t.amount);
      if (tot > 0) map[c.name] = tot;
    }
    return map;
  }

  bool _isInRange(DateTime d, DateTimeRange r) =>
      !d.isBefore(r.start) && !d.isAfter(r.end);

  bool _matchesSearch(CategoryData cat, Tx t) {
    if (_search.trim().isEmpty) return true;
    final q = _search.toLowerCase();
    return cat.name.toLowerCase().contains(q) ||
        t.merchant.toLowerCase().contains(q) ||
        _formatCurrency(t.amount).toLowerCase().contains(q);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() => _search = _searchCtrl.text);
    });
  }

  void _removeTx(String catId, Tx tx) {
    final cat = _categories.firstWhere(
      (c) => c.id == catId,
      orElse: () => CategoryData.empty(),
    );
    if (cat.isEmpty) return;
    setState(() {
      cat.transactions.remove(tx);
      lastUpdated = DateTime.now();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _accordionScroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totals = _computeTotals();
    final overall = totals.values.fold<double>(0.0, (a, b) => a + b);

    final ordered = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final pieMap = Map<String, double>.fromEntries(
      ordered.isEmpty ? [MapEntry('No data', 1.0)] : ordered,
    );

    final colorList = ordered.isEmpty
        ? [colorScheme.primary]
        : ordered.map((e) {
            final cat = _categories.firstWhere(
              (c) => c.name == e.key,
              orElse: () => CategoryData.empty(),
            );
            return _colorFor(cat.id, theme);
          }).toList();

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    hintText: 'Search categories',
                    controller: _searchCtrl,
                    suffixWidget: Icon(Icons.search),
                  ),
                ),
                const SizedBox(width: 12),
                DateRangePickerWidget(
                  onDateRangeSelected: (start, end) {},
                  initialText: "Select Date Range",
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 20,
                  ),
                ),
              ],
            ),
          ),
          // chart + legend + list
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),

                    child: PieChart(
                      dataMap: pieMap,
                      chartType: ChartType.ring,
                      colorList: colorList,
                      chartRadius: 160,
                      ringStrokeWidth: 32,
                      centerText: 'Total\n${_formatCurrency(overall)}',
                      centerTextStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      chartValuesOptions: const ChartValuesOptions(
                        showChartValues: false,
                      ),
                      legendOptions: const LegendOptions(showLegends: true),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: _buildAccordionList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionList() {
    final visible = _categories.where((c) {
      final anyTxInRange = c.transactions.any(
        (t) => _isInRange(t.date, _activeRange),
      );
      if (!anyTxInRange) return false;
      if (_search.trim().isEmpty) return true;
      final q = _search.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.transactions.any((t) => t.merchant.toLowerCase().contains(q));
    }).toList();

    if (visible.isEmpty) {
      return Center(
        child: AppText(
          'No categories match your search.',
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      itemBuilder: (context, idx) {
        final cat = visible[idx];
        return Padding(
          key: _categoryKeys[cat.id],
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCategoryTile(cat),
        );
      },
    );
  }

  Widget _buildCategoryTile(CategoryData cat) {
    final theme = Theme.of(context);
    final filteredTxs = cat.transactions
        .where(
          (t) => _isInRange(t.date, _activeRange) && _matchesSearch(cat, t),
        )
        .toList();
    final total = filteredTxs.fold<double>(0.0, (s, t) => s + t.amount);
    final color = _colorFor(cat.id, theme);

    return Card(
      color: theme.colorScheme.surfaceVariant,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        key: PageStorageKey(cat.id),
        initiallyExpanded: cat.expanded,
        onExpansionChanged: (v) => setState(() => cat.expanded = v),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        shape: RoundedRectangleBorder(),
        collapsedShape: RoundedRectangleBorder(),
        collapsedBackgroundColor: Colors.transparent,

        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppText(
                cat.name,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            AppText(
              _formatCurrency(total),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        children: [
          _tableHeader(),
          if (filteredTxs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: AppText(
                'No transactions for this category in selected range.',
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            )
          else
            ...filteredTxs.map((t) => _txRow(cat.id, t)),
          _categoryTotalRow(total),
        ],
      ),
    );
  }

  Widget _tableHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      spacing: 3,
      children: const [
        Expanded(
          flex: 4,
          child: FittedText(
            'Merchant',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: FittedText(
            'Date',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: FittedText(
            'Amount',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(width: 30, height: 30),
      ],
    ),
  );

  Widget _categoryTotalRow(double total) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        const Expanded(child: SizedBox()),
        Expanded(
          flex: 2,
          child: AppText(
            "",
            fontSize: 14,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          flex: 2,
          child: AppText(
            _formatCurrency(total),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.left,
            color: orangeColor,
          ),
        ),
      ],
    ),
  );

  Widget _txRow(String catId, Tx tx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 4, child: FittedText(tx.merchant)),
          Expanded(flex: 2, child: FittedText(_formatShortDate(tx.date))),
          Expanded(flex: 2, child: FittedText(_formatCurrency(tx.amount))),
          SizedBox(
            width: 30,
            height: 30,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18),
              padding: EdgeInsetsGeometry.zero,
              itemBuilder: (context) {
                return [
                  const PopupMenuItem<String>(
                    value: "remove",
                    child: Text("Remove"),
                  ),
                  const PopupMenuItem<String>(
                    value: "add",
                    child: Text("Add Receipt"),
                  ),
                  const PopupMenuItem<String>(
                    value: "cancel",
                    child: Text("Cancel"),
                  ),
                ];
              },
              onSelected: (value) {
                switch (value) {
                  case "remove":
                    _removeTx(catId, tx);
                    break;
                  case "add":
                    setState(() => tx.hasReceipt = true);
                    break;
                  case "cancel":
                    // Do nothing
                    break;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double n) => '\$${n.toStringAsFixed(2)}';
  String _formatShortDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class CategoryData {
  final String id;
  final String name;
  final List<Tx> transactions;
  bool expanded;

  CategoryData({
    required this.id,
    required this.name,
    required this.transactions,
    this.expanded = false,
  });

  bool get isEmpty => id.isEmpty;
  static CategoryData empty() =>
      CategoryData(id: '', name: '', transactions: []);
}

class Tx {
  final String merchant;
  final DateTime date;
  final double amount;
  bool hasReceipt;

  Tx({
    required this.merchant,
    required this.date,
    required this.amount,
    this.hasReceipt = false,
  });
}
