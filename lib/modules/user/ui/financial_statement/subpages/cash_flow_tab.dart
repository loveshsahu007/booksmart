import 'package:booksmart/constant/exports.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:booksmart/modules/user/controllers/financial_report_controller.dart';
import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'package:booksmart/models/transaction_model.dart';
import 'package:booksmart/modules/common/controllers/auth_controller.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/utils/supabase.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:booksmart/modules/user/ui/tax_filling/upload_tax_doc_dialog.dart';
import 'package:booksmart/widgets/recent_documents_widget.dart';
import 'package:booksmart/modules/user/ui/financial_statement/pdf_export_service.dart';
import 'package:booksmart/modules/user/ui/financial_statement/export_modal_widget.dart';
import 'package:booksmart/modules/user/utils/cash_flow_manual_entry_service.dart';
import 'dart:developer' as dev;
import 'package:booksmart/widgets/snackbar.dart';
import 'package:booksmart/utils/downloader.dart';
import 'package:xml/xml.dart';
import 'package:booksmart/models/cash_flow_manual_entry_model.dart';

class CashFlowTab extends StatefulWidget {
  const CashFlowTab({super.key});

  @override
  State<CashFlowTab> createState() => _CashFlowTabState();
}

class _CashFlowTabState extends State<CashFlowTab> {
  final CashFlowManualEntryService _manualEntryService =
      CashFlowManualEntryService();
  DateTime asOfDate = DateTime.now();
  // 0: 7d, 1: 30d, 2: 3mo, 3: 12mo, 4: Yearly, 5: Custom
  int _selectedFilterIdx = 2;
  int? _selectedYear;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _showMoneyIn = true;
  bool _showMoneyOut = true;
  bool _showNetCash = true;
  bool _comparePriorPeriod = false;

  final Map<String, bool> _expandedCards = {
    "Operating Activities": false,
    "Investing Activities": false,
    "Financing Activities": false,
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _startDate = today.subtract(const Duration(days: 89));
    _endDate = today;
  }

  void _exportCSV(FinancialReportController controller) async {
    final buffer = StringBuffer();
    final String orgName = getCurrentOrganization?.name ?? 'Organization';
    final String periodLabel =
        "${DateFormat('MM-dd-yyyy').format(_startDate ?? DateTime.now())}_to_${DateFormat('MM-dd-yyyy').format(_endDate ?? DateTime.now())}";

    buffer.writeln('Cash Flow Statement - $orgName');
    buffer.writeln('Period: $periodLabel');
    buffer.writeln('');

    void addActivitySection(
      String title,
      List<Map<String, dynamic>> items,
      double total,
    ) {
      buffer.writeln(title.toUpperCase());
      buffer.writeln('Activity Item,Amount');
      for (var item in items) {
        buffer.writeln('"${item["label"]}",${item["value"]}');
      }
      buffer.writeln('TOTAL $title,$total');
      buffer.writeln('');
    }

    addActivitySection(
      'Operating Activities',
      _getOperatingItems(controller),
      controller.operatingCashFlow.value,
    );
    addActivitySection(
      'Investing Activities',
      _getInvestingItems(controller),
      controller.investingCashFlow.value,
    );
    addActivitySection(
      'Financing Activities',
      _getFinancingItems(controller),
      controller.financingCashFlow.value,
    );

    final netCash =
        controller.operatingCashFlow.value +
        controller.investingCashFlow.value +
        controller.financingCashFlow.value;
    buffer.writeln('NET CHANGE IN CASH,$netCash');

    final csvBytes = utf8.encode(buffer.toString());
    await downloadFile(
      '${orgName}_Cash_Flow_$periodLabel.csv',
      csvBytes,
      mimeType: 'text/csv',
    );
  }

