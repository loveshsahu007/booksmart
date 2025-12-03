import 'package:get/get.dart';

import '../../../../../constant/exports.dart';
import '../detail_screen.dart';

class CpaCard extends StatelessWidget {
  const CpaCard({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme scheme = Get.theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            goToCpaDetailScreen();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 15,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person_outline, size: 30),
                    ),
                    const SizedBox(height: 5),
                    FittedText("⭐⭐⭐⭐⭐ • 5.0", style: TextStyle(fontSize: 8)),
                    Row(),
                    AppText("4 Reviews", fontSize: 10),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "John Doe",
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 4),
                      AppText("4 years experience • CA", fontSize: 12),
                      AppText("Pricing: \$50/hr", fontSize: 12),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: ["CPA", "Accounting", "Tax Preparation"]
                              .map((tag) {
                                return Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: scheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: scheme.primary),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: scheme.primary,
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.chat_bubble_outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
