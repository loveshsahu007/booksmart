import 'dart:ui' as ui;

import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/user/controllers/tax_document_controller.dart';
import 'package:get/get.dart';
import 'package:booksmart/widgets/statement_viewer_dialog.dart';
import 'package:booksmart/utils/downloader.dart';
import 'package:screenshot/screenshot.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf_gen;
import 'package:booksmart/models/user_document_model.dart';
import 'package:intl/intl.dart';

class RecentDocumentsWidget extends StatelessWidget {
  final String? type;
  final double topMargin;

  /// Section header (e.g. "Recently Added" on balance sheet).
  final String sectionTitle;

  /// When true, subtitle includes upload date from [UserDocument.createdAt].
  final bool showUploadDateInSubtitle;

  /// When true, image MIME types show a small network thumbnail.
  final bool useImageThumbnailWhenPossible;

  /// When true, show a delete control with confirmation.
  final bool showDeleteAction;

  /// Template PDF export icon in the row trailing area.
  final bool showExportTemplateAction;

  const RecentDocumentsWidget({
    super.key,
    this.type,
    this.topMargin = 32,
    this.sectionTitle = 'Recently Uploaded',
    this.showUploadDateInSubtitle = false,
    this.useImageThumbnailWhenPossible = false,
    this.showDeleteAction = false,
    this.showExportTemplateAction = true,
  });

  void _exportTemplate(UserDocument doc, BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ScreenshotController screenshotController = ScreenshotController();

      // Render the dialog off-screen accurately matching the exact visual UI rendering
      final Uint8List imageBytes = await screenshotController.captureFromWidget(
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Theme(
            data: Theme.of(context),
            child: MediaQuery(
              data: const MediaQueryData(size: Size(850, 1100)),
              child: StatementViewerCard(document: doc),
            ),
          ),
        ),
        delay: const Duration(milliseconds: 200),
      );

      final pdf_gen.PdfDocument document = pdf_gen.PdfDocument();
      final pdf_gen.PdfPage page = document.pages.add();
      final pdf_gen.PdfBitmap image = pdf_gen.PdfBitmap(imageBytes);

      // Scale to fit PDF constraints elegantly
      final double pageWidth = page.getClientSize().width;
      final double pageHeight = page.getClientSize().height;
      final double imageWidth = image.width.toDouble();
      final double imageHeight = image.height.toDouble();

      double drawWidth = pageWidth;
      double drawHeight = (imageHeight * pageWidth) / imageWidth;

      if (drawHeight > pageHeight) {
        drawHeight = pageHeight;
        drawWidth = (imageWidth * pageHeight) / imageHeight;
      }

      page.graphics.drawImage(
        image,
        Rect.fromLTWH(0, 0, drawWidth, drawHeight),
      );

      final List<int> bytes = await document.save();
      document.dispose();

      String filename = '${doc.name.replaceAll(" ", "_")}_Template.pdf';
      await downloadFile(filename, bytes, mimeType: 'application/pdf');

      messenger.showSnackBar(
        const SnackBar(content: Text('Template PDF exported successfully!')),
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to export PDF template')),
      );
    }
  }

  static final _uploadDateFmt = DateFormat.yMMMd();

  Future<void> _confirmDelete(
    BuildContext context,
    TaxDocumentController ctrl,
    UserDocument doc,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text(
          'Remove "${doc.name}" from your uploaded documents? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ctrl.deleteDocument(doc);
    }
  }

  Widget _leadingPreview(UserDocument doc) {
    final mime = doc.mimeType?.toLowerCase() ?? '';
    final isImage =
        useImageThumbnailWhenPossible && mime.startsWith('image/');
    if (!isImage) {
      return Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          TaxDocumentController.iconForMime(doc.mimeType),
          color: const Color(0xFFEAB308),
          size: 22,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Image.network(
          doc.fileUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            TaxDocumentController.iconForMime(doc.mimeType),
            color: const Color(0xFFEAB308),
            size: 22,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TaxDocumentController ctrl = Get.isRegistered<TaxDocumentController>()
        ? Get.find<TaxDocumentController>()
        : Get.put(TaxDocumentController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Obx(() {
      if (ctrl.isLoading.value && ctrl.documents.isEmpty) {
        return const SizedBox.shrink();
      }

      // Filter documents by type if provided
      var filteredDocs = ctrl.documents.toList();
      if (type != null) {
        filteredDocs = filteredDocs.where((doc) {
          final cat = doc.category?.toLowerCase() ?? '';
          final searchType = type!.toLowerCase();

          if (cat.contains(searchType) || cat == searchType) return true;

          if (searchType == 'pnl' && cat.contains('profit')) return true;
          if (searchType == 'bs' && cat.contains('balance')) return true;
          if (searchType == 'cf' && cat.contains('cash')) return true;
          if (searchType == 'pl' && cat.contains('profit')) return true;

          return false;
        }).toList();
      }

      if (filteredDocs.isEmpty) {
        return const SizedBox.shrink();
      }

      final recentDocs = filteredDocs.take(5).toList();

      return Padding(
        padding: EdgeInsets.only(top: topMargin),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black12,
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      sectionTitle,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    TextButton(
                      onPressed: () =>
                          Get.toNamed('/tax-filling'), // Adjust route if needed
                      child: const AppText(
                        "View All",
                        color: Color(0xFFEAB308),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentDocs.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.white.withValues(alpha: 0.05),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final doc = recentDocs[index];
                  final uploaded =
                      showUploadDateInSubtitle
                          ? 'Uploaded ${_uploadDateFmt.format(doc.createdAt.toLocal())}'
                          : null;
                  final subtitleParts = <String>[
                    if (uploaded != null) uploaded,
                    doc.category ?? 'Uncategorized',
                    doc.taxYear ?? 'N/A',
                  ];
                  return ListTile(
                    leading: _leadingPreview(doc),
                    title: AppText(
                      doc.name,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    subtitle: AppText(
                      subtitleParts.join(' • '),
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (doc.fileSizeLabel.isNotEmpty) ...[
                          AppText(
                            doc.fileSizeLabel,
                            fontSize: 12,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 8),
                        ],
                        TextButton(
                          onPressed: () {
                            Get.dialog(StatementViewerDialog(document: doc));
                          },
                          child: const AppText(
                            'View',
                            color: Color(0xFFEAB308),
                            fontSize: 13,
                          ),
                        ),
                        if (showDeleteAction) ...[
                          IconButton(
                            tooltip: 'Delete file',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 22,
                            ),
                            onPressed: () =>
                                _confirmDelete(context, ctrl, doc),
                          ),
                        ],
                        if (showExportTemplateAction) ...[
                          Tooltip(
                            message: 'Export Template',
                            child: InkWell(
                              onTap: () => _exportTemplate(doc, context),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.download,
                                  size: 16,
                                  color: Color(0xFF19C37D),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}
