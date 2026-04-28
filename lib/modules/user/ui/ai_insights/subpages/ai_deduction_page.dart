import 'dart:async';
import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/helpers/currency_formatter.dart';
import 'package:booksmart/models/deduction_rule_model.dart';
import 'package:booksmart/models/transaction_model.dart';
import 'package:booksmart/modules/admin/controllers/category_controler.dart';
import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'package:booksmart/modules/user/controllers/transaction_controller.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/utils/supabase.dart';
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
  int? _userStateId;

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
    } else {}

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

      if (_catCtrl.states.isEmpty) {
        await _catCtrl.fetchStates();
      }
      await _catCtrl.fetchDeductionRules();

      final org = getCurrentOrganization;
      final orgState = org?.primaryState ?? org?.state;
      _userStateId = _catCtrl.states
          .firstWhereOrNull((s) => s.name == orgState || s.code == orgState)
          ?.id;

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
    for (var entry in _subCatTotals.entries) {
      final subId = entry.key;
      final total = entry.value;
      final subName = _catCtrl.getSubCategoryName(subId);
      if (total > 0) {
        if (_search.isEmpty ||
            subName.toLowerCase().contains(_search.toLowerCase())) {
          map[subName] = total;
        }
      }
    }
    return map;
  }

  double _getDeduction(double amount, int subCatId, {required bool isFederal}) {
    final stateId = isFederal ? null : _userStateId;
    final rule = _catCtrl.deductionRules.firstWhereOrNull(
      (r) => r.subCategoryId == subCatId && r.stateId == stateId,
    );
    if (rule == null) return 0.0;
    if (rule.ruleType == RuleType.percentage) {
      return amount * (rule.value / 100);
    } else {
      return rule.value;
    }
  }

  String _getDeductionDisplay(
    double amount,
    int subCatId, {
    required bool isFederal,
  }) {
    final stateId = isFederal ? null : _userStateId;
    final rule = _catCtrl.deductionRules.firstWhereOrNull(
      (r) => r.subCategoryId == subCatId && r.stateId == stateId,
    );
    if (rule == null) return _formatCurrency(0);

    final calculated = _getDeduction(amount, subCatId, isFederal: isFederal);
    if (rule.ruleType == RuleType.percentage) {
      return "${_formatCurrency(calculated)} (${rule.value.toStringAsFixed(0)}%)";
    } else {
      return "${_formatCurrency(calculated)} (${_formatCurrency(rule.value)})";
    }
  }

  Color _colorFor(int id, ThemeData theme) {
    if (id == 0) return theme.colorScheme.primary;
    final hue = (id * 137.508) % 360;
    return HSLColor.fromAHSL(1.0, hue, 0.65, 0.55).toColor();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() => _search = _searchCtrl.text);
    });
  }

  // Future<void> _removeTx(int txId) async {
  //   await showConfirmationDialog(
  //     title: 'Remove Transaction',
  //     description:
  //         'Are you sure you want to remove this transaction from this subcategory?',
  //     onYes: () async {
  //       Get.back(); // Close dialog
  //       await _txCtrl.deleteTransaction(txId);
  //       _loadData();
  //     },
  //   );
  // }

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
        : List.generate(ordered.length, (index) {
            // Using the golden angle to distribute colors evenly based on their
            // sorted index. This guarantees no two slices get the same color,
            // even if their IDs are missing or duplicate.
            final hue = (index * 137.508) % 360;
            return HSLColor.fromAHSL(1.0, hue, 0.65, 0.55).toColor();
          });

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
                        : _buildDeductionTable(),
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 16,
                  //     vertical: 8,
                  //   ),
                  //   child: _isLoading
                  //       ? const SizedBox()
                  //       : _buildAccordionList(),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDateRangeText() {
    final now = DateTime.now();
    final start = _activeRange.start;
    final end = _activeRange.end;

    final isEndToday =
        end.year == now.year && end.month == now.month && end.day == now.day;

    if (isEndToday) {
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day);
      final difference = endDay.difference(startDay).inDays;
      return 'Last ${difference == 0 ? 1 : difference} Days';
    } else {
      String pad(int n) => n.toString().padLeft(2, '0');
      return '${pad(start.month)}/${pad(start.day)}/${start.year} - ${pad(end.month)}/${pad(end.day)}/${end.year}';
    }
  }

  Widget _buildDeductionTable() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<int> activeSubCatIds = _subCatTotals.keys.where((id) {
      if (_search.isEmpty) return true;
      return _catCtrl
          .getSubCategoryName(id)
          .toLowerCase()
          .contains(_search.toLowerCase());
    }).toList();

    if (activeSubCatIds.isEmpty) return const SizedBox();

    double grandTotalAmount = 0;
    double grandTotalState = 0;
    double grandTotalFederal = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                'Deductions Breakdown',
                fontWeight: FontWeight.bold,
              ),
              AppText(_getDateRangeText(), fontWeight: FontWeight.bold),
            ],
          ),
        ),

        /// HEADER
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: _TableCell('Sub-Category', isHeader: true),
              ),
              Expanded(
                flex: 2,
                child: _TableCell('Total Amount', isHeader: true),
              ),
              Expanded(
                flex: 2,
                child: _TableCell('State Deduction', isHeader: true),
              ),
              Expanded(
                flex: 5,
                child: _TableCell('Federal Deduction', isHeader: true),
              ),
            ],
          ),
        ),

        /// BODY (Expandable Rows)
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              ...activeSubCatIds.map((subId) {
                final amount = _subCatTotals[subId] ?? 0;
                final stateDed = _getDeduction(amount, subId, isFederal: false);
                final fedDed = _getDeduction(amount, subId, isFederal: true);

                final transactions = _txBySubCat[subId] ?? [];

                grandTotalAmount += amount;
                grandTotalState += stateDed;
                grandTotalFederal += fedDed;

                return Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(_catCtrl.getSubCategoryName(subId)),
                        ),
                        Expanded(flex: 2, child: Text(_formatCurrency(amount))),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _getDeductionDisplay(
                              amount,
                              subId,
                              isFederal: false,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _getDeductionDisplay(
                              amount,
                              subId,
                              isFederal: true,
                            ),
                          ),
                        ),
                      ],
                    ),

                    /// 🔥 EXPANDED TRANSACTIONS
                    children: [
                      if (transactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('No transactions'),
                        )
                      else
                        Column(
                          children: transactions.map((tx) {
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(tx.title),

                              trailing: Text(_formatCurrency(tx.amount)),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                );
              }),

              /// TOTAL ROW
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(_formatCurrency(grandTotalAmount)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(_formatCurrency(grandTotalState)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(_formatCurrency(grandTotalFederal)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  String _formatCurrency(double n) => CurrencyUtils.format(n);
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  const _TableCell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: AppText(
        text,
        fontSize: isHeader ? 12 : 11,
        fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        textAlign: TextAlign.center,
      ),
    );
  }
}
