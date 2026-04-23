import 'dart:ui';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf_gen;

import 'package:booksmart/utils/downloader.dart';

enum PdfViewType { monthly, quarterly, yearly }

enum PdfTemplateVariant { templateA, templateB }

class PdfExportRequest {
  PdfExportRequest({
    required this.startDate,
    required this.endDate,
    required this.viewType,
    required this.templateVariant,
    required this.companyName,
    required this.companyAddress,
    this.logoBytes,
  });

  final DateTime startDate;
  final DateTime endDate;
  final PdfViewType viewType;
  final PdfTemplateVariant templateVariant;
  final String companyName;
  final String companyAddress;
  final Uint8List? logoBytes;
}

class CashFlowPdfData {
  CashFlowPdfData({
    required this.sections,
    required this.netChange,
    required this.beginningCash,
    required this.endingCash,
    this.operatingTotal,
    this.investingTotal,
    this.financingTotal,
    this.netChangeTotal,
    this.beginningCashTotal,
    this.endingCashTotal,
  });

  final List<CashFlowPdfSectionData> sections;
  final List<double> netChange;
  final List<double> beginningCash;
  final List<double> endingCash;
  final double? operatingTotal;
  final double? investingTotal;
  final double? financingTotal;
  final double? netChangeTotal;
  final double? beginningCashTotal;
  final double? endingCashTotal;
}

class CashFlowPdfSectionData {
  CashFlowPdfSectionData({required this.title, required this.rows});

  final String title;
  final List<CashFlowPdfRowData> rows;
}

class CashFlowPdfRowData {
  CashFlowPdfRowData({
    required this.label,
    required this.values,
    this.isTotal = false,
    this.periodTotalOverride,
  });

  final String label;
  final List<double> values;
  final bool isTotal;
  final double? periodTotalOverride;
}

class PnlPdfData {
  PnlPdfData({
    required this.sections,
    required this.netProfit,
  });

  final List<PnlPdfSectionData> sections;
  final List<double> netProfit;
}

class PnlPdfSectionData {
  PnlPdfSectionData({required this.title, required this.rows});

  final String title;
  final List<PnlPdfRowData> rows;
}

class PnlPdfRowData {
  PnlPdfRowData({
    required this.label,
    required this.values,
    this.isBold = false,
  });

  final String label;
  final List<double> values;
  final bool isBold;
}

class PdfExportService {
  static const int maxColumns = 5;

  String? validateRange(DateTime start, DateTime end, PdfViewType viewType) {
    if (end.isBefore(start)) return 'End date must be on or after start date.';

    final months = _monthSpanInclusive(start, end);
    switch (viewType) {
      case PdfViewType.monthly:
        if (months > 5) return 'Monthly view supports max 5 months.';
        return null;
      case PdfViewType.quarterly:
        final quarters = ((months + 2) / 3).ceil();
        if (quarters > 5) return 'Quarterly view supports max 5 quarters.';
        return null;
      case PdfViewType.yearly:
        final years = _yearSpanInclusive(start, end);
        if (years > 5) return 'Yearly view supports max 5 years.';
        return null;
    }
  }

  List<String> buildBucketLabels(
    DateTime start,
    DateTime end,
    PdfViewType viewType,
  ) {
    switch (viewType) {
      case PdfViewType.monthly:
        return _buildMonthLabels(start, end);
      case PdfViewType.quarterly:
        return _buildQuarterLabels(start, end);
      case PdfViewType.yearly:
        return _buildYearLabels(start, end);
    }
  }

  Future<void> exportProfitLossPresentationPdf(
    PdfExportRequest request, {
    PnlPdfData? pnlData,
  }) async {
    final validation = validateRange(
      request.startDate,
      request.endDate,
      request.viewType,
    );
    if (validation != null) {
      throw ArgumentError(validation);
    }

    final labels = buildBucketLabels(
      request.startDate,
      request.endDate,
      request.viewType,
    );
    if (labels.isEmpty || labels.length > maxColumns) {
      throw ArgumentError('Invalid column configuration. Max 5 columns allowed.');
    }

    final statement = pnlData != null
        ? _statementFromPnlData(pnlData, labels.length)
        : _dummyStatement(labels.length);
    final document = pdf_gen.PdfDocument();
    document.pageSettings.orientation = labels.length > 3
        ? pdf_gen.PdfPageOrientation.landscape
        : pdf_gen.PdfPageOrientation.portrait;
    final page = document.pages.add();
    final graphics = page.graphics;
    final size = page.getClientSize();

    _drawTemplateA(
      page: page,
      graphics: graphics,
      size: size,
      request: request,
      labels: labels,
      statement: statement,
    );

    final bytes = await document.save();
    document.dispose();

    final rangeText =
        '${DateFormat('yyyyMMdd').format(request.startDate)}_${DateFormat('yyyyMMdd').format(request.endDate)}';
    await downloadFile(
      'PL_Presentation_${request.viewType.name}_$rangeText.pdf',
      bytes,
      mimeType: 'application/pdf',
    );
  }

