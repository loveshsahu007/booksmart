import 'dart:developer';

import 'package:booksmart/models/user_document_model.dart';
import 'package:booksmart/services/storage_service.dart';
import 'package:booksmart/supabase/buckets.dart';
import 'package:booksmart/supabase/tables.dart';
import 'package:booksmart/utils/supabase.dart';
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
    final userId = supabase.auth.currentUser?.id;
    print("******1* $userId");
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
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (file != null) {
        pickedFile = file;
        update(); // refresh dialog UI
      }
    } catch (e) {
      log('Device pick error: $e');
      Get.snackbar('Error', 'Could not pick file');
    }
  }

  /// Uploads [pickedFile] to the `documents` bucket, then inserts a row in
  /// `user_documents`. Refreshes the list on success.
  ///
  /// Returns `true` on success, `false` otherwise.
  Future<bool> uploadDocument({
    required String name,
    String? taxYear,
    String? category,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      Get.snackbar('Error', 'User not authenticated');
      return false;
    }
    if (pickedFile == null) {
      Get.snackbar('Error', 'Please select a file first');
      return false;
    }
    if (name.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a document name');
      return false;
    }

    try {
      isUploading.value = true;

      // 1. Upload to Storage
      final fileUrl = await uploadFileToSupabaseStorage(
        file: pickedFile!,
        bucketName: SupabaseStorageBucket.documents,
      );

      if (fileUrl == null || fileUrl.isEmpty) {
        Get.snackbar('Error', 'Upload failed. Try again.');
        return false;
      }

      // 2. Get file size
      int? fileSize;
      try {
        final bytes = await pickedFile!.readAsBytes();
        fileSize = bytes.length;
      } catch (_) {}

      // 3. Insert DB row
      final payload = <String, dynamic>{
        'user_id': userId,
        'name': name.trim(),
        'file_url': fileUrl,
        if (taxYear != null && taxYear.isNotEmpty) 'tax_year': taxYear,
        if (category != null && category.isNotEmpty) 'category': category,
        if (fileSize != null) 'file_size': fileSize,
        'mime_type': _guessMime(pickedFile!.name),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from(SupabaseTable.userDocuments).insert(payload);

      // 4. Reset picked file and refresh list
      pickedFile = null;
      await fetchDocuments();
      Get.snackbar('Success', 'Document uploaded successfully');
      return true;
    } catch (e, st) {
      log('TaxDocumentController.uploadDocument error: $e\n$st');
      Get.snackbar('Error', 'Failed to upload document: $e');
      return false;
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
    return Icons.insert_drive_file;
  }
}
