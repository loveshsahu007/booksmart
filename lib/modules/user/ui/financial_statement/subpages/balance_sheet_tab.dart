import 'dart:ui' as ui;
import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/user/controllers/financial_report_controller.dart';
import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'package:intl/intl.dart';
import 'package:booksmart/modules/common/controllers/auth_controller.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:booksmart/modules/user/ui/tax_filling/upload_tax_doc_dialog.dart';
import 'package:booksmart/widgets/recent_documents_widget.dart';
import 'package:booksmart/widgets/app_button.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf_gen;
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:booksmart/utils/downloader.dart';
import 'package:booksmart/modules/user/ui/financial_statement/balance_sheet_excel_service.dart';
import 'package:booksmart/modules/user/ui/financial_statement/export_modal_widget.dart';

class BalanceSheetTab extends StatefulWidget {
  const BalanceSheetTab({super.key});

  @override
  State<BalanceSheetTab> createState() => _BalanceSheetTabState();
}

class _BalanceSheetTabState extends State<BalanceSheetTab> with TickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  int _selectedFilterIdx = 2; // 3 Months by default
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Initialize with default 3 months (Index 1)
    final now = DateTime.now();
    _startDate = now.subtract(const Duration(days: 90));
    _endDate = now;
  }

  Future<void> _selectDate(BuildContext context, FinancialReportController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: orangeColor,
              onPrimary: Colors.black,
              surface: isDark ? const Color(0xFF0F1E37) : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black87,
            ),
            scaffoldBackgroundColor: isDark ? const Color(0xFF0F1E37) : Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      final asOf = DateTime(picked.year, picked.month, picked.day);
      final start = _deriveStartDateForEndDate(asOf);
      setState(() {
        selectedDate = picked;
        _selectedFilterIdx = 5;
        _startDate = start;
        _endDate = asOf;
      });
      await controller.fetchAndAggregateData(
        startDate: start,
        endDate: asOf,
      );
    }
  }

  DateTime? _deriveStartDateForEndDate(DateTime endDate) {
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    switch (_selectedFilterIdx) {
      case 0:
        return end.subtract(const Duration(days: 7));
      case 1:
        return end.subtract(const Duration(days: 30));
      case 2:
        return end.subtract(const Duration(days: 90));
      case 3:
        return end.subtract(const Duration(days: 180));
      case 4:
        final yr = _selectedYear ?? end.year;
        return DateTime(yr, 1, 1);
      case 5:
        if (_startDate == null) return null;
        return DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      default:
        return null;
    }
  }

  Future<void> _selectCustomRange(FinancialReportController controller) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime? tempStart;
    DateTime? tempEnd;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF0F1E37) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText("Select Date Range", fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              const SizedBox(height: 24),
              SfDateRangePicker(
                view: DateRangePickerView.month,
                selectionMode: DateRangePickerSelectionMode.range,
                headerStyle: DateRangePickerHeaderStyle(
                  textStyle: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                ),
                monthCellStyle: DateRangePickerMonthCellStyle(
                  textStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  todayTextStyle: const TextStyle(color: orangeColor),
                ),
                rangeTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
                monthViewSettings: DateRangePickerMonthViewSettings(
                  viewHeaderStyle: DateRangePickerViewHeaderStyle(
                    textStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                  ),
                ),
                yearCellStyle: DateRangePickerYearCellStyle(
                  textStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  todayTextStyle: const TextStyle(color: orangeColor),
                ),
                rangeSelectionColor: orangeColor.withValues(alpha: 0.1),
                startRangeSelectionColor: orangeColor,
                endRangeSelectionColor: orangeColor,
                todayHighlightColor: orangeColor,
                onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
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
                    child: const AppText("Close", color: Colors.white38),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (tempStart != null && tempEnd != null) {
                        setState(() {
                          _selectedFilterIdx = 5;
                          _startDate = tempStart;
                          _endDate = tempEnd;
                        });
                        controller.fetchAndAggregateData(startDate: tempStart, endDate: tempEnd);
                        Navigator.pop(context);
                      }
                    },
                    child: const AppText("Select", color: Colors.black, fontWeight: FontWeight.bold),
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

  void _exportExcel(FinancialReportController controller) async {
    try {
      final asOfDate = _endDate ?? DateTime.now();
      final orgName = getCurrentOrganization?.name ?? 'Organization';
      final excel = excel_lib.Excel.createExcel();
      final sheet = excel['Balance Sheet'];
      final existingSheets = List<String>.from(excel.tables.keys);
      for (final name in existingSheets) {
        final isDefaultSheet = name.toLowerCase().startsWith('sheet');
        if (isDefaultSheet && name != 'Balance Sheet') {
          excel.delete(name);
        }
      }

      final headerStyle = excel_lib.CellStyle(
        bold: true,
        fontColorHex: excel_lib.ExcelColor.fromHexString('FFFFFFFF'),
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('FF0F1E37'),
        horizontalAlign: excel_lib.HorizontalAlign.Center,
      );
      final sectionStyle = excel_lib.CellStyle(
        bold: true,
        fontColorHex: excel_lib.ExcelColor.fromHexString('FFFFFFFF'),
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('FF1F4E78'),
      );
      final labelStyle = excel_lib.CellStyle(
        horizontalAlign: excel_lib.HorizontalAlign.Left,
      );
      final totalStyle = excel_lib.CellStyle(
        bold: true,
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('FFE9F0FA'),
      );
      final currencyStyle = excel_lib.CellStyle(
        numberFormat: const excel_lib.CustomNumericNumFormat(
          formatCode: r'$#,##0.00;[Red]-$#,##0.00',
        ),
        horizontalAlign: excel_lib.HorizontalAlign.Right,
      );
      final currencyTotalStyle = currencyStyle.copyWith(
        boldVal: true,
        backgroundColorHexVal: excel_lib.ExcelColor.fromHexString('FFE9F0FA'),
      );

      void setCell(
        int c,
        int r,
        excel_lib.CellValue v, [
        excel_lib.CellStyle? style,
      ]) {
        final cell = sheet.cell(
          excel_lib.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
        );
        cell.value = v;
        if (style != null) {
          cell.cellStyle = style;
        }
      }

      sheet.setColumnWidth(0, 42);
      sheet.setColumnWidth(1, 18);

      setCell(0, 0, excel_lib.TextCellValue('Balance Sheet'), headerStyle);
      setCell(1, 0, excel_lib.TextCellValue('Balance Sheet'), headerStyle);
      setCell(
        0,
        1,
        excel_lib.TextCellValue(
          '$orgName | As of ${DateFormat('MMM dd, yyyy').format(asOfDate)}',
        ),
        headerStyle,
      );
      setCell(
        1,
        1,
        excel_lib.TextCellValue(
          '$orgName | As of ${DateFormat('MMM dd, yyyy').format(asOfDate)}',
        ),
        headerStyle,
      );
      sheet.merge(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0),
      );
      sheet.merge(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1),
      );

      int row = 3;
      void writeHeader() {
        setCell(0, row, excel_lib.TextCellValue('Line Item'), headerStyle);
        setCell(1, row, excel_lib.TextCellValue('Amount'), headerStyle);
        row++;
      }

      void writeSection(String title) {
        setCell(0, row, excel_lib.TextCellValue(title), sectionStyle);
        setCell(1, row, excel_lib.TextCellValue(' '), sectionStyle);
        row++;
      }

      void writeRows(Map<String, double> map) {
        map.forEach((key, value) {
          final clean = key.contains(']') ? key.split(']').last.trim() : key;
          setCell(0, row, excel_lib.TextCellValue(clean), labelStyle);
          setCell(1, row, excel_lib.DoubleCellValue(value), currencyStyle);
          row++;
        });
      }

      void writeTotal(String label, double value) {
        setCell(0, row, excel_lib.TextCellValue(label), totalStyle);
        setCell(1, row, excel_lib.DoubleCellValue(value), currencyTotalStyle);
        row++;
      }

      final currentAssets =
          controller.currentAssetsBreakdown.values.fold(0.0, (a, b) => a + b);
      final fixedAssets =
          controller.fixedAssetsBreakdown.values.fold(0.0, (a, b) => a + b);
      final otherAssets =
          controller.otherAssetsBreakdown.values.fold(0.0, (a, b) => a + b);
      final totalAssets = controller.totalAssets.value;
      final currentLiabilities = controller.currentLiabilitiesBreakdown.values
          .fold(0.0, (a, b) => a + b);
      final longTermLiabilities = controller.longTermLiabilitiesBreakdown.values
          .fold(0.0, (a, b) => a + b);
      final totalLiabilities = controller.totalLiabilities.value;
      final equityMap = <String, double>{
        'Net Income (Retained Earnings)': controller.netIncome.value,
        ...controller.ownerEquityBreakdown,
      };
      final totalEquity = totalAssets - totalLiabilities;

      writeHeader();
      writeSection('ASSETS');
      writeSection('Current Assets');
      writeRows(controller.currentAssetsBreakdown);
      writeSection('Fixed Assets');
      writeRows(controller.fixedAssetsBreakdown);
      writeSection('Other Assets');
      writeRows(controller.otherAssetsBreakdown);
      writeTotal('TOTAL ASSETS', totalAssets);

      row++;
      writeSection('LIABILITIES');
      writeSection('Current Liabilities');
      writeRows(controller.currentLiabilitiesBreakdown);
      writeSection('Long-Term Liabilities');
      writeRows(controller.longTermLiabilitiesBreakdown);
      writeTotal('TOTAL LIABILITIES', totalLiabilities);

      row++;
      writeSection('OWNER\'S EQUITY');
      writeRows(equityMap);
      writeTotal('TOTAL EQUITY', totalEquity);
      writeTotal('TOTAL LIABILITIES + EQUITY', totalLiabilities + totalEquity);

      final bytes = excel.save();
      if (bytes == null) {
        throw Exception('Unable to generate Excel file.');
      }
      await downloadFile(
        'Balance_Sheet_${DateFormat('yyyyMMdd').format(asOfDate)}.xlsx',
        bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e, st) {
      dev.log('Excel Export Error: $e\n$st');
      showSnackBar('Please review Excel generation: $e', isError: true);
    }
  }

  // Define some styles inside the method scope or as reusable markers
  static final netProfitStyle = excel_lib.CellStyle(
    bold: true,
    fontColorHex: excel_lib.ExcelColor.fromHexString('#FFFFFF'),
    backgroundColorHex: excel_lib.ExcelColor.fromHexString('#0F1E37'),
  );

  void _exportCSV(FinancialReportController controller) async {
    final buffer = StringBuffer();
    final orgName = getCurrentOrganization?.name ?? 'Financial Report';
    final dateStr = _endDate != null ? "As of ${DateFormat('MMM dd, yyyy').format(_endDate!)}" : "Current Period";

    buffer.writeln('Balance Sheet Report');
    buffer.writeln('Organization,$orgName');
    buffer.writeln('Date,$dateStr');
    buffer.writeln('');

    void addCsvSection(String title, Map<String, double> items, double total) {
      buffer.writeln(title.toUpperCase());
      buffer.writeln('Description,Amount');
      items.forEach((key, val) {
        final cleanKey = key.contains(']') ? key.split(']').last.trim() : key;
        buffer.writeln('"$cleanKey",$val');
      });
      buffer.writeln('TOTAL $title,$total');
      buffer.writeln('');
    }

    final currentAssets = controller.currentAssetsBreakdown.values.fold(0.0, (a, b) => a + b);
    final fixedAssets = controller.fixedAssetsBreakdown.values.fold(0.0, (a, b) => a + b);
    final otherAssets = controller.otherAssetsBreakdown.values.fold(0.0, (a, b) => a + b);
    final totalAssets = controller.totalAssets.value;

    addCsvSection('Current Assets', controller.currentAssetsBreakdown, currentAssets);
    addCsvSection('Fixed Assets', controller.fixedAssetsBreakdown, fixedAssets);
    addCsvSection('Other Assets', controller.otherAssetsBreakdown, otherAssets);
    buffer.writeln('TOTAL ASSETS,$totalAssets');
    buffer.writeln('');

    final currentLiab = controller.currentLiabilitiesBreakdown.values.fold(0.0, (a, b) => a + b);
    final longTermLiab = controller.longTermLiabilitiesBreakdown.values.fold(0.0, (a, b) => a + b);
    final totalLiab = controller.totalLiabilities.value;

    addCsvSection('Current Liabilities', controller.currentLiabilitiesBreakdown, currentLiab);
    addCsvSection('Long-Term Liabilities', controller.longTermLiabilitiesBreakdown, longTermLiab);

    final equityMap = {
      "Net Income (Retained Earnings)": controller.netIncome.value,
      ...controller.ownerEquityBreakdown,
    };
    final totalEquity = totalAssets - totalLiab;
    addCsvSection('Equity', equityMap, totalEquity);

    buffer.writeln('TOTAL LIABILITIES & EQUITY,${totalLiab + totalEquity}');

    final csvBytes = utf8.encode(buffer.toString());
    await downloadFile('Balance_Sheet_${orgName.replaceAll(" ", "_")}.csv', csvBytes, mimeType: 'text/csv');
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
        return "6 months";
      case 4:
        return "year";
      default:
        return "period";
    }
  }

  double _percentChange(double current, double previous) {
    if (previous.abs() < 0.000001) return 0.0;
    final pct = ((current - previous) / previous) * 100;
    if (pct.isNaN || pct.isInfinite) return 0.0;
    return pct;
  }

  Widget _outlineButton(String text, {required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: orangeColor, width: 1.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AppText(
          text.toUpperCase(),
          color: orangeColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _premiumKPICard({
    required String title,
    required String value,
    required double change,
    required bool isCurrency,
    String? timeframe,
    Color? borderColor,
    double? borderWidth,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = change >= 0;
    final Color softRed = const Color(0xFFE57373);
    final Color changeColor = isPositive ? const Color(0xFF19C37D) : softRed;
    final IconData changeIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    
    final bool isNegativeValue = value.contains('-') || (isCurrency && value.startsWith('-\$'));
    final Color valueColor = isNegativeValue ? softRed : (isDark ? Colors.white : Colors.black87);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? (isDark ? Colors.yellow.withValues(alpha: 0.3) : Colors.black12), width: borderWidth ?? 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AppText(value, fontSize: 28, fontWeight: FontWeight.w900, color: valueColor),
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
                  color: isPositive ? changeColor.withValues(alpha: 0.15) : softRed.withValues(alpha: 0.15),
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
              AppText("vs previous $timeframe", fontSize: 11, color: isDark ? Colors.white30 : Colors.black38, disableFormat: true),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FinancialReportController>(
      tag: getCurrentOrganization!.id.toString(),
      builder: (controller) {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: orangeColor));
        }

        final totalAssets = controller.totalAssets.value;
        final totalLiabilities = controller.totalLiabilities.value;
        final totalEquity = totalAssets - totalLiabilities;
        final previousEquity =
            controller.prevPeriodAssets.value - controller.prevPeriodLiabilities.value;
        final assetsChange =
            _percentChange(totalAssets, controller.prevPeriodAssets.value);
        final liabilitiesChange =
            _percentChange(totalLiabilities, controller.prevPeriodLiabilities.value);
        final equityChange = _percentChange(totalEquity, previousEquity);
        final currentRatioChange =
            _percentChange(controller.currentRatio, controller.prevPeriodCurrentRatio);
        final debtToEquityChange =
            _percentChange(controller.debtToEquity, controller.prevPeriodDebtToEquity);
        final roeChange = _percentChange(
          controller.returnOnEquity,
          controller.prevPeriodReturnOnEquity,
        );

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isNarrow = screenWidth <= 1024;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isNarrow ? 12 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Title & Filter Header
                isNarrow 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "Balance Sheet",
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      if (_endDate != null) ...[
                        const SizedBox(height: 4),
                        AppText(
                          "As of ${DateFormat('MMM dd, yyyy').format(_endDate!)}",
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildTimeFilter(controller),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            "Balance Sheet",
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          if (_endDate != null) ...[
                            const SizedBox(height: 4),
                            AppText(
                              "As of ${DateFormat('MMM dd, yyyy').format(_endDate!)}",
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black45,
                            ),
                          ],
                        ],
                      ),
                      _buildTimeFilter(controller),
                    ],
                  ),
                const SizedBox(height: 24),

                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PopupMenuButton<String>(
                        offset: const Offset(0, 40),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          if (value == 'csv') _exportCSV(controller);
                          if (value == 'pdf') {
                            ExportModalWidget.showPdfModal(
                              context: context,
                              companyName:
                                  (getCurrentOrganization?.name ?? '')
                                          .trim()
                                          .isNotEmpty
                                      ? (getCurrentOrganization?.name ?? '')
                                            .trim()
                                      : 'Booksmart',
                              companyAddress: 'Address not available',
                              reportType: ExportPdfReportType.balanceSheet,
                              useSingleDate: true,
                              singleDateLabel: 'As Of Date',
                              initialEndDate: _endDate,
                              onExport: (request) async {
                                final DateTime asOfDate = request.endDate;
                                final start = _deriveStartDateForEndDate(asOfDate);
                                setState(() {
                                  _startDate = start;
                                  _endDate = asOfDate;
                                });
                                await controller.fetchAndAggregateData(
                                  startDate: start,
                                  endDate: asOfDate,
                                );
                                await _exportPDF(controller);
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
                                      ? (getCurrentOrganization?.name ?? '')
                                            .trim()
                                      : 'Booksmart',
                              companyAddress: 'Address not available',
                              reportType: ExportPdfReportType.balanceSheet,
                              useSingleDate: true,
                              singleDateLabel: 'As Of Date',
                              initialEndDate: _endDate,
                              onExport: (request) async {
                                final DateTime asOfDate = request.endDate;
                                final start = _deriveStartDateForEndDate(asOfDate);
                                setState(() {
                                  _startDate = start;
                                  _endDate = asOfDate;
                                });
                                await controller.fetchAndAggregateData(
                                  startDate: start,
                                  endDate: asOfDate,
                                );
                                _exportExcel(controller);
                              },
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'csv', child: AppText("Export CSV", fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                          PopupMenuItem<String>(height: 1, padding: EdgeInsets.zero, enabled: false, child: Divider(height: 1, thickness: 0.2, color: isDark ? Colors.white24 : Colors.black12)),
                          PopupMenuItem(value: 'pdf', child: AppText("Export PDF", fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                          PopupMenuItem<String>(height: 1, padding: EdgeInsets.zero, enabled: false, child: Divider(height: 1, thickness: 0.2, color: isDark ? Colors.white24 : Colors.black12)),
                          PopupMenuItem(value: 'excel', child: AppText("Export Excel", fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                        ],
                        child: Builder(
                          builder: (context) {
                            bool isHovered = false;
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return MouseRegion(
                                  onEnter: (_) => setState(() => isHovered = true),
                                  onExit: (_) => setState(() => isHovered = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isHovered ? orangeColor.withValues(alpha: 0.1) : Colors.transparent,
                                      border: Border.all(color: orangeColor, width: 1.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        AppText("EXPORT", fontSize: 12, fontWeight: FontWeight.w600, color: orangeColor),
                                        SizedBox(width: 6),
                                        Icon(Icons.keyboard_arrow_down, size: 16, color: orangeColor),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      _outlineButton("Upload", onPressed: () => showUploadTaxDocumentDialog(type: 'bs')),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 🔹 Top Section: 3 Large Cards
                isNarrow 
                ? Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: screenWidth - 36,
                      child: _premiumKPICard(
                        title: "Total Assets",
                        value: _formatCurrency(totalAssets),
                        change: assetsChange,
                        isCurrency: true,
                        timeframe: _getTimeframeLabel(),
                        borderColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.15) : Colors.black12,
                        borderWidth: 0.8,
                      ),
                    ),
                    SizedBox(
                      width: screenWidth - 36,
                      child: _premiumKPICard(
                        title: "Total Liabilities",
                        value: _formatCurrency(totalLiabilities),
                        change: liabilitiesChange,
                        isCurrency: true,
                        timeframe: _getTimeframeLabel(),
                        borderColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.15) : Colors.black12,
                        borderWidth: 0.8,
                      ),
                    ),
                    SizedBox(
                      width: screenWidth - 36,
                      child: _premiumKPICard(
                        title: "Equity",
                        value: _formatCurrency(totalEquity),
                        change: equityChange,
                        isCurrency: true,
                        timeframe: _getTimeframeLabel(),
                        borderColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.15) : Colors.black12,
                        borderWidth: 0.8,
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
                          title: "Total Assets",
                          value: _formatCurrency(totalAssets),
                          change: assetsChange,
                          isCurrency: true,
                          timeframe: _getTimeframeLabel(),
                          borderColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.15) : Colors.black12,
                          borderWidth: 0.8,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _premiumKPICard(
                          title: "Total Liabilities",
                          value: _formatCurrency(totalLiabilities),
                          change: liabilitiesChange,
                          isCurrency: true,
                          timeframe: _getTimeframeLabel(),
                          borderColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.15) : Colors.black12,
                          borderWidth: 0.8,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _premiumKPICard(
                          title: "Equity",
                          value: _formatCurrency(totalEquity),
                          change: equityChange,
                          isCurrency: true,
                          timeframe: _getTimeframeLabel(),
                          borderColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.15) : Colors.black12,
                          borderWidth: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 🔹 Second Row: 4 Small Ratio Cards
                isNarrow 
                ? Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: screenWidth - 36,
                      child: _premiumKPICard(
                        title: "Current Ratio",
                        value: controller.currentRatio.toStringAsFixed(2),
                        change: currentRatioChange,
                        isCurrency: false,
                        timeframe: _getTimeframeLabel(),
                        borderColor: Colors.yellow.withValues(alpha: 0.6),
                        borderWidth: 1.5,
                      ),
                    ),
                    SizedBox(
                      width: screenWidth - 36,
                      child: _premiumKPICard(
                        title: "Debt / Equity Ratio",
                        value: controller.debtToEquity.toStringAsFixed(2),
                        change: debtToEquityChange,
                        isCurrency: false,
                        timeframe: _getTimeframeLabel(),
                        borderColor: Colors.yellow.withValues(alpha: 0.6),
                        borderWidth: 1.5,
                      ),
                    ),
                    SizedBox(
                      width: screenWidth - 36,
                      child: _premiumKPICard(
                        title: "Return on Equity (ROE)",
                        value: "${controller.returnOnEquity.toStringAsFixed(1)}%",
                        change: roeChange,
                        isCurrency: false,
                        timeframe: _getTimeframeLabel(),
                        borderColor: Colors.yellow.withValues(alpha: 0.6),
                        borderWidth: 1.5,
                      ),
                    ),
                    SizedBox(
                      width: screenWidth - 36,
                      child: _premiumKPICard(
                        title: "Total Assets",
                        value: _formatCurrency(totalAssets),
                        change: assetsChange,
                        isCurrency: true,
                        timeframe: _getTimeframeLabel(),
                        borderColor: Colors.yellow.withValues(alpha: 0.6),
                        borderWidth: 1.5,
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
                          title: "Current Ratio",
                          value: controller.currentRatio.toStringAsFixed(2),
                          change: currentRatioChange,
                          isCurrency: false,
                          timeframe: _getTimeframeLabel(),
                          borderColor: Colors.yellow.withValues(alpha: 0.6),
                          borderWidth: 1.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _premiumKPICard(
                          title: "Debt / Equity Ratio",
                          value: controller.debtToEquity.toStringAsFixed(2),
                          change: debtToEquityChange,
                          isCurrency: false,
                          timeframe: _getTimeframeLabel(),
                          borderColor: Colors.yellow.withValues(alpha: 0.6),
                          borderWidth: 1.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _premiumKPICard(
                          title: "Return on Equity (ROE)",
                          value: "${controller.returnOnEquity.toStringAsFixed(1)}%",
                          change: roeChange,
                          isCurrency: false,
                          timeframe: _getTimeframeLabel(),
                          borderColor: Colors.yellow.withValues(alpha: 0.6),
                          borderWidth: 1.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _premiumKPICard(
                          title: "Total Assets",
                          value: _formatCurrency(totalAssets),
                          change: assetsChange,
                          isCurrency: true,
                          timeframe: _getTimeframeLabel(),
                          borderColor: Colors.yellow.withValues(alpha: 0.6),
                          borderWidth: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 🔹 Bottom Section: Side-by-Side Breakdown
                IntrinsicHeight(
                  child: isNarrow 
                   ? Column(
                      children: [
                        _buildBreakdownPanel(
                          title: "Assets",
                          sections: [
                            _BreakdownSection(title: "Current Assets", items: controller.currentAssetsBreakdown),
                            _BreakdownSection(title: "Fixed Assets", items: controller.fixedAssetsBreakdown),
                            _BreakdownSection(title: "Other Assets", items: controller.otherAssetsBreakdown),
                          ],
                          total: totalAssets,
                        ),
                        const SizedBox(height: 24),
                        _buildBreakdownPanel(
                          title: "Liabilities & Equity",
                          sections: [
                            _BreakdownSection(title: "Current Liabilities", items: controller.currentLiabilitiesBreakdown),
                            _BreakdownSection(title: "Long Term Liabilities", items: controller.longTermLiabilitiesBreakdown),
                            _BreakdownSection(title: "Equity", items: {
                               "Net Income (Retained Earnings)": controller.netIncome.value,
                               ...controller.ownerEquityBreakdown,
                            }),
                          ],
                          total: totalLiabilities + totalEquity,
                        ),
                      ],
                    )
                   : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildBreakdownPanel(
                          title: "Assets",
                          sections: [
                            _BreakdownSection(title: "Current Assets", items: controller.currentAssetsBreakdown),
                            _BreakdownSection(title: "Fixed Assets", items: controller.fixedAssetsBreakdown),
                            _BreakdownSection(title: "Other Assets", items: controller.otherAssetsBreakdown),
                          ],
                          total: totalAssets,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildBreakdownPanel(
                          title: "Liabilities & Equity",
                          sections: [
                            _BreakdownSection(title: "Current Liabilities", items: controller.currentLiabilitiesBreakdown),
                            _BreakdownSection(title: "Long Term Liabilities", items: controller.longTermLiabilitiesBreakdown),
                            _BreakdownSection(title: "Equity", items: {
                               "Net Income (Retained Earnings)": controller.netIncome.value,
                               ...controller.ownerEquityBreakdown,
                            }),
                          ],
                          total: totalLiabilities + totalEquity,
                        ),
                      ),
                    ],
                  ),
                ),
                const RecentDocumentsWidget(type: 'bs'),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  int? _selectedYear;

  // Helper method to update filter and trigger data fetch
  Future<void> _updateFilter(int index, FinancialReportController controller, {int? year}) async {
    DateTime now = DateTime.now();
    DateTime? start;
    DateTime end = now;

    if (index == 0) {
      start = now.subtract(const Duration(days: 7));
    } else if (index == 1) {
      start = now.subtract(const Duration(days: 30));
    } else if (index == 2) {
      start = now.subtract(const Duration(days: 90));
    } else if (index == 3) {
      start = now.subtract(const Duration(days: 180));
    } else if (index == 4) {
      // Specific Year
      final yr = year ?? _selectedYear ?? now.year;
      start = DateTime(yr, 1, 1);
      if (yr == now.year) {
        end = now;
      } else {
        end = DateTime(yr, 12, 31);
      }
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

  Widget _buildTimeFilter(FinancialReportController controller) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.black26 : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _filterItem("7 Days", _selectedFilterIdx == 0, () => _updateFilter(0, controller)),
          _filterItem("30 Days", _selectedFilterIdx == 1, () => _updateFilter(1, controller)),
          _filterItem("3 Months", _selectedFilterIdx == 2, () => _updateFilter(2, controller)),
          _filterItem("6 Months", _selectedFilterIdx == 3, () => _updateFilter(3, controller)),
          _buildYearDropdown(controller),
          _filterItem("Custom", _selectedFilterIdx == 5, () => _selectCustomRange(controller)),
        ],
      ),
    );
  }

  Widget _buildYearDropdown(FinancialReportController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int currentYear = DateTime.now().year;
    final List<int> years = List.generate(5, (index) => currentYear - index);
    final bool isSelected = _selectedFilterIdx == 4;

    return PopupMenuButton<int>(
      offset: const Offset(0, 40),
      onSelected: (year) => _updateFilter(4, controller, year: year),
      itemBuilder: (context) => years.map((y) => PopupMenuItem(
        value: y,
        child: AppText(y.toString(), fontSize: 13, disableFormat: true),
      )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF1E293B) : Colors.black.withValues(alpha: 0.05)) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: isDark ? Colors.white12 : Colors.black12) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              isSelected ? (_selectedYear?.toString() ?? "Yearly") : "Yearly",
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white38 : Colors.black45),
              disableFormat: true,
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 12, color: isSelected ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white38 : Colors.black45)),
          ],
        ),
      ),
    );
  }

  Widget _filterItem(String text, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF1E293B) : Colors.black.withValues(alpha: 0.05)) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: isDark ? Colors.white12 : Colors.black12) : null,
        ),
        child: AppText(
          text,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white38 : Colors.black45),
        ),
      ),
    );
  }

  Widget _buildBreakdownPanel({
    required String title,
    required List<_BreakdownSection> sections,
    required double total,
  }) {
    // Collect all items from all sections for the Pie Chart (Top 5 Overall)
    Map<String, double> allItems = {};
    for (var section in sections) {
       allItems.addAll(section.items);
    }

    final sortedItems = allItems.entries
        .where((e) => e.value != 0)
        .toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    
    final displayItems = sortedItems.take(5).toList();
    final bool hasData = allItems.isNotEmpty;

    final List<Color> palette = [
      const Color(0xFF10B981), // Emerald/Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF84CC16), // Lime
      const Color(0xFFF59E0B), // Amber
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(title, fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
                  const SizedBox(height: 4),
                  AppText(
                    "As of ${DateFormat('MMM dd, yyyy').format(_endDate ?? DateTime.now())}",
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.black54,
                  ),
                ],
              ),
              AppText(_formatCurrency(total), fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
            ],
          ),
          const SizedBox(height: 32),
          if (!hasData)
            SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pie_chart_outline, size: 48, color: isDark ? Colors.white24 : Colors.black12),
                    const SizedBox(height: 12),
                    AppText("No Data Available", color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  height: 180,
                  width: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: displayItems.asMap().entries.map((e) {
                        return PieChartSectionData(
                          color: palette[e.key % palette.length],
                          value: e.value.value.abs(),
                          title: '',
                          radius: 50,
                          showTitle: false,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 260, // Constrained width to prevent congestion
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            ...sections.map<Widget>((section) {
                              if (section.items.isEmpty) return const SizedBox.shrink();
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12, bottom: 6),
                                    child: Text(
                                      section.title.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: orangeColor.withValues(alpha: 0.7),
                                      ),
                                      softWrap: false,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                  ...section.items.entries.map((e) {
                                    final pct = total != 0 ? (e.value.abs() / total.abs()) * 100 : 0.0;
                                    int index = allItems.keys.toList().indexOf(e.key);
                                    return _buildLegendItem(
                                      e.key.contains(']') ? e.key.split(']').last.trim() : e.key,
                                      "${pct.toStringAsFixed(0)}%",
                                      palette[index % palette.length],
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String percent, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              label,
              fontSize: 11,
              color: Colors.white54,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 24), // Restored internal space
          AppText(percent, fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
          const SizedBox(width: 4),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color.withValues(alpha: 0.5), shape: BoxShape.circle)),
        const SizedBox(width: 6),
        AppText(label, fontSize: 11, color: Colors.white30),
      ],
    );
  }

  Widget _buildBreakdownRow({required String label, required double value, required double total}) {
    final double percentage = total != 0 ? (value.abs() / total.abs()) * 100 : 0;
    final bool isNegative = value < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: AppText(label, fontSize: 13, color: Colors.white70),
          ),
          AppText(
            isNegative ? "(${_formatCurrency(value.abs())})" : _formatCurrency(value),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isNegative ? Colors.redAccent : Colors.white,
          ),
          const SizedBox(width: 12),
          Container(
            width: 45,
            alignment: Alignment.centerRight,
            child: AppText(
              percentage == 0 ? "0%" : "${percentage.toStringAsFixed(1)}%",
              fontSize: 11,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPDF(FinancialReportController controller) async {
    try {
      final asOfDate = _endDate ?? DateTime.now();
      final orgName = getCurrentOrganization?.name ?? 'Organization';
      final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
      String fmt(double v) => formatter.format(v);

      final currentAssets =
          controller.currentAssetsBreakdown.values.fold(0.0, (a, b) => a + b);
      final fixedAssets =
          controller.fixedAssetsBreakdown.values.fold(0.0, (a, b) => a + b);
      final otherAssets =
          controller.otherAssetsBreakdown.values.fold(0.0, (a, b) => a + b);
      final totalAssets = controller.totalAssets.value;

      final currentLiabilities = controller.currentLiabilitiesBreakdown.values
          .fold(0.0, (a, b) => a + b);
      final longTermLiabilities = controller.longTermLiabilitiesBreakdown.values
          .fold(0.0, (a, b) => a + b);
      final totalLiabilities = controller.totalLiabilities.value;

      final equityMap = <String, double>{
        'Net Income (Retained Earnings)': controller.netIncome.value,
        ...controller.ownerEquityBreakdown,
      };
      final totalEquity = totalAssets - totalLiabilities;

      final pdf = pdf_gen.PdfDocument();
      final page = pdf.pages.add();
      final size = page.getClientSize();
      final titleFont = pdf_gen.PdfStandardFont(
        pdf_gen.PdfFontFamily.helvetica,
        18,
        style: pdf_gen.PdfFontStyle.bold,
      );
      final subtitleFont = pdf_gen.PdfStandardFont(
        pdf_gen.PdfFontFamily.helvetica,
        11,
      );
      final bodyFont = pdf_gen.PdfStandardFont(
        pdf_gen.PdfFontFamily.helvetica,
        10,
      );
      final boldFont = pdf_gen.PdfStandardFont(
        pdf_gen.PdfFontFamily.helvetica,
        10,
        style: pdf_gen.PdfFontStyle.bold,
      );

      page.graphics.drawString(
        orgName,
        titleFont,
        bounds: Rect.fromLTWH(20, 18, size.width - 40, 24),
      );
      page.graphics.drawString(
        'Balance Sheet',
        boldFont,
        bounds: Rect.fromLTWH(20, 44, size.width - 40, 18),
      );
      page.graphics.drawString(
        'As of ${DateFormat('MMM dd, yyyy').format(asOfDate)}',
        subtitleFont,
        bounds: Rect.fromLTWH(20, 62, size.width - 40, 16),
      );

      final grid = pdf_gen.PdfGrid();
      grid.columns.add(count: 2);
      grid.columns[0].width = size.width * 0.68;
      grid.columns[1].width = size.width * 0.28;
      final header = grid.headers.add(1)[0];
      header.cells[0].value = 'Line Item';
      header.cells[1].value = 'Amount';
      header.style = pdf_gen.PdfGridRowStyle(
        backgroundBrush: pdf_gen.PdfSolidBrush(pdf_gen.PdfColor(15, 30, 55)),
        textBrush: pdf_gen.PdfBrushes.white,
        font: boldFont,
      );

      void addSection(String title) {
        final row = grid.rows.add();
        row.cells[0].value = title;
        row.cells[0].columnSpan = 2;
        row.style = pdf_gen.PdfGridRowStyle(
          font: boldFont,
          textBrush: pdf_gen.PdfSolidBrush(pdf_gen.PdfColor(15, 30, 55)),
        );
      }

      void addRows(Map<String, double> data) {
        data.forEach((label, value) {
          final row = grid.rows.add();
          row.cells[0].value =
              label.contains(']') ? label.split(']').last.trim() : label;
          row.cells[1].value = fmt(value);
          row.cells[1].style = pdf_gen.PdfGridCellStyle(
            format: pdf_gen.PdfStringFormat(
              alignment: pdf_gen.PdfTextAlignment.right,
            ),
          );
          row.style = pdf_gen.PdfGridRowStyle(font: bodyFont);
        });
      }

      void addTotal(String label, double value) {
        final row = grid.rows.add();
        row.cells[0].value = label;
        row.cells[1].value = fmt(value);
        row.style = pdf_gen.PdfGridRowStyle(
          font: boldFont,
          backgroundBrush: pdf_gen.PdfSolidBrush(pdf_gen.PdfColor(233, 240, 250)),
        );
        row.cells[1].style = pdf_gen.PdfGridCellStyle(
          format: pdf_gen.PdfStringFormat(
            alignment: pdf_gen.PdfTextAlignment.right,
          ),
        );
      }

      addSection('ASSETS');
      addSection('Current Assets');
      addRows(controller.currentAssetsBreakdown);
      addSection('Fixed Assets');
      addRows(controller.fixedAssetsBreakdown);
      addSection('Other Assets');
      addRows(controller.otherAssetsBreakdown);
      addTotal('TOTAL ASSETS', totalAssets);

      addSection('LIABILITIES');
      addSection('Current Liabilities');
      addRows(controller.currentLiabilitiesBreakdown);
      addSection('Long-Term Liabilities');
      addRows(controller.longTermLiabilitiesBreakdown);
      addTotal('TOTAL LIABILITIES', totalLiabilities);

      addSection('OWNER\'S EQUITY');
      addRows(equityMap);
      addTotal('TOTAL EQUITY', totalEquity);
      addTotal('TOTAL LIABILITIES + EQUITY', totalLiabilities + totalEquity);

      grid.style = pdf_gen.PdfGridStyle(
        cellPadding: pdf_gen.PdfPaddings(left: 6, right: 6, top: 5, bottom: 5),
      );
      grid.draw(
        page: page,
        bounds: Rect.fromLTWH(20, 90, size.width - 40, 0),
      );

      final bytes = await pdf.save();
      pdf.dispose();
      await downloadFile(
        'Balance_Sheet_${DateFormat('yyyyMMdd').format(asOfDate)}.pdf',
        bytes,
        mimeType: 'application/pdf',
      );
    } catch (e, st) {
      dev.log('PDF Export Error: $e\n$st');
      showSnackBar('Please review PDF generation: $e', isError: true);
    }
  }

  String _formatCurrency(double value) {
    final formatted = NumberFormat("#,##0.00").format(value.abs());
    return value < 0 ? '-\$$formatted' : '\$$formatted';
  }
}

class _BreakdownSection {
  final String title;
  final Map<String, double> items;

  _BreakdownSection({required this.title, required this.items});
}
