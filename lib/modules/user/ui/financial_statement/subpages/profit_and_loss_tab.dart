import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:booksmart/constant/app_colors.dart';
import 'package:booksmart/widgets/app_text.dart';
import 'package:get/get.dart';

import 'package:booksmart/modules/user/controllers/financial_report_controller.dart';
import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'package:booksmart/modules/user/ui/financial_statement/export_modal_widget.dart';
import 'package:booksmart/modules/user/ui/financial_statement/pdf_export_service.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:booksmart/modules/user/ui/tax_filling/upload_tax_doc_dialog.dart';
import 'package:booksmart/widgets/recent_documents_widget.dart';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:booksmart/widgets/snackbar.dart';
import 'package:booksmart/utils/downloader.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'dart:math' as math;
import 'package:booksmart/models/transaction_model.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/utils/supabase.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _PnlExportData {
  const _PnlExportData({
    required this.incomeBreakdown,
    required this.expenseBreakdown,
    required this.periodicIncomeBreakdown,
    required this.periodicExpenseBreakdown,
    required this.periodicNetIncome,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netIncome,
  });

  final Map<String, double> incomeBreakdown;
  final Map<String, double> expenseBreakdown;
  final Map<String, Map<String, double>> periodicIncomeBreakdown;
  final Map<String, Map<String, double>> periodicExpenseBreakdown;
  final Map<String, double> periodicNetIncome;
  final double totalIncome;
  final double totalExpenses;
  final double netIncome;
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  // 0: 7d, 1: 30d, 2: 3mo, 3: 12mo, 4: Yearly, 5: Custom
  int _selectedFilterIdx = 2;
  int? _selectedYear;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _showRevenue = true;
  bool _showExpenses = true;
  bool _showProfit = true;
  bool _comparePriorPeriod = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _startDate = today.subtract(const Duration(days: 89));
    _endDate = today;
  }

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
                  color: isDark ? Colors.white : Colors.black87,
                ),
                const SizedBox(height: 24),
                SfDateRangePicker(
                  view: DateRangePickerView.month,
                  selectionMode: DateRangePickerSelectionMode.range,
                  headerStyle: DateRangePickerHeaderStyle(
                    textStyle: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  monthCellStyle: DateRangePickerMonthCellStyle(
                    textStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
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
                y.toString().replaceAll(RegExp(r'[^0-9]'), ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'Outfit',
                ),
              ),
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
                  ? (_selectedYear?.toString().replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        ) ??
                        "Yearly")
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

  // Removed hardcoded monthly data, will use controller.monthlyData

  void _exportCSV(FinancialReportController controller) async {
    final buffer = StringBuffer();
    final String orgName = getCurrentOrganization?.name ?? 'Organization';
    final String periodLabel =
        "${DateFormat('MM-dd-yyyy').format(_startDate ?? DateTime.now())}_to_${DateFormat('MM-dd-yyyy').format(_endDate ?? DateTime.now())}";

    buffer.writeln('Profit & Loss Statement - $orgName');
    buffer.writeln('Period: $periodLabel');
    buffer.writeln('');

    buffer.writeln('INCOME');
    buffer.writeln('Description,Amount');
    controller.incomeBreakdown.forEach((title, amount) {
      buffer.writeln('"$title",${amount.toStringAsFixed(2)}');
    });
    buffer.writeln(
      'Total Income,,${controller.totalIncome.value.toStringAsFixed(2)}',
    );
    buffer.writeln('');

    buffer.writeln('EXPENSES');
    buffer.writeln('Description,Amount');
    controller.expenseBreakdown.forEach((title, amount) {
      buffer.writeln('"$title",${amount.toStringAsFixed(2)}');
    });
    buffer.writeln(
      'Total Expenses,,${controller.totalExpenses.value.toStringAsFixed(2)}',
    );
    buffer.writeln('');

    buffer.writeln(
      'NET PROFIT/LOSS,,${controller.netIncome.value.toStringAsFixed(2)}',
    );

    final csvBytes = utf8.encode(buffer.toString());
    await downloadFile(
      '${orgName}_PL_$periodLabel.csv',
      csvBytes,
      mimeType: 'text/csv',
    );
  }

  void _exportExcel(FinancialReportController controller) async {
    try {
      final start =
          _startDate ?? DateTime.now().subtract(const Duration(days: 89));
      final end = _endDate ?? DateTime.now();
      if (end.isBefore(start)) {
        showSnackBar('End date must be on or after start date.', isError: true);
        return;
      }

      final totalMonths =
          (end.year - start.year) * 12 + end.month - start.month + 1;
      final useYearly = totalMonths > 12;
      final periodKeys = <String>[];
      final periodLabels = <String>[];
      if (useYearly) {
        for (int y = start.year; y <= end.year; y++) {
          periodKeys.add(y.toString());
          periodLabels.add(y.toString());
        }
      } else {
        DateTime current = DateTime(start.year, start.month, 1);
        final last = DateTime(end.year, end.month, 1);
        while (!current.isAfter(last)) {
          periodKeys.add(DateFormat('yyyy-MM').format(current));
          periodLabels.add(DateFormat('MMM yyyy').format(current));
          current = DateTime(current.year, current.month + 1, 1);
        }
      }
      final exportData = await _buildPnlExportData(start, end);

      double periodicValue(
        Map<String, Map<String, double>> periodicMap,
        String periodKey,
        String category,
      ) {
        if (useYearly) {
          double total = 0;
          periodicMap.forEach((key, row) {
            if (key.startsWith(periodKey)) {
              total += row[category] ?? 0;
            }
          });
          return total;
        }
        return periodicMap[periodKey]?[category] ?? 0;
      }

      final excel = excel_lib.Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['P&L Statement'];
      final orgName = getCurrentOrganization?.name ?? 'Booksmart';

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
      final totalLabelStyle = excel_lib.CellStyle(
        bold: true,
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('FFE9F0FA'),
      );
      final currencyStyle = excel_lib.CellStyle(
        numberFormat: const excel_lib.CustomNumericNumFormat(
          formatCode: r'$#,##0.00;[Red]-$#,##0.00',
        ),
        horizontalAlign: excel_lib.HorizontalAlign.Right,
      );
      final currencyBoldStyle = currencyStyle.copyWith(
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
        if (style != null) cell.cellStyle = style;
      }

      final totalCols = periodKeys.length + 2;
      final totalColIdx = periodKeys.length + 1;
      sheet.setColumnWidth(0, 34);
      for (int c = 1; c < totalColIdx; c++) {
        sheet.setColumnWidth(c, 14);
      }
      sheet.setColumnWidth(totalColIdx, 16);

      for (int c = 0; c < totalCols; c++) {
        setCell(
          c,
          0,
          excel_lib.TextCellValue('Profit & Loss Statement'),
          headerStyle,
        );
        setCell(
          c,
          1,
          excel_lib.TextCellValue(
            '$orgName | ${DateFormat('MMM dd, yyyy').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}',
          ),
          headerStyle,
        );
      }
      sheet.merge(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        excel_lib.CellIndex.indexByColumnRow(
          columnIndex: totalColIdx,
          rowIndex: 0,
        ),
      );
      sheet.merge(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        excel_lib.CellIndex.indexByColumnRow(
          columnIndex: totalColIdx,
          rowIndex: 1,
        ),
      );

      int row = 3;
      void writeColumnHeader() {
        setCell(0, row, excel_lib.TextCellValue('Description'), headerStyle);
        for (int i = 0; i < periodLabels.length; i++) {
          setCell(
            i + 1,
            row,
            excel_lib.TextCellValue(periodLabels[i]),
            headerStyle,
          );
        }
        setCell(
          totalColIdx,
          row,
          excel_lib.TextCellValue('TOTAL'),
          headerStyle,
        );
        row++;
      }

      void writeSectionTitle(String title) {
        for (int c = 0; c < totalCols; c++) {
          setCell(c, row, excel_lib.TextCellValue(' '), sectionStyle);
        }
        setCell(0, row, excel_lib.TextCellValue(title), sectionStyle);
        row++;
      }

      void writeCategoryRows(
        Map<String, double> breakdown,
        Map<String, Map<String, double>> periodicMap,
      ) {
        for (final category in breakdown.keys) {
          if (category.trim().isEmpty ||
              category.toLowerCase() == 'uncategorized') {
            continue;
          }
          setCell(0, row, excel_lib.TextCellValue(category), labelStyle);
          double rowTotal = 0;
          for (int i = 0; i < periodKeys.length; i++) {
            final v = periodicValue(periodicMap, periodKeys[i], category);
            rowTotal += v;
            setCell(i + 1, row, excel_lib.DoubleCellValue(v), currencyStyle);
          }
          setCell(
            totalColIdx,
            row,
            excel_lib.DoubleCellValue(rowTotal),
            currencyStyle,
          );
          row++;
        }
      }

      void writeTotalRow(
        String label,
        Map<String, Map<String, double>> periodicMap,
        double grandTotal,
      ) {
        setCell(0, row, excel_lib.TextCellValue(label), totalLabelStyle);
        for (int i = 0; i < periodKeys.length; i++) {
          double pTotal = 0;
          if (useYearly) {
            periodicMap.forEach((key, values) {
              if (key.startsWith(periodKeys[i])) {
                pTotal += values.values.fold(0.0, (a, b) => a + b);
              }
            });
          } else {
            pTotal = (periodicMap[periodKeys[i]] ?? {}).values.fold(
              0.0,
              (a, b) => a + b,
            );
          }
          setCell(
            i + 1,
            row,
            excel_lib.DoubleCellValue(pTotal),
            currencyBoldStyle,
          );
        }
        setCell(
          totalColIdx,
          row,
          excel_lib.DoubleCellValue(grandTotal),
          currencyBoldStyle,
        );
        row++;
      }

      writeSectionTitle('INCOME');
      writeColumnHeader();
      writeCategoryRows(
        exportData.incomeBreakdown,
        exportData.periodicIncomeBreakdown,
      );
      writeTotalRow(
        'Total Income',
        exportData.periodicIncomeBreakdown,
        exportData.totalIncome,
      );

      row++;
      writeSectionTitle('EXPENSES');
      writeColumnHeader();
      writeCategoryRows(
        exportData.expenseBreakdown,
        exportData.periodicExpenseBreakdown,
      );
      writeTotalRow(
        'Total Expenses',
        exportData.periodicExpenseBreakdown,
        exportData.totalExpenses,
      );

      row++;
      setCell(
        0,
        row,
        excel_lib.TextCellValue('NET PROFIT / LOSS'),
        sectionStyle,
      );
      for (int i = 0; i < periodKeys.length; i++) {
        double pNet = 0;
        if (useYearly) {
          exportData.periodicNetIncome.forEach((k, v) {
            if (k.startsWith(periodKeys[i])) pNet += v;
          });
        } else {
          pNet = exportData.periodicNetIncome[periodKeys[i]] ?? 0;
        }
        setCell(i + 1, row, excel_lib.DoubleCellValue(pNet), currencyBoldStyle);
      }
      setCell(
        totalColIdx,
        row,
        excel_lib.DoubleCellValue(exportData.netIncome),
        currencyBoldStyle,
      );

      final bytes = excel.save();
      if (bytes == null) {
        throw Exception('Unable to generate Excel file.');
      }
      await downloadFile(
        '${orgName.replaceAll(' ', '_')}_Periodic_PL.xlsx',
        bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e, st) {
      dev.log('Excel Export Error: $e\n$st');
      showSnackBar('Please review Excel generation: $e', isError: true);
    }
  }

  static const List<String> _exportExpenseKeywords = <String>[
    'starbucks',
    'mcdonald',
    'subway',
    'burger king',
    'uber',
    'lyft',
    'amazon',
    'netflix',
    'spotify',
    'airbnb',
    'airlines',
    'united',
    'delta',
    'shell',
    'chevron',
    'at&t',
    'verizon',
    'utilities',
    'comcast',
    'internet',
    'subscription',
    'insurance',
    'interest payment',
    'tax payment',
  ];

  String _sqlDateLocal(DateTime d) {
    final x = DateTime(d.year, d.month, d.day);
    final mm = x.month.toString().padLeft(2, '0');
    final dd = x.day.toString().padLeft(2, '0');
    return '${x.year}-$mm-$dd';
  }

  DateTime _nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

  bool _isKnownExportExpense(String title) {
    for (final kw in _exportExpenseKeywords) {
      if (title.contains(kw)) return true;
    }
    return false;
  }

  Future<_PnlExportData> _buildPnlExportData(
    DateTime start,
    DateTime end,
  ) async {
    final orgId = getCurrentOrganization?.id;
    if (orgId == null) {
      return const _PnlExportData(
        incomeBreakdown: {},
        expenseBreakdown: {},
        periodicIncomeBreakdown: {},
        periodicExpenseBreakdown: {},
        periodicNetIncome: {},
        totalIncome: 0,
        totalExpenses: 0,
        netIncome: 0,
      );
    }

    final subCategoryRows = await supabase
        .from(SupabaseTable.subCategory)
        .select('id,name');
    final Map<int, String> subCategoryNames = {
      for (final row in (subCategoryRows as List))
        (row['id'] as int): (row['name'] as String? ?? '').trim(),
    };

    final txRows = await supabase
        .from(SupabaseTable.transaction)
        .select()
        .eq('org_id', orgId)
        .gte('date_time', _sqlDateLocal(start))
        .lt('date_time', _sqlDateLocal(_nextDay(end)));

    final txs = (txRows as List)
        .map((e) => TransactionModel.fromJson(e))
        .toList();

    final incomeBreakdown = <String, double>{};
    final expenseBreakdown = <String, double>{};
    final periodicIncomeBreakdown = <String, Map<String, double>>{};
    final periodicExpenseBreakdown = <String, Map<String, double>>{};
    final periodicNetIncome = <String, double>{};

    String cleanTitle(String raw) =>
        raw.replaceAll(RegExp(r'\[.*?\]'), '').trim();

    for (final tx in txs) {
      final title = tx.title.toLowerCase();
      final absAmt = tx.amount.abs();
      final monthKey = DateFormat('yyyy-MM').format(tx.dateTime);

      periodicIncomeBreakdown[monthKey] ??= <String, double>{};
      periodicExpenseBreakdown[monthKey] ??= <String, double>{};
      periodicNetIncome[monthKey] ??= 0;

      final bool isAL =
          title.contains('[asset') ||
          title.contains('[liab') ||
          title.contains('equity') ||
          title.contains('[cf:');

      bool isIncome = false;
      bool isExpense = false;

      if (title.startsWith('[revenue]')) {
        isIncome = true;
      } else if (title.startsWith('[cogs]') ||
          title.contains('cost of goods')) {
        isExpense = true;
      } else if (title.startsWith('[opex]')) {
        isExpense = true;
      } else if (isAL) {
        // Excluded from P&L
      } else {
        final knownExpense = _isKnownExportExpense(title);
        final isTransfer =
            title.contains('credit card payment') ||
            title.contains('transfer to') ||
            title.contains('autopay');
        if (knownExpense) {
          isExpense = true;
        } else if (isTransfer) {
          // Ignore transfers
        } else if (tx.amount > 0) {
          isIncome = true;
        } else {
          isExpense = true;
        }
      }

      final fallback = cleanTitle(tx.title);
      final subName = tx.subcategory != null
          ? (subCategoryNames[tx.subcategory!] ?? '')
          : '';
      final label = subName.isNotEmpty ? subName : fallback;

      if (isIncome) {
        incomeBreakdown[label] = (incomeBreakdown[label] ?? 0) + absAmt;
        periodicIncomeBreakdown[monthKey]![label] =
            (periodicIncomeBreakdown[monthKey]![label] ?? 0) + absAmt;
        periodicNetIncome[monthKey] =
            (periodicNetIncome[monthKey] ?? 0) + absAmt;
      } else if (isExpense) {
        expenseBreakdown[label] = (expenseBreakdown[label] ?? 0) + absAmt;
        periodicExpenseBreakdown[monthKey]![label] =
            (periodicExpenseBreakdown[monthKey]![label] ?? 0) + absAmt;
        periodicNetIncome[monthKey] =
            (periodicNetIncome[monthKey] ?? 0) - absAmt;
      }
    }

    final totalIncome = incomeBreakdown.values.fold<double>(
      0.0,
      (a, b) => a + b,
    );
    final totalExpenses = expenseBreakdown.values.fold<double>(
      0.0,
      (a, b) => a + b,
    );
    final netIncome = totalIncome - totalExpenses;

    return _PnlExportData(
      incomeBreakdown: incomeBreakdown,
      expenseBreakdown: expenseBreakdown,
      periodicIncomeBreakdown: periodicIncomeBreakdown,
      periodicExpenseBreakdown: periodicExpenseBreakdown,
      periodicNetIncome: periodicNetIncome,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netIncome: netIncome,
    );
  }

  Future<PnlPdfData> _buildPnlPdfData(PdfExportRequest request) async {
    final exportData = await _buildPnlExportData(
      request.startDate,
      request.endDate,
    );
    final labels = PdfExportService().buildBucketLabels(
      request.startDate,
      request.endDate,
      request.viewType,
    );

    Map<String, double> aggregateToBuckets(
      Map<String, Map<String, double>> periodicMap,
      String category,
    ) {
      final out = <String, double>{for (final l in labels) l: 0.0};
      periodicMap.forEach((monthKey, values) {
        final month = DateFormat('yyyy-MM').parse(monthKey);
        final label = _bucketLabelForMonth(month, request.viewType);
        if (out.containsKey(label)) {
          out[label] = (out[label] ?? 0) + (values[category] ?? 0);
        }
      });
      return out;
    }

    List<double> valuesFromBuckets(Map<String, double> bucketMap) =>
        labels.map((l) => bucketMap[l] ?? 0).toList();

    final revenueRows = <PnlPdfRowData>[];
    for (final category in exportData.incomeBreakdown.keys) {
      if (category.trim().isEmpty ||
          category.toLowerCase() == 'uncategorized') {
        continue;
      }
      final values = valuesFromBuckets(
        aggregateToBuckets(exportData.periodicIncomeBreakdown, category),
      );
      revenueRows.add(PnlPdfRowData(label: category, values: values));
    }
    final revenueTotal = List<double>.filled(labels.length, 0);
    for (final row in revenueRows) {
      for (int i = 0; i < revenueTotal.length; i++) {
        revenueTotal[i] += row.values[i];
      }
    }
    revenueRows.add(
      PnlPdfRowData(label: 'Total Income', values: revenueTotal, isBold: true),
    );

    final expenseRows = <PnlPdfRowData>[];
    for (final category in exportData.expenseBreakdown.keys) {
      if (category.trim().isEmpty ||
          category.toLowerCase() == 'uncategorized') {
        continue;
      }
      final values = valuesFromBuckets(
        aggregateToBuckets(exportData.periodicExpenseBreakdown, category),
      );
      expenseRows.add(PnlPdfRowData(label: category, values: values));
    }
    final expenseTotal = List<double>.filled(labels.length, 0);
    for (final row in expenseRows) {
      for (int i = 0; i < expenseTotal.length; i++) {
        expenseTotal[i] += row.values[i];
      }
    }
    expenseRows.add(
      PnlPdfRowData(
        label: 'Total Expenses',
        values: expenseTotal,
        isBold: true,
      ),
    );

    final netProfit = List<double>.filled(labels.length, 0);
    for (int i = 0; i < labels.length; i++) {
      netProfit[i] = revenueTotal[i] - expenseTotal[i];
    }

    return PnlPdfData(
      sections: [
        PnlPdfSectionData(title: 'Revenue', rows: revenueRows),
        PnlPdfSectionData(title: 'Expenses', rows: expenseRows),
      ],
      netProfit: netProfit,
    );
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

  double _percentChange(double current, double previous) {
    if (previous == 0) {
      if (current > 0) return 100;
      if (current < 0) return -100;
      return 0;
    }
    return ((current - previous) / previous.abs()) * 100;
  }

  final numFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FinancialReportController>(
      tag: getCurrentOrganization!.id.toString(),
      builder: (controller) {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final numFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

        // KPI Calculations
        final double income = controller.totalIncome.value;
        final double prevIncome = controller.prevPeriodIncome.value;
        final double incomeChange = _percentChange(income, prevIncome);

        final double expenses = controller.totalExpenses.value;
        final double prevExpenses = controller.prevPeriodExpenses.value;
        final double expensesChange = _percentChange(expenses, prevExpenses);

        final double grossProfit = controller.grossProfit.value;
        final double prevGrossProfit = controller.prevPeriodGrossProfit.value;
        final double grossProfitChange = _percentChange(
          grossProfit,
          prevGrossProfit,
        );

        final double margin = controller.grossMarginPct.value.clamp(0, 100);
        final double prevMargin = controller.prevPeriodGrossMarginPct.value
            .clamp(0, 100);
        final double marginChange = _percentChange(margin, prevMargin);

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isNarrow = screenWidth <= 1024;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
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
                            "Profit & Loss",
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                "Profit & Loss",
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
                const SizedBox(height: 24),
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
                              reportType: ExportPdfReportType.profitLoss,
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
                                final liveData = await _buildPnlPdfData(
                                  request,
                                );
                                await PdfExportService()
                                    .exportProfitLossPresentationPdf(
                                      request,
                                      pnlData: liveData,
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
                              reportType: ExportPdfReportType.profitLoss,
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
                      _outlineButton(
                        "Upload",
                        onPressed: () => showUploadTaxDocumentDialog(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                isNarrow
                    ? Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: screenWidth - 32,
                            child: _premiumKPICard(
                              title: "Income",
                              value: numFormat.format(income),
                              change: incomeChange,
                              isCurrency: true,
                              timeframe: _getTimeframeLabel(),
                            ),
                          ),
                          SizedBox(
                            width: screenWidth - 32,
                            child: _premiumKPICard(
                              title: "Expenses",
                              value: numFormat.format(expenses),
                              change: expensesChange,
                              isCurrency: true,
                              timeframe: _getTimeframeLabel(),
                            ),
                          ),
                          SizedBox(
                            width: screenWidth - 32,
                            child: _premiumKPICard(
                              title: "Gross Profit",
                              value: numFormat.format(grossProfit),
                              change: grossProfitChange,
                              isCurrency: true,
                              timeframe: _getTimeframeLabel(),
                            ),
                          ),
                          SizedBox(
                            width: screenWidth - 32,
                            child: _premiumKPICard(
                              title: "% Margin",
                              value: "${margin.toStringAsFixed(1)}%",
                              change: marginChange,
                              isCurrency: false,
                              timeframe: _getTimeframeLabel(),
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
                                title: "Income",
                                value: numFormat.format(income),
                                change: incomeChange,
                                isCurrency: true,
                                timeframe: _getTimeframeLabel(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _premiumKPICard(
                                title: "Expenses",
                                value: numFormat.format(expenses),
                                change: expensesChange,
                                isCurrency: true,
                                timeframe: _getTimeframeLabel(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _premiumKPICard(
                                title: "Gross Profit",
                                value: numFormat.format(grossProfit),
                                change: grossProfitChange,
                                isCurrency: true,
                                timeframe: _getTimeframeLabel(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _premiumKPICard(
                                title: "% Margin",
                                value: "${margin.toStringAsFixed(1)}%",
                                change: marginChange,
                                isCurrency: false,
                                timeframe: _getTimeframeLabel(),
                              ),
                            ),
                          ],
                        ),
                      ),

                const SizedBox(height: 32),

                /// 🔹 Main Combined Chart Section
                _buildMainChartSection(controller),

                const SizedBox(height: 32),

                /// 🔹 Bottom Section: Revenue vs Expenses Growth & COGS %
                isNarrow
                    ? Column(
                        children: [
                          _buildRevenueExpenseGrowthChart(controller),
                          const SizedBox(height: 16),
                          _buildCogsRevenueChart(controller),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildRevenueExpenseGrowthChart(controller),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: _buildCogsRevenueChart(controller)),
                        ],
                      ),
                const RecentDocumentsWidget(type: 'pl'),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔹 Outline button builder (for Filter/Export/Upload)
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
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPositive = change >= 0;
    // Soft red color instead of harsh bright red
    final Color softRed = const Color(0xFFE57373);
    final Color changeColor = isPositive ? const Color(0xFF19C37D) : softRed;
    final IconData changeIcon = isPositive
        ? Icons.arrow_upward
        : Icons.arrow_downward;

    // Negative values should be soft red
    final bool isNegativeValue =
        value.contains('-') || (isCurrency && value.startsWith('-\$'));
    final Color valueColor = isNegativeValue
        ? softRed
        : (isDark ? Colors.white : Colors.black87);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.yellow.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
              color: valueColor,
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
                color: isDark ? Colors.white30 : Colors.black45,
                disableFormat: true,
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

  Widget _buildMainChartSection(FinancialReportController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final series = controller.trendChartSeries;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 30,
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
                      "Profit & Loss Trends",
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
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
                            controller.trendGranularityLabel.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText(
                                "${DateFormat('MMM dd, yyyy').format(_startDate!)} – ${DateFormat('MMM dd, yyyy').format(_endDate!)}",
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black54,
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
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ],
                          )
                        else ...[
                          if (_startDate != null && _endDate != null)
                            AppText(
                              "${DateFormat('MMM dd, yyyy').format(_startDate!)} – ${DateFormat('MMM dd, yyyy').format(_endDate!)}",
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          if (controller.trendGranularityLabel.isNotEmpty)
                            AppText(
                              controller.trendGranularityLabel,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
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
                  _buildPnLMetricToggles(isDark),
                  Container(
                    width: 1,
                    height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  InkWell(
                    onTap: () => setState(
                      () => _comparePriorPeriod = !_comparePriorPeriod,
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
                                  () => _comparePriorPeriod = v ?? false,
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
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
                            color: isDark ? Colors.white54 : Colors.black45,
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
            child: series.isEmpty
                ? Center(
                    child: AppText(
                      "Data will appear for this range",
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      const leftAxis = 50.0;
                      final usableW = (constraints.maxWidth - leftAxis).clamp(
                        1.0,
                        double.infinity,
                      );
                      final n = series.length;
                      final groupW = _pnlTrendGroupWidth(n);
                      final centers = _barGroupCenterXsSpaceAround(
                        usableW,
                        n,
                        groupW,
                      );
                      final spotXN = centers.map((c) => c / usableW).toList();
                      return Stack(
                        children: [
                          _buildPnLTrendBarChart(series, isDark),
                          _buildPnLTrendLineOverlay(
                            controller,
                            series,
                            isDark,
                            spotXN: spotXN,
                            compactXAxis: n > 6,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.center,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 8,
              children: [
                if (_showRevenue)
                  _legendItem(const Color(0xFF19C37D), "Revenue"),
                if (_showExpenses)
                  _legendItem(const Color(0xFF2B7FFF), "Expenses"),
                if (_showProfit)
                  _legendItem(
                    isDark ? Colors.white : Colors.black87,
                    "Profit",
                    isLine: true,
                  ),
                if (_comparePriorPeriod)
                  _legendItem(
                    isDark ? Colors.white54 : Colors.black45,
                    "Prior profit",
                    isLine: true,
                    isDashed: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPnLMetricToggles(bool isDark) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        setState(() {
          if (value == "revenue") _showRevenue = !_showRevenue;
          if (value == "expense") _showExpenses = !_showExpenses;
          if (value == "profit") _showProfit = !_showProfit;
        });
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem<String>(
          value: "revenue",
          checked: _showRevenue,
          child: const AppText("Revenue", fontSize: 12),
        ),
        CheckedPopupMenuItem<String>(
          value: "expense",
          checked: _showExpenses,
          child: const AppText("Expense", fontSize: 12),
        ),
        CheckedPopupMenuItem<String>(
          value: "profit",
          checked: _showProfit,
          child: const AppText("Profit", fontSize: 12),
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

  double _trendMinY(List<Map<String, dynamic>> series) {
    double minVal = 0;
    for (final d in series) {
      final inc = (d['income'] as num?)?.toDouble() ?? 0;
      final exp = (d['expense'] as num?)?.toDouble() ?? 0;
      final net = (d['net'] as num?)?.toDouble() ?? 0;
      if (_showRevenue && inc < minVal) minVal = inc;
      if (_showExpenses && exp < minVal) minVal = exp;
      if (_showProfit && net < minVal) minVal = net;
    }
    if (minVal == 0) return 0;
    final interval = minVal.abs() > 50000 ? 10000.0 : 5000.0;
    return (minVal / interval).floor() * interval;
  }

  double _trendMaxY(List<Map<String, dynamic>> series) {
    double maxVal = 0;
    for (final d in series) {
      final inc = (d['income'] as num?)?.toDouble() ?? 0;
      final exp = (d['expense'] as num?)?.toDouble() ?? 0;
      final net = (d['net'] as num?)?.toDouble() ?? 0;
      if (_showRevenue && inc > maxVal) maxVal = inc;
      if (_showExpenses && exp > maxVal) maxVal = exp;
      if (_showProfit && net > maxVal) maxVal = net;
    }
    if (maxVal == 0) return 10000;
    final interval = maxVal > 50000 ? 10000.0 : 5000.0;
    return (maxVal / interval).ceil() * interval;
  }

  /// Group center X positions for [BarChartAlignment.spaceAround] (same layout as fl_chart).
  List<double> _barGroupCenterXsSpaceAround(
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

  double _pnlTrendGroupWidth(int n) {
    final rodW = (320 / n).clamp(4.0, 18.0);
    var rodCount = 0;
    if (_showRevenue) rodCount++;
    if (_showExpenses) rodCount++;
    if (rodCount == 0) return 1.0;
    if (rodCount == 1) return rodW;
    return rodW * 2 + 6;
  }

  Widget _buildPnLTrendBarChart(
    List<Map<String, dynamic>> series,
    bool isDark,
  ) {
    final minY = _trendMinY(series);
    final maxY = _trendMaxY(series);
    final n = series.length;
    // Show every bucket on the x-axis (daily, weekly, monthly, quarterly) — user prefers full labels.
    final bool compactXAxis = n > 6;

    return BarChart(
      BarChartData(
        baselineY: 0,
        alignment: BarChartAlignment.spaceAround,
        minY: minY,
        maxY: maxY,
        // Tooltips are shown from the profit line overlay (near dots only).
        barTouchData: const BarTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: (maxY - minY) / 4,
              getTitlesWidget: (value, meta) {
                if ((value - meta.max).abs() < 0.01) {
                  return const SizedBox.shrink();
                }
                String text;
                if (value == 0) {
                  text = "\$0";
                } else if (value.abs() >= 1000) {
                  text = "\$${(value / 1000).toInt()}K";
                } else {
                  text = "\$${value.toInt()}";
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppText(
                    text,
                    fontSize: 10,
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: compactXAxis ? 48 : 36,
              interval: 1,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= n) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(top: compactXAxis ? 6.0 : 12.0),
                  child: AppText(
                    series[i]['label']?.toString() ?? '',
                    fontSize: compactXAxis ? 8 : 10,
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
        barGroups: List.generate(n, (i) {
          final data = series[i];
          final inc = (data['income'] as num?)?.toDouble() ?? 0;
          final exp = (data['expense'] as num?)?.toDouble() ?? 0;
          final rods = <BarChartRodData>[];
          if (_showRevenue) {
            rods.add(
              BarChartRodData(
                toY: inc,
                color: const Color(0xFF19C37D),
                width: (320 / n).clamp(4.0, 18.0),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF19C37D).withValues(alpha: 0.4),
                    const Color(0xFF19C37D),
                  ],
                ),
              ),
            );
          }
          if (_showExpenses) {
            rods.add(
              BarChartRodData(
                toY: exp,
                color: const Color(0xFF2B7FFF),
                width: (320 / n).clamp(4.0, 18.0),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF2B7FFF).withValues(alpha: 0.4),
                    const Color(0xFF2B7FFF),
                  ],
                ),
              ),
            );
          }
          if (rods.isEmpty) {
            rods.add(
              BarChartRodData(toY: 0.001, color: Colors.transparent, width: 1),
            );
          }
          return BarChartGroupData(x: i, barsSpace: 6, barRods: rods);
        }),
      ),
    );
  }

  Widget _buildPnLTrendLineOverlay(
    FinancialReportController controller,
    List<Map<String, dynamic>> series,
    bool isDark, {
    required List<double> spotXN,
    required bool compactXAxis,
  }) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final minY = _trendMinY(series);
    final maxY = _trendMaxY(series);
    final n = series.length;
    final profitColor = isDark ? Colors.white : Colors.black87;
    final prev = controller.prevTrendChartSeries;
    final prevN = prev.length;
    final compareLen = prevN < n ? prevN : n;
    final bottomReserved = compactXAxis ? 48.0 : 36.0;

    final lineBars = <LineChartBarData>[];
    if (_showProfit) {
      lineBars.add(
        LineChartBarData(
          spots: List.generate(n, (i) {
            final net = (series[i]['net'] as num?)?.toDouble() ?? 0;
            final xn = i < spotXN.length ? spotXN[i] : 0.5;
            return FlSpot(xn, net);
          }),
          isCurved: true,
          preventCurveOverShooting: true,
          curveSmoothness: 0.35,
          color: profitColor,
          barWidth: 2,
          belowBarData: BarAreaData(
            show: true,
            applyCutOffY: true,
            cutOffY: 0,
            color: const Color(0xFF19C37D).withValues(alpha: 0.2),
          ),
          aboveBarData: BarAreaData(
            show: true,
            applyCutOffY: true,
            cutOffY: 0,
            color: const Color(0xFFE57373).withValues(alpha: 0.2),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, p1, p2, p3) => FlDotCirclePainter(
              radius: n > 60 ? 2.0 : 3.0,
              color: profitColor,
              strokeWidth: 1.5,
              strokeColor: const Color(0xFF0F1E37),
            ),
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
          preventCurveOverShooting: true,
          curveSmoothness: 0.35,
          color: isDark ? Colors.white54 : Colors.black38,
          barWidth: 2,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
        ),
      );
    }

    final tooltipEnabled = _showProfit && lineBars.isNotEmpty;

    return LineChart(
      LineChartData(
        baselineY: 0,
        minX: 0,
        maxX: 1,
        minY: minY,
        maxY: maxY,
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
            getTooltipColor: (_) =>
                isDark ? const Color(0xFF1E293B) : const Color(0xFF0F1E37),
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
                          : DateFormat('MMMM dd, yyyy').format(bucketDate))
                    : (bucketDate != null
                          ? DateFormat('MMM dd, yyyy').format(bucketDate)
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
                      text: 'Revenue: ${currencyFormat.format(inc)}\n',
                      style: const TextStyle(
                        color: Color(0xFF19C37D),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    TextSpan(
                      text: 'Expenses: ${currencyFormat.format(exp)}\n',
                      style: const TextStyle(
                        color: Color(0xFF2B7FFF),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    TextSpan(
                      text: 'Profit: ${currencyFormat.format(net)}',
                      style: const TextStyle(
                        color: Colors.white,
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
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
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
        lineBarsData: lineBars.isEmpty
            ? [
                LineChartBarData(
                  spots: const [FlSpot(0, 0)],
                  dotData: const FlDotData(show: false),
                ),
              ]
            : lineBars,
      ),
    );
  }

  Widget _buildRevenueExpenseGrowthChart(FinancialReportController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final growthSeries = controller.chartData;
    final xAxisStep = _chartXAxisStep(growthSeries.length);
    final hideDenseDots = growthSeries.length > 18;
    final negativeAreaColor = const Color(0xFFE57373).withValues(alpha: 0.25);
    final negativeAreaSpots = growthSeries.asMap().entries.map((e) {
      final revenueGrowth = (e.value['revenueGrowth'] as num?)?.toDouble() ?? 0;
      final expenseGrowth = (e.value['expenseGrowth'] as num?)?.toDouble() ?? 0;
      final minGrowth = revenueGrowth < expenseGrowth
          ? revenueGrowth
          : expenseGrowth;
      return FlSpot(e.key.toDouble(), minGrowth < 0 ? minGrowth : 0);
    }).toList();
    final allValues = growthSeries
        .expand(
          (e) => [
            (e['revenueGrowth'] as num?)?.toDouble() ?? 0,
            (e['expenseGrowth'] as num?)?.toDouble() ?? 0,
          ],
        )
        .toList();
    final maxV = allValues.isEmpty
        ? 10.0
        : allValues.reduce((a, b) => a > b ? a : b);
    final minV = allValues.isEmpty
        ? -10.0
        : allValues.reduce((a, b) => a < b ? a : b);
    final maxY = ((maxV + 10) / 10).ceil() * 10.0;
    final minY = ((minV - 10) / 10).floor() * 10.0;
    final yInterval = _growthYAxisInterval(minY, maxY);

    return Container(
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            "Revenue Growth vs Expense Growth",
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
          const SizedBox(height: 8),
          if (_startDate != null && _endDate != null)
            AppText(
              "${DateFormat('MMM dd, yyyy').format(_startDate!)} – ${DateFormat('MMM dd, yyyy').format(_endDate!)}",
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black54,
            ),
          const SizedBox(height: 32),
          Expanded(
            child: growthSeries.isEmpty
                ? Center(
                    child: AppText(
                      "Data will appear for this range",
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  )
                : LineChart(
                    LineChartData(
                      baselineY: 0,
                      minY: minY,
                      maxY: maxY,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              if (spot.barIndex == 0) return null;
                              final label = spot.barIndex == 1
                                  ? "Revenue Growth"
                                  : "Expense Growth";
                              final isRevenue = spot.barIndex == 1;
                              final color = isRevenue
                                  ? const Color(0xFF19C37D)
                                  : const Color(0xFF2B7FFF);
                              return LineTooltipItem(
                                "$label: ",
                                TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                    text: _formatSignedPercent(spot.y),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                        ),
                        getTouchedSpotIndicator:
                            (LineChartBarData barData, List<int> spotIndexes) {
                              return spotIndexes.map((index) {
                                return TouchedSpotIndicatorData(
                                  const FlLine(color: Colors.transparent),
                                  FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (
                                          spot,
                                          percent,
                                          barData,
                                          index,
                                        ) => FlDotCirclePainter(
                                          radius: 4,
                                          color: barData.color ?? Colors.white,
                                          strokeWidth: 1.5,
                                          strokeColor: const Color(0xFF0F1E37),
                                        ),
                                  ),
                                );
                              }).toList();
                            },
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: (Get.isDarkMode ? Colors.white : Colors.black)
                              .withValues(alpha: 0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            interval: yInterval,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.max || value == meta.min) {
                                return const SizedBox.shrink();
                              }
                              return AppText(
                                _formatPercentAxis(value),
                                fontSize: 10,
                                color: Get.isDarkMode
                                    ? Colors.white38
                                    : Colors.black45,
                                fontWeight: FontWeight.bold,
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: 1,
                            getTitlesWidget: (value, _) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= growthSeries.length) {
                                return const SizedBox.shrink();
                              }
                              if (!_shouldShowXAxisLabel(
                                idx,
                                growthSeries.length,
                                xAxisStep,
                              )) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: AppText(
                                  growthSeries[idx]['name'] ?? "",
                                  fontSize: 10,
                                  color: Get.isDarkMode
                                      ? Colors.white38
                                      : Colors.black45,
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
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: negativeAreaSpots,
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: Colors.transparent,
                          barWidth: 0,
                          dotData: const FlDotData(show: false),
                          aboveBarData: BarAreaData(
                            show: true,
                            applyCutOffY: true,
                            cutOffY: 0,
                            color: negativeAreaColor,
                          ),
                        ),
                        LineChartBarData(
                          spots: growthSeries
                              .asMap()
                              .entries
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  (e.value['revenueGrowth'] as num?)
                                          ?.toDouble() ??
                                      0,
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: const Color(0xFF19C37D),
                          barWidth: 3,
                          dotData: FlDotData(show: !hideDenseDots),
                        ),
                        LineChartBarData(
                          spots: growthSeries
                              .asMap()
                              .entries
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  (e.value['expenseGrowth'] as num?)
                                          ?.toDouble() ??
                                      0,
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: const Color(0xFF2B7FFF),
                          barWidth: 3,
                          dotData: FlDotData(show: !hideDenseDots),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(
                const Color(0xFF19C37D),
                "Revenue Growth",
                isLine: true,
              ),
              const SizedBox(width: 24),
              _legendItem(
                const Color(0xFF2B7FFF),
                "Expense Growth",
                isLine: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCogsRevenueChart(FinancialReportController controller) {
    final isDark = Get.isDarkMode;
    final compactFormat = NumberFormat.compactCurrency(symbol: '\$');
    final fullFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final cogsSeries = controller.chartData;
    final xAxisStep = _chartXAxisStep(cogsSeries.length);
    final hideDenseDots = cogsSeries.length > 18;
    final maxRevenue = _getMaxRevenue(controller);
    final revenueAxisMax = ((maxRevenue * 1.2) / 200).ceil() * 200;
    final leftAxisInterval = _niceAxisInterval(revenueAxisMax.toDouble());
    final cogsValues = cogsSeries
        .map((e) => (e['cogsPct'] as num?)?.toDouble() ?? 0)
        .toList();
    final maxCogs = cogsValues.isEmpty
        ? 0.0
        : cogsValues.reduce((a, b) => a > b ? a : b);
    final minCogs = cogsValues.isEmpty
        ? 0.0
        : cogsValues.reduce((a, b) => a < b ? a : b);
    final cogsAxisMax =
        (((maxCogs > 0 ? maxCogs : 100) * 1.15) / 10).ceil() * 10.0;
    final cogsAxisMin = minCogs < 0
        ? (((minCogs * 1.15) - 10) / 10).floor() * 10.0
        : 0.0;

    return Container(
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            "COGS % of Revenue",
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
          const SizedBox(height: 8),
          if (_startDate != null && _endDate != null)
            AppText(
              "${DateFormat('MMM dd, yyyy').format(_startDate!)} – ${DateFormat('MMM dd, yyyy').format(_endDate!)}",
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black54,
            ),
          const SizedBox(height: 32),
          Expanded(
            child: cogsSeries.isEmpty
                ? Center(
                    child: AppText(
                      "Data will appear for this range",
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  )
                : Stack(
                    children: [
                      BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: revenueAxisMax.toDouble(),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => Get.isDarkMode
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              getTooltipItem: (group, groupIdx, rod, rodIdx) {
                                final data = cogsSeries[groupIdx];
                                final cogsPct =
                                    (data['cogsPct'] as num?)?.toDouble() ?? 0;
                                return BarTooltipItem(
                                  "Revenue: ",
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          "${fullFormat.format((data['revenue'] as num?)?.toDouble() ?? 0)}\n",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "COGS % of Revenue: ",
                                      style: TextStyle(
                                        color: orangeColor.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "${cogsPct.toStringAsFixed(1)}%",
                                      style: const TextStyle(
                                        color: orangeColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                interval: leftAxisInterval,
                                getTitlesWidget: (value, _) {
                                  if (value > revenueAxisMax + 0.001) {
                                    return const SizedBox.shrink();
                                  }
                                  return AppText(
                                    compactFormat.format(value),
                                    fontSize: 10,
                                    color: Get.isDarkMode
                                        ? Colors.white38
                                        : Colors.black45,
                                    fontWeight: FontWeight.bold,
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                interval: 1,
                                getTitlesWidget: (value, _) {
                                  int idx = value.toInt();
                                  if (idx < 0 || idx >= cogsSeries.length) {
                                    return const SizedBox.shrink();
                                  }
                                  if (!_shouldShowXAxisLabel(
                                    idx,
                                    cogsSeries.length,
                                    xAxisStep,
                                  )) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: AppText(
                                      cogsSeries[idx]['name'] ?? "",
                                      fontSize: 10,
                                      color: Get.isDarkMode
                                          ? Colors.white38
                                          : Colors.black45,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                interval: revenueAxisMax / 4,
                                getTitlesWidget: (value, _) {
                                  final pct = (value / revenueAxisMax) * 100;
                                  if (pct > 105 || pct < -5) {
                                    return const SizedBox.shrink();
                                  }
                                  return AppText(
                                    "${pct.toInt()}%",
                                    fontSize: 10,
                                    color: orangeColor.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.bold,
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color:
                                  (Get.isDarkMode ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.05),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: cogsSeries.asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY:
                                      (e.value['revenue'] as num?)
                                          ?.toDouble() ??
                                      0,
                                  color: const Color(
                                    0xFF19C37D,
                                  ).withValues(alpha: 0.6),
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 45, right: 45),
                        child: LineChart(
                          LineChartData(
                            minY: cogsAxisMin,
                            maxY: cogsAxisMax,
                            baselineY: 0,
                            lineTouchData: LineTouchData(
                              enabled: true,
                              handleBuiltInTouches: true,
                              touchSpotThreshold: 18,
                              getTouchedSpotIndicator:
                                  (
                                    LineChartBarData barData,
                                    List<int> spotIndexes,
                                  ) {
                                    return spotIndexes
                                        .map(
                                          (_) => TouchedSpotIndicatorData(
                                            FlLine(
                                              color: Colors.transparent,
                                              strokeWidth: 0,
                                            ),
                                            FlDotData(
                                              show: true,
                                              getDotPainter:
                                                  (spot, percent, bar, index) =>
                                                      FlDotCirclePainter(
                                                        radius: 4.5,
                                                        color: orangeColor,
                                                        strokeWidth: 1.5,
                                                        strokeColor:
                                                            const Color(
                                                              0xFF0F1E37,
                                                            ),
                                                      ),
                                            ),
                                          ),
                                        )
                                        .toList();
                                  },
                              touchTooltipData: LineTouchTooltipData(
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                getTooltipColor: (_) => Get.isDarkMode
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF0F1E37),
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final idx = spot.spotIndex;
                                    if (idx < 0 || idx >= cogsSeries.length) {
                                      return null;
                                    }
                                    final row = cogsSeries[idx];
                                    final tooltipDate =
                                        row['tooltipDate']?.toString() ??
                                        row['name']?.toString() ??
                                        '';
                                    final revenue =
                                        (row['revenue'] as num?)?.toDouble() ??
                                        0;
                                    final cogsPct =
                                        (row['cogsPct'] as num?)?.toDouble() ??
                                        0;
                                    return LineTooltipItem(
                                      '',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '$tooltipDate\n',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            height: 1.35,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              'Revenue: ${fullFormat.format(revenue)}\n',
                                          style: const TextStyle(
                                            color: Color(0xFF19C37D),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                            height: 1.35,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              'COGS % of Revenue: ${cogsPct.toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            color: orangeColor,
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
                                  reservedSize: 45,
                                  getTitlesWidget: (_, __) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget: (_, __) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  getTitlesWidget: (_, __) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: cogsSeries
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => FlSpot(
                                        e.key.toDouble(),
                                        (e.value['cogsPct'] as num?)
                                                ?.toDouble() ??
                                            0,
                                      ),
                                    )
                                    .toList(),
                                isCurved: false,
                                color: orangeColor,
                                barWidth: 3,
                                dotData: FlDotData(show: !hideDenseDots),
                                aboveBarData: BarAreaData(
                                  show: true,
                                  applyCutOffY: true,
                                  cutOffY: 0,
                                  color: const Color(
                                    0xFFE57373,
                                  ).withValues(alpha: 0.25),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(
                const Color(0xFF19C37D).withValues(alpha: 0.6),
                "Revenue",
                isBar: true,
              ),
              const SizedBox(width: 24),
              _legendItem(orangeColor, "COGS % of Revenue", isLine: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    Color color,
    String label, {
    bool isBar = false,
    bool isLine = false,
    bool isDashed = false,
  }) {
    final isDark = Get.isDarkMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDashed)
          Row(
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
        else
          Container(
            width: isLine ? 16 : 10,
            height: isLine ? 2 : 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: (isBar || isLine)
                  ? BorderRadius.circular(isBar ? 2 : 5)
                  : null,
              shape: (isBar || isLine) ? BoxShape.rectangle : BoxShape.circle,
            ),
          ),
        const SizedBox(width: 8),
        AppText(
          label,
          fontSize: 11,
          color: isDark ? Colors.white70 : Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }

  double _getMaxRevenue(FinancialReportController controller) {
    double maxVal = 0;
    for (var d in controller.chartData) {
      if ((d['revenue'] ?? 0) > maxVal) maxVal = d['revenue'];
    }
    return maxVal == 0 ? 100 : maxVal;
  }

  double _niceAxisInterval(double maxY) {
    if (maxY <= 0) return 1;
    final raw = maxY / 4; // target ~4 major ticks
    final exponent = (math.log(raw) / math.ln10).floor();
    final magnitude = math.pow(10, exponent).toDouble();
    final normalized = raw / magnitude;
    double nice;
    if (normalized <= 1) {
      nice = 1;
    } else if (normalized <= 2) {
      nice = 2;
    } else if (normalized <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude;
  }

  String _formatSignedPercent(double value) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }

  int _chartXAxisStep(int pointCount) {
    if (pointCount <= 8) return 1;
    if (pointCount <= 14) return 2;
    if (pointCount <= 24) return 3;
    if (pointCount <= 40) return 5;
    if (pointCount <= 60) return 7;
    return 10;
  }

  bool _shouldShowXAxisLabel(int index, int total, int step) {
    if (total <= 1) return true;
    return index == 0 || index == total - 1 || index % step == 0;
  }

  double _growthYAxisInterval(double minY, double maxY) {
    final range = (maxY - minY).abs();
    if (range <= 0) return 10;

    // Keep around 5 y-axis labels to avoid overlap on large spikes.
    final rawStep = range / 5;
    final magnitude = math.pow(10, (math.log(rawStep) / math.ln10).floor());
    final normalized = rawStep / magnitude;

    double niceNormalized;
    if (normalized <= 1) {
      niceNormalized = 1;
    } else if (normalized <= 2) {
      niceNormalized = 2;
    } else if (normalized <= 5) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }
    return niceNormalized * magnitude;
  }

  String _formatPercentAxis(double value) {
    final abs = value.abs();
    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K%';
    }
    return '${value.toInt()}%';
  }
}