  Future<void> exportCashFlowPresentationPdf(
    PdfExportRequest request, {
    CashFlowPdfData? cashFlowData,
  }) async {
    final validation = validateRange(
      request.startDate,
      request.endDate,
      request.viewType,
    );
    if (validation != null) {
      throw ArgumentError(validation);
    }

    final labels = buildBucketLabels(
      request.startDate,
      request.endDate,
      request.viewType,
    );
    if (labels.isEmpty || labels.length > maxColumns) {
      throw ArgumentError('Invalid column configuration. Max 5 columns allowed.');
    }

    final statement = cashFlowData != null
        ? _cashFlowStatementFromData(cashFlowData, labels.length)
        : _dummyCashFlowStatement(labels.length);
    final document = pdf_gen.PdfDocument();
    document.pageSettings.orientation = pdf_gen.PdfPageOrientation.portrait;
    final page = document.pages.add();
    final graphics = page.graphics;
    final size = page.getClientSize();

    _drawCashFlowTemplate(
      page: page,
      graphics: graphics,
      size: size,
      request: request,
      labels: labels,
      statement: statement,
    );

    final bytes = await document.save();
    document.dispose();

    final rangeText =
        '${DateFormat('yyyyMMdd').format(request.startDate)}_${DateFormat('yyyyMMdd').format(request.endDate)}';
    await downloadFile(
      'CF_Presentation_${request.viewType.name}_$rangeText.pdf',
      bytes,
      mimeType: 'application/pdf',
    );
  }

  void _drawTemplateA({
    required pdf_gen.PdfPage page,
    required pdf_gen.PdfGraphics graphics,
    required dynamic size,
    required PdfExportRequest request,
    required List<String> labels,
    required _StatementDummy statement,
  }) {
    final titleFont = pdf_gen.PdfStandardFont(pdf_gen.PdfFontFamily.helvetica, 15, style: pdf_gen.PdfFontStyle.bold);
    final headerFont = pdf_gen.PdfStandardFont(
      pdf_gen.PdfFontFamily.helvetica,
      11,
      style: pdf_gen.PdfFontStyle.bold,
    );
    final bodyFont = pdf_gen.PdfStandardFont(pdf_gen.PdfFontFamily.helvetica, 10);
    final bodyBold = pdf_gen.PdfStandardFont(
      pdf_gen.PdfFontFamily.helvetica,
      10,
      style: pdf_gen.PdfFontStyle.bold,
    );

    final deepBlue = pdf_gen.PdfColor(38, 91, 189);
    final bandBlue = pdf_gen.PdfColor(74, 133, 226);
    final lightHeader = pdf_gen.PdfColor(237, 243, 255);
    final displayCompanyName =
        request.companyName.trim().isEmpty ? 'Booksmart' : request.companyName.trim();
    final displayAddress = request.companyAddress.trim().isEmpty
        ? 'Address not available'
        : request.companyAddress.trim();
    final periodText =
        'Periods ${DateFormat('MMM dd, yyyy').format(request.startDate)} - ${DateFormat('MMM dd, yyyy').format(request.endDate)}';
    final preparedText = 'Date Prepared: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}';

    graphics.drawRectangle(
      brush: pdf_gen.PdfSolidBrush(deepBlue),
      bounds: Rect.fromLTWH(0, 0, size.width, 52),
    );
    graphics.drawString(
      'Profit & Loss Statement',
      titleFont,
      brush: pdf_gen.PdfBrushes.white,
      bounds: Rect.fromLTWH(20, 14, 280, 24),
    );
    graphics.drawString(
      periodText,
      bodyBold,
      brush: pdf_gen.PdfBrushes.white,
      bounds: Rect.fromLTWH(size.width - 360, 10, 340, 18),
      format: pdf_gen.PdfStringFormat(alignment: pdf_gen.PdfTextAlignment.right),
    );
    graphics.drawString(
      preparedText,
      bodyFont,
      brush: pdf_gen.PdfBrushes.white,
      bounds: Rect.fromLTWH(size.width - 360, 28, 340, 16),
      format: pdf_gen.PdfStringFormat(alignment: pdf_gen.PdfTextAlignment.right),
    );

    graphics.drawRectangle(
      brush: pdf_gen.PdfSolidBrush(lightHeader),
      bounds: Rect.fromLTWH(0, 52, size.width, 76),
    );
    if (request.logoBytes != null && request.logoBytes!.isNotEmpty) {
      final logo = pdf_gen.PdfBitmap(request.logoBytes!);
      graphics.drawImage(
        logo,
        Rect.fromLTWH(size.width / 2 - 85, 70, 26, 26),
      );
    }
    graphics.drawString(
      displayCompanyName,
      pdf_gen.PdfStandardFont(pdf_gen.PdfFontFamily.helvetica, 18, style: pdf_gen.PdfFontStyle.bold),
      brush: pdf_gen.PdfSolidBrush(pdf_gen.PdfColor(25, 62, 122)),
      bounds: Rect.fromLTWH(0, 70, size.width, 24),
      format: pdf_gen.PdfStringFormat(alignment: pdf_gen.PdfTextAlignment.center),
    );
    graphics.drawString(
      displayAddress,
      pdf_gen.PdfStandardFont(pdf_gen.PdfFontFamily.helvetica, 12),
      brush: pdf_gen.PdfSolidBrush(pdf_gen.PdfColor(60, 60, 60)),
      bounds: Rect.fromLTWH(0, 95, size.width, 20),
      format: pdf_gen.PdfStringFormat(alignment: pdf_gen.PdfTextAlignment.center),
    );

    double y = 138;
    y = _drawTabularStatement(
      page: page,
      graphics: graphics,
      yStart: y,
      labels: labels,
      headerFont: headerFont,
      bodyFont: bodyFont,
      bodyBold: bodyBold,
      sectionColor: bandBlue,
      statement: statement,
    );
  }

