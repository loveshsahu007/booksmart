import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
  Future<String> uploadFile({
    required String bucketName,
    required dynamic file, // File (mobile), Uint8List (web), or XFile
    String? fileName,
    String? folderPath,
    String? contentType, // Optional content type
  }) async {
    try {
      // Generate file name if not provided
      String finalFileName =
          fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}';

      // Add folder path if provided
      String filePath = finalFileName;
      if (folderPath != null) {
        filePath = '$folderPath$finalFileName';
      }

      // Convert to Uint8List
      Uint8List fileBytes;
      if (file is File) {
        final List<int> bytes = await file.readAsBytes();
        fileBytes = Uint8List.fromList(bytes);
      } else if (file is Uint8List) {
        fileBytes = file;
      } else if (file is XFile) {
        // Handle XFile from image_picker
        final bytes = await file.readAsBytes();
        fileBytes = Uint8List.fromList(bytes);
      } else {
        throw Exception(
          "Unsupported file type. Use File, Uint8List, or XFile.",
        );
      }

      // Upload to Supabase Storage with file options
      final fileOptions = FileOptions(
        upsert: true,
        contentType: contentType ?? 'application/octet-stream',
      );

      await _supabase.storage
          .from(bucketName)
          .uploadBinary(filePath, fileBytes, fileOptions: fileOptions);

      // Get public URL
      final String publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      debugPrint("File uploaded successfully: $publicUrl");
      return publicUrl;
    } catch (e) {
      debugPrint("File upload failed: $e");
      throw Exception("File upload failed: $e");
    }
  }
}