  CashFlowPdfData _buildCashFlowPdfData(
    FinancialReportController controller,
    PdfExportRequest request,
  ) {
    final bucketLabels = PdfExportService().buildBucketLabels(
      request.startDate,
      request.endDate,
      request.viewType,
    );

    final monthlyNetIncome = <String, double>{};
    final monthlyDepAmort = <String, double>{};
    final monthlyWorkingCapital = <String, double>{};
    final monthlyOperatingOther = <String, double>{};
    final monthlyOperatingTotal = <String, double>{};

    final monthlyCapex = <String, double>{};
    final monthlyInvestingOther = <String, double>{};
    final monthlyInvestingTotal = <String, double>{};

    final monthlyLoanActivities = <String, double>{};
    final monthlyOwnerContributions = <String, double>{};
    final monthlyDistributions = <String, double>{};
    final monthlyFinancingOther = <String, double>{};
    final monthlyFinancingTotal = <String, double>{};

    DateTime cursor = DateTime(
      request.startDate.year,
      request.startDate.month,
      1,
    );
    final DateTime last = DateTime(
      request.endDate.year,
      request.endDate.month,
      1,
    );
    while (!cursor.isAfter(last)) {
      final monthKey = DateFormat('yyyy-MM').format(cursor);

      final netIncome = controller.periodicNetIncome[monthKey] ?? 0.0;
      final expenseMap =
          controller.periodicExpenseBreakdown[monthKey] ?? <String, double>{};
      final operatingMap =
          controller.periodicOperatingActivities[monthKey] ??
          <String, double>{};
      final investingMap =
          controller.periodicInvestingActivities[monthKey] ??
          <String, double>{};
      final financingMap =
          controller.periodicFinancingActivities[monthKey] ??
          <String, double>{};

      final depAmort = _sumByKeywords(expenseMap, const [
        'depreciation',
        'amortization',
      ]);
      final wcChanges = _sumByKeywords(operatingMap, const [
        'receivable',
        'inventory',
        'payable',
        'accrued',
        'deferred',
        'prepaid',
        '[cf:workingcapital]',
      ]);
      final operatingOther = _sumValues(operatingMap) - wcChanges;
      final operatingTotal = netIncome + depAmort + wcChanges + operatingOther;

      final capex = _sumByKeywords(investingMap, const [
        'equipment',
        'property',
        'asset purchase',
        '[cf:investing]',
      ]);
      final investingOther = _sumValues(investingMap) - capex;
      final investingTotal = capex + investingOther;

      final loanActivities = _sumByKeywords(financingMap, const [
        'loan',
        'debt',
        '[cf:financing]',
      ]);
      final ownerContributions = _sumByKeywords(financingMap, const [
        'contribution',
        'share capital',
        '[cf:contribution]',
      ]);
      final distributions = _sumByKeywords(financingMap, const [
        'distribution',
        'dividend',
        'owner draw',
        '[cf:distributions]',
      ]);
      final financingOther =
          _sumValues(financingMap) -
          loanActivities -
          ownerContributions -
          distributions;
      final financingTotal =
          loanActivities + ownerContributions + distributions + financingOther;

      monthlyNetIncome[monthKey] = netIncome;
      monthlyDepAmort[monthKey] = depAmort;
      monthlyWorkingCapital[monthKey] = wcChanges;
      monthlyOperatingOther[monthKey] = operatingOther;
      monthlyOperatingTotal[monthKey] = operatingTotal;

      monthlyCapex[monthKey] = capex;
      monthlyInvestingOther[monthKey] = investingOther;
      monthlyInvestingTotal[monthKey] = investingTotal;

      monthlyLoanActivities[monthKey] = loanActivities;
      monthlyOwnerContributions[monthKey] = ownerContributions;
      monthlyDistributions[monthKey] = distributions;
      monthlyFinancingOther[monthKey] = financingOther;
      monthlyFinancingTotal[monthKey] = financingTotal;

      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    final netIncomeByBucket = _aggregateMonthlyToBuckets(
      monthlyNetIncome,
      bucketLabels,
      request.viewType,
    );
    final depByBucket = _aggregateMonthlyToBuckets(
      monthlyDepAmort,
      bucketLabels,
      request.viewType,
    );
    final wcByBucket = _aggregateMonthlyToBuckets(
      monthlyWorkingCapital,
      bucketLabels,
      request.viewType,
    );
    final opOtherByBucket = _aggregateMonthlyToBuckets(
      monthlyOperatingOther,
      bucketLabels,
      request.viewType,
    );
    final opTotalByBucket = _aggregateMonthlyToBuckets(
      monthlyOperatingTotal,
      bucketLabels,
      request.viewType,
    );

    final capexByBucket = _aggregateMonthlyToBuckets(
      monthlyCapex,
      bucketLabels,
      request.viewType,
    );
    final investingOtherByBucket = _aggregateMonthlyToBuckets(
      monthlyInvestingOther,
      bucketLabels,
      request.viewType,
    );
    final investingTotalByBucket = _aggregateMonthlyToBuckets(
      monthlyInvestingTotal,
      bucketLabels,
      request.viewType,
    );

    final loanByBucket = _aggregateMonthlyToBuckets(
      monthlyLoanActivities,
      bucketLabels,
      request.viewType,
    );
    final contribByBucket = _aggregateMonthlyToBuckets(
      monthlyOwnerContributions,
      bucketLabels,
      request.viewType,
    );
    final distributionsByBucket = _aggregateMonthlyToBuckets(
      monthlyDistributions,
      bucketLabels,
      request.viewType,
    );
    final finOtherByBucket = _aggregateMonthlyToBuckets(
      monthlyFinancingOther,
      bucketLabels,
      request.viewType,
    );
    final financingTotalByBucket = _aggregateMonthlyToBuckets(
      monthlyFinancingTotal,
      bucketLabels,
      request.viewType,
    );

    final opTotalSeries = _valuesFromBuckets(opTotalByBucket, bucketLabels);
    final investingTotalSeries = _valuesFromBuckets(
      investingTotalByBucket,
      bucketLabels,
    );
    final financingTotalSeries = _valuesFromBuckets(
      financingTotalByBucket,
      bucketLabels,
    );

    final netChangeSeries = List<double>.generate(
      bucketLabels.length,
      (i) =>
          opTotalSeries[i] + investingTotalSeries[i] + financingTotalSeries[i],
    );

    final beginningCashSeries = <double>[];
    final endingCashSeries = <double>[];
    var runningCash = controller.beginningCashBalance.value;
    for (var i = 0; i < netChangeSeries.length; i++) {
      beginningCashSeries.add(runningCash);
      runningCash += netChangeSeries[i];
      endingCashSeries.add(runningCash);
    }

    return CashFlowPdfData(
      sections: [
        CashFlowPdfSectionData(
          title: 'Operating Activities',
          rows: [
            CashFlowPdfRowData(
              label: 'Net income',
              values: _valuesFromBuckets(netIncomeByBucket, bucketLabels),
            ),
            CashFlowPdfRowData(
              label: 'Depreciation & amortization',
              values: _valuesFromBuckets(depByBucket, bucketLabels),
            ),
            CashFlowPdfRowData(
              label: 'Working capital changes',
              values: _valuesFromBuckets(wcByBucket, bucketLabels),
            ),
            CashFlowPdfRowData(
              label: 'Other operating adjustments',
              values: _valuesFromBuckets(opOtherByBucket, bucketLabels),
            ),
            CashFlowPdfRowData(
              label: 'Net Cash from Operating Activities (A)',
              values: opTotalSeries,
              isTotal: true,
            ),
          ],
        ),
        CashFlowPdfSectionData(
          title: 'Investing Activities',
          rows: [
            CashFlowPdfRowData(
              label: 'Asset purchases / CapEx',
              values: _valuesFromBuckets(capexByBucket, bucketLabels),
            ),
            CashFlowPdfRowData(
              label: 'Other investing activities',
              values: _valuesFromBuckets(investingOtherByBucket, bucketLabels),
            ),
            CashFlowPdfRowData(
              label: 'Net Cash from Investing Activities (B)',
              values: investingTotalSeries,
              isTotal: true,
            ),
          ],
        ),
        CashFlowPdfSectionData(
          title: 'Financing Activities',
          rows: [
            CashFlowPdfRowData(
              label: 'Loan activities',
              values: _valuesFromBuckets(loanByBucket, bucketLabels),
            ),
            CashFlowPdfRowData(
              label: 'Owner contributions',
              values: _valuesFromBuckets(contribByBucket, bucketLabels),
            ),
            CashFlowPdfRowData(
              label: 'Distributions',
              values: _valuesFromBuckets(distributionsByBucket, bucketLabels),
            ),
            CashFlowPdfRowData(
              label: 'Other financing activities',
              values: _valuesFromBuckets(finOtherByBucket, bucketLabels),
            ),
            CashFlowPdfRowData(
              label: 'Net Cash from Financing Activities (C)',
              values: financingTotalSeries,
              isTotal: true,
            ),
          ],
        ),
      ],
      netChange: netChangeSeries,
      beginningCash: beginningCashSeries,
      endingCash: endingCashSeries,
    );
  }

  Map<String, double> _aggregateMonthlyToBuckets(
    Map<String, double> monthlyData,
    List<String> bucketLabels,
    PdfViewType viewType,
  ) {
    final aggregated = <String, double>{
      for (final label in bucketLabels) label: 0.0,
    };
    monthlyData.forEach((monthKey, value) {
      final DateTime month = DateFormat('yyyy-MM').parse(monthKey);
      final label = _bucketLabelForMonth(month, viewType);
      if (aggregated.containsKey(label)) {
        aggregated[label] = (aggregated[label] ?? 0) + value;
      }
    });
    return aggregated;
  }

  String _bucketLabelForMonth(DateTime month, PdfViewType viewType) {
    switch (viewType) {
      case PdfViewType.monthly:
        return DateFormat('MMM yyyy').format(month);
      case PdfViewType.quarterly:
        final q = ((month.month - 1) ~/ 3) + 1;
        return 'Q$q ${month.year}';
      case PdfViewType.yearly:
        return month.year.toString();
    }
  }

  List<double> _valuesFromBuckets(
    Map<String, double> bucketMap,
    List<String> orderedLabels,
  ) {
    return orderedLabels.map((label) => bucketMap[label] ?? 0.0).toList();
  }

  double _sumValues(Map<String, double> values) {
    return values.values.fold<double>(0.0, (sum, v) => sum + v);
  }

  double _sumByKeywords(Map<String, double> values, List<String> keywords) {
    var sum = 0.0;
    values.forEach((key, value) {
      final lower = key.toLowerCase();
      final matched = keywords.any((kw) => lower.contains(kw));
      if (matched) {
        sum += value;
      }
    });
    return sum;
  }

  void _exportExcel(FinancialReportController controller) async {
    try {
      final org = getCurrentOrganization;
      if (org == null) {
        showSnackBar('Please select an organization.', isError: true);
        return;
      }

      final now = DateTime.now();
      final DateTime defaultYtdStart = DateTime(now.year, 1, 1);
      final DateTime selectedStart = _startDate != null
          ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
          : defaultYtdStart;
      final DateTime selectedEnd = _endDate != null
          ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day)
          : DateTime(now.year, now.month, now.day);
      final DateTime reportStart = selectedEnd.isBefore(selectedStart)
          ? selectedEnd
          : selectedStart;
      final DateTime reportEnd = selectedEnd.isBefore(selectedStart)
          ? selectedStart
          : selectedEnd;
      final String orgName = org.name;
      DateTime nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);
      String sqlDateLocal(DateTime d) {
        final x = DateTime(d.year, d.month, d.day);
        final mm = x.month.toString().padLeft(2, '0');
        final dd = x.day.toString().padLeft(2, '0');
        return '${x.year}-$mm-$dd';
      }

      String cleanTitle(String raw) {
        return raw.replaceAll(RegExp(r'\[[^\]]+\]'), '').trim();
      }

      List<String> extractTags(String title) {
        return RegExp(r'\[([^\]]+)\]')
            .allMatches(title)
            .map((m) => m.group(1)?.trim() ?? '')
            .where((x) => x.isNotEmpty)
            .toList();
      }

      String classifyFlowSection(String titleLower) {
        if (titleLower.contains('[cf:manual:operating]') ||
            titleLower.contains('[cf:manual:other]')) {
          return 'Operating';
        }
        if (titleLower.contains('[cf:manual:investing]') ||
            titleLower.contains('[cf:invest:other]') ||
            titleLower.contains('other investing')) {
          return 'Investing';
        }
        if (titleLower.contains('[cf:manual:financing]')) {
          return 'Financing';
        }
        if (titleLower.contains('[cf:investing]') ||
            titleLower.contains('asset purchase') ||
            titleLower.contains('equipment') ||
            titleLower.contains('property') ||
            titleLower.contains('investment')) {
          return 'Investing';
        }
        if (titleLower.contains('[cf:financing]') ||
            titleLower.contains('loan') ||
            titleLower.contains('debt') ||
            titleLower.contains('contribution') ||
            titleLower.contains('dividend') ||
            titleLower.contains('share capital') ||
            titleLower.contains('capital repayment')) {
          return 'Financing';
        }
        return 'Operating';
      }

      final totalMonths =
          (reportEnd.year - reportStart.year) * 12 +
          reportEnd.month -
          reportStart.month +
          1;
      final PdfViewType viewType = _selectedFilterIdx == 4
          ? PdfViewType.yearly
          : (totalMonths <= 5 ? PdfViewType.monthly : PdfViewType.quarterly);
      final request = PdfExportRequest(
        startDate: reportStart,
        endDate: reportEnd,
        viewType: viewType,
        templateVariant: PdfTemplateVariant.templateA,
        companyName: orgName,
        companyAddress: '',
      );
      final liveData = _buildCashFlowPdfData(controller, request);
      final bucketLabels = PdfExportService().buildBucketLabels(
        reportStart,
        reportEnd,
        viewType,
      );
      final keys = List<String>.generate(bucketLabels.length, (i) => 'b$i');
      final Map<String, String> keyToLabel = {
        for (int i = 0; i < keys.length; i++) keys[i]: bucketLabels[i],
      };

      List<double> seriesFor(String sectionTitle, String rowLabel) {
        for (final section in liveData.sections) {
          if (section.title != sectionTitle) continue;
          for (final row in section.rows) {
            if (row.label == rowLabel) return row.values;
          }
        }
        return List<double>.filled(bucketLabels.length, 0);
      }

      Map<String, double> mapFromSeries(List<double> values) {
        return {for (int i = 0; i < keys.length; i++) keys[i]: values[i]};
      }

      final netIncomeMap = mapFromSeries(
        seriesFor('Operating Activities', 'Net income'),
      );
      final depAmortMap = mapFromSeries(
        seriesFor('Operating Activities', 'Depreciation & amortization'),
      );
      final wcMap = mapFromSeries(
        seriesFor('Operating Activities', 'Working capital changes'),
      );
      final opOtherMap = mapFromSeries(
        seriesFor('Operating Activities', 'Other operating adjustments'),
      );
      final operatingMap = mapFromSeries(
        seriesFor(
          'Operating Activities',
          'Net Cash from Operating Activities (A)',
        ),
      );
      final investingMap = mapFromSeries(
        seriesFor(
          'Investing Activities',
          'Net Cash from Investing Activities (B)',
        ),
      );
      final financingMap = mapFromSeries(
        seriesFor(
          'Financing Activities',
          'Net Cash from Financing Activities (C)',
        ),
      );
      final netChangeMap = mapFromSeries(liveData.netChange);
      final beginningCashMap = mapFromSeries(liveData.beginningCash);
      final endingCashMap = mapFromSeries(liveData.endingCash);

      final adjustmentsMap = {
        for (final k in keys) k: (depAmortMap[k] ?? 0) + (opOtherMap[k] ?? 0),
      };
      final reconciliationTotalMap = {
        for (final k in keys)
          k:
              (netIncomeMap[k] ?? 0) +
              (adjustmentsMap[k] ?? 0) +
              (wcMap[k] ?? 0),
      };
      final varianceMap = {
        for (final k in keys)
          k: (reconciliationTotalMap[k] ?? 0) - (netChangeMap[k] ?? 0),
      };

      double periodTotal(Map<String, double> values) =>
          keys.fold<double>(0.0, (sum, key) => sum + (values[key] ?? 0.0));

      final rangeRes = await supabase
          .from(SupabaseTable.transaction)
          .select()
          .eq('org_id', org.id)
          .gte('date_time', sqlDateLocal(reportStart))
          .lt('date_time', sqlDateLocal(nextDay(reportEnd)));

      final transactions =
          (rangeRes as List).map((e) => TransactionModel.fromJson(e)).toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      final excel = excel_lib.Excel.createExcel();
      final summary = excel['Cash Flow Summary'];
      final detail = excel['Transaction Detail'];
      final recon = excel['Reconciliation'];
      excel.delete('Sheet1');

      final int totalCols =
          keys.length + 2; // Description + buckets + period total
      const descCol = 0;
      const firstMonthCol = 1;
      final int ytdCol = keys.length + 1;

      final titleStyle = excel_lib.CellStyle(
        bold: true,
        fontSize: 16,
        fontColorHex: excel_lib.ExcelColor.fromHexString('FFFFFFFF'),
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('FF134A85'),
        horizontalAlign: excel_lib.HorizontalAlign.Center,
      );
      final subTitleStyle = excel_lib.CellStyle(
        bold: false,
        fontSize: 11,
        fontColorHex: excel_lib.ExcelColor.fromHexString('FFFFFFFF'),
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('FF1F5C99'),
        horizontalAlign: excel_lib.HorizontalAlign.Center,
      );
      final quarterBandStyle = excel_lib.CellStyle(
        bold: true,
        fontColorHex: excel_lib.ExcelColor.fromHexString('FF134A85'),
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('FFE7F1FC'),
        horizontalAlign: excel_lib.HorizontalAlign.Center,
      );
      final headerStyle = excel_lib.CellStyle(
        bold: true,
        fontColorHex: excel_lib.ExcelColor.fromHexString('FFFFFFFF'),
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('FF134A85'),
        horizontalAlign: excel_lib.HorizontalAlign.Center,
      );
      final sectionStyle = excel_lib.CellStyle(
        bold: true,
        fontColorHex: excel_lib.ExcelColor.fromHexString('FFFFFFFF'),
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('FF3B6EA5'),
      );
      final labelStyle = excel_lib.CellStyle(
        horizontalAlign: excel_lib.HorizontalAlign.Left,
      );
      final totalLabelStyle = excel_lib.CellStyle(
        bold: true,
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('FFE7F1FC'),
      );
      final currencyStyle = excel_lib.CellStyle(
        horizontalAlign: excel_lib.HorizontalAlign.Right,
        numberFormat: const excel_lib.CustomNumericNumFormat(
          formatCode: r'$#,##0.00;[Red]-$#,##0.00',
        ),
      );
      final currencyTotalStyle = excel_lib.CellStyle(
        bold: true,
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('FFE7F1FC'),
        horizontalAlign: excel_lib.HorizontalAlign.Right,
        numberFormat: const excel_lib.CustomNumericNumFormat(
          formatCode: r'$#,##0.00;[Red]-$#,##0.00',
        ),
      );

      void setCell(
        excel_lib.Sheet sheet,
        int col,
        int row,
        excel_lib.CellValue value, [
        excel_lib.CellStyle? style,
      ]) {
        final cell = sheet.cell(
          excel_lib.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = value;
        if (style != null) {
          cell.cellStyle = style;
        }
      }

      // Tab 1: Cash Flow Summary
      summary.setColumnWidth(descCol, 40);
      for (var c = firstMonthCol; c <= ytdCol; c++) {
        summary.setColumnWidth(c, c == ytdCol ? 15 : 11);
      }

      for (int c = 0; c < totalCols; c++) {
        setCell(
          summary,
          c,
          0,
          excel_lib.TextCellValue('Cash Flow Summary'),
          titleStyle,
        );
        setCell(summary, c, 1, excel_lib.TextCellValue(orgName), subTitleStyle);
        setCell(
          summary,
          c,
          2,
          excel_lib.TextCellValue(
            'Period ${DateFormat('MMM dd, yyyy').format(reportStart)} - ${DateFormat('MMM dd, yyyy').format(reportEnd)}',
          ),
          subTitleStyle,
        );
      }
      summary.merge(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        excel_lib.CellIndex.indexByColumnRow(columnIndex: ytdCol, rowIndex: 0),
      );
      summary.merge(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        excel_lib.CellIndex.indexByColumnRow(columnIndex: ytdCol, rowIndex: 1),
      );
      summary.merge(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
        excel_lib.CellIndex.indexByColumnRow(columnIndex: ytdCol, rowIndex: 2),
      );
      summary.setMergedCellStyle(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        titleStyle,
      );
      summary.setMergedCellStyle(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        subTitleStyle,
      );
      summary.setMergedCellStyle(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
        subTitleStyle,
      );

      setCell(
        summary,
        0,
        4,
        excel_lib.TextCellValue('Grouped Columns'),
        quarterBandStyle,
      );
      if (keys.isNotEmpty) {
        summary.merge(
          excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4),
          excel_lib.CellIndex.indexByColumnRow(
            columnIndex: ytdCol - 1,
            rowIndex: 4,
          ),
        );
        setCell(
          summary,
          1,
          4,
          excel_lib.TextCellValue('Months (expand/collapse)'),
          quarterBandStyle,
        );
      }
      setCell(
        summary,
        ytdCol,
        4,
        excel_lib.TextCellValue('Period Total'),
        quarterBandStyle,
      );

      setCell(summary, 0, 5, excel_lib.TextCellValue('Line Item'), headerStyle);
      for (int i = 0; i < keys.length; i++) {
        setCell(
          summary,
          i + 1,
          5,
          excel_lib.TextCellValue(keyToLabel[keys[i]] ?? keys[i]),
          headerStyle,
        );
      }
      setCell(
        summary,
        ytdCol,
        5,
        excel_lib.TextCellValue('Period Total'),
        headerStyle,
      );

      int row = 7;
      void writeSection(String title) {
        for (int c = 0; c <= ytdCol; c++) {
          setCell(summary, c, row, excel_lib.TextCellValue(' '), sectionStyle);
        }
        setCell(summary, 0, row, excel_lib.TextCellValue(title), sectionStyle);
        row++;
      }

      void writeMetricRow(
        String label,
        Map<String, double> values, {
        bool total = false,
      }) {
        setCell(
          summary,
          0,
          row,
          excel_lib.TextCellValue(label),
          total ? totalLabelStyle : labelStyle,
        );
        for (int i = 0; i < keys.length; i++) {
          final v = values[keys[i]] ?? 0.0;
          setCell(
            summary,
            i + 1,
            row,
            excel_lib.DoubleCellValue(v),
            total ? currencyTotalStyle : currencyStyle,
          );
        }
        setCell(
          summary,
          ytdCol,
          row,
          excel_lib.DoubleCellValue(periodTotal(values)),
          total ? currencyTotalStyle : currencyStyle,
        );
        row++;
      }

      writeSection('Operating Activities');
      writeMetricRow('Net Income', netIncomeMap);
      writeMetricRow('Adjustments', adjustmentsMap);
      writeMetricRow('Balance Sheet Changes', wcMap);
      writeMetricRow(
        'Net Cash from Operating Activities',
        operatingMap,
        total: true,
      );
      row++;

      writeSection('Investing Activities');
      writeMetricRow(
        'Net Cash from Investing Activities',
        investingMap,
        total: true,
      );
      row++;

      writeSection('Financing Activities');
      writeMetricRow(
        'Net Cash from Financing Activities',
        financingMap,
        total: true,
      );
      row++;

      writeSection('Cash Position');
      writeMetricRow('Net Change in Cash', netChangeMap, total: true);
      writeMetricRow('Beginning Cash', beginningCashMap);
      writeMetricRow('Ending Cash', endingCashMap, total: true);

      // Tab 2: Transaction Detail
      detail.setColumnWidth(0, 14);
      detail.setColumnWidth(1, 36);
      detail.setColumnWidth(2, 14);
      detail.setColumnWidth(3, 14);
      detail.setColumnWidth(4, 18);
      detail.setColumnWidth(5, 18);
      detail.setColumnWidth(6, 12);
      detail.setColumnWidth(7, 12);

      for (int c = 0; c < 8; c++) {
        setCell(
          detail,
          c,
          0,
          excel_lib.TextCellValue('Cash Flow Transaction Detail'),
          titleStyle,
        );
        setCell(
          detail,
          c,
          1,
          excel_lib.TextCellValue(
            '${DateFormat('MMM dd, yyyy').format(reportStart)} - ${DateFormat('MMM dd, yyyy').format(reportEnd)} | Generated ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
          ),
          subTitleStyle,
        );
      }
      detail.merge(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0),
      );
      detail.merge(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 1),
      );
      detail.setMergedCellStyle(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        titleStyle,
      );
      detail.setMergedCellStyle(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        subTitleStyle,
      );

      final detailHeaders = [
        'Date',
        'Transaction',
        'Amount',
        'Flow Section',
        'Category',
        'Tag',
        'Type',
        'Deductible',
      ];
      for (int c = 0; c < detailHeaders.length; c++) {
        setCell(
          detail,
          c,
          3,
          excel_lib.TextCellValue(detailHeaders[c]),
          headerStyle,
        );
      }

      int detailRow = 4;
      for (final tx in transactions) {
        final tags = extractTags(tx.title);
        final titleLower = tx.title.toLowerCase();
        final category =
            (tx.plaidCategory?['primary']?.toString().trim().isNotEmpty ??
                false)
            ? tx.plaidCategory!['primary'].toString()
            : (tx.category != null
                  ? 'Category #${tx.category}'
                  : 'Uncategorized');
        final tagText = tags.isEmpty ? '-' : tags.join(', ');

        setCell(
          detail,
          0,
          detailRow,
          excel_lib.TextCellValue(DateFormat('yyyy-MM-dd').format(tx.dateTime)),
        );
        setCell(
          detail,
          1,
          detailRow,
          excel_lib.TextCellValue(cleanTitle(tx.title)),
        );
        setCell(
          detail,
          2,
          detailRow,
          excel_lib.DoubleCellValue(tx.amount),
          currencyStyle,
        );
        setCell(
          detail,
          3,
          detailRow,
          excel_lib.TextCellValue(classifyFlowSection(titleLower)),
        );
        setCell(detail, 4, detailRow, excel_lib.TextCellValue(category));
        setCell(detail, 5, detailRow, excel_lib.TextCellValue(tagText));
        setCell(detail, 6, detailRow, excel_lib.TextCellValue(tx.type));
        setCell(
          detail,
          7,
          detailRow,
          excel_lib.TextCellValue(tx.deductible ? 'Yes' : 'No'),
        );
        detailRow++;
      }

      // Tab 3: Reconciliation
      recon.setColumnWidth(descCol, 40);
      for (var c = firstMonthCol; c <= ytdCol; c++) {
        recon.setColumnWidth(c, c == ytdCol ? 15 : 11);
      }

      for (int c = 0; c < totalCols; c++) {
        setCell(
          recon,
          c,
          0,
          excel_lib.TextCellValue('Cash Flow Reconciliation'),
          titleStyle,
        );
      }
      recon.merge(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        excel_lib.CellIndex.indexByColumnRow(columnIndex: ytdCol, rowIndex: 0),
      );
      recon.setMergedCellStyle(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        titleStyle,
      );

      setCell(recon, 0, 2, excel_lib.TextCellValue('Line Item'), headerStyle);
      for (int i = 0; i < keys.length; i++) {
        setCell(
          recon,
          i + 1,
          2,
          excel_lib.TextCellValue(keyToLabel[keys[i]] ?? keys[i]),
          headerStyle,
        );
      }
      setCell(
        recon,
        ytdCol,
        2,
        excel_lib.TextCellValue('Period Total'),
        headerStyle,
      );

      int reconRow = 4;
      void writeReconRow(
        String label,
        Map<String, double> values, {
        bool total = false,
      }) {
        setCell(
          recon,
          0,
          reconRow,
          excel_lib.TextCellValue(label),
          total ? totalLabelStyle : labelStyle,
        );
        for (int i = 0; i < keys.length; i++) {
          setCell(
            recon,
            i + 1,
            reconRow,
            excel_lib.DoubleCellValue(values[keys[i]] ?? 0),
            total ? currencyTotalStyle : currencyStyle,
          );
        }
        setCell(
          recon,
          ytdCol,
          reconRow,
          excel_lib.DoubleCellValue(periodTotal(values)),
          total ? currencyTotalStyle : currencyStyle,
        );
        reconRow++;
      }

      writeReconRow('Net Income', netIncomeMap);
      writeReconRow('Adjustments', adjustmentsMap);
      writeReconRow('Balance Sheet Changes', wcMap);
      writeReconRow(
        'Reconciliation Total',
        reconciliationTotalMap,
        total: true,
      );
      writeReconRow('Net Change in Cash', netChangeMap, total: true);
      writeReconRow('Variance', varianceMap, total: true);

      List<int> applySummaryMonthGrouping(List<int> xlsxBytes) {
        try {
          final archive = ZipDecoder().decodeBytes(xlsxBytes);
          final sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
          if (sheetFile == null || sheetFile.content == null) return xlsxBytes;

          final xmlText = utf8.decode(sheetFile.content as List<int>);
          final doc = XmlDocument.parse(xmlText);
          final worksheet = doc.rootElement;
          final sheetData = worksheet.getElement('sheetData');
          if (sheetData == null) return xlsxBytes;

          XmlElement? cols = worksheet.getElement('cols');
          if (cols == null) {
            cols = XmlElement(XmlName('cols'));
            final idx = worksheet.children.indexOf(sheetData);
            if (idx >= 0) {
              worksheet.children.insert(idx, cols);
            } else {
              worksheet.children.add(cols);
            }
          }

          cols.children.add(
            XmlElement(XmlName('col'), [
              XmlAttribute(XmlName('min'), '2'),
              XmlAttribute(XmlName('max'), (keys.length + 1).toString()),
              XmlAttribute(XmlName('outlineLevel'), '1'),
            ]),
          );

          final sheetFormatPr = worksheet.getElement('sheetFormatPr');
          sheetFormatPr?.setAttribute('outlineLevelCol', '1');

          XmlElement? sheetPr = worksheet.getElement('sheetPr');
          if (sheetPr == null) {
            sheetPr = XmlElement(XmlName('sheetPr'));
            worksheet.children.insert(0, sheetPr);
          }
          if (sheetPr.getElement('outlinePr') == null) {
            sheetPr.children.add(
              XmlElement(XmlName('outlinePr'), [
                XmlAttribute(XmlName('summaryBelow'), '1'),
                XmlAttribute(XmlName('summaryRight'), '1'),
              ]),
            );
          }

          final patched = utf8.encode(doc.toXmlString());
          archive.addFile(
            ArchiveFile('xl/worksheets/sheet1.xml', patched.length, patched),
          );
          return ZipEncoder().encode(archive) ?? xlsxBytes;
        } catch (_) {
          return xlsxBytes;
        }
      }

      final bytes = excel.save();
      if (bytes == null) {
        throw Exception('Unable to generate Excel file.');
      }
      final groupedBytes = applySummaryMonthGrouping(bytes);

      await downloadFile(
        '${orgName.replaceAll(' ', '_')}_Cash_Flow_Analysis_${DateFormat('yyyyMMdd').format(reportStart)}_${DateFormat('yyyyMMdd').format(reportEnd)}.xlsx',
        groupedBytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e, st) {
      dev.log('Excel Export Error: $e\n$st');
      showSnackBar('Please review Excel generation: $e', isError: true);
    }
  }

  // Helper method to update filter and trigger data fetch
  Future<void> _updateFilter(
    int index,
    FinancialReportController controller, {
    int? year,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    DateTime? start;
    DateTime end = today;

    if (index == 0) {
      start = today.subtract(const Duration(days: 6));
    } else if (index == 1) {
      start = today.subtract(const Duration(days: 29));
    } else if (index == 2) {
      start = today.subtract(const Duration(days: 89));
    } else if (index == 3) {
      start = today.subtract(const Duration(days: 364));
    } else if (index == 4) {
      final yr = year ?? _selectedYear ?? now.year;
      start = DateTime(yr, 1, 1);
      end = yr == now.year ? today : DateTime(yr, 12, 31);
    }

    setState(() {
      _selectedFilterIdx = index;
      if (year != null) _selectedYear = year;
      _startDate = start;
      _endDate = end;
    });

    if (start != null) {
      await controller.fetchAndAggregateData(startDate: start, endDate: end);
    }
  }

  Future<void> _selectCustomRange(FinancialReportController controller) async {
    DateTime? tempStart;
    DateTime? tempEnd;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF0F1E37) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  "Select Date Range",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
                const SizedBox(height: 24),
                SfDateRangePicker(
                  view: DateRangePickerView.month,
                  selectionMode: DateRangePickerSelectionMode.range,
                  headerStyle: DateRangePickerHeaderStyle(
                    textStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  monthCellStyle: DateRangePickerMonthCellStyle(
                    textStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                    todayTextStyle: const TextStyle(color: orangeColor),
                  ),
                  rangeSelectionColor: orangeColor.withValues(alpha: 0.1),
                  startRangeSelectionColor: orangeColor,
                  endRangeSelectionColor: orangeColor,
                  todayHighlightColor: orangeColor,
                  onSelectionChanged:
                      (DateRangePickerSelectionChangedArgs args) {
                        if (args.value is PickerDateRange) {
                          tempStart = args.value.startDate;
                          tempEnd = args.value.endDate;
                        }
                      },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: AppText(
                        "Close",
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        if (tempStart != null && tempEnd != null) {
                          final ts = tempStart!;
                          final te = tempEnd!;
                          final s = DateTime(ts.year, ts.month, ts.day);
                          final e = DateTime(te.year, te.month, te.day);
                          setState(() {
                            _selectedFilterIdx = 5;
                            _startDate = s;
                            _endDate = e;
                          });
                          controller.fetchAndAggregateData(
                            startDate: s,
                            endDate: e,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const AppText(
                        "Select",
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeFilter(FinancialReportController controller) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black26
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          _filterItem(
            "7 Days",
            _selectedFilterIdx == 0,
            () => _updateFilter(0, controller),
          ),
          _filterItem(
            "30 Days",
            _selectedFilterIdx == 1,
            () => _updateFilter(1, controller),
          ),
          _filterItem(
            "3 Months",
            _selectedFilterIdx == 2,
            () => _updateFilter(2, controller),
          ),
          _filterItem(
            "12 Months",
            _selectedFilterIdx == 3,
            () => _updateFilter(3, controller),
          ),
          _buildYearDropdown(controller),
          _filterItem(
            "Custom",
            _selectedFilterIdx == 5,
            () => _selectCustomRange(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildYearDropdown(FinancialReportController controller) {
    final int currentYear = DateTime.now().year;
    final List<int> years = List.generate(5, (index) => currentYear - index);
    final bool isSelected = _selectedFilterIdx == 4;

    return PopupMenuButton<int>(
      offset: const Offset(0, 40),
      onSelected: (year) => _updateFilter(4, controller, year: year),
      itemBuilder: (context) => years
          .map(
            (y) => PopupMenuItem(
              value: y,
              child: Text(
                '$y',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  fontFamily: 'Outfit',
                ),
              ), // Standard Text to avoid AppText's auto-formatting
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : Colors.black.withValues(alpha: 0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white12
                      : Colors.black12,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSelected
                  ? (_selectedYear != null ? '$_selectedYear' : "Yearly")
                  : "Yearly",
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87)
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white38
                          : Colors.black45),
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 12,
              color: isSelected
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87)
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white38
                        : Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterItem(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : Colors.black.withValues(alpha: 0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white12
                      : Colors.black12,
                )
              : null,
        ),
        child: AppText(
          text,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87)
              : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white38
                    : Colors.black45),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const moneyInColor = Color(0xFF19C37D);
    const moneyOutColor = Color(0xFF2B7FFF);
    const netCashColor = Color(0xFFF2C94C);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    final backgroundColor = isDark
        ? const Color(0xFF071223)
        : const Color(0xFFF8FAFC);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth <= 1024;

    return GetBuilder<FinancialReportController>(
      tag: getCurrentOrganization!.id.toString(),
      builder: (controller) {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final trendSeries = controller.trendChartSeries;
        final operatingCash = controller.operatingCashFlow.value;
        final investingCash = controller.investingCashFlow.value;
        final financingCash = controller.financingCashFlow.value;

        final totalIn =
            (operatingCash > 0 ? operatingCash : 0.0) +
            (investingCash > 0 ? investingCash : 0.0) +
            (financingCash > 0 ? financingCash : 0.0);
        final totalOut =
            (operatingCash < 0 ? -operatingCash : 0.0) +
            (investingCash < 0 ? -investingCash : 0.0) +
            (financingCash < 0 ? -financingCash : 0.0);
        final netCash = operatingCash + investingCash + financingCash;

        final netInvestingFinancing = netCash;

        final prevIn = controller.prevPeriodIncome.value;
        final prevOut = controller.prevPeriodExpenses.value;
        final prevNet = controller.prevPeriodNetIncome.value;

        final double incomeChange = prevIn != 0
            ? ((totalIn - prevIn) / prevIn) * 100
            : (totalIn > 0 ? 100 : 0);
        final double expensesChange = prevOut != 0
            ? ((totalOut - prevOut) / prevOut) * 100
            : (totalOut > 0 ? 100 : 0);
        final double netCashChange = prevNet != 0
            ? ((netCash - prevNet) / prevNet) * 100
            : (netCash > 0 ? 100 : 0);

        return Container(
          color: backgroundColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Title & Filter Header
                isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            "Cash Flow Dashboard",
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          const SizedBox(height: 12),
                          _buildTimeFilter(controller),
                          if (_startDate != null && _endDate != null) ...[
                            const SizedBox(height: 8),
                            AppText(
                              "${DateFormat('MMM dd, yyyy').format(_startDate!)} – ${DateFormat('MMM dd, yyyy').format(_endDate!)}",
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black45,
                            ),
                          ],
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                "Cash Flow Dashboard",
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              if (_startDate != null && _endDate != null) ...[
                                const SizedBox(height: 4),
                                AppText(
                                  "${DateFormat('MMM dd, yyyy').format(_startDate!)} – ${DateFormat('MMM dd, yyyy').format(_endDate!)}",
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black45,
                                ),
                              ],
                            ],
                          ),
                          _buildTimeFilter(controller),
                        ],
                      ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PopupMenuButton<String>(
                        offset: const Offset(0, 40),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'csv') _exportCSV(controller);
                          if (value == 'pdf') {
                            ExportModalWidget.showPdfModal(
                              context: context,
                              companyName:
                                  (getCurrentOrganization?.name ?? '')
                                      .trim()
                                      .isNotEmpty
                                  ? (getCurrentOrganization?.name ?? '').trim()
                                  : 'Booksmart',
                              companyAddress: 'Address not available',
                              reportType: ExportPdfReportType.cashFlow,
                              initialStartDate: _startDate,
                              initialEndDate: _endDate,
                              onExport: (request) async {
                                setState(() {
                                  _startDate = request.startDate;
                                  _endDate = request.endDate;
                                });
                                await controller.fetchAndAggregateData(
                                  startDate: request.startDate,
                                  endDate: request.endDate,
                                );
                                final liveData = _buildCashFlowPdfData(
                                  controller,
                                  request,
                                );
                                await PdfExportService()
                                    .exportCashFlowPresentationPdf(
                                      request,
                                      cashFlowData: liveData,
                                    );
                              },
                            );
                          }
                          if (value == 'excel') {
                            ExportModalWidget.showExcelModal(
                              context: context,
                              companyName:
                                  (getCurrentOrganization?.name ?? '')
                                      .trim()
                                      .isNotEmpty
                                  ? (getCurrentOrganization?.name ?? '').trim()
                                  : 'Booksmart',
                              companyAddress: 'Address not available',
                              reportType: ExportPdfReportType.cashFlow,
                              initialStartDate: _startDate,
                              initialEndDate: _endDate,
                              onExport: (request) async {
                                setState(() {
                                  _startDate = request.startDate;
                                  _endDate = request.endDate;
                                });
                                await controller.fetchAndAggregateData(
                                  startDate: request.startDate,
                                  endDate: request.endDate,
                                );
                                _exportExcel(controller);
                              },
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'csv',
                            child: AppText(
                              "Export CSV",
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          PopupMenuItem<String>(
                            height: 1,
                            padding: EdgeInsets.zero,
                            enabled: false,
                            child: Divider(
                              height: 1,
                              thickness: 0.2,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'pdf',
                            child: AppText(
                              "Export PDF",
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          PopupMenuItem<String>(
                            height: 1,
                            padding: EdgeInsets.zero,
                            enabled: false,
                            child: Divider(
                              height: 1,
                              thickness: 0.2,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'excel',
                            child: AppText(
                              "Export Excel",
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                        child: Builder(
                          builder: (context) {
                            bool isHovered = false;
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => isHovered = true),
                                  onExit: (_) =>
                                      setState(() => isHovered = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isHovered
                                          ? orangeColor.withValues(alpha: 0.1)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: orangeColor,
                                        width: 1.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        AppText(
                                          "EXPORT",
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: orangeColor,
                                        ),
                                        SizedBox(width: 6),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                          color: orangeColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      InkWell(
                        onTap: () => showUploadTaxDocumentDialog(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: orangeColor, width: 1.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const AppText(
                            "UPLOAD",
                            color: orangeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => _showManualCashFlowDialog(controller),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: orangeColor, width: 1.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const AppText(
                            "ADJUST CASH FLOW",
                            color: orangeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return isNarrow
                        ? Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: screenWidth - 32,
                                child: _premiumKPICard(
                                  title: "Money In",
                                  value: _formatCurrency(totalIn),
                                  change: incomeChange,
                                  isCurrency: true,
                                  timeframe: _getTimeframeLabel(),
                                  valueColor: moneyInColor,
                                ),
                              ),
                              SizedBox(
                                width: screenWidth - 32,
                                child: _premiumKPICard(
                                  title: "Money Out",
                                  value: _formatCurrency(totalOut),
                                  change: expensesChange,
                                  isCurrency: true,
                                  timeframe: _getTimeframeLabel(),
                                  valueColor: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              SizedBox(
                                width: screenWidth - 32,
                                child: _premiumKPICard(
                                  title: "Net Cash",
                                  value: _formatCurrency(netCash),
                                  change: netCashChange,
                                  isCurrency: true,
                                  timeframe: _getTimeframeLabel(),
                                  isNetCash: true,
                                ),
                              ),
                            ],
                          )
                        : IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _premiumKPICard(
                                    title: "Money In",
                                    value: _formatCurrency(totalIn),
                                    change: incomeChange,
                                    isCurrency: true,
                                    timeframe: _getTimeframeLabel(),
                                    valueColor: moneyInColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _premiumKPICard(
                                    title: "Money Out",
                                    value: _formatCurrency(totalOut),
                                    change: expensesChange,
                                    isCurrency: true,
                                    timeframe: _getTimeframeLabel(),
                                    valueColor: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _premiumKPICard(
                                    title: "Net Cash",
                                    value: _formatCurrency(netCash),
                                    change: netCashChange,
                                    isCurrency: true,
                                    timeframe: _getTimeframeLabel(),
                                    isNetCash: true,
                                  ),
                                ),
                              ],
                            ),
                          );
                  },
                ),
                const SizedBox(height: 24),

                // 🔹 Middle Section: Chart Area
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black12,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.15 : 0.03,
                        ),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "Cash Flow Trend",
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (_startDate != null &&
                                        _endDate != null &&
                                        controller
                                            .trendGranularityLabel
                                            .isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AppText(
                                            "${DateFormat('MMM dd, yyyy').format(_startDate!)} – ${DateFormat('MMM dd, yyyy').format(_endDate!)}",
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: textSecondary,
                                          ),
                                          Container(
                                            width: 1,
                                            height: 12,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            color: Colors.white,
                                          ),
                                          AppText(
                                            controller.trendGranularityLabel,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                          ),
                                        ],
                                      )
                                    else ...[
                                      if (_startDate != null &&
                                          _endDate != null)
                                        AppText(
                                          "${DateFormat('MMM dd, yyyy').format(_startDate!)} – ${DateFormat('MMM dd, yyyy').format(_endDate!)}",
                                          fontSize: 12,
                                          color: textSecondary,
                                        ),
                                      if (controller
                                          .trendGranularityLabel
                                          .isNotEmpty)
                                        AppText(
                                          controller.trendGranularityLabel,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: textSecondary,
                                        ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCashFlowMetricToggles(isDark),
                              Container(
                                width: 1,
                                height: 18,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                              InkWell(
                                onTap: () => setState(
                                  () => _comparePriorPeriod =
                                      !_comparePriorPeriod,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: Transform.scale(
                                          scale: 0.78,
                                          child: Checkbox(
                                            value: _comparePriorPeriod,
                                            onChanged: (v) => setState(
                                              () => _comparePriorPeriod =
                                                  v ?? false,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity: const VisualDensity(
                                              horizontal: -4,
                                              vertical: -4,
                                            ),
                                            activeColor: orangeColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      AppText(
                                        "vs prior period",
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                        disableFormat: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 320,
                        child: trendSeries.isEmpty
                            ? Center(
                                child: AppText(
                                  "Data will appear for this range",
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black45,
                                ),
                              )
                            : _buildCashFlowTrendChart(
                                controller,
                                trendSeries,
                                moneyInColor,
                                moneyOutColor,
                                netCashColor,
                                isDark,
                              ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 24,
                          runSpacing: 8,
                          children: [
                            if (_showMoneyIn)
                              _LegendItem(
                                color: moneyInColor,
                                label: "Money In",
                              ),
                            if (_showMoneyOut)
                              _LegendItem(
                                color: moneyOutColor,
                                label: "Money Out",
                              ),
                            if (_showNetCash)
                              _LegendItem(
                                color: netCashColor,
                                label: "Net Cash",
                                isLine: true,
                              ),
                            if (_comparePriorPeriod)
                              _LegendItem(
                                color: isDark ? Colors.white54 : Colors.black45,
                                label: "Prior net",
                                isLine: true,
                                isDashed: true,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // 🔹 Bottom Section: Cash Flow Statement Container (match trend chart surface)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: .05)
                          : Colors.black12,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.15 : 0.03,
                        ),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              "Cash Flow Statement",
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            const SizedBox(height: 24),

                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 950;
                                final opItems = _getOperatingItems(controller);
                                final investItems = _getInvestingItems(
                                  controller,
                                );
                                final financeItems = _getFinancingItems(
                                  controller,
                                );

                                final statementCardFill = Theme.of(
                                  context,
                                ).colorScheme.surface;
                                if (isWide) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildStatementCard(
                                          "Operating Activities",
                                          opItems,
                                          controller.operatingCashFlow.value,
                                          const Color(0xFF19C37D),
                                          statementCardFill,
                                          textPrimary,
                                          textSecondary,
                                          equalHeightWithNeighbors: false,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildStatementCard(
                                          "Investing Activities",
                                          investItems,
                                          controller.investingCashFlow.value,
                                          const Color(0xFF2B7FFF),
                                          statementCardFill,
                                          textPrimary,
                                          textSecondary,
                                          equalHeightWithNeighbors: false,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildStatementCard(
                                          "Financing Activities",
                                          financeItems,
                                          controller.financingCashFlow.value,
                                          const Color(0xFFF2C94C),
                                          statementCardFill,
                                          textPrimary,
                                          textSecondary,
                                          equalHeightWithNeighbors: false,
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      _buildStatementCard(
                                        "Operating Activities",
                                        opItems,
                                        controller.operatingCashFlow.value,
                                        const Color(0xFF19C37D),
                                        statementCardFill,
                                        textPrimary,
                                        textSecondary,
                                        equalHeightWithNeighbors: false,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStatementCard(
                                        "Investing Activities",
                                        investItems,
                                        controller.investingCashFlow.value,
                                        const Color(0xFF2B7FFF),
                                        statementCardFill,
                                        textPrimary,
                                        textSecondary,
                                        equalHeightWithNeighbors: false,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStatementCard(
                                        "Financing Activities",
                                        financeItems,
                                        controller.financingCashFlow.value,
                                        const Color(0xFFF2C94C),
                                        statementCardFill,
                                        textPrimary,
                                        textSecondary,
                                        equalHeightWithNeighbors: false,
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // 3️⃣ Shared Footer: Net Change in Cash
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.02)
                              : Colors.black.withValues(alpha: 0.02),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(24),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText(
                                "Net Cash: ",
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              AppText(
                                _formatCurrencyExact(netInvestingFinancing),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: netCash < 0
                                    ? const Color(0xFFE57373)
                                    : const Color(0xFF19C37D),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const RecentDocumentsWidget(type: 'cf'),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _premiumKPICard({
    required String title,
    required String value,
    required double change,
    required bool isCurrency,
    String? timeframe,
    Color? valueColor,
    bool isNetCash = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPositive = change >= 0;
    const Color softRed = Color(0xFFE57373);
    const Color cashGreen = Color(0xFF19C37D);
    final Color changeColor = isPositive ? cashGreen : softRed;
    final IconData changeIcon = isPositive
        ? Icons.arrow_upward
        : Icons.arrow_downward;

    // Explicit value color rules as per reqs
    Color displayValueColor = valueColor ?? Colors.white;
    if (isNetCash) {
      displayValueColor = cashGreen; // ✅ Consistently Green as per req
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black)
                  .withValues(alpha: 0.05),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppText(
            title,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AppText(
              value,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: displayValueColor,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? changeColor.withValues(alpha: 0.15)
                      : softRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(changeIcon, size: 12, color: changeColor),
                    const SizedBox(width: 4),
                    AppText(
                      "${change.abs().toStringAsFixed(1)}%",
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: changeColor,
                    ),
                  ],
                ),
              ),
              AppText(
                "vs previous $timeframe",
                fontSize: 11,
                color: Colors.white30,
                disableFormat: true, // ✅ Force lowercase vs
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeframeLabel() {
    switch (_selectedFilterIdx) {
      case 0:
        return "7 days";
      case 1:
        return "30 days";
      case 2:
        return "3 months";
      case 3:
        return "12 months";
      case 4:
        return "year";
      default:
        return "period";
    }
  }

  String _manualSectionLabel(CashFlowManualSection section) {
    switch (section) {
      case CashFlowManualSection.operating:
        return 'Operating Adjustment';
      case CashFlowManualSection.investing:
        return 'Investing Activity';
      case CashFlowManualSection.financing:
        return 'Financing Activity';
      case CashFlowManualSection.other:
        return 'Other Adjustment';
    }
  }

  Future<void> _showManualCashFlowDialog(
    FinancialReportController controller,
  ) async {
    final org = getCurrentOrganization;
    final user = authPerson;
    if (org == null || user == null) {
      showSnackBar(
        'Please make sure organization and user are available.',
        isError: true,
      );
      return;
    }

    final categoryCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime selectedDate =
        _endDate ??
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    CashFlowManualSection selectedSection = CashFlowManualSection.operating;
    bool isNonCash = false;
    String suggestionMessage = '';
    bool suggestionIsError = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked == null) return;
              setDialogState(() {
                selectedDate = DateTime(picked.year, picked.month, picked.day);
              });
            }

            void useSuggestion() {
              final combined =
                  '${categoryCtrl.text} ${notesCtrl.text} ${amountCtrl.text}';
              if (combined.trim().isEmpty) {
                setDialogState(() {
                  suggestionMessage =
                      'Add category or notes first to get a suggestion.';
                  suggestionIsError = true;
                });
                return;
              }
              final suggested = _manualEntryService.suggestSection(combined);
              setDialogState(() {
                selectedSection = suggested;
                suggestionMessage =
                    'Suggested: ${_manualSectionLabel(suggested)}';
                suggestionIsError = false;
                if (combined.toLowerCase().contains('depreciation') ||
                    combined.toLowerCase().contains('amortization')) {
                  isNonCash = true;
                }
              });
            }

            Future<void> save() async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (categoryCtrl.text.trim().isEmpty || amount == null) {
                setDialogState(() {
                  suggestionMessage = 'Category and valid amount are required.';
                  suggestionIsError = true;
                });
                return;
              }

              final entry = CashFlowManualEntryModel(
                section: selectedSection,
                category: categoryCtrl.text.trim(),
                amount: amount,
                date: selectedDate,
                notes: notesCtrl.text.trim(),
                isNonCash: isNonCash,
              );
              await _manualEntryService.saveManualEntry(
                userId: user.id,
                orgId: org.id,
                entry: entry,
              );
              await controller.fetchAndAggregateData(
                startDate: _startDate,
                endDate: _endDate,
              );
              if (mounted) Get.back();
              showSnackBar('Manual cash flow entry added.');
            }

            return AlertDialog(
              title: const Text('Adjust Cash Flow'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<CashFlowManualSection>(
                        initialValue: selectedSection,
                        decoration: const InputDecoration(labelText: 'Section'),
                        items: CashFlowManualSection.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(_manualSectionLabel(s)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => selectedSection = v);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: categoryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Category / Adjustment Name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Amount'),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Date'),
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(selectedDate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Notes'),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Non-cash adjustment'),
                        value: isNonCash,
                        onChanged: (v) =>
                            setDialogState(() => isNonCash = v ?? false),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: useSuggestion,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Use AI Suggestion'),
                        ),
                      ),
                      if (suggestionMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            suggestionMessage,
                            style:
                                const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFE57373),
                                  fontWeight: FontWeight.w600,
                                ).copyWith(
                                  color: suggestionIsError
                                      ? const Color(0xFFE57373)
                                      : const Color(0xFF19C37D),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: save,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCashFlowMetricToggles(bool isDark) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        setState(() {
          if (value == "money_in") _showMoneyIn = !_showMoneyIn;
          if (value == "money_out") _showMoneyOut = !_showMoneyOut;
          if (value == "net") _showNetCash = !_showNetCash;
        });
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem<String>(
          value: "money_in",
          checked: _showMoneyIn,
          child: const AppText("Money In", fontSize: 12),
        ),
        CheckedPopupMenuItem<String>(
          value: "money_out",
          checked: _showMoneyOut,
          child: const AppText("Money Out", fontSize: 12),
        ),
        CheckedPopupMenuItem<String>(
          value: "net",
          checked: _showNetCash,
          child: const AppText("Net", fontSize: 12),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              "Filter",
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down,
              size: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  double _cfTrendMinY(List<Map<String, dynamic>> series) {
    double minVal = 0;
    for (final d in series) {
      final inc = (d['income'] as num?)?.toDouble() ?? 0;
      final exp = (d['expense'] as num?)?.toDouble() ?? 0;
      final net = (d['net'] as num?)?.toDouble() ?? 0;
      if (_showMoneyIn && inc < minVal) minVal = inc;
      if (_showMoneyOut && exp < minVal) minVal = exp;
      if (_showNetCash && net < minVal) minVal = net;
    }
    if (minVal == 0) return 0;
    final interval = minVal.abs() > 50000 ? 10000.0 : 5000.0;
    return (minVal / interval).floor() * interval;
  }

  double _cfTrendMaxY(List<Map<String, dynamic>> series) {
    double maxVal = 0;
    for (final d in series) {
      final inc = (d['income'] as num?)?.toDouble() ?? 0;
      final exp = (d['expense'] as num?)?.toDouble() ?? 0;
      final net = (d['net'] as num?)?.toDouble() ?? 0;
      if (_showMoneyIn && inc > maxVal) maxVal = inc;
      if (_showMoneyOut && exp > maxVal) maxVal = exp;
      if (_showNetCash && net > maxVal) maxVal = net;
    }
    if (maxVal == 0) return 10000;
    final interval = maxVal > 50000 ? 10000.0 : 5000.0;
    return (maxVal / interval).ceil() * interval;
  }

  /// Same as fl_chart [BarChartAlignment.spaceAround] group centers (uniform group width).
  List<double> _cfBarGroupCenterXsSpaceAround(
    double viewWidth,
    int n,
    double groupWidth,
  ) {
    if (n <= 0) return [];
    final sumWidth = groupWidth * n;
    final spaceAvailable = viewWidth - sumWidth;
    final eachSpace = spaceAvailable / (n * 2);
    var tempX = 0.0;
    final out = <double>[];
    for (var i = 0; i < n; i++) {
      tempX += eachSpace;
      tempX += groupWidth / 2;
      out.add(tempX);
      tempX += groupWidth / 2;
      tempX += eachSpace;
    }
    return out;
  }

  double _cfTrendGroupWidth(int n) {
    final rodW = (320 / n).clamp(4.0, 16.0);
    var rodCount = 0;
    if (_showMoneyIn) rodCount++;
    if (_showMoneyOut) rodCount++;
    if (rodCount == 0) return 1.0;
    if (rodCount == 1) return rodW;
    return rodW * 2 + 6;
  }

  Widget _buildCashFlowTrendChart(
    FinancialReportController controller,
    List<Map<String, dynamic>> series,
    Color inColor,
    Color outColor,
    Color netColor,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const leftAxis = 50.0;
        final usableW = (constraints.maxWidth - leftAxis).clamp(
          1.0,
          double.infinity,
        );
        final minY = _cfTrendMinY(series);
        final maxY = _cfTrendMaxY(series);
        final n = series.length;
        final bool compactXAxis = n > 6;
        final prev = controller.prevTrendChartSeries;
        final compareLen = prev.length < n ? prev.length : n;
        final groupW = _cfTrendGroupWidth(n);
        final centers = _cfBarGroupCenterXsSpaceAround(usableW, n, groupW);
        final spotXN = centers.map((c) => c / usableW).toList();
        final bottomReserved = compactXAxis ? 52.0 : 42.0;

        final lineBars = <LineChartBarData>[];
        if (_showNetCash) {
          lineBars.add(
            LineChartBarData(
              spots: List.generate(n, (i) {
                final net = (series[i]['net'] as num?)?.toDouble() ?? 0;
                final xn = i < spotXN.length ? spotXN[i] : 0.5;
                return FlSpot(xn, net);
              }),
              isCurved: true,
              curveSmoothness: 0.35,
              color: netColor,
              barWidth: 1.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, p, b, i) => FlDotCirclePainter(
                  radius: n > 60 ? 2.0 : 2.5,
                  color: netColor,
                  strokeWidth: 1,
                  strokeColor: Colors.white70,
                ),
              ),
              aboveBarData: BarAreaData(
                show: true,
                applyCutOffY: true,
                cutOffY: 0,
                color: const Color(0xFFE57373).withValues(alpha: 0.22),
              ),
            ),
          );
        }
        if (_comparePriorPeriod && compareLen > 0) {
          lineBars.add(
            LineChartBarData(
              spots: List.generate(compareLen, (i) {
                final net = (prev[i]['net'] as num?)?.toDouble() ?? 0;
                final xn = i < spotXN.length ? spotXN[i] : 0.5;
                return FlSpot(xn, net);
              }),
              isCurved: true,
              curveSmoothness: 0.35,
              color: isDark ? Colors.white54 : Colors.black38,
              barWidth: 2,
              dashArray: [6, 4],
              dotData: const FlDotData(show: false),
            ),
          );
        }

        final tooltipEnabled = _showNetCash && lineBars.isNotEmpty;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: minY,
                baselineY: 0,
                barTouchData: const BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= n) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(
                            top: compactXAxis ? 6.0 : 12.0,
                          ),
                          child: AppText(
                            series[idx]['label']?.toString() ?? '',
                            fontSize: compactXAxis ? 8 : 10,
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                      reservedSize: bottomReserved,
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: (maxY - minY) / 4,
                      getTitlesWidget: (v, meta) {
                        if ((v - meta.max).abs() < 0.01) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AppText(
                            _formatCompact(v),
                            fontSize: 10,
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(n, (i) {
                  final data = series[i];
                  final inc = (data['income'] as num?)?.toDouble() ?? 0;
                  final exp = (data['expense'] as num?)?.toDouble() ?? 0;
                  final rods = <BarChartRodData>[];
                  if (_showMoneyIn) {
                    rods.add(
                      BarChartRodData(
                        toY: inc,
                        color: inColor,
                        width: (320 / n).clamp(4.0, 16.0),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [inColor.withValues(alpha: 0.4), inColor],
                        ),
                      ),
                    );
                  }
                  if (_showMoneyOut) {
                    rods.add(
                      BarChartRodData(
                        toY: exp,
                        color: outColor,
                        width: (320 / n).clamp(4.0, 16.0),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [outColor.withValues(alpha: 0.4), outColor],
                        ),
                      ),
                    );
                  }
                  if (rods.isEmpty) {
                    rods.add(
                      BarChartRodData(
                        toY: 0.001,
                        color: Colors.transparent,
                        width: 1,
                      ),
                    );
                  }
                  return BarChartGroupData(x: i, barsSpace: 6, barRods: rods);
                }),
              ),
            ),
            LineChart(
              LineChartData(
                minX: 0,
                maxX: 1,
                maxY: maxY,
                minY: minY,
                baselineY: 0,
                lineTouchData: LineTouchData(
                  enabled: tooltipEnabled,
                  handleBuiltInTouches: tooltipEnabled,
                  touchSpotThreshold: 18,
                  distanceCalculator: (touch, spotPixel) =>
                      (touch - spotPixel).distance,
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes
                        .map(
                          (_) => TouchedSpotIndicatorData(
                            FlLine(color: Colors.transparent, strokeWidth: 0),
                            const FlDotData(show: false),
                          ),
                        )
                        .toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    maxContentWidth: 240,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipColor: (_) => isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF0F1E37),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        if (s.barIndex != 0) return null;
                        final idx = s.spotIndex;
                        if (idx < 0 || idx >= series.length) return null;
                        final row = series[idx];
                        final dateStr = row['tooltipDate']?.toString() ?? '';
                        final bucketStart = row['bucketStart'];
                        final bucketDate = bucketStart is DateTime
                            ? bucketStart
                            : DateTime.tryParse(bucketStart?.toString() ?? '');
                        final hasSpecificDay = RegExp(
                          r'\b[A-Za-z]{3,9}\s+\d{1,2}\b',
                        ).hasMatch(dateStr);
                        final tooltipDateText = dateStr.isNotEmpty
                            ? (hasSpecificDay || bucketDate == null
                                  ? dateStr
                                  : DateFormat(
                                      'MMMM dd, yyyy',
                                    ).format(bucketDate))
                            : (bucketDate != null
                                  ? DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(bucketDate)
                                  : '');
                        final inc = (row['income'] as num?)?.toDouble() ?? 0;
                        final exp = (row['expense'] as num?)?.toDouble() ?? 0;
                        final net = (row['net'] as num?)?.toDouble() ?? 0;
                        return LineTooltipItem(
                          '',
                          const TextStyle(color: Colors.white, fontSize: 12),
                          children: [
                            TextSpan(
                              text: '$tooltipDateText\n',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                            TextSpan(
                              text: 'Money In: ${_formatCurrencyExact(inc)}\n',
                              style: TextStyle(
                                color: inColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                            TextSpan(
                              text: 'Money Out: ${_formatCurrencyExact(exp)}\n',
                              style: TextStyle(
                                color: outColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                            TextSpan(
                              text: 'Net Cash: ${_formatCurrencyExact(net)}',
                              style: TextStyle(
                                color: netColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: bottomReserved,
                      getTitlesWidget: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: lineBars.isEmpty
                    ? [
                        LineChartBarData(
                          spots: const [FlSpot(0, 0)],
                          dotData: const FlDotData(show: false),
                        ),
                      ]
                    : lineBars,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatementCard(
    String title,
    List<Map<String, dynamic>> items,
    double total,
    Color accentColor,
    Color cardColor,
    Color textPrimary,
    Color textSecondary, {
    bool equalHeightWithNeighbors = false,
  }) {
    bool isExpanded = _expandedCards[title] ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget detailSection = isExpanded
        ? Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            item["label"],
                            fontSize: 13,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          AppText(
                            _formatCurrencyExact(item["value"]),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: (item["value"] as double) < 0
                                ? const Color(0xFFE57373)
                                : textPrimary,
                          ),
                        ],
                      ),
                    ),
                    if (idx < items.length - 1)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                  ],
                );
              }).toList(),
            ),
          )
        : const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () =>
                        setState(() => _expandedCards[title] = !isExpanded),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: AppText(
                              title,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_right,
                            size: 20,
                            color: textSecondary.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    detailSection,
                    if (items.length < 3)
                      SizedBox(height: (3 - items.length) * 44.0),
                  ],
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(24),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: accentColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          title == "Operating Activities"
                              ? "Operating Cash Flow"
                              : (title == "Investing Activities"
                                    ? "Investing Cash Flow"
                                    : "Financing Cash Flow"),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                        ),
                        AppText(
                          _formatCurrencyExact(total),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: total >= 0
                              ? const Color(0xFF19C37D)
                              : const Color(0xFFE57373),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getOperatingItems(
    FinancialReportController controller,
  ) {
    return [
      {"label": "Net Income", "value": controller.netIncome.value},
      {"label": "Adjustments", "value": controller.operatingAdjustments.value},
      {
        "label": "Working Capital",
        "value": controller.workingCapitalChanges.value,
      },
      {"label": "Other Operating", "value": controller.operatingOther.value},
    ];
  }

  List<Map<String, dynamic>> _getInvestingItems(
    FinancialReportController controller,
  ) {
    return [
      {"label": "Asset Purchases", "value": controller.assetPurchases.value},
      {"label": "Investments", "value": controller.investmentActivities.value},
    ];
  }

  List<Map<String, dynamic>> _getFinancingItems(
    FinancialReportController controller,
  ) {
    return [
      {"label": "Loans", "value": controller.loanActivities.value},
      {"label": "Contributions", "value": controller.ownerContributions.value},
      {"label": "Distributions", "value": controller.distributions.value},
      {"label": "Other Financing", "value": controller.financingOther.value},
    ];
  }

  String _formatCurrency(double value) {
    final formatted = NumberFormat("#,##0.00").format(value.abs());
    return value < 0 ? '-\$$formatted' : '\$$formatted';
  }

  String _formatCompact(double value) {
    if (value == 0) return "\$0";
    final isNegative = value < 0;
    final absVal = value.abs();
    String formatted;
    if (absVal >= 1000000) {
      formatted = "\$${(absVal / 1000000).toStringAsFixed(1)}M";
    } else if (absVal >= 1000) {
      formatted = "\$${(absVal / 1000).toStringAsFixed(0)}k";
    } else {
      formatted = "\$${absVal.toInt()}";
    }
    return isNegative ? "-$formatted" : formatted;
  }

  String _formatCurrencyExact(double value) {
    final formatted = NumberFormat("#,##0.00").format(value.abs());
    return value < 0 ? '-\$$formatted' : '\$$formatted';
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isLine;
  final bool isDashed;
  const _LegendItem({
    required this.color,
    required this.label,
    this.isLine = false,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLine)
          isDashed
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 2,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 5,
                      height: 2,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                )
              : Container(width: 16, height: 2, color: color)
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 8),
        AppText(
          label,
          fontSize: 11,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : Colors.black54,
        ),
      ],
    );
  }
}