  void _drawCashFlowTemplate({
    required pdf_gen.PdfPage page,
    required pdf_gen.PdfGraphics graphics,
    required dynamic size,
    required PdfExportRequest request,
    required List<String> labels,
    required _CashFlowStatementDummy statement,
  }) {
    final titleFont = pdf_gen.PdfStandardFont(
      pdf_gen.PdfFontFamily.helvetica,
      18,
      style: pdf_gen.PdfFontStyle.bold,
    );
    final headerFont = pdf_gen.PdfStandardFont(
      pdf_gen.PdfFontFamily.helvetica,
      9,
      style: pdf_gen.PdfFontStyle.bold,
    );
    final bodyFont = pdf_gen.PdfStandardFont(pdf_gen.PdfFontFamily.helvetica, 8);
    final bodyBold = pdf_gen.PdfStandardFont(
      pdf_gen.PdfFontFamily.helvetica,
      8,
      style: pdf_gen.PdfFontStyle.bold,
    );

    final headerBlue = pdf_gen.PdfColor(112, 145, 176);
    final totalBand = pdf_gen.PdfColor(244, 247, 252);
    final companyName = request.companyName.trim().isEmpty
        ? 'Organization'
        : request.companyName.trim();
    final datePrepared = DateFormat('MM/dd/yyyy').format(DateTime.now());
    final asOfText = 'As of ${DateFormat('MMMM dd,').format(request.endDate)}';
    final companyMeta = request.companyAddress.trim().isEmpty
        ? 'Address not available'
        : request.companyAddress.trim();
    final addressLines = companyMeta
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    graphics.drawString(
      companyName,
      pdf_gen.PdfStandardFont(
        pdf_gen.PdfFontFamily.helvetica,
        13,
        style: pdf_gen.PdfFontStyle.bold,
      ),
      brush: pdf_gen.PdfSolidBrush(pdf_gen.PdfColor(35, 35, 35)),
      bounds: Rect.fromLTWH(34, 22, size.width * 0.38, 18),
    );
    graphics.drawString(
      addressLines.isNotEmpty ? addressLines.first : companyMeta,
      bodyFont,
      brush: pdf_gen.PdfSolidBrush(pdf_gen.PdfColor(90, 90, 90)),
      bounds: Rect.fromLTWH(34, 38, size.width * 0.38, 12),
    );
    if (addressLines.length > 1) {
      graphics.drawString(
        addressLines[1],
        bodyFont,
        brush: pdf_gen.PdfSolidBrush(pdf_gen.PdfColor(90, 90, 90)),
        bounds: Rect.fromLTWH(34, 49, size.width * 0.38, 12),
      );
    }

    final titleBounds = Rect.fromLTWH(size.width * 0.58, 16, size.width * 0.36, 24);
    graphics.drawString(
      'Cash Flow Statement',
      titleFont,
      brush: pdf_gen.PdfSolidBrush(pdf_gen.PdfColor(20, 20, 20)),
      bounds: titleBounds,
      format: pdf_gen.PdfStringFormat(alignment: pdf_gen.PdfTextAlignment.right),
    );
    graphics.drawString(
      'Date Prepared: $datePrepared',
      bodyFont,
      brush: pdf_gen.PdfSolidBrush(pdf_gen.PdfColor(70, 70, 70)),
      bounds: Rect.fromLTWH(size.width * 0.58, 41, size.width * 0.36, 12),
      format: pdf_gen.PdfStringFormat(alignment: pdf_gen.PdfTextAlignment.right),
    );
    graphics.drawString(
      asOfText,
      bodyFont,
      brush: pdf_gen.PdfSolidBrush(pdf_gen.PdfColor(70, 70, 70)),
      bounds: Rect.fromLTWH(size.width * 0.58, 53, size.width * 0.36, 12),
      format: pdf_gen.PdfStringFormat(alignment: pdf_gen.PdfTextAlignment.right),
    );
    graphics.drawLine(
      pdf_gen.PdfPen(pdf_gen.PdfColor(220, 226, 234), width: 0.7),
      Offset(34, 72),
      Offset(size.width - 34, 72),
    );

    _drawCashFlowStatementGrid(
      page: page,
      yStart: 82,
      labels: labels,
      headerFont: headerFont,
      bodyFont: bodyFont,
      bodyBold: bodyBold,
      sectionColor: headerBlue,
      totalHighlight: totalBand,
      statement: statement,
    );
  }

