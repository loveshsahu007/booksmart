import 'dart:developer';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

import 'package:booksmart/models/financial_template_models.dart';
import 'package:booksmart/models/user_document_model.dart';
import 'package:booksmart/modules/common/controllers/auth_controller.dart';
import 'package:booksmart/modules/user/controllers/financial_report_controller.dart';
import 'package:booksmart/modules/user/controllers/organization_controller.dart';
import 'package:booksmart/services/document_parser_service.dart';
import 'package:booksmart/services/storage_service.dart';
import 'package:booksmart/supabase/buckets.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/utils/supabase.dart';
import 'package:booksmart/widgets/app_text.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class TaxDocumentController extends GetxController {
  // ── Reactive state ────────────────────────────────────────────────────────

  final documents = <UserDocument>[].obs;
  final isLoading = false.obs;
  final isUploading = false.obs;
  final extractedData = Rxn<dynamic>();
  final NumberFormat _moneyFmt = NumberFormat('#,##0.00');

  // ── Form state (used by the upload dialog) ────────────────────────────────

  /// The file chosen by the user (camera or gallery/device).
  XFile? pickedFile;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    fetchDocuments();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Loads all documents belonging to the current user.
  Future<void> fetchDocuments() async {
    final int? userId = authUser?.id;

    if (userId == null) return;

    try {
      isLoading.value = true;
      final result = await supabase
          .from(SupabaseTable.userDocuments)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      documents.value = (result as List)
          .map((e) => UserDocument.fromJson(e))
          .toList();
    } catch (e, st) {
      log('TaxDocumentController.fetchDocuments error: $e\n$st');
      Get.snackbar('Error', 'Failed to load documents');
    } finally {
      isLoading.value = false;
    }
  }

  /// Picks a file from the camera (mobile-only).
  Future<void> pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (file != null) {
        pickedFile = file;
        update(); // refresh dialog UI
      }
    } catch (e) {
      log('Camera pick error: $e');
      Get.snackbar('Error', 'Could not open camera');
    }
  }

  /// Picks a file from the device gallery / file system.
  Future<void> pickFromDevice() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: kIsWeb,
      );
      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.single;
        if (kIsWeb && platformFile.bytes != null) {
          pickedFile = XFile.fromData(
            platformFile.bytes!,
            name: platformFile.name,
          );
        } else if (platformFile.path != null) {
          pickedFile = XFile(platformFile.path!, name: platformFile.name);
        }
        update(); // refresh dialog UI
      }
    } catch (e) {
      log('Device pick error: $e');
      Get.snackbar('Error', 'Could not pick file');
    }
  }

  /// Returns the `fileUrl` on success, `null` otherwise.
  Future<String?> uploadDocument({
    required String name,
    String? taxYear,
    String? category,
    String? type,
    int? userId,
    int? orderId,
    int? cpaId,
    XFile? manualFile,
  }) async {
    final int? effectiveUserId = userId ?? authUser?.id;
    if (effectiveUserId == null) {
      showSnackBar('User not authenticated', isError: true);
      return null;
    }

    final XFile? fileToUpload = manualFile ?? pickedFile;
    if (fileToUpload == null) {
      showSnackBar('Please select a file first', isError: true);
      return null;
    }
    if (name.trim().isEmpty) {
      showSnackBar('Please enter a document name', isError: true);
      return null;
    }

    // Ensure name has the correct extension
    String finalName = name.trim();
    final extension = p.extension(fileToUpload.name).toLowerCase();
    if (extension.isNotEmpty && !finalName.toLowerCase().endsWith(extension)) {
      finalName = '$finalName$extension';
    }

    try {
      isUploading.value = true;

      // 1. Upload to Storage
      final mimeType = _guessMime(fileToUpload.name);
      final fileUrl = await uploadFileToSupabaseStorage(
        file: fileToUpload,
        bucketName: SupabaseStorageBucket.documents,
        contentType: mimeType,
      );

      if (fileUrl == null || fileUrl.isEmpty) {
        showSnackBar('Upload failed. Try again.', isError: true);
        return null;
      }

      // 2. Get file size
      int? fileSize;
      try {
        final bytes = await fileToUpload.readAsBytes();
        fileSize = bytes.length;
      } catch (_) {}

      // 3. Insert DB row
      final payload = <String, dynamic>{
        'user_id': effectiveUserId,
        'name': finalName,
        'file_url': fileUrl,
        if (taxYear != null && taxYear.isNotEmpty) 'tax_year': taxYear,
        if (category != null && category.isNotEmpty) 'category': category,
        if (fileSize != null) 'file_size': fileSize,
        if (orderId != null) 'order_id': orderId,
        if (cpaId != null) 'cpa_id': cpaId,
        'mime_type': mimeType,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from(SupabaseTable.userDocuments).insert(payload);

      final normalizedType = _normalizeType(type);
      if (normalizedType != null) {
        final parsedData = await DocumentParserService.parseDocument(
          fileToUpload,
          type: normalizedType,
        );

        if (parsedData != null) {
          extractedData.value = parsedData;
        } else {
          if (normalizedType == 'pnl') {
            extractedData.value = ProfitAndLossTemplate(
              revenue: 0,
              cogs: 0,
              grossProfit: 0,
              operatingExpenses: 0,
              netIncome: 0,
            );
          } else if (normalizedType == 'bs') {
            extractedData.value = BalanceSheetTemplate(
              currentAssets: 0,
              nonCurrentAssets: 0,
              currentLiabilities: 0,
              longTermLiabilities: 0,
              equity: 0,
            );
          } else {
            extractedData.value = CashFlowTemplate(
              operatingActivities: 0,
              investingActivities: 0,
              financingActivities: 0,
            );
          }
        }

        final confirmed = await _showReviewDialog(normalizedType);
        if (!confirmed) return null;

        final orgId = getCurrentOrganization?.id;
        if (orgId != null) {
          final txDate = _effectiveTxDate(taxYear);
          await _saveExtractedData(
            effectiveUserId,
            orgId,
            finalName,
            txDate,
            normalizedType,
          );
          final tag = orgId.toString();
          if (Get.isRegistered<FinancialReportController>(tag: tag)) {
            final fc = Get.find<FinancialReportController>(tag: tag);
            fc.fetchAndAggregateData(
              startDate: fc.lastStartDate,
              endDate: fc.lastEndDate,
            );
          }
        }
      }

      // 4. Reset picked file and refresh list
      if (manualFile == null) {
        pickedFile = null;
      }
      await fetchDocuments();
      return fileUrl;
    } catch (e, st) {
      log('TaxDocumentController.uploadDocument error: $e\n$st');
      showSnackBar('Failed to upload document: $e', isError: true);
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  String? _normalizeType(String? type) {
    if (type == null || type.trim().isEmpty) return null;
    final t = type.trim().toLowerCase();
    if (t == 'pl' || t == 'pnl' || t == 'profit_loss' || t == 'profitloss') {
      return 'pnl';
    }
    if (t == 'bs' || t == 'balance_sheet' || t == 'balancesheet') return 'bs';
    if (t == 'cf' || t == 'cash_flow' || t == 'cashflow') return 'cf';
    return null;
  }

  DateTime _effectiveTxDate(String? taxYear) {
    final yr = int.tryParse((taxYear ?? '').trim());
    if (yr == null || yr == DateTime.now().year) return DateTime.now();
    return DateTime(yr, 1, 1);
  }

  Future<bool> _showReviewDialog(String type) async {
    final data = extractedData.value;
    if (data == null) return false;

    final controllers = <String, TextEditingController>{};
    if (type == 'pnl' && data is ProfitAndLossTemplate) {
      controllers['revenue'] = TextEditingController(
        text: _formatMoneyInput(data.revenue),
      );
      controllers['cogs'] = TextEditingController(
        text: _formatMoneyInput(data.cogs),
      );
      controllers['operatingExpenses'] = TextEditingController(
        text: _formatMoneyInput(data.operatingExpenses),
      );
      controllers['grossProfit'] = TextEditingController(
        text: _formatMoneyInput(data.grossProfit),
      );
      controllers['netIncome'] = TextEditingController(
        text: _formatMoneyInput(data.netIncome),
      );
    } else if (type == 'bs' && data is BalanceSheetTemplate) {
      controllers['currentAssets'] = TextEditingController(
        text: _formatMoneyInput(data.currentAssets),
      );
      controllers['nonCurrentAssets'] = TextEditingController(
        text: _formatMoneyInput(data.nonCurrentAssets),
      );
      controllers['currentLiabilities'] = TextEditingController(
        text: _formatMoneyInput(data.currentLiabilities),
      );
      controllers['longTermLiabilities'] = TextEditingController(
        text: _formatMoneyInput(data.longTermLiabilities),
      );
      controllers['equity'] = TextEditingController(
        text: _formatMoneyInput(data.equity),
      );
    } else if (type == 'cf' && data is CashFlowTemplate) {
      controllers['operatingActivities'] = TextEditingController(
        text: _formatMoneyInput(data.operatingActivities),
      );
      controllers['operatingAdjustments'] = TextEditingController(
        text: _formatMoneyInput(data.operatingAdjustments),
      );
      controllers['workingCapitalChanges'] = TextEditingController(
        text: _formatMoneyInput(data.workingCapitalChanges),
      );
      controllers['investingActivities'] = TextEditingController(
        text: _formatMoneyInput(data.investingActivities),
      );
      controllers['assetPurchases'] = TextEditingController(
        text: _formatMoneyInput(data.assetPurchases),
      );
      controllers['investmentActivities'] = TextEditingController(
        text: _formatMoneyInput(data.investmentActivities),
      );
      controllers['financingActivities'] = TextEditingController(
        text: _formatMoneyInput(data.financingActivities),
      );
      controllers['loanActivities'] = TextEditingController(
        text: _formatMoneyInput(data.loanActivities),
      );
      controllers['ownerContributions'] = TextEditingController(
        text: _formatMoneyInput(data.ownerContributions),
      );
      controllers['distributions'] = TextEditingController(
        text: _formatMoneyInput(data.distributions),
      );
    }

    bool confirmed = false;
    final isManual = _isZeroTemplate(type);
    await Get.dialog(
      StatefulBuilder(
        builder: (context, setLocalState) {
          void recalcCashFlow(String fieldKey) {
            if (type != 'cf') return;
            final assetPurchases =
                _parseMoney(controllers['assetPurchases']?.text ?? '0');
            final investmentActivities =
                _parseMoney(controllers['investmentActivities']?.text ?? '0');
            final loanActivities =
                _parseMoney(controllers['loanActivities']?.text ?? '0');
            final ownerContributions =
                _parseMoney(controllers['ownerContributions']?.text ?? '0');
            final distributions =
                _parseMoney(controllers['distributions']?.text ?? '0');

            if (fieldKey == 'assetPurchases' ||
                fieldKey == 'investmentActivities') {
              final investing = assetPurchases + investmentActivities;
              controllers['investingActivities']?.text =
                  _formatMoneyInput(investing);
            }
            if (fieldKey == 'loanActivities' ||
                fieldKey == 'ownerContributions' ||
                fieldKey == 'distributions') {
              final financing =
                  loanActivities + ownerContributions + distributions;
              controllers['financingActivities']?.text =
                  _formatMoneyInput(financing);
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF0A192F),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isManual ? 'Manual Review Template' : 'Review Extracted Data',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isManual)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'AI could not auto-read this. Please enter values below.',
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                    ),
                  ),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._buildReviewFields(
                      type,
                      controllers,
                      onFieldChanged: (fieldKey) {
                        recalcCashFlow(fieldKey);
                        setLocalState(() {});
                      },
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            _summaryLabel(type),
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                          AppText(
                            _formatMoneyDisplay(_summaryValue(type, controllers)),
                            fontWeight: FontWeight.w900,
                            color: _summaryValue(type, controllers) >= 0
                                ? const Color(0xFF19C37D)
                                : const Color(0xFFE57373),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAB308),
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  _applyControllersToExtractedData(type, controllers);
                  confirmed = true;
                  Get.back();
                },
                child: const Text(
                  'Confirm & Save',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
      barrierDismissible: false,
    );

    for (final c in controllers.values) {
      c.dispose();
    }
    return confirmed;
  }

  bool _isZeroTemplate(String type) {
    final data = extractedData.value;
    if (type == 'pnl' && data is ProfitAndLossTemplate) {
      return data.revenue == 0 &&
          data.cogs == 0 &&
          data.operatingExpenses == 0 &&
          data.netIncome == 0;
    }
    if (type == 'bs' && data is BalanceSheetTemplate) {
      return data.currentAssets == 0 &&
          data.nonCurrentAssets == 0 &&
          data.currentLiabilities == 0 &&
          data.longTermLiabilities == 0;
    }
    if (type == 'cf' && data is CashFlowTemplate) {
      return data.operatingActivities == 0 &&
          data.investingActivities == 0 &&
          data.financingActivities == 0;
    }
    return false;
  }

  String _summaryLabel(String type) {
    if (type == 'pnl') return 'Projected Net Income';
    if (type == 'bs') return 'Balance Difference';
    return 'Net Cash Change';
  }

  double _summaryValue(
    String type,
    Map<String, TextEditingController> controllers,
  ) {
    double v(String key) => _parseMoney(controllers[key]?.text ?? '0');
    if (type == 'pnl') {
      return (v('revenue') - v('cogs')) - v('operatingExpenses');
    }
    if (type == 'bs') {
      return (v('currentAssets') + v('nonCurrentAssets')) -
          (v('currentLiabilities') + v('longTermLiabilities') + v('equity'));
    }
    final investingByParts = v('assetPurchases') + v('investmentActivities');
    final financingByParts =
        v('loanActivities') + v('ownerContributions') + v('distributions');
    final hasInvestingBreakdown =
        v('assetPurchases') != 0 ||
        v('investmentActivities') != 0;
    final hasFinancingBreakdown =
        v('loanActivities') != 0 ||
        v('ownerContributions') != 0 ||
        v('distributions') != 0;
    final operating = v('operatingActivities');
    final investing = hasInvestingBreakdown
        ? investingByParts
        : v('investingActivities');
    final financing = hasFinancingBreakdown
        ? financingByParts
        : v('financingActivities');
    return operating + investing + financing;
  }

  List<Widget> _buildReviewFields(
    String type,
    Map<String, TextEditingController> controllers,
    {ValueChanged<String>? onFieldChanged}
  ) {
    final fields = <Widget>[];
    if (type == 'pnl') {
      fields.add(
        _buildEditRow(
          'Revenue',
          controllers['revenue'],
          onChanged: () => onFieldChanged?.call('revenue'),
        ),
      );
      fields.add(
        _buildEditRow(
          'COGS',
          controllers['cogs'],
          onChanged: () => onFieldChanged?.call('cogs'),
        ),
      );
      fields.add(
        _buildEditRow(
          'Operating Expenses',
          controllers['operatingExpenses'],
          onChanged: () => onFieldChanged?.call('operatingExpenses'),
        ),
      );
      fields.add(
        _buildEditRow(
          'Gross Profit',
          controllers['grossProfit'],
          onChanged: () => onFieldChanged?.call('grossProfit'),
        ),
      );
      fields.add(
        _buildEditRow(
          'Net Income',
          controllers['netIncome'],
          onChanged: () => onFieldChanged?.call('netIncome'),
        ),
      );
    } else if (type == 'bs') {
      fields.add(
        _buildEditRow(
          'Current Assets',
          controllers['currentAssets'],
          onChanged: () => onFieldChanged?.call('currentAssets'),
        ),
      );
      fields.add(
        _buildEditRow(
          'Non-Current Assets',
          controllers['nonCurrentAssets'],
          onChanged: () => onFieldChanged?.call('nonCurrentAssets'),
        ),
      );
      fields.add(
        _buildEditRow(
          'Current Liabilities',
          controllers['currentLiabilities'],
          onChanged: () => onFieldChanged?.call('currentLiabilities'),
        ),
      );
      fields.add(
        _buildEditRow(
          'Long-Term Liabilities',
          controllers['longTermLiabilities'],
          onChanged: () => onFieldChanged?.call('longTermLiabilities'),
        ),
      );
      fields.add(
        _buildEditRow(
          'Equity',
          controllers['equity'],
          onChanged: () => onFieldChanged?.call('equity'),
        ),
      );
    } else if (type == 'cf') {
      fields.add(
        _buildEditRow(
          'Net Operating Activities',
          controllers['operatingActivities'],
          onChanged: () => onFieldChanged?.call('operatingActivities'),
        ),
      );
      fields.add(
        _buildEditRow(
          'Operating adjustments (e.g. Depreciation)',
          controllers['operatingAdjustments'],
          onChanged: () => onFieldChanged?.call('operatingAdjustments'),
        ),
      );
      fields.add(
        _buildEditRow(
          'Working Capital changes',
          controllers['workingCapitalChanges'],
          onChanged: () => onFieldChanged?.call('workingCapitalChanges'),
        ),
      );
      fields.add(const Divider(color: Colors.white24));
      fields.add(
        _buildEditRow(
          'Net Investing Activities',
          controllers['investingActivities'],
          onChanged: () => onFieldChanged?.call('investingActivities'),
        ),
      );
      fields.add(
        _buildEditRow(
          'Asset purchases',
          controllers['assetPurchases'],
          onChanged: () => onFieldChanged?.call('assetPurchases'),
        ),
      );
      fields.add(
        _buildEditRow(
          'Investment activities',
          controllers['investmentActivities'],
          onChanged: () => onFieldChanged?.call('investmentActivities'),
        ),
      );
      fields.add(const Divider(color: Colors.white24));
      fields.add(
        _buildEditRow(
          'Net Financing Activities',
          controllers['financingActivities'],
          onChanged: () => onFieldChanged?.call('financingActivities'),
        ),
      );
      fields.add(
        _buildEditRow(
          'Loan activities (Debt)',
          controllers['loanActivities'],
          onChanged: () => onFieldChanged?.call('loanActivities'),
        ),
      );
      fields.add(
        _buildEditRow(
          'Owner contributions',
          controllers['ownerContributions'],
          onChanged: () => onFieldChanged?.call('ownerContributions'),
        ),
      );
      fields.add(
        _buildEditRow(
          'Distributions / Dividends',
          controllers['distributions'],
          onChanged: () => onFieldChanged?.call('distributions'),
        ),
      );
    }
    return fields;
  }

  Widget _buildEditRow(
    String label,
    TextEditingController? controller, {
    bool readOnly = false,
    VoidCallback? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: const TextStyle(color: Colors.white70),
              fillColor: Colors.white.withValues(alpha: 0.1),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (_) => onChanged?.call(),
          ),
        ],
      ),
    );
  }

  void _applyControllersToExtractedData(
    String type,
    Map<String, TextEditingController> controllers,
  ) {
    double v(String key) => _parseMoney(controllers[key]?.text ?? '0');
    if (type == 'pnl') {
      final revenue = v('revenue');
      final cogs = v('cogs');
      final opex = v('operatingExpenses');
      final gross = revenue - cogs;
      final net = gross - opex;
      extractedData.value = ProfitAndLossTemplate(
        revenue: revenue,
        cogs: cogs,
        grossProfit: gross,
        operatingExpenses: opex,
        netIncome: net,
      );
    } else if (type == 'bs') {
      final ca = v('currentAssets');
      final nca = v('nonCurrentAssets');
      final cl = v('currentLiabilities');
      final ltl = v('longTermLiabilities');
      final eq = v('equity');
      extractedData.value = BalanceSheetTemplate(
        currentAssets: ca,
        nonCurrentAssets: nca,
        currentLiabilities: cl,
        longTermLiabilities: ltl,
        equity: eq,
      );
    } else {
      final investingByParts = v('assetPurchases') + v('investmentActivities');
      final financingByParts =
          v('loanActivities') + v('ownerContributions') + v('distributions');
      final hasInvestingBreakdown =
          v('assetPurchases') != 0 || v('investmentActivities') != 0;
      final hasFinancingBreakdown =
          v('loanActivities') != 0 ||
          v('ownerContributions') != 0 ||
          v('distributions') != 0;

      extractedData.value = CashFlowTemplate(
        operatingActivities: v('operatingActivities'),
        operatingAdjustments: v('operatingAdjustments'),
        workingCapitalChanges: v('workingCapitalChanges'),
        investingActivities: hasInvestingBreakdown
            ? investingByParts
            : v('investingActivities'),
        assetPurchases: v('assetPurchases'),
        investmentActivities: v('investmentActivities'),
        financingActivities: hasFinancingBreakdown
            ? financingByParts
            : v('financingActivities'),
        loanActivities: v('loanActivities'),
        ownerContributions: v('ownerContributions'),
        distributions: v('distributions'),
      );
    }
  }

  double _parseMoney(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (cleaned.isEmpty || cleaned == '-' || cleaned == '.') return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatMoneyInput(double value) => _moneyFmt.format(value);

  String _formatMoneyDisplay(double value) => '\$${_moneyFmt.format(value)}';

  Future<void> _saveExtractedData(
    int userId,
    int orgId,
    String name,
    DateTime docDate,
    String type,
  ) async {
    final data = extractedData.value;
    if (data == null) return;

    final transactions = <Map<String, dynamic>>[];
    if (type == 'pnl' && data is ProfitAndLossTemplate) {
      transactions.add({'title': '[Revenue] $name', 'amount': data.revenue});
      transactions.add({'title': '[COGS] $name', 'amount': -data.cogs.abs()});
      transactions.add({
        'title': '[OpEx] $name',
        'amount': -data.operatingExpenses.abs(),
      });
    } else if (type == 'bs' && data is BalanceSheetTemplate) {
      transactions.add({
        'title': '[Asset:Current] $name',
        'amount': data.currentAssets,
      });
      transactions.add({
        'title': '[Asset:Non-Current] $name',
        'amount': data.nonCurrentAssets,
      });
      transactions.add({
        'title': '[Liab:Current] $name',
        'amount': -data.currentLiabilities.abs(),
      });
      transactions.add({
        'title': '[Liab:Long-Term] $name',
        'amount': -data.longTermLiabilities.abs(),
      });
      transactions.add({
        'title': '[Equity] $name',
        'amount': data.equity,
      });
    } else if (type == 'cf' && data is CashFlowTemplate) {
      // ChatGPT-aligned strict approach:
      // - Use section totals as authoritative for dashboard/KPIs
      // - Recompute investing/financing totals from details when provided
      // - Avoid double-counting by saving only section totals
      final hasInvestingBreakdown =
          data.assetPurchases != 0 || data.investmentActivities != 0;
      final hasFinancingBreakdown =
          data.loanActivities != 0 ||
          data.ownerContributions != 0 ||
          data.distributions != 0;

      final investingTotal = hasInvestingBreakdown
          ? (-data.assetPurchases.abs()) + data.investmentActivities
          : data.investingActivities;
      final financingTotal = hasFinancingBreakdown
          ? data.loanActivities +
                data.ownerContributions.abs() -
                data.distributions.abs()
          : data.financingActivities;

      transactions.add({
        'title': '[CF:Operating] $name',
        'amount': data.operatingActivities,
      });
      transactions.add({
        'title': '[CF:Investing] $name',
        'amount': investingTotal,
      });
      transactions.add({
        'title': '[CF:Financing] $name',
        'amount': financingTotal,
      });
    }

    for (final tx in transactions) {
      await supabase.from(SupabaseTable.transaction).insert({
        'user_id': userId,
        'org_id': orgId,
        'title': tx['title'],
        'amount': tx['amount'],
        'type': 'Business',
        'date_time': docDate.toIso8601String(),
      });
    }
  }

  /// Deletes [doc] from storage and from the database.
  Future<void> deleteDocument(UserDocument doc) async {
    try {
      isLoading.value = true;

      // 1. Delete from storage (best-effort)
      await deleteFileFromSupabase(doc.fileUrl);

      // 2. Delete from DB
      await supabase
          .from(SupabaseTable.userDocuments)
          .delete()
          .eq('id', doc.id);

      // 3. Remove from local list
      documents.remove(doc);
      Get.snackbar('Deleted', '${doc.name} has been removed');
    } catch (e, st) {
      log('TaxDocumentController.deleteDocument error: $e\n$st');
      Get.snackbar('Error', 'Failed to delete document');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _guessMime(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  /// Icon to show in the list based on mime type.
  static IconData iconForMime(String? mime) {
    if (mime == null) return Icons.insert_drive_file;
    if (mime.startsWith('image/')) return Icons.image;
    if (mime == 'application/pdf') return Icons.picture_as_pdf;
    if (mime.contains('word')) return Icons.description;
    if (mime.contains('spreadsheet') ||
        mime.contains('excel') ||
        mime.contains('csv')) {
      return Icons.table_chart;
    }
    if (mime.contains('presentation') || mime.contains('powerpoint')) {
      return Icons.slideshow;
    }
    if (mime.contains('zip') || mime.contains('compressed')) {
      return Icons.folder_zip;
    }
    if (mime.startsWith('text/')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }
}
