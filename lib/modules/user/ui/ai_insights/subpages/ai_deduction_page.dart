import 'dart:async';
import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/helpers/currency_formatter.dart';
import 'package:booksmart/models/category.dart';
import 'package:booksmart/models/transaction_model.dart';
import 'package:booksmart/modules/admin/controllers/category_controler.dart';
import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'package:booksmart/modules/user/controllers/transaction_controller.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/utils/supabase.dart';
import 'package:booksmart/widgets/confirmation_dialog.dart';
import 'package:booksmart/widgets/date_range_picker.dart';
import 'package:get/get.dart';
import 'package:pie_chart/pie_chart.dart';
import 'dart:developer' as dev;

class AIDeductionPage extends StatefulWidget {
  const AIDeductionPage({super.key});

  @override
  State<AIDeductionPage> createState() => _AIDeductionPageState();
}

class _AIDeductionPageState extends State<AIDeductionPage> {
  late CategoryAdminController _catCtrl;
  late TransactionController _txCtrl;

  final Map<int, bool> _expandedCats = {};
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _search = '';

  DateTimeRange _activeRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 365)),
    end: DateTime.now(),
  );

  bool _isLoading = false;
  final Map<int, List<TransactionModel>> _txBySubCat = {};
  final Map<int, double> _subCatTotals = {};
  final Map<int, double> _parentCatTotals = {};

  @override
  void initState() {
    super.initState();

    // Register or find CategoryAdminController
    if (Get.isRegistered<CategoryAdminController>()) {
      _catCtrl = Get.find<CategoryAdminController>();
    } else {
      _catCtrl = Get.put(CategoryAdminController());
    }

    final tag = getCurrentOrganization!.id.toString();
    if (Get.isRegistered<TransactionController>(tag: tag)) {
      _txCtrl = Get.find<TransactionController>(tag: tag);
    } else {
      _txCtrl = Get.put(TransactionController(), tag: tag);
    }

    _loadData();
    _searchCtrl.addListener(_onSearchChanged);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (_catCtrl.categories.isEmpty) {
        await _catCtrl.fetchAll();
      }

      final res = await supabase
          .from(SupabaseTable.transaction)
          .select()
          .eq('org_id', getCurrentOrganization!.id)
          .gte('date_time', _activeRange.start.toIso8601String().split('T')[0])
          .lte('date_time', _activeRange.end.toIso8601String().split('T')[0]);

      final List<TransactionModel> fetched = (res as List)
          .map((e) => TransactionModel.fromJson(e))
          .toList();

      _processTransactions(fetched);
    } catch (e) {
      dev.log("Error loading AI Deduction data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _processTransactions(List<TransactionModel> txs) {
    _txBySubCat.clear();
    _subCatTotals.clear();
    _parentCatTotals.clear();

    for (var tx in txs) {
      if (tx.category == null || tx.subcategory == null) continue;

      _txBySubCat.putIfAbsent(tx.subcategory!, () => []).add(tx);

      final amt = tx.amount.abs();
      _subCatTotals[tx.subcategory!] =
          (_subCatTotals[tx.subcategory!] ?? 0) + amt;
      _parentCatTotals[tx.category!] =
          (_parentCatTotals[tx.category!] ?? 0) + amt;
    }
  }

  Map<String, double> _computePieData() {
    final Map<String, double> map = {};
    for (var cat in _catCtrl.categories) {
      final total = _parentCatTotals[cat.id] ?? 0;
      if (total > 0) {
        if (_search.isEmpty ||
            cat.name.toLowerCase().contains(_search.toLowerCase())) {
          map[cat.name] = total;
        }
      }
    }
    return map;
  }

  Color _colorFor(int id, ThemeData theme) {
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

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() => _search = _searchCtrl.text);
    });
  }

  Future<void> _removeTx(int txId) async {
    await showConfirmationDialog(
      title: 'Remove Transaction',
      description:
          'Are you sure you want to remove this transaction from this subcategory?',
      onYes: () async {
        Get.back(); // Close dialog
        await _txCtrl.deleteTransaction(txId);
        _loadData();
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final pieData = _computePieData();
    final overall = pieData.values.fold<double>(0.0, (a, b) => a + b);

    final ordered = pieData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final pieMap = Map<String, double>.fromEntries(
      ordered.isEmpty ? [MapEntry('No data', 1.0)] : ordered,
    );

    final colorList = ordered.isEmpty
        ? [colorScheme.primary]
        : ordered.map((e) {
            final cat = _catCtrl.categories.firstWhereOrNull(
              (c) => c.name == e.key,
            );
            return _colorFor(cat?.id ?? 0, theme);
          }).toList();

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            height: 70,
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    hintText: 'Search merchant or category',
                    controller: _searchCtrl,
                    suffixWidget: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(width: 12),
                DateRangePickerWidget(
                  onDateRangeSelected: (start, end) {
                    setState(() {
                      _activeRange = DateTimeRange(start: start, end: end);
                    });
                    _loadData();
                  },
                  initialText: "Select Date Range",
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 20,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: _isLoading
                        ? const SizedBox(
                            height: 160,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : PieChart(
                            dataMap: pieMap,
                            chartType: ChartType.ring,
                            colorList: colorList,
                            chartRadius: 160,
                            ringStrokeWidth: 32,
                            centerWidget: Text(
                              'Total\n${_formatCurrency(overall)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            chartValuesOptions: const ChartValuesOptions(
                              showChartValues: false,
                            ),
                            legendOptions: const LegendOptions(
                              showLegends: true,
                            ),
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
                    child: _isLoading
                        ? const SizedBox()
                        : _buildAccordionList(),
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
    final visibleParents = _catCtrl.categories.where((c) {
      final total = _parentCatTotals[c.id] ?? 0;
      if (total <= 0) return false;
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      if (c.name.toLowerCase().contains(q)) return true;

      final subs = _catCtrl.getSubCategoriesByCategory(c.id);
      for (var sub in subs) {
        if (sub.name.toLowerCase().contains(q)) return true;
        final txs = _txBySubCat[sub.id] ?? [];
        if (txs.any((t) => t.title.toLowerCase().contains(q))) return true;
      }
      return false;
    }).toList();

    if (visibleParents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: AppText(
            'No transactions found from\n${_formatShortDate(_activeRange.start)} to ${_formatShortDate(_activeRange.end)}',
            // color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            textAlign: TextAlign.center,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleParents.length,
      itemBuilder: (context, idx) {
        final cat = visibleParents[idx];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCategoryTile(cat),
        );
      },
    );
  }

  Widget _buildCategoryTile(CategoryModel cat) {
    final theme = Theme.of(context);
    final color = _colorFor(cat.id, theme);
    final total = _parentCatTotals[cat.id] ?? 0;

    final subcategories = _catCtrl.getSubCategoriesByCategory(cat.id);

    return Card(
      color: theme.colorScheme.surfaceVariant,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        key: PageStorageKey(cat.id),
        initiallyExpanded: _expandedCats[cat.id] ?? false,
        onExpansionChanged: (v) => setState(() => _expandedCats[cat.id] = v),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
        children: subcategories
            .map((sub) => _buildSubcategorySection(sub))
            .toList(),
      ),
    );
  }

  Widget _buildSubcategorySection(SubCategoryModel sub) {
    final txs = (_txBySubCat[sub.id] ?? []).where((t) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return sub.name.toLowerCase().contains(q) ||
          t.title.toLowerCase().contains(q);
    }).toList();

    final total = _subCatTotals[sub.id] ?? 0;
    if (total <= 0 && txs.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: AppText(
                  sub.name,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              AppText(
                _formatCurrency(total),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: orangeColor,
              ),
            ],
          ),
        ),
        _tableHeader(),
        if (txs.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(36, 8, 12, 12),
            child: AppText(
              'No transactions found in this subcategory.',
              fontSize: 12,
            ),
          )
        else
          ...txs.map((t) => _txRow(t)),
        const Divider(indent: 24, endIndent: 12),
      ],
    );
  }

  Widget _tableHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 12, 8),
    child: Row(
      spacing: 3,
      children: const [
        Expanded(
          flex: 4,
          child: FittedText(
            'Merchant',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: FittedText(
            'Date',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: FittedText(
            'Amount',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(width: 30, height: 30),
      ],
    ),
  );

  Widget _txRow(TransactionModel tx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 12, 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: FittedText(tx.title, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: FittedText(
              _formatShortDate(tx.dateTime),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: FittedText(
              _formatCurrency(tx.amount.abs()),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 30,
            height: 30,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 16),
              padding: EdgeInsetsGeometry.zero,
              itemBuilder: (context) {
                return [
                  const PopupMenuItem<String>(
                    value: "remove",
                    child: Text("Remove"),
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
                    _removeTx(tx.id);
                    break;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double n) => CurrencyUtils.format(n);
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
