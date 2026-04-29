import 'dart:async';
import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/helpers/currency_formatter.dart';
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
    // start: DateTime(DateTime.now().year, 1, 1),
    start: DateTime.now().subtract(const Duration(days: 365)),
    end: DateTime.now(),
  );

  bool _isLoading = false;
  List<dynamic> _rpcResults = [];
  final Map<int, List<TransactionModel>> _txBySubCat = {};
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

      final org = getCurrentOrganization;
      if (org == null) return;

      _userStateId = org.state;

      final res = await supabase.rpc(
        'get_subcategory_totals_with_deductions',
        params: {
          'p_org_id': org.id,
          'p_state_id': _userStateId,
          'p_start_date': _activeRange.start.toIso8601String().split('T')[0],
          'p_end_date': _activeRange.end.toIso8601String().split('T')[0],
        },
      );

      _rpcResults = res as List<dynamic>;
      // debugPrint("Org_id+${org.id}");
      // debugPrint("State_id+$_userStateId");
      // debugPrint(_rpcResults.length.toString());
      _txBySubCat.clear(); // Clear cached transactions when range changes

      if (_catCtrl.states.isEmpty) {
        await _catCtrl.fetchStates();
      }
    } catch (e) {
      dev.log("Error loading AI Deduction data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSubCategoryTransactions(int subCatId) async {
    if (_txBySubCat.containsKey(subCatId)) return; // Already fetched

    try {
      final res = await supabase
          .from(SupabaseTable.transaction)
          .select()
          .eq('org_id', getCurrentOrganization!.id)
          .eq('sub_category_id', subCatId)
          .gte('date_time', _activeRange.start.toIso8601String().split('T')[0])
          .lte('date_time', _activeRange.end.toIso8601String().split('T')[0]);

      final List<TransactionModel> txs = (res as List)
          .map((e) => TransactionModel.fromJson(e))
          .toList();

      setState(() {
        _txBySubCat[subCatId] = txs;
      });
    } catch (e) {
      dev.log("Error fetching transactions for subcategory $subCatId: $e");
    }
  }

  Map<String, double> _computePieData() {
    final Map<String, double> map = {};
    for (var row in _rpcResults) {
      final subId = row['sub_category_id'] as int;
      final total = (row['total_amount'] ?? 0.0) as double;
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

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() => _search = _searchCtrl.text);
    });
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDateRangeText() {
    final start = _activeRange.start;
    final end = _activeRange.end;

    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(start.month)}/${pad(start.day)}/${start.year} - ${pad(end.month)}/${pad(end.day)}/${end.year}';
  }

  Widget _buildDeductionTable() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<dynamic> filteredRows = _rpcResults.where((row) {
      if (_search.isEmpty) return true;
      final subId = row['sub_category_id'] as int;
      return _catCtrl
          .getSubCategoryName(subId)
          .toLowerCase()
          .contains(_search.toLowerCase());
    }).toList();

    if (filteredRows.isEmpty) return const SizedBox();

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
              ...filteredRows.map((row) {
                final subId = row['sub_category_id'] as int;
                final amount = (row['total_amount'] ?? 0.0) as double;
                final stateDed = (row['state_deduction'] ?? 0.0) as double;
                final fedDed = (row['federal_deduction'] ?? 0.0) as double;

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
                    onExpansionChanged: (expanded) {
                      if (expanded) {
                        _fetchSubCategoryTransactions(subId);
                      }
                    },
                    title: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(_catCtrl.getSubCategoryName(subId)),
                        ),
                        Expanded(flex: 2, child: Text(_formatCurrency(amount))),
                        Expanded(
                          flex: 2,
                          child: Text(_formatCurrency(stateDed)),
                        ),
                        Expanded(flex: 2, child: Text(_formatCurrency(fedDed))),
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
