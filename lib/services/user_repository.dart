import 'package:booksmart/models/user_data_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  //final String table = 'User'; // change if your table name differs
  final String table = 'users'; // change if your table name differs
  /// Fetch single user row by auth_id
  Future<UserModel?> getByAuthId(String authId) async {
    try {
      final res = await _supabase
          .from(table)
          .select()
          .eq('auth_id', authId)
          .maybeSingle(); // will return single row or null

      // The SDK may return the row directly or wrap it; normalize:
      final dyn = res as dynamic;
      if (dyn == null) return null;

      // If result is a Map already:
      final Map<String, dynamic> row = (dyn is Map<String, dynamic>)
          ? dyn
          : (dyn as Map<String, dynamic>);
      return UserModel.fromJson(row);
    } catch (e) {
      // bubble up or log
      throw Exception('Failed to fetch user: $e');
    }
  }

  /// Update user by auth_id. Returns updated UserModel
  Future<UserModel?> updateByAuthId(
    String authId,
    Map<String, dynamic> values,
  ) async {
    try {
      final res = await _supabase
          .from(table)
          .update(values)
          .eq('auth_id', authId)
          .select()
          .maybeSingle();
      final dyn = res as dynamic;
      if (dyn == null) return null;
      final Map<String, dynamic> row = (dyn is Map<String, dynamic>)
          ? dyn
          : (dyn as Map<String, dynamic>);
      return UserModel.fromJson(row);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Insert new user row (if needed)
  Future<UserModel?> insert(Map<String, dynamic> data) async {
    try {
      final res = await _supabase
          .from(table)
          .insert(data)
          .select()
          .maybeSingle();
      final dyn = res as dynamic;
      if (dyn == null) return null;
      final Map<String, dynamic> row = (dyn is Map<String, dynamic>)
          ? dyn
          : (dyn as Map<String, dynamic>);
      return UserModel.fromJson(row);
    } catch (e) {
      throw Exception('Failed to insert user: $e');
    }
  }
}
