import 'package:flutter/material.dart'; // Add this
import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/models/user_data_model.dart';
import 'package:get/get.dart';

class ProfileUnderReviewScreenCPA extends StatelessWidget {
  final UserModel? userData;

  const ProfileUnderReviewScreenCPA({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWeb = width > 900;
    final isTablet = width > 600 && width <= 900;

    // Try to get data from Get.arguments if not passed in constructor
    final data = userData ?? (Get.arguments as UserModel?);

    return Scaffold(
      appBar: AppBar(title: const Text("Registration Submitted!")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20), // Added const
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.amber,
              size: isWeb ? 80 : (isTablet ? 70 : 60),
            ),

            const SizedBox(height: 20),

            const AppText(
              "Thank you for joining the BookSmart CPA Network. Your information is under review.",
              textAlign: TextAlign.center,
              fontSize: 14,
            ),

            const SizedBox(height: 25),

            Card(
              elevation: 1,
              child: Padding(
                padding: EdgeInsets.all(isWeb ? 20 : (isTablet ? 18 : 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      "Verification Status",
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),

                    const SizedBox(height: 15),

                    if (data != null) ...[
                      // License Number
                      if (data.licenseNumber != null)
                        Column(
                          children: [
                            _buildStatusRow(
                              "License Number",
                              data.licenseNumber!,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),

                      // Certifications
                      if (data.certifications?.isNotEmpty == true)
                        Column(
                          children: [
                            _buildStatusRow(
                              "Certification",
                              data.certifications!.join(", "),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),

                      // States
                      if (data.stateFocuses?.isNotEmpty == true)
                        Column(
                          children: [
                            _buildStatusRow(
                              "State(s)",
                              data.stateFocuses!.join(", "),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                    ],

                    _buildStatusRow(
                      "License Verification",
                      "Pending Verification via License Database",
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 10),

                    _buildStatusRow(
                      "Profile Status",
                      data?.status?.toUpperCase() ?? "PENDING",
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Profile Card with actual user data or fallback
            Card(
              child: Padding(
                padding: EdgeInsets.all(isWeb ? 20 : (isTablet ? 18 : 16)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: data?.imgUrl != null
                          ? NetworkImage(data!.imgUrl!) // Fixed: removed cast
                          : null,
                      child: data?.imgUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data != null) ...[
                            // Full name
                            AppText(
                              _getFullName(data),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            const SizedBox(height: 5),

                            // Certifications
                            if (data.certifications?.isNotEmpty == true)
                              Column(
                                children: [
                                  AppText(
                                    data.certifications!.join(", "),
                                    fontSize: 12,
                                  ),
                                  const SizedBox(height: 5),
                                ],
                              ),

                            // Experience
                            if (data.yearsOfExperience != null)
                              Column(
                                children: [
                                  AppText(
                                    "Experience: ${data.yearsOfExperience} ${data.yearsOfExperience == 1 ? 'year' : 'years'}",
                                    fontSize: 12,
                                  ),
                                  const SizedBox(height: 5),
                                ],
                              ),

                            // Bio (truncated)
                            if (data.professionalBio != null)
                              AppText(
                                _truncateText(data.professionalBio!, 80),
                                fontSize: 12,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ] else ...[
                            // Fallback content when no data is available
                            const AppText(
                              "Profile information will appear here",
                              fontSize: 14,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            AppButton(
              buttonText: "Edit Profile",
              onTapFunction: () {
                Get.back();
              },
              buttonColor: const Color.fromARGB(255, 19, 44, 82),
              fontSize: 14,
              textColor: Colors.white,
              radius: 8,
            ),
            const SizedBox(height: 20),

            AppButton(
              buttonText: "Dashboard (Temp)",
              onTapFunction: () {
                Get.offAllNamed(Routes.dashboardCPA);
              },
              radius: 8,
              fontSize: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String title, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(flex: 2, child: AppText(title, fontSize: 13)),
        Expanded(
          flex: 3,
          child: AppText(
            value,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // Helper method to get full name
  String _getFullName(UserModel user) {
    final parts = [
      user.firstName,
      user.middleName,
      user.lastName,
    ].where((part) => part != null && part.isNotEmpty).toList();

    return parts.join(" ");
  }

  // Helper method to truncate text
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
