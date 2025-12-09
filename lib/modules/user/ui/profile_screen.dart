// File: lib/screens/profile/user_profile_screen.dart

import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/controllers/user_controller.dart';
import 'package:booksmart/modules/common/providers/supabase_crud.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final _crud = SupabaseCrudService();

  bool _loading = false;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? get _currentAuthId => Supabase.instance.client.auth.currentUser?.id;

  Future<void> _loadProfile() async {
    setState(() => _initialLoading = true);

    final authId = _currentAuthId;
    if (authId == null) {
      setState(() => _initialLoading = false);
      Get.snackbar(
        'Not signed in',
        'Please sign in to edit your profile.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final res = await _crud.read(
        table: 'users',
        filters: {'auth_id': authId},
        single: true,
      );

      // res might be maybeSingle result shaped by your SDK; normalize it.
      final Map<String, dynamic>? row = (res is Map<String, dynamic>)
          ? res
          : (res is List && res.isNotEmpty ? res.first : null);

      if (row != null) {
        _firstNameCtrl.text = (row['first_name'] ?? '') as String;
        _lastNameCtrl.text = (row['last_name'] ?? '') as String;
        // phone_number vs phone-number — use the exact column name in your DB
        _phoneCtrl.text = (row['phone_number'] ?? '') as String;
      }
    } catch (e) {
      // quietly log and show a friendly message
      debugPrint('Failed to load profile: $e');
      Get.snackbar(
        'Error',
        'Failed to load profile data',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _initialLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authId = _currentAuthId;
    if (authId == null) {
      Get.snackbar(
        'Not signed in',
        'Please sign in to update profile.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _loading = true);

    final payload = <String, dynamic>{
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
    };

    try {
      // 1️⃣ Update in Supabase
      await _crud.update(
        table: 'users',
        data: payload,
        filters: {'auth_id': authId},
      );

      // 2️⃣ Update in UserController
      final userCtrl = Get.find<UserController>();
      if (userCtrl.hasUser) {
        final updatedUser = userCtrl.user.value!.copyWith(
          firstName: payload['first_name'],
          lastName: payload['last_name'],
          phoneNumber: payload['phone_number'],
        );
        userCtrl.user.value = updatedUser;
      }

      // 3️⃣ Navigate or show success
      Get.offAllNamed(Routes.home); // User Dashboard
      // Optional Snackbar
      // Get.snackbar('Success', 'Profile updated', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      debugPrint('Profile update failed: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: kIsWeb ? null : AppBar(),
      body: Scrollbar(
        thumbVisibility: true,
        radius: const Radius.circular(10),
        thickness: 6,
        controller: _scrollController,
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// 🔹 Title
                    AppText(
                      "Set Up Your Profile",
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),

                    0.05.verticalSpace,

                    // Profile Image (tap to upload could be added later)
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.camera_alt),
                    ),
                    0.03.verticalSpace,

                    if (_initialLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: CircularProgressIndicator(),
                      )
                    else ...[
                      AppTextField(
                        controller: _firstNameCtrl,
                        hintText: "First Name *",
                        keyboardType: TextInputType.name,
                        maxLines: 1,
                        fieldValidator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return "Enter first name";
                          return null;
                        },
                      ),
                      0.02.verticalSpace,
                      AppTextField(
                        controller: _lastNameCtrl,
                        hintText: "Last Name *",
                        keyboardType: TextInputType.name,
                        maxLines: 1,
                        fieldValidator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return "Enter last name";
                          return null;
                        },
                      ),
                      0.02.verticalSpace,
                      AppTextField(
                        controller: _phoneCtrl,
                        hintText: "Phone Number",
                        keyboardType: TextInputType.phone,
                        maxLines: 1,
                        fieldValidator: (v) {
                          if (v != null && v.isNotEmpty && v.length < 6)
                            return "Enter a valid phone number";
                          return null;
                        },
                      ),
                      0.06.verticalSpace,

                      AppButton(
                        buttonText: _loading ? "Saving..." : "Save Changes",
                        fontSize: 16,
                        radius: 8,
                        onTapFunction: _loading ? null : _saveProfile,
                      ),

                      0.05.verticalSpace,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
