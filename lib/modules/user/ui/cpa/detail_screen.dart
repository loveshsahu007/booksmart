import 'package:booksmart/constant/exports.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../widgets/custom_dialog.dart';

void goToCpaDetailScreen({bool shouldCloseBefore = false}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back(); // close previous dialog
    }
    customDialog(
      child: const CpaDetailScreen(),
      title: 'CPA Details',
      barrierDismissible: true,
      maxWidth: 800,
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => const CpaDetailScreen());
    } else {
      Get.to(() => const CpaDetailScreen());
    }
  }
}

class CpaDetailScreen extends StatelessWidget {
  const CpaDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme scheme = Get.theme.colorScheme;

    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("CPA Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // CPA Profile Card
            _buildCpaProfileCard(scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildCpaProfileCard(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    child: Icon(
                      Icons.person_outline,
                      size: 30,
                      color: scheme.onPrimary,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.yellow[600],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      "Laura Green, CPA, EA",
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      "Licensed in CA • 12 years experience",
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    const SizedBox(height: 8),

                    // Star Rating
                    Row(
                      children: [
                        _buildStarRating(4.8),
                        const SizedBox(width: 8),
                        AppText("4.8 (23 reviews)", fontSize: 12),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Service Pricing
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AppText(
                        "Starting at \$299 for standard filing",
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bio Section
          AppText(
            "Laura specializes in strategic tax planning for self-employed professionals and small business owners. "
            "With over a decade of experience across real estate, e-commerce, and service-based businesses, she focuses "
            "on helping clients minimize taxes and maximize growth.",
            fontSize: 13,
          ),
          const SizedBox(height: 20),

          // Expertise Sections
          _buildSectionHeader("Tax Expertise", Icons.receipt_long),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag("Tax Planning & Strategy"),
              _buildTag("Small Business Tax"),
              _buildTag("Cryptocurrency Taxation"),
              _buildTag("Bookkeeping Clean-up"),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader(
            "Industry-Specific Expertise",
            Icons.business_center,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag("Self-Employed"),
              _buildTag("E-Commerce"),
              _buildTag("Real Estate"),
              _buildTag("Investors"),
            ],
          ),

          const SizedBox(height: 24),

          // Response Time
          AppText("Typically replies within 24 hours", fontSize: 12),
          const SizedBox(height: 16),

          // Action Buttons
          AppButton(
            buttonText: "Send Message",
            onTapFunction: () {
              showConfirmationDialog();
            },
            radius: 8,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          // Full star
          return Icon(Icons.star, color: Colors.yellow[600], size: 16);
        } else if (index == rating.floor() && rating % 1 != 0) {
          // Half star
          return Icon(Icons.star_half, color: Colors.yellow[600], size: 16);
        } else {
          // Empty star
          return Icon(Icons.star_border, color: Colors.yellow[600], size: 16);
        }
      }),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 6),
          AppText(title, fontSize: 14, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Chip(
      label: AppText(text, fontSize: 12),
      side: BorderSide.none,
      backgroundColor: Colors.grey.shade800,
    );
  }
}

void showConfirmationDialog() {
  Get.dialog(
    AlertDialog(
      title: AppText("Confirm Selection", fontSize: 14),
      content: AppText(
        "Are you sure you'd like to connect with Laura Green, CPA, EA?",
        fontSize: 12,
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: AppText("Cancel", fontSize: 12),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            // Navigate to Access Granted screen
          },
          child: AppText("Confirm", fontSize: 12),
        ),
      ],
    ),
  );
}
