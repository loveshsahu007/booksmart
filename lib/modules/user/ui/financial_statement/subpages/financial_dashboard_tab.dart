import 'package:booksmart/constant/exports.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'package:booksmart/modules/user/controllers/financial_report_controller.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:booksmart/modules/user/utils/plaid_connect_utils.dart';

import '../financial_statement.dart';

class FinancialDashboardTab extends StatefulWidget {
  const FinancialDashboardTab({super.key});

  @override
  State<FinancialDashboardTab> createState() => _FinancialDashboardTabState();
}

class _FinancialDashboardTabState extends State<FinancialDashboardTab> {
  int _trendIndex = 2; // 3M default
  static const List<String> _trendLabels = ['7d', '30d', '3M', '6M', '12M'];
  static const List<int> _trendPoints = [7, 30, 90, 180, 365];

  static const Color _bg = Color(0xFF020E2C);
  static const Color _cardStart = Color(0xFF071F4A);
  static const Color _cardEnd = Color(0xFF061A3D);
  static const Color _cardStroke = Color(0xFF123469);
  static const Color _title = Color(0xFFA9BCDE);
  static const Color _text = Color(0xFFEAF2FF);
  static const Color _muted = Color(0xFF6E86AD);
  static const Color _green = Color(0xFF4AE481);
  static const Color _red = Color(0xFFFF6A6A);
  static const Color _yellow = Color(0xFFFFC52C);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: GetBuilder<FinancialReportController>(
        tag: getCurrentOrganization!.id.toString(),
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final monthly = controller.monthlyData;
          final income = controller.totalIncome.value;
          final expenses = controller.totalExpenses.value;
          final netIncome = controller.netIncome.value;
          final assets = controller.totalAssets.value;
          final liabilities = controller.totalLiabilities.value;
          final equity = assets - liabilities;
          final cashIn = controller.cashInflow.value;
          final cashOut = controller.cashOutflow.value;
          final netCashChange = cashIn - cashOut;

          final pIncome = controller.prevPeriodIncome.value;
          final pExpenses = controller.prevPeriodExpenses.value;
          final pNetIncome = controller.prevPeriodNetIncome.value;
          final pAssets = controller.prevPeriodAssets.value;
          final pLiabilities = controller.prevPeriodLiabilities.value;
          final pEquity = pAssets - pLiabilities;
          final pCashIn = controller.prevPeriodCashInflow.value;
          final pCashOut = controller.prevPeriodCashOutflow.value;
          final pNetCash = pCashIn - pCashOut;

          final dateRange = _formatRange(controller.lastStartDate, controller.lastEndDate);
          final deductionPct = _deductionPct(controller.totalTaxDeductions.value, income, expenses);
          final healthScore = _healthScore(
            netIncome: netIncome,
            revenue: income,
            currentRatio: controller.currentRatio,
            debtToEquity: controller.debtToEquity,
            netCash: netCashChange,
            deductionPct: deductionPct,
          );
          final prevHealthScore = _healthScore(
            netIncome: pNetIncome,
            revenue: pIncome,
            currentRatio: controller.prevPeriodCurrentRatio,
            debtToEquity: controller.prevPeriodDebtToEquity,
            netCash: pNetCash,
            deductionPct: deductionPct,
          );

          final trendSeries = _filterTrendSeries(
            monthly,
            _trendPoints[_trendIndex],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 1100;

                final chartRow = Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 70,
                      child: _chartCard(
                        revenue: trendSeries['income']!,
                        expense: trendSeries['expense']!,
                        netCash: trendSeries['cashflow']!,
                        profit: trendSeries['profit']!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 30,
                      child: _insightsCard(
                        netIncome: netIncome,
                        pNetIncome: pNetIncome,
                        income: income,
                        expenses: expenses,
                        equity: equity,
                        pEquity: pEquity,
                        netCashChange: netCashChange,
                        taxDeduction: controller.totalTaxDeductions.value,
                      ),
                    ),
                  ],
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topBand(
                      score: healthScore,
                      netIncome: netIncome,
                      pNetIncome: pNetIncome,
                      assets: assets,
                      pAssets: pAssets,
                      cashFlow: netCashChange,
                      pCashFlow: pNetCash,
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: AppText(
                        'Business Overview',
                        fontSize: 14,
                        color: _text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _overviewBand(
                      dateRange: dateRange,
                      income: income, pIncome: pIncome,
                      expenses: expenses, pExpenses: pExpenses,
                      netIncome: netIncome, pNetIncome: pNetIncome,
                      assets: assets, pAssets: pAssets,
                      liabilities: liabilities, pLiabilities: pLiabilities,
                      equity: equity, pEquity: pEquity,
                      debtToEquity: controller.debtToEquity,
                      pDebtToEquity: controller.prevPeriodDebtToEquity,
                      cashIn: cashIn, pCashIn: pCashIn,
                      cashOut: cashOut, pCashOut: pCashOut,
                      netCashChange: netCashChange,
                      taxDeduction: controller.totalTaxDeductions.value,
                    ),
                    const SizedBox(height: 12),
                    if (isDesktop)
                      SizedBox(height: 270, child: chartRow)
                    else ...[
                      SizedBox(height: 270, child: _chartCard(
                        revenue: trendSeries['income']!,
                        expense: trendSeries['expense']!,
                        netCash: trendSeries['cashflow']!,
                        profit: trendSeries['profit']!,
                      )),
                      const SizedBox(height: 12),
                      SizedBox(height: 270, child: _insightsCard(
                        netIncome: netIncome,
                        pNetIncome: pNetIncome,
                        income: income,
                        expenses: expenses,
                        equity: equity,
                        pEquity: pEquity,
                        netCashChange: netCashChange,
                        taxDeduction: controller.totalTaxDeductions.value,
                      )),
                    ],
                    const SizedBox(height: 12),
                    _footerBanner(
                      score: healthScore,
                      prevScore: prevHealthScore,
                      netIncome: netIncome,
                      income: income,
                      expenses: expenses,
                      cashFlow: netCashChange,
                      currentRatio: controller.currentRatio,
                      debtToEquity: controller.debtToEquity,
                    ),
                    const SizedBox(height: 12),
                    _actionRow(),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _topBand({
    required double score,
    required double netIncome,
    required double pNetIncome,
    required double assets,
    required double pAssets,
    required double cashFlow,
    required double pCashFlow,
  }) {
    final money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return SizedBox(
      height: 196,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _healthCard(score)),
          const SizedBox(width: 12),
          Expanded(
            child: _metricCard(
              title: 'Net Income (Profit)',
              value: money.format(netIncome),
              deltaPct: _pctChange(netIncome, pNetIncome),
              valueIsNegative: netIncome < 0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metricCard(
              title: 'Total Assets',
              value: money.format(assets),
              deltaPct: _pctChange(assets, pAssets),
              valueIsNegative: assets < 0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metricCard(
              title: 'Cash Flow (Net Cash)',
              value: money.format(cashFlow),
              deltaPct: _pctChange(cashFlow, pCashFlow),
              valueIsNegative: cashFlow < 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthCard(double score) {
    final status = score <= 40
        ? 'Weak'
        : score <= 70
            ? 'Moderate'
            : 'Good';
    final statusColor = score >= 60
        ? _green
        : score >= 40
            ? _yellow
            : _red;
    return _glassCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AppText(
            'Business Health Score',
            fontSize: 13,
            color: _title,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 92,
            width: double.infinity,
            child: _getRadialGauge(score),
          ),
          const SizedBox(height: 1),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  score.toInt().toString(),
                  fontSize: 20,
                  color: _text,
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.center,
                ),
                AppText(
                  status,
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  textAlign: TextAlign.center,
                ),
                AppText(
                  DateFormat('MMM dd, yyyy').format(DateTime.now()),
                  fontSize: 10,
                  color: _muted,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required double? deltaPct,
    required bool valueIsNegative,
  }) {
    final positive = (deltaPct ?? 0) >= 0;
    final deltaColor = positive ? _green : _red;
    return _glassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppText(
            title,
            fontSize: 13,
            color: _title,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: AppText(
              value,
              fontSize: 32,
              color: valueIsNegative ? _red : _text,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: deltaColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AppText(
                  _formatDelta(deltaPct),
                  fontSize: 10,
                  color: deltaColor,
                  fontWeight: FontWeight.w600,
                  disableFormat: true,
                ),
              ),
              const AppText(
                'vs prev period',
                fontSize: 11,
                color: _muted,
                disableFormat: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewBand({
    required String dateRange,
    required double income, required double pIncome,
    required double expenses, required double pExpenses,
    required double netIncome, required double pNetIncome,
    required double assets, required double pAssets,
    required double liabilities, required double pLiabilities,
    required double equity, required double pEquity,
    required double debtToEquity, required double pDebtToEquity,
    required double cashIn, required double pCashIn,
    required double cashOut, required double pCashOut,
    required double netCashChange,
    required double taxDeduction,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1150;
        final cards = [
          _businessOverviewCard(
            dateRange: dateRange,
            income: income, pIncome: pIncome,
            expenses: expenses, pExpenses: pExpenses,
            netIncome: netIncome, pNetIncome: pNetIncome,
          ),
          _balanceOverviewCard(
            assets: assets, pAssets: pAssets,
            liabilities: liabilities, pLiabilities: pLiabilities,
            equity: equity, pEquity: pEquity,
            debtToEquity: debtToEquity, pDebtToEquity: pDebtToEquity,
          ),
          _cashFlowOverviewCard(
            dateRange: dateRange,
            cashIn: cashIn, pCashIn: pCashIn,
            cashOut: cashOut, pCashOut: pCashOut,
            netCashChange: netCashChange,
          ),
          _aiDeductionCard(taxDeduction: taxDeduction, income: income, expenses: expenses),
        ];
        if (!compact) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
                const SizedBox(width: 12),
                Expanded(child: cards[2]),
                const SizedBox(width: 12),
                Expanded(child: cards[3]),
              ],
            ),
          );
        }
        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[3]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _businessOverviewCard({
    required String dateRange,
    required double income, required double pIncome,
    required double expenses, required double pExpenses,
    required double netIncome, required double pNetIncome,
  }) {
    final money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final marginCur = income <= 0 ? 0.0 : (netIncome / income) * 100;
    final marginPrev = pIncome <= 0 ? 0.0 : (pNetIncome / pIncome) * 100;
    return _glassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppText('Profit & Loss Overview', fontSize: 13, color: _title, fontWeight: FontWeight.w600),
          AppText(dateRange, fontSize: 10, color: _muted),
          const SizedBox(height: 8),
          _overviewLine('Income', money.format(income), _pctChange(income, pIncome), positiveIsGood: true),
          _overviewLine('Expenses', money.format(expenses), _pctChange(expenses, pExpenses), positiveIsGood: false),
          _overviewLine('Gross Profit', money.format(netIncome), _pctChange(netIncome, pNetIncome), positiveIsGood: true),
          _overviewLine('% Margin', '${marginCur.toStringAsFixed(1)}%', _absDiff(marginCur, marginPrev), positiveIsGood: true, isPctPoint: true),
          const SizedBox(height: 4),
          _viewLink('View Profit & Loss', () => _goToTab(2)),
        ],
      ),
    );
  }

  Widget _balanceOverviewCard({
    required double assets, required double pAssets,
    required double liabilities, required double pLiabilities,
    required double equity, required double pEquity,
    required double debtToEquity, required double pDebtToEquity,
  }) {
    final money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return _glassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppText('Balance Sheet Overview', fontSize: 13, color: _title, fontWeight: FontWeight.w600),
          AppText('As of ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', fontSize: 10, color: _muted),
          const SizedBox(height: 8),
          _overviewLine('Total Assets', money.format(assets), _pctChange(assets, pAssets), positiveIsGood: true),
          _overviewLine('Total Liabilities', money.format(liabilities), _pctChange(liabilities, pLiabilities), positiveIsGood: false),
          _overviewLine('Equity', money.format(equity), _pctChange(equity, pEquity), positiveIsGood: true),
          _overviewLine(
            'Debt-to-Equity',
            equity.abs() < 0.0001 ? 'N/A' : debtToEquity.toStringAsFixed(2),
            _pctChange(debtToEquity, pDebtToEquity),
            positiveIsGood: false,
          ),
          const SizedBox(height: 4),
          _viewLink('View Balance Sheet', () => _goToTab(3)),
        ],
      ),
    );
  }

  Widget _cashFlowOverviewCard({
    required String dateRange,
    required double cashIn, required double pCashIn,
    required double cashOut, required double pCashOut,
    required double netCashChange,
  }) {
    final money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final pNetCash = pCashIn - pCashOut;
    return _glassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppText('Cash Flow Overview', fontSize: 13, color: _title, fontWeight: FontWeight.w600),
          AppText(dateRange, fontSize: 10, color: _muted),
          const SizedBox(height: 8),
          _overviewLine('Money In', money.format(cashIn), _pctChange(cashIn, pCashIn), positiveIsGood: true),
          _overviewLine('Money Out', money.format(cashOut), _pctChange(cashOut, pCashOut), positiveIsGood: false),
          _overviewLine('Net Cash', money.format(netCashChange), _pctChange(netCashChange, pNetCash), positiveIsGood: true),
          _overviewLineText('Cash Flow Trend', netCashChange >= 0 ? 'Positive' : 'Negative', positive: netCashChange >= 0),
          const SizedBox(height: 4),
          _viewLink('View Cash Flow', () => _goToTab(4)),
        ],
      ),
    );
  }

  Widget _aiDeductionCard({
    required double taxDeduction,
    required double income,
    required double expenses,
  }) {
    final base = expenses > 0 ? expenses : income;
    final optimizationPct = base <= 0
        ? 0.0
        : ((taxDeduction / base) * 100).clamp(0.0, 100.0);
    final unutilized = (100 - optimizationPct).clamp(0.0, 100.0);
    final money0 = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final potentialSavings = taxDeduction * 0.24;
    return _glassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('AI Deduction Optimization', fontSize: 13, color: _title, fontWeight: FontWeight.w600),
          const AppText('Deduction Optimization Level', fontSize: 10, color: _muted),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  height: 76,
                  width: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 76,
                        width: 76,
                        child: CircularProgressIndicator(
                          value: optimizationPct / 100,
                          strokeWidth: 8,
                          backgroundColor: const Color(0xFF1A355F),
                          valueColor: const AlwaysStoppedAnimation<Color>(_green),
                        ),
                      ),
                      AppText(
                        '${optimizationPct.toStringAsFixed(0)}%',
                        fontSize: 18,
                        color: _text,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppText('Additional Tax\nDeductions Found', fontSize: 9, color: _muted),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AppText(
                          money0.format(taxDeduction),
                          fontSize: 18,
                          color: _green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const AppText('Potential Tax Savings', fontSize: 9, color: _muted),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AppText(
                          money0.format(potentialSavings),
                          fontSize: 18,
                          color: _text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppText(
            '${unutilized.toStringAsFixed(0)}% of deductions not yet utilized',
            fontSize: 9,
            color: _muted,
          ),
          const SizedBox(height: 4),
          _viewLink('View Deductions', () {}),
        ],
      ),
    );
  }

  Widget _overviewLine(
    String label,
    String value,
    double? deltaPct, {
    required bool positiveIsGood,
    bool isPctPoint = false,
  }) {
    final isFlat = deltaPct == null || deltaPct.abs() < 0.0001;
    final up = (deltaPct ?? 0) > 0;
    final color = isFlat ? _muted : (up == positiveIsGood ? _green : _red);
    final deltaText = isPctPoint
        ? _formatPctPoint(deltaPct)
        : _formatDelta(deltaPct);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: AppText(label, fontSize: 11, color: _title),
          ),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: AppText(
                  value,
                  fontSize: 12,
                  color: _text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 56,
            child: AppText(
              deltaText,
              fontSize: 10,
              color: color,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewLineText(String label, String value, {required bool positive}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: AppText(label, fontSize: 11, color: _title),
          ),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: AppText(
                value,
                fontSize: 12,
                color: positive ? _green : _red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  Widget _viewLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          AppText(label, fontSize: 12, color: _text, fontWeight: FontWeight.w500),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_rounded, size: 13, color: _text),
        ],
      ),
    );
  }

  void _goToTab(int idx) {
    if (Get.isRegistered<FinincialTabController>()) {
      Get.find<FinincialTabController>().changeTab(idx);
    }
  }

  static double? _pctChange(double current, double previous) {
    if (previous.abs() < 0.0001) {
      if (current.abs() < 0.0001) return 0;
      return null;
    }
    return ((current - previous) / previous.abs()) * 100;
  }

  static double _absDiff(double a, double b) => a - b;

  static String _formatDelta(double? pct) {
    if (pct == null) return '— —';
    if (pct.abs() < 0.0001) return '0.0%';
    final positive = pct >= 0;
    final abs = pct.abs();
    final shown = abs >= 1000 ? '999+' : abs.toStringAsFixed(1);
    return '${positive ? '↑' : '↓'} $shown%';
  }

  static String _formatPctPoint(double? pp) {
    if (pp == null) return '— —';
    final positive = pp >= 0;
    final abs = pp.abs().toStringAsFixed(1);
    return '${positive ? '↑' : '↓'} ${abs}pp';
  }

  static String _formatRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '';
    final df = DateFormat('MMM d');
    final yr = end.year;
    return '${df.format(start)} - ${df.format(end)}, $yr';
  }

  Widget _chartCard({
    required List<double> revenue,
    required List<double> expense,
    required List<double> netCash,
    required List<double> profit,
  }) {
    final data = [revenue, expense, netCash, profit].expand((e) => e).toList();
    final minY = data.isEmpty ? -10.0 : data.reduce((a, b) => a < b ? a : b);
    final maxY = data.isEmpty ? 10.0 : data.reduce((a, b) => a > b ? a : b);
    return _glassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppText('Financial Trend', fontSize: 13, color: _title, fontWeight: FontWeight.w600),
              const Spacer(),
              Wrap(
                spacing: 6,
                children: List.generate(_trendLabels.length, (i) {
                  final active = i == _trendIndex;
                  return InkWell(
                    onTap: () => setState(() => _trendIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF1A3B72) : const Color(0xFF0A254F),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: active ? _yellow : _cardStroke),
                      ),
                      child: AppText(
                        _trendLabels[i],
                        fontSize: 10,
                        color: active ? _text : _muted,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY - ((maxY - minY) * 0.12),
                maxY: maxY + ((maxY - minY) * 0.12),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: ((maxY - minY).abs() / 4).clamp(1, 100000000).toDouble(),
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFF173761), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: ((maxY - minY).abs() / 3).clamp(1, 100000000).toDouble(),
                      reservedSize: 34,
                      getTitlesWidget: (value, _) => AppText(
                        value >= 0 ? '\$${(value / 1000).toStringAsFixed(0)}K' : '-\$${((-value) / 1000).toStringAsFixed(0)}K',
                        fontSize: 10,
                        color: _muted,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 20,
                      getTitlesWidget: (value, _) {
                        const labels = ['Jan 26', 'Feb 2', 'Feb 9', 'Feb 16', 'Feb 23', 'Mar 2', 'Mar 9', 'Mar 16', 'Mar 23', 'Mar 30', 'Apr 6', 'Apr 13', 'Apr 20', 'Apr 27'];
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                        return AppText(labels[i], fontSize: 9, color: _muted);
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _line(revenue, const Color(0xFF52D97B)),
                  _line(expense, const Color(0xFF258CFF)),
                  _line(netCash, _yellow),
                  _line(profit, const Color(0xFFEFF4FF)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot('Revenue', Color(0xFF52D97B)),
              SizedBox(width: 14),
              _LegendDot('Expenses', Color(0xFF258CFF)),
              SizedBox(width: 14),
              _LegendDot('Net Cash', Color(0xFFFFC52C)),
              SizedBox(width: 14),
              _LegendDot('Profit', Color(0xFFEFF4FF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _insightsCard({
    required double netIncome,
    required double pNetIncome,
    required double income,
    required double expenses,
    required double equity,
    required double pEquity,
    required double netCashChange,
    required double taxDeduction,
  }) {
    final money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final niPct = _pctChange(netIncome, pNetIncome);
    final eqPct = _pctChange(equity, pEquity);
    final overspend = expenses - income;
    final insights = <String>[
      'Net income is ${money.format(netIncome)}',
      if (overspend > 0)
        'Expenses exceeded income by ${money.format(overspend)}'
      else
        'Income exceeded expenses by ${money.format(-overspend)}',
      eqPct == null
          ? 'Equity remains stable'
          : 'Equity ${eqPct >= 0 ? 'increased' : 'decreased'} ${eqPct.abs().toStringAsFixed(1)}%',
      '${netCashChange >= 0 ? 'Positive' : 'Negative'} cash flow of ${money.format(netCashChange)}',
      if (taxDeduction > 0)
        'You have ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(taxDeduction)} in potential deductions',
      if (niPct != null)
        'Net income ${niPct >= 0 ? 'improved' : 'declined'} ${niPct.abs().toStringAsFixed(1)}% vs previous period',
    ].take(5).toList();
    return _glassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Key Financial Insights', fontSize: 13, color: _title, fontWeight: FontWeight.w600),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: insights.length,
              itemBuilder: (_, i) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == insights.length - 1 ? Colors.transparent : const Color(0xFF133560),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppText(insights[i], fontSize: 11, color: _text, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerBanner({
    required double score,
    required double prevScore,
    required double netIncome,
    required double income,
    required double expenses,
    required double cashFlow,
    required double currentRatio,
    required double debtToEquity,
  }) {
    final message = _healthSummary(
      score: score,
      prevScore: prevScore,
      netIncome: netIncome,
      income: income,
      expenses: expenses,
      cashFlow: cashFlow,
      currentRatio: currentRatio,
      debtToEquity: debtToEquity,
    );
    return _glassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppText('Business Health Summary', fontSize: 12, color: _title, fontWeight: FontWeight.w600),
              AppText(
                message.$1,
                fontSize: 12,
                color: _text,
                fontWeight: FontWeight.w600,
              ),
              AppText(
                message.$2,
                fontSize: 10,
                color: _muted,
              ),
            ],
          ),
          const Spacer(),
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF092B55),
              borderRadius: BorderRadius.all(Radius.circular(8)),
              border: Border.fromBorderSide(BorderSide(color: Color(0xFF3C5A87))),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFFFFC72B), size: 14),
                  SizedBox(width: 6),
                  AppText('Ask BookSmart AI', fontSize: 11, color: Color(0xFFFFD978), fontWeight: FontWeight.w600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1100;
        final tiles = [
          _actionTile(title: 'Transactions', onTap: () => _goToTab(1)),
          _actionTile(
            title: 'Dun & Bradstreet',
            onTap: () async {
              await launchUrl(Uri.parse('https://www.dnb.com'), mode: LaunchMode.externalApplication);
            },
          ),
          _actionTile(title: 'Reports', onTap: () => _goToTab(2)),
          _actionTile(
            title: 'Accounts',
            onTap: () async {
              await hanldePlaidBankConnection();
            },
          ),
        ];
        if (!compact) {
          return SizedBox(
            height: 80,
            child: Row(
              children: [
                Expanded(child: tiles[0]),
                const SizedBox(width: 12),
                Expanded(child: tiles[1]),
                const SizedBox(width: 12),
                Expanded(child: tiles[2]),
                const SizedBox(width: 12),
                Expanded(child: tiles[3]),
              ],
            ),
          );
        }
        return Column(
          children: [
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(width: 12),
                  Expanded(child: tiles[1]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  Expanded(child: tiles[2]),
                  const SizedBox(width: 12),
                  Expanded(child: tiles[3]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _actionTile({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: _glassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Center(
          child: AppText(title, fontSize: 14, color: _text, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsets? padding, double? height}) {
    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardStart, _cardEnd],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardStroke),
        boxShadow: const [
          BoxShadow(color: Color(0x66010A20), blurRadius: 10, spreadRadius: 0, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _getRadialGauge(double pointerValue) {
    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 100,
          startAngle: 180,
          endAngle: 0,
          showTicks: true,
          showLabels: false,
          interval: 20,
          minorTicksPerInterval: 1,
          radiusFactor: 0.98,
          centerY: 0.86,
          axisLabelStyle: const GaugeTextStyle(color: _title, fontSize: 9),
          majorTickStyle: const MajorTickStyle(length: 6, thickness: 1.1, color: Color(0xFF7893B9)),
          minorTickStyle: const MinorTickStyle(length: 3, thickness: 1, color: Color(0xFF456286)),
          axisLineStyle: const AxisLineStyle(
            thickness: 14,
            cornerStyle: CornerStyle.bothCurve,
            gradient: SweepGradient(
              colors: [Color(0xFFF34F4F), Color(0xFFFF9A36), Color(0xFFF6C546), Color(0xFF59E182), Color(0xFF40D86E)],
              stops: [0.0, 0.24, 0.5, 0.76, 1.0],
            ),
          ),
          pointers: [
            NeedlePointer(
              value: pointerValue.clamp(0, 100),
              needleColor: const Color(0xFFEAF2FF),
              knobStyle: const KnobStyle(knobRadius: 0.05, color: Color(0xFFEAF2FF)),
              tailStyle: const TailStyle(length: 0.08, width: 3, color: Color(0xFFEAF2FF)),
              needleLength: 0.6,
              needleStartWidth: 0,
              needleEndWidth: 3,
            ),
          ],
        ),
      ],
    );
  }
  List<double> _extractSeries(List<dynamic> monthlyData, String key) {
    if (monthlyData.isEmpty) {
      return List<double>.filled(14, 0);
    }
    final values = monthlyData.map((e) {
      final val = e[key];
      if (val is num) return val.toDouble();
      if (key == 'cashflow') {
        final n = (e['net'] as num?)?.toDouble();
        if (n != null) return n;
        final i = (e['income'] as num?)?.toDouble() ?? 0;
        final ex = (e['expense'] as num?)?.toDouble() ?? 0;
        return i - ex;
      }
      if (key == 'profit') {
        final n = (e['net'] as num?)?.toDouble();
        if (n != null) return n;
        final i = (e['income'] as num?)?.toDouble() ?? 0;
        final ex = (e['expense'] as num?)?.toDouble() ?? 0;
        return i - ex;
      }
      return 0.0;
    }).toList();
    if (key == 'cashflow') {
      // Plot Net Cash as cumulative position so it is distinct from period Profit.
      double running = 0;
      final cumulative = <double>[];
      for (final v in values) {
        running += v;
        cumulative.add(running);
      }
      if (cumulative.length >= 14) return cumulative.take(14).toList();
      return [...cumulative, ...List<double>.filled(14 - cumulative.length, cumulative.last)];
    }
    if (values.length >= 14) return values.take(14).toList();
    return [...values, ...List<double>.filled(14 - values.length, values.last)];
  }

  LineChartBarData _line(List<double> data, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Map<String, List<double>> _filterTrendSeries(List<dynamic> monthlyData, int days) {
    // We do best-effort slicing based on available aggregated points.
    final allIncome = _extractSeries(monthlyData, 'income');
    final allExpense = _extractSeries(monthlyData, 'expense');
    final allCash = _extractSeries(monthlyData, 'cashflow');
    final allProfit = _extractSeries(monthlyData, 'profit');
    final points = days <= 7
        ? 7
        : days <= 30
            ? 10
            : days <= 90
                ? 14
                : days <= 180
                    ? 18
                    : 24;
    return {
      'income': _tailWithPad(allIncome, points),
      'expense': _tailWithPad(allExpense, points),
      'cashflow': _tailWithPad(allCash, points),
      'profit': _tailWithPad(allProfit, points),
    };
  }

  List<double> _tailWithPad(List<double> values, int points) {
    if (values.isEmpty) return List<double>.filled(points, 0);
    if (values.length >= points) return values.sublist(values.length - points);
    return [...List<double>.filled(points - values.length, values.first), ...values];
  }

  double _deductionPct(double taxDeduction, double income, double expenses) {
    final base = expenses > 0 ? expenses : income;
    if (base <= 0) return 0;
    return ((taxDeduction / base) * 100).clamp(0, 100);
  }

  double _healthScore({
    required double netIncome,
    required double revenue,
    required double currentRatio,
    required double debtToEquity,
    required double netCash,
    required double deductionPct,
  }) {
    final profitScore = _normalize(
      revenue == 0 ? 0 : netIncome / revenue,
      min: -0.5,
      max: 0.5,
    );
    final liquidityScore = _normalize(currentRatio, min: 0.5, max: 2.5);
    final leverageScore = 100 - _normalize(debtToEquity, min: 0.0, max: 2.0);
    final cashScore = _normalize(netCash, min: -10000, max: 10000);
    final taxScore = deductionPct;
    final score = (profitScore * 0.25) +
        (liquidityScore * 0.20) +
        (leverageScore * 0.15) +
        (cashScore * 0.20) +
        (taxScore * 0.20);
    return score.clamp(0, 100).toDouble();
  }

  double _normalize(double value, {required double min, required double max}) {
    if (max <= min) return 0;
    return (((value - min) / (max - min)) * 100).clamp(0, 100).toDouble();
  }

  (String, String) _healthSummary({
    required double score,
    required double prevScore,
    required double netIncome,
    required double income,
    required double expenses,
    required double cashFlow,
    required double currentRatio,
    required double debtToEquity,
  }) {
    String primary;
    if (score <= 40) {
      primary = 'Your business is under financial pressure.';
    } else if (score <= 70) {
      primary = 'Your business is stable but has areas to improve.';
    } else {
      primary = 'Your business is in strong financial condition.';
    }

    final drivers = <String>[];
    if (netIncome < 0 || expenses > income) drivers.add('expenses are exceeding income');
    if (cashFlow < 0) drivers.add('cash outflows are higher than inflows');
    if (debtToEquity > 1.5) drivers.add('debt levels are high relative to equity');
    if (currentRatio < 1.0) drivers.add('short-term liquidity is constrained');
    if (drivers.isEmpty) {
      if (cashFlow > 0) drivers.add('cash inflows are exceeding outflows');
      if (netIncome > 0) drivers.add('revenue exceeds expenses');
      if (debtToEquity < 0.5) drivers.add('debt levels are well managed');
    }

    final delta = score - prevScore;
    String trendLine;
    if (delta >= 5) {
      trendLine = 'Financial health improved vs previous period.';
    } else if (delta <= -5) {
      trendLine = 'Financial health declined vs previous period.';
    } else {
      trendLine = 'Financial performance remained consistent.';
    }
    final reason = drivers.take(2).join(' and ');
    final support = reason.isEmpty ? trendLine : '$reason. $trendLine';
    return (primary, support);
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.label, this.color);

  final String label;
  final Color color;
  static const Color _legendText = Color(0xFF6E86AD);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        ),
        const SizedBox(width: 4),
        AppText(label, fontSize: 10, color: _legendText),
      ],
    );
  }
}
