// File: lib/screens/profile/user_profile_screen.dart

import 'dart:typed_data';

import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/controllers/user_controller.dart';
import 'package:booksmart/modules/common/providers/supabase_crud.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
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
  final _imagePicker = ImagePicker();

  // Profile image upload
  XFile? _profileImage; // selected file (kept for upload)
  Uint8List?
  _profileImageBytes; // in-memory bytes for preview (works on web + mobile)
  String? _profileImageUrl; // remote URL (from server)

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

      final Map<String, dynamic>? row = (res is Map<String, dynamic>)
          ? res
          : (res is List && res.isNotEmpty ? res.first : null);

      if (row != null) {
        _firstNameCtrl.text = (row['first_name'] ?? '') as String;
        _lastNameCtrl.text = (row['last_name'] ?? '') as String;
        _phoneCtrl.text = (row['phone_number'] ?? '') as String;

        // Load existing profile image URL
        _profileImageUrl = row['img_url'] as String?;
      }
    } catch (e) {
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

  /// Pick image from gallery and store bytes for preview.
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        setState(() {
          _profileImage = pickedFile;
          _profileImageBytes = bytes;
          // keep _profileImageUrl as-is (so if user cancels before saving, old URL remains)
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image',
        snackPosition: SnackPosition.BOTTOM,
      );
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

    try {
      // Upload profile image if selected
      if (_profileImage != null) {
        // Your SupabaseCrudService.uploadFile should accept XFile and return public URL
        final uploadedUrl = await _crud.uploadFile(
          _profileImage!,
          'userImages',
        );

        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          _profileImageUrl = uploadedUrl;

          // After successful upload, clear local preview bytes to prefer showing the remote image
          _profileImage = null;
          _profileImageBytes = null;
        }
      }

      // Prepare payload
      final payload = <String, dynamic>{
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'phone_number': _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
        if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
          'img_url': _profileImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Remove null values from payload
      payload.removeWhere((key, value) => value == null);

      // 1️⃣ Update in Supabase
      await _crud.update(
        table: 'users',
        data: payload,
        filters: {'auth_id': authId},
      );

      // 2️⃣ Update in UserController (local app state)
      try {
        final userCtrl = Get.find<UserController>();
        if (userCtrl.hasUser) {
          final updatedUser = userCtrl.user.value!.copyWith(
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            phoneNumber: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
            imgUrl: _profileImageUrl,
          );
          userCtrl.user.value = updatedUser;
        }
      } catch (e) {
        // If UserController isn't found, don't crash — just log.
        debugPrint('UserController update skipped: $e');
      }

      // 3️⃣ Show success message
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Profile update failed: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildProfileImageSection() {
    ImageProvider? avatarImage;

    // Prefer local preview bytes if present (user just picked an image)
    if (_profileImageBytes != null) {
      avatarImage = MemoryImage(_profileImageBytes!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      // Fall back to network image (uploaded previously)
      avatarImage = NetworkImage(_profileImageUrl!);
    } else {
      avatarImage = null;
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? const Icon(Icons.camera_alt, size: 30, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: _pickImage,
              child: const Text('Change Profile Picture'),
            ),
            if (avatarImage != null)
              TextButton(
                onPressed: () {
                  // remove selection & remote URL (if user wants to remove pic)
                  setState(() {
                    _profileImage = null;
                    _profileImageBytes = null;
                    _profileImageUrl = null;
                  });
                },
                child: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text('My Profile')),
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

                    // Profile Image
                    _buildProfileImageSection(),

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