  double _drawTabularStatement({
    required pdf_gen.PdfPage page,
    required pdf_gen.PdfGraphics graphics,
    required double yStart,
    required List<String> labels,
    required pdf_gen.PdfFont headerFont,
    required pdf_gen.PdfFont bodyFont,
    required pdf_gen.PdfFont bodyBold,
    required pdf_gen.PdfColor sectionColor,
    required _StatementDummy statement,
  }) {
    final grid = pdf_gen.PdfGrid();
    final colCount = labels.length + 2; // Description + periods + total
    grid.columns.add(count: colCount);
    grid.columns[0].width = 220;
    for (var i = 1; i < colCount; i++) {
      grid.columns[i].width =
          (page.getClientSize().width - 260) / (labels.length + 1);
    }

    final header = grid.headers.add(1)[0];
    header.cells[0].value = statement.sections.first.title;
    for (var i = 0; i < labels.length; i++) {
      header.cells[i + 1].value = labels[i];
    }
    header.cells[colCount - 1].value = 'TOTAL';
    header.style = pdf_gen.PdfGridRowStyle(
      backgroundBrush: pdf_gen.PdfSolidBrush(sectionColor),
      textBrush: pdf_gen.PdfBrushes.white,
      font: headerFont,
    );
    grid.style = pdf_gen.PdfGridStyle(
      cellPadding: pdf_gen.PdfPaddings(left: 6, right: 6, top: 4, bottom: 4),
    );

    for (var sIndex = 0; sIndex < statement.sections.length; sIndex++) {
      final section = statement.sections[sIndex];
      if (sIndex > 0) {
        final secRow = grid.rows.add();
        secRow.cells[0].value = section.title;
        secRow.cells[0].columnSpan = colCount;
        secRow.style = pdf_gen.PdfGridRowStyle(
          backgroundBrush: pdf_gen.PdfSolidBrush(sectionColor),
          textBrush: pdf_gen.PdfBrushes.white,
          font: headerFont,
        );
      }

      for (final row in section.rows.where((r) => !r.values.every((v) => v == 0))) {
        final dataRow = grid.rows.add();
        dataRow.cells[0].value = row.label;
        double rowTotal = 0;
        for (var i = 0; i < labels.length; i++) {
          final value = row.values[i];
          rowTotal += value;
          dataRow.cells[i + 1].value = _money(value);
          dataRow.cells[i + 1].style = pdf_gen.PdfGridCellStyle(
            format: pdf_gen.PdfStringFormat(alignment: pdf_gen.PdfTextAlignment.right),
          );
        }
        dataRow.cells[colCount - 1].value = _money(rowTotal);
        dataRow.cells[colCount - 1].style = pdf_gen.PdfGridCellStyle(
          format: pdf_gen.PdfStringFormat(alignment: pdf_gen.PdfTextAlignment.right),
        );
        if (row.isBold) {
          dataRow.style = pdf_gen.PdfGridRowStyle(font: bodyBold);
        } else {
          dataRow.style = pdf_gen.PdfGridRowStyle(font: bodyFont);
        }
      }
    }

    final netRow = grid.rows.add();
    netRow.cells[0].value = 'Net Profit';
    double netTotal = 0;
    for (var i = 0; i < labels.length; i++) {
      final value = statement.netProfit[i];
      netTotal += value;
      netRow.cells[i + 1].value = _money(value);
      netRow.cells[i + 1].style = pdf_gen.PdfGridCellStyle(
        format: pdf_gen.PdfStringFormat(alignment: pdf_gen.PdfTextAlignment.right),
      );
    }
    netRow.cells[colCount - 1].value = _money(netTotal);
    netRow.cells[colCount - 1].style = pdf_gen.PdfGridCellStyle(
      format: pdf_gen.PdfStringFormat(alignment: pdf_gen.PdfTextAlignment.right),
    );
    netRow.style = pdf_gen.PdfGridRowStyle(
      backgroundBrush: pdf_gen.PdfSolidBrush(sectionColor),
      textBrush: pdf_gen.PdfBrushes.white,
      font: bodyBold,
    );

    final result = grid.draw(
      page: page,
      bounds: Rect.fromLTWH(20, yStart, page.getClientSize().width - 40, 0),
    )!;
    return result.bounds.bottom;
  }

