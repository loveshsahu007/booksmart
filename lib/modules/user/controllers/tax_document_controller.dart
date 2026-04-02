import 'dart:developer';

import 'package:booksmart/models/user_document_model.dart';
import 'package:booksmart/modules/common/controllers/auth_controller.dart';
import 'package:booksmart/services/storage_service.dart';
import 'package:booksmart/supabase/buckets.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/utils/supabase.dart';
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
          pickedFile = XFile(platformFile.path!);
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

    try {
      isUploading.value = true;

      // 1. Upload to Storage
      final fileUrl = await uploadFileToSupabaseStorage(
        file: fileToUpload,
        bucketName: SupabaseStorageBucket.documents,
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
        'name': name.trim(),
        'file_url': fileUrl,
        if (taxYear != null && taxYear.isNotEmpty) 'tax_year': taxYear,
        if (category != null && category.isNotEmpty) 'category': category,
        if (fileSize != null) 'file_size': fileSize,
        if (orderId != null) 'order_id': orderId,
        if (cpaId != null) 'cpa_id': cpaId,
        'mime_type': _guessMime(fileToUpload.name),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from(SupabaseTable.userDocuments).insert(payload);

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
