
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Add this import

class SupabaseCrudService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// ---------------------------
  /// CREATE (INSERT) - Add alias for create
  /// ---------------------------
  Future<dynamic> create({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final res = await _supabase
          .from(table)
          .insert(data)
          .select()
          .whenComplete(() {
            debugPrint("***/////***???---- Data inserted ");
          });
      return res; // returns inserted row(s)
    } catch (e) {
      throw Exception("Insert failed: $e");
    }
  }

  /// ---------------------------
  /// CREATE (INSERT) - Keep original
  /// ---------------------------
  Future<dynamic> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final res = await _supabase
          .from(table)
          .insert(data)
          .select()
          .whenComplete(() {
            debugPrint("***/////***???---- Data inserted ");
          });
      return res; // returns inserted row(s)
    } catch (e) {
      throw Exception("Insert failed: $e");
    }
  }

  /// ---------------------------
  /// READ (SELECT)
  /// ---------------------------
  Future<dynamic> read({
    required String table,
    Map<String, dynamic>? filters,
    bool single = false,
  }) async {
    try {
      var query = _supabase.from(table).select();

      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      if (single) {
        return await query.maybeSingle();
      } else {
        return await query;
      }
    } catch (e) {
      throw Exception("Read failed: $e");
    }
  }

  /// ---------------------------
  /// UPDATE - Fix to handle lists properly
  /// ---------------------------
  Future<dynamic> update({
    required String table,
    required Map<String, dynamic> data,
    required Map<String, dynamic> filters,
  }) async {
    try {
      // Format data for Supabase (handle array fields)
      final formattedData = _formatDataForSupabase(data);

      var query = _supabase.from(table).update(formattedData);

      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      final res = await query.select();
      return res;
    } catch (e) {
      throw Exception("Update failed: $e");
    }
  }

  /// Helper method to format data for Supabase
  Map<String, dynamic> _formatDataForSupabase(Map<String, dynamic> data) {
    final formatted = Map<String, dynamic>.from(data);

    // Ensure array fields are properly formatted
    // Supabase expects List<dynamic> for array columns
    final arrayFields = ['certifications', 'specialties', 'state_focuses'];

    for (final field in arrayFields) {
      if (formatted.containsKey(field)) {
        final value = formatted[field];
        if (value is List<String>) {
          formatted[field] = value;
        } else if (value == null) {
          formatted[field] = []; // Empty array for null
        }
      }
    }

    return formatted;
  }

  /// ---------------------------
  /// DELETE
  /// ---------------------------
  Future<dynamic> delete({
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    try {
      var query = _supabase.from(table).delete();

      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      final res = await query;
      return res;
    } catch (e) {
      throw Exception("Delete failed: $e");
    }
  }

  /// ---------------------------
  /// UPLOAD SINGLE FILE/IMAGE - FIXED
  /// ---------------------------
  /// Uploads a single file to Supabase Storage and returns the public URL
  ///
  /// Parameters:
  /// - `bucketName`: The name of the storage bucket
  /// - `file`: Can be File (mobile), Uint8List (web), or XFile
  /// - `fileName`: Optional custom file name, uses timestamp if not provided
  /// - `folderPath`: Optional folder path within the bucket
  ///
  /// Returns:
  /// - Public URL of the uploaded file
  // FIXED: Proper file upload method for Supabase with Uint8List
  Future<String?> uploadFile(
    XFile file,
    String bucketName,
  
  ) async {
    try {
      final fileBytes = await file.readAsBytes();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';

      // Upload binary data (Uint8List)
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _getMimeType(file.path),
            ),
          );

      // Get public URL
      final url = _supabase.storage.from(bucketName).getPublicUrl(fileName);
      return url;
    } catch (e) {
      debugPrint('File upload failed: $e');
      Get.snackbar(
        'Upload Error',
        'Failed to upload file: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }
}

// Helper to get MIME type from file extension
String _getMimeType(String filePath) {
  final extension = path.extension(filePath).toLowerCase();
  switch (extension) {
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.png':
      return 'image/png';
    case '.gif':
      return 'image/gif';
    case '.pdf':
      return 'application/pdf';
    case '.doc':
      return 'application/msword';
    case '.docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    default:
      return 'application/octet-stream';
  }
}