  double _drawCashFlowStatementGrid({
    required pdf_gen.PdfPage page,
    required double yStart,
    required List<String> labels,
    required pdf_gen.PdfFont headerFont,
    required pdf_gen.PdfFont bodyFont,
    required pdf_gen.PdfFont bodyBold,
    required pdf_gen.PdfColor sectionColor,
    required pdf_gen.PdfColor totalHighlight,
    required _CashFlowStatementDummy statement,
  }) {
    final grid = pdf_gen.PdfGrid();
    final colCount = 1 + (labels.length * 2); // Description + ($, amount) * periods
    final singlePeriod = labels.length == 1;
    grid.columns.add(count: colCount);

    final totalWidth = page.getClientSize().width - 68;
    final descriptionWidth = totalWidth * 0.50;
    grid.columns[0].width = descriptionWidth;
    final symbolWidth = (totalWidth - descriptionWidth) * 0.12 / labels.length;
    final amountWidth =
        (totalWidth - descriptionWidth - (symbolWidth * labels.length)) /
        labels.length;
    for (var i = 0; i < labels.length; i++) {
      grid.columns[1 + (i * 2)].width = symbolWidth;
      grid.columns[2 + (i * 2)].width = amountWidth;
    }

    final header = grid.headers.add(1)[0];
    header.cells[0].value = statement.sections.first.title;
    for (var i = 0; i < labels.length; i++) {
      header.cells[1 + (i * 2)].value = labels[i];
      header.cells[1 + (i * 2)].columnSpan = 2;
    }
    header.style = pdf_gen.PdfGridRowStyle(
      font: headerFont,
      textBrush: pdf_gen.PdfBrushes.white,
      backgroundBrush: pdf_gen.PdfSolidBrush(sectionColor),
    );
    for (var i = 0; i < colCount; i++) {
      header.cells[i].style = pdf_gen.PdfGridCellStyle(
        borders: pdf_gen.PdfBorders(
          bottom: pdf_gen.PdfPens.transparent,
          left: pdf_gen.PdfPens.transparent,
          right: pdf_gen.PdfPens.transparent,
          top: pdf_gen.PdfPens.transparent,
        ),
        format: i == 0
            ? pdf_gen.PdfStringFormat(alignment: pdf_gen.PdfTextAlignment.left)
            : pdf_gen.PdfStringFormat(alignment: pdf_gen.PdfTextAlignment.center),
      );
    }

    grid.style = pdf_gen.PdfGridStyle(
      cellPadding: pdf_gen.PdfPaddings(left: 4, right: 4, top: 3, bottom: 3),
    );

    String amountOnly(double value) {
      if (value == 0) return '-';
      final core = NumberFormat('#,##0.00').format(value.abs());
      return value < 0 ? '($core)' : core;
    }

    for (int s = 0; s < statement.sections.length; s++) {
      final section = statement.sections[s];
      if (s > 0) {
        final secRow = grid.rows.add();
        secRow.cells[0].value = section.title;
        secRow.cells[0].columnSpan = colCount;
        secRow.style = pdf_gen.PdfGridRowStyle(
          font: headerFont,
          textBrush: pdf_gen.PdfBrushes.white,
          backgroundBrush: pdf_gen.PdfSolidBrush(sectionColor),
        );
        secRow.cells[0].style = pdf_gen.PdfGridCellStyle(
          borders: pdf_gen.PdfBorders(
            bottom: pdf_gen.PdfPens.transparent,
            left: pdf_gen.PdfPens.transparent,
            right: pdf_gen.PdfPens.transparent,
            top: pdf_gen.PdfPens.transparent,
          ),
        );
      }

      for (final row in section.rows) {
        final dataRow = grid.rows.add();
        dataRow.cells[0].value = row.label;
        for (var i = 0; i < labels.length; i++) {
          final v = row.values[i];
          dataRow.cells[1 + (i * 2)].value = '\$';
          dataRow.cells[1 + (i * 2)].style = pdf_gen.PdfGridCellStyle(
            format: pdf_gen.PdfStringFormat(alignment: pdf_gen.PdfTextAlignment.center),
            borders: pdf_gen.PdfBorders(
              bottom: pdf_gen.PdfPens.transparent,
              left: pdf_gen.PdfPens.transparent,
              right: pdf_gen.PdfPens.transparent,
              top: pdf_gen.PdfPens.transparent,
            ),
          );
          dataRow.cells[2 + (i * 2)].value = amountOnly(v);
          if (singlePeriod) {
            dataRow.cells[2 + (i * 2)].value = '  ${amountOnly(v)}';
          }
          dataRow.cells[2 + (i * 2)].style = pdf_gen.PdfGridCellStyle(
            format: pdf_gen.PdfStringFormat(
              alignment: singlePeriod
                  ? pdf_gen.PdfTextAlignment.left
                  : pdf_gen.PdfTextAlignment.right,
            ),
            borders: pdf_gen.PdfBorders(
              bottom: pdf_gen.PdfPens.transparent,
              left: pdf_gen.PdfPens.transparent,
              right: pdf_gen.PdfPens.transparent,
              top: pdf_gen.PdfPens.transparent,
            ),
          );
        }
        dataRow.cells[0].style = pdf_gen.PdfGridCellStyle(
          borders: pdf_gen.PdfBorders(
            bottom: pdf_gen.PdfPens.transparent,
            left: pdf_gen.PdfPens.transparent,
            right: pdf_gen.PdfPens.transparent,
            top: pdf_gen.PdfPens.transparent,
          ),
        );

        dataRow.style = pdf_gen.PdfGridRowStyle(
          font: row.isTotal ? bodyBold : bodyFont,
          textBrush: row.isTotal
              ? pdf_gen.PdfSolidBrush(pdf_gen.PdfColor(40, 40, 40))
              : pdf_gen.PdfSolidBrush(pdf_gen.PdfColor(50, 50, 50)),
          backgroundBrush: row.isTotal
              ? pdf_gen.PdfSolidBrush(totalHighlight)
              : null,
        );
      }
    }

    final result = grid.draw(
      page: page,
      bounds: Rect.fromLTWH(34, yStart, page.getClientSize().width - 68, 0),
    )!;
    return result.bounds.bottom;
  }

