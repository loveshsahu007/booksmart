import 'package:booksmart/constant/exports.dart';
import 'package:flutter/foundation.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

                    // Profile Image
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(Icons.camera_alt),
                    ),
                    0.03.verticalSpace,
                    AppTextField(
                      hintText: "First Name *",
                      keyboardType: TextInputType.name,
                      maxLines: 1,
                    ),
                    0.02.verticalSpace,
                    AppTextField(
                      hintText: "Last Name *",
                      keyboardType: TextInputType.name,
                      maxLines: 1,
                    ),
                    0.02.verticalSpace,

                    AppTextField(
                      hintText: "Phone Number",
                      keyboardType: TextInputType.phone,
                      maxLines: 1,
                    ),

                    0.06.verticalSpace,

                    AppButton(
                      buttonText: "Save Changes",
                      fontSize: 16,
                      radius: 8,
                      onTapFunction: () {},
                    ),

                    0.05.verticalSpace,
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
