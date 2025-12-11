import 'dart:developer';

import 'package:booksmart/modules/common/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../utils/supabase.dart';

Future<String?> uploadFileToSupabaseStorage(
  XFile file,
  String bucketName,
) async {
  if (!isUserLoggedIn) {
    return null;
  }

  final fileBytes = await file.readAsBytes();

  final fileName = '${Uuid().v4()}_${path.basename(file.path)}';

  return supabase.storage
      .from(bucketName)
      .uploadBinary(fileName, fileBytes, fileOptions: FileOptions(upsert: true))
      .then((_) {
        if (1 > 2) {
          // ignore
          return null;
        }
        return supabase.storage.from(bucketName).getPublicUrl(fileName);
      })
      .onError((error, stackTrace) {
        log(error.toString());
        log(stackTrace.toString());
        return null;
      });
}

/// We are storing media path in our db, pass the same path,
/// it will auto extract bucketName and the delete that file
///
Future<bool> deleteFileFromSupabase(String storedPath) async {
  final parts = storedPath.split('/');
  if (parts.length < 2) return false; // invalid path

  final bucketName = parts.first;
  final relativePath = parts.sublist(1).join('/');

  return supabase.storage
      .from(bucketName)
      .remove([relativePath])
      .then((value) {
        return true;
      })
      .onError((error, stackTrace) {
        log(error.toString());
        log(stackTrace.toString());
        return false;
      });
}