  _StatementDummy _dummyStatement(int columns) {
    final sales = List<double>.generate(columns, (i) => 78000 + i * 3500);
    final salesReturn = List<double>.generate(columns, (i) => 4000 + i * 100);
    final discount = List<double>.generate(columns, (i) => 100 + i * 10);
    final netSales = List<double>.generate(columns, (i) => sales[i] - salesReturn[i] - discount[i]);

    final materials = List<double>.generate(columns, (i) => 8000 + i * 450);
    final labor = List<double>.generate(columns, (i) => 9000 + i * 250);
    final overhead = List<double>.generate(columns, (i) => 2000 + i * 200);
    final totalCogs = List<double>.generate(columns, (i) => materials[i] + labor[i] + overhead[i]);

    final grossProfit = List<double>.generate(columns, (i) => netSales[i] - totalCogs[i]);

    final wages = List<double>.generate(columns, (i) => 10000 + i * 500);
    final advertising = List<double>.generate(columns, (i) => 500 + i * 15);
    final repair = List<double>.generate(columns, (i) => 1000 + i * 40);
    final travel = List<double>.generate(columns, (i) => 500 + i * 20);
    final rent = List<double>.generate(columns, (i) => 5550 + i * 180);
    final delivery = List<double>.generate(columns, (i) => 1000 + i * 30);
    final utilities = List<double>.filled(columns, 1000);
    final insurance = List<double>.generate(columns, (i) => 1500 + i * 30);
    final mileage = List<double>.generate(columns, (i) => 800 + i * 25);
    final office = List<double>.generate(columns, (i) => 1000 + i * 20);
    final depreciation = List<double>.generate(columns, (i) => 800 + i * 20);
    final interest = List<double>.generate(columns, (i) => 200 + i * 10);
    final otherExpense = List<double>.generate(columns, (i) => 1200 + i * 35);

    final totalOpex = List<double>.generate(
      columns,
      (i) =>
          wages[i] +
          advertising[i] +
          repair[i] +
          travel[i] +
          rent[i] +
          delivery[i] +
          utilities[i] +
          insurance[i] +
          mileage[i] +
          office[i] +
          depreciation[i] +
          interest[i] +
          otherExpense[i],
    );

    final operatingProfit = List<double>.generate(columns, (i) => grossProfit[i] - totalOpex[i]);
    final interestIncome = List<double>.generate(columns, (i) => 2000 + i * 100);
    final otherIncome = List<double>.generate(columns, (i) => 1000 + i * 70);
    final profitBeforeTax = List<double>.generate(
      columns,
      (i) => operatingProfit[i] + interestIncome[i] + otherIncome[i],
    );
    final taxExpense = List<double>.generate(columns, (i) => 4000 + i * 220);
    final net = List<double>.generate(columns, (i) => profitBeforeTax[i] - taxExpense[i]);

    return _StatementDummy(
      sections: [
        _StatementSectionDummy(
          title: 'Revenue',
          rows: [
            _StatementRowDummy(label: 'Sales', values: sales),
            _StatementRowDummy(label: 'Less: Sales Return', values: salesReturn),
            _StatementRowDummy(label: 'Less: Discounts and Allowances', values: discount),
            _StatementRowDummy(label: 'Net Sales', values: netSales, isBold: true),
          ],
        ),
        _StatementSectionDummy(
          title: 'Cost of Goods Sold',
          rows: [
            _StatementRowDummy(label: 'Materials', values: materials),
            _StatementRowDummy(label: 'Labor', values: labor),
            _StatementRowDummy(label: 'Overhead', values: overhead),
            _StatementRowDummy(label: 'Total Cost of Goods Sold', values: totalCogs, isBold: true),
          ],
        ),
        _StatementSectionDummy(
          title: 'Gross Profit',
          rows: [
            _StatementRowDummy(label: 'Gross Profit', values: grossProfit, isBold: true),
          ],
        ),
        _StatementSectionDummy(
          title: 'Operating Expenses',
          rows: [
            _StatementRowDummy(label: 'Wages', values: wages),
            _StatementRowDummy(label: 'Advertising', values: advertising),
            _StatementRowDummy(label: 'Repairs & Maintenance', values: repair),
            _StatementRowDummy(label: 'Travel', values: travel),
            _StatementRowDummy(label: 'Rent/Lease', values: rent),
            _StatementRowDummy(label: 'Delivery/Freight Expense', values: delivery),
            _StatementRowDummy(label: 'Utilities/Telephone Expenses', values: utilities),
            _StatementRowDummy(label: 'Insurance', values: insurance),
            _StatementRowDummy(label: 'Mileage', values: mileage),
            _StatementRowDummy(label: 'Office Supplies', values: office),
            _StatementRowDummy(label: 'Depreciation', values: depreciation),
            _StatementRowDummy(label: 'Interest', values: interest),
            _StatementRowDummy(label: 'Other Expenses', values: otherExpense),
            _StatementRowDummy(label: 'Total Operating Expenses', values: totalOpex, isBold: true),
          ],
        ),
        _StatementSectionDummy(
          title: 'Operating Profit (Loss)',
          rows: [
            _StatementRowDummy(label: 'Operating Profit (Loss)', values: operatingProfit, isBold: true),
          ],
        ),
        _StatementSectionDummy(
          title: 'Add Other Income',
          rows: [
            _StatementRowDummy(label: 'Interest Income', values: interestIncome),
            _StatementRowDummy(label: 'Other Income', values: otherIncome),
          ],
        ),
        _StatementSectionDummy(
          title: 'Profit Before Taxes',
          rows: [
            _StatementRowDummy(label: 'Profit Before Taxes', values: profitBeforeTax, isBold: true),
          ],
        ),
        _StatementSectionDummy(
          title: 'Less: Tax Expense',
          rows: [
            _StatementRowDummy(label: 'Tax Expense', values: taxExpense),
          ],
        ),
      ],
      netProfit: net,
    );
  }

