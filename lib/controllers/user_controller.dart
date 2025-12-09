import 'package:booksmart/models/user_data_model.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_repository.dart';

class UserController extends GetxController {
  final UserRepository _repo = UserRepository();

  // Rxn allows null value
  final Rxn<UserModel> user = Rxn<UserModel>();

  bool get hasUser => user.value != null;
  String? get authId => Supabase.instance.client.auth.currentUser?.id;

  /// Load current user from DB (by auth_id) and store in controller
  Future<void> loadCurrentUser() async {
    final id = authId;
    if (id == null) {
      user.value = null;
      return;
    }

    try {
      final u = await _repo.getByAuthId(id);
      user.value = u;
    } catch (e) {
      // optionally log
      user.value = null;
      rethrow;
    }
  }

  /// Update basic fields and refresh controller state
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    final id = authId;
    if (id == null) throw Exception('Not authenticated');

    final Map<String, dynamic> payload = {};
    if (firstName != null) payload['first_name'] = firstName;
    if (lastName != null) payload['last_name'] = lastName;
    if (phoneNumber != null) payload['phone_number'] = phoneNumber;

    final updated = await _repo.updateByAuthId(id, payload);
    if (updated != null) user.value = updated;
  }

  /// Create user row if not present (useful after sign up when row doesn't exist)
  Future<void> createIfMissing({required Map<String, dynamic> data}) async {
    final id = authId;
    if (id == null) throw Exception('Not authenticated');

    final existing = await _repo.getByAuthId(id);
    if (existing != null) {
      user.value = existing;
      return;
    }

    // ensure auth_id present
    data['auth_id'] = id;
    final created = await _repo.insert(data);
    user.value = created;
  }
}