  _StatementDummy _statementFromPnlData(PnlPdfData data, int columns) {
    List<double> fit(List<double> source) {
      if (source.length == columns) return source;
      if (source.length > columns) {
        return source.sublist(0, columns);
      }
      return <double>[
        ...source,
        ...List<double>.filled(columns - source.length, 0),
      ];
    }

    return _StatementDummy(
      sections: data.sections
          .map(
            (s) => _StatementSectionDummy(
              title: s.title,
              rows: s.rows
                  .map(
                    (r) => _StatementRowDummy(
                      label: r.label,
                      values: fit(r.values),
                      isBold: r.isBold,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      netProfit: fit(data.netProfit),
    );
  }

  _CashFlowStatementDummy _dummyCashFlowStatement(int columns) {
    final operatingProfit = List<double>.generate(columns, (i) => 11600 + (i * 420));
    final depreciation = List<double>.generate(columns, (i) => 5000 + (i * 180));
    final incomeTaxes = List<double>.generate(columns, (i) => -2900 - (i * 70));
    final workingCapital = List<double>.generate(columns, (i) => 6400 + (i * 190));

    final operating = List<double>.generate(
      columns,
      (i) => operatingProfit[i] + depreciation[i] + incomeTaxes[i] + workingCapital[i],
    );

    final assetSales = List<double>.generate(columns, (i) => 2000 + (i * 100));
    final capex = List<double>.generate(columns, (i) => -1800 - (i * 120));
    final intangibles = List<double>.generate(columns, (i) => -200 - (i * 20));
    final investing = List<double>.generate(
      columns,
      (i) => assetSales[i] + capex[i] + intangibles[i],
    );

    final equityIssue = List<double>.generate(columns, (i) => 5000 + (i * 260));
    final debtRepayment = List<double>.generate(columns, (i) => -5000 - (i * 220));
    final interestPaid = List<double>.generate(columns, (i) => -750 - (i * 40));
    final financing = List<double>.generate(
      columns,
      (i) => equityIssue[i] + debtRepayment[i] + interestPaid[i],
    );

    final netChange = List<double>.generate(columns, (i) => operating[i] + investing[i] + financing[i]);

    final beginning = List<double>.generate(columns, (i) {
      if (i == 0) return 22000;
      return List<double>.generate(i, (index) => netChange[index])
              .fold<double>(22000, (sum, value) => sum + value);
    });
    final ending = List<double>.generate(
      columns,
      (i) => beginning[i] + netChange[i],
    );

    return _CashFlowStatementDummy(
      sections: [
        _CashFlowSectionDummy(
          title: 'Operating Activities',
          rows: [
            _CashFlowRowDummy(
              label: 'Operating profit/(loss) for the financial year',
              values: operatingProfit,
            ),
            _CashFlowRowDummy(
              label: 'Depreciation of property, plant and equipment',
              values: depreciation,
            ),
            _CashFlowRowDummy(
              label: 'Income taxes',
              values: incomeTaxes,
            ),
            _CashFlowRowDummy(
              label: 'Cash flow from operations before financial expenses',
              values: workingCapital,
            ),
            _CashFlowRowDummy(
              label: 'Net Cash from Operating Activities (A)',
              values: operating,
              isTotal: true,
            ),
          ],
        ),
        _CashFlowSectionDummy(
          title: 'Investing Activities',
          rows: [
            _CashFlowRowDummy(
              label: 'Proceeds from sales of long-term assets',
              values: assetSales,
            ),
            _CashFlowRowDummy(
              label: 'Purchases of property, plant and equipment',
              values: capex,
            ),
            _CashFlowRowDummy(
              label: 'Purchases of intangible assets',
              values: intangibles,
            ),
            _CashFlowRowDummy(
              label: 'Net Cash from Investing Activities (B)',
              values: investing,
              isTotal: true,
            ),
          ],
        ),
        _CashFlowSectionDummy(
          title: 'Financing Activities',
          rows: [
            _CashFlowRowDummy(
              label: 'Issue of share capital',
              values: equityIssue,
            ),
            _CashFlowRowDummy(
              label: 'Capital repayments (including share buy-backs)',
              values: debtRepayment,
            ),
            _CashFlowRowDummy(
              label: 'Interest paid',
              values: interestPaid,
            ),
            _CashFlowRowDummy(
              label: 'Net Cash from Financing Activities (C)',
              values: financing,
              isTotal: true,
            ),
          ],
        ),
        _CashFlowSectionDummy(
          title: 'Net Change in Cash',
          rows: [
            _CashFlowRowDummy(
              label: 'Change in Cash (A + B + C)',
              values: netChange,
              isTotal: true,
            ),
          ],
        ),
        _CashFlowSectionDummy(
          title: 'Beginning Cash',
          rows: [
            _CashFlowRowDummy(
              label: 'Cash and Cash Equivalents at Beginning',
              values: beginning,
            ),
          ],
        ),
        _CashFlowSectionDummy(
          title: 'Ending Cash',
          rows: [
            _CashFlowRowDummy(
              label: 'Cash and Cash Equivalents at End',
              values: ending,
              isTotal: true,
            ),
          ],
        ),
      ],
    );
  }

  _CashFlowStatementDummy _cashFlowStatementFromData(
    CashFlowPdfData data,
    int columns,
  ) {
    List<double> fit(List<double> source) {
      if (source.length == columns) return source;
      if (source.length > columns) {
        return source.sublist(0, columns);
      }
      return <double>[
        ...source,
        ...List<double>.filled(columns - source.length, 0),
      ];
    }

    final sections = data.sections
        .map(
          (section) => _CashFlowSectionDummy(
            title: section.title,
            rows: section.rows
                .map(
                  (row) => _CashFlowRowDummy(
                    label: row.label,
                    values: fit(row.values),
                    isTotal: row.isTotal,
                    periodTotalOverride: row.periodTotalOverride,
                  ),
                )
                .toList(),
          ),
        )
        .toList();

    sections.add(
      _CashFlowSectionDummy(
        title: 'Net Change in Cash',
        rows: [
          _CashFlowRowDummy(
            label: 'Change in Cash (A + B + C)',
            values: fit(data.netChange),
            isTotal: true,
            periodTotalOverride: data.netChangeTotal,
          ),
        ],
      ),
    );
    sections.add(
      _CashFlowSectionDummy(
        title: 'Beginning Cash',
        rows: [
          _CashFlowRowDummy(
            label: 'Cash and Cash Equivalents at Beginning',
            values: fit(data.beginningCash),
            periodTotalOverride: data.beginningCashTotal,
          ),
        ],
      ),
    );
    sections.add(
      _CashFlowSectionDummy(
        title: 'Ending Cash',
        rows: [
          _CashFlowRowDummy(
            label: 'Cash and Cash Equivalents at End',
            values: fit(data.endingCash),
            isTotal: true,
            periodTotalOverride: data.endingCashTotal,
          ),
        ],
      ),
    );

    return _CashFlowStatementDummy(sections: sections);
  }

  List<String> _buildMonthLabels(DateTime start, DateTime end) {
    final labels = <String>[];
    var cursor = DateTime(start.year, start.month, 1);
    final last = DateTime(end.year, end.month, 1);
    while (!cursor.isAfter(last)) {
      labels.add(DateFormat('MMM yyyy').format(cursor));
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return labels;
  }

  List<String> _buildQuarterLabels(DateTime start, DateTime end) {
    final labels = <String>[];
    var cursor = DateTime(start.year, (((start.month - 1) ~/ 3) * 3) + 1, 1);
    while (!cursor.isAfter(end)) {
      final q = ((cursor.month - 1) ~/ 3) + 1;
      labels.add('Q$q ${cursor.year}');
      cursor = DateTime(cursor.year, cursor.month + 3, 1);
    }
    return labels;
  }

  List<String> _buildYearLabels(DateTime start, DateTime end) {
    final labels = <String>[];
    for (var y = start.year; y <= end.year; y++) {
      labels.add(y.toString());
    }
    return labels;
  }

  int _monthSpanInclusive(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + end.month - start.month + 1;
  }

  int _yearSpanInclusive(DateTime start, DateTime end) => end.year - start.year + 1;

  String _money(double value) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return fmt.format(value);
  }
}

class _StatementDummy {
  _StatementDummy({required this.sections, required this.netProfit});
  final List<_StatementSectionDummy> sections;
  final List<double> netProfit;
}

class _StatementSectionDummy {
  _StatementSectionDummy({required this.title, required this.rows});
  final String title;
  final List<_StatementRowDummy> rows;
}

class _StatementRowDummy {
  _StatementRowDummy({
    required this.label,
    required this.values,
    this.isBold = false,
  });

  final String label;
  final List<double> values;
  final bool isBold;
}

class _CashFlowStatementDummy {
  _CashFlowStatementDummy({required this.sections});
  final List<_CashFlowSectionDummy> sections;
}

class _CashFlowSectionDummy {
  _CashFlowSectionDummy({required this.title, required this.rows});
  final String title;
  final List<_CashFlowRowDummy> rows;
}

class _CashFlowRowDummy {
  _CashFlowRowDummy({
    required this.label,
    required this.values,
    this.isTotal = false,
    this.periodTotalOverride,
  });

  final String label;
  final List<double> values;
  final bool isTotal;
  final double? periodTotalOverride;
}
