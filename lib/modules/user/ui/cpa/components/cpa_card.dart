import 'package:booksmart/widgets/custom_circle_avatar.dart';
import 'package:get/get.dart';

import 'package:booksmart/models/user_base_model.dart';
import 'package:booksmart/modules/common/ui/chat/chat_screen.dart';

import '../../../../../constant/exports.dart';
import '../detail_screen.dart';
import 'package:booksmart/helpers/currency_formatter.dart';

class CpaCard extends StatelessWidget {
  final CpaModel cpa;
  const CpaCard({super.key, required this.cpa});

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
            goToCpaDetailScreen(cpa);
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
                    CustomCircleAvatar(
                      imgUrl: cpa.imgUrl,
                      alternateText: cpa.firstName,
                      radius: 30,
                      backgroundColor: scheme.primary.withValues(alpha: 0.1),
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
                        "${cpa.firstName} ${cpa.lastName}",
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        "${cpa.getExperienceInYears} years experience",
                        fontSize: 12,
                      ),
                      AppText(
                        "Pricing: \$${formatNumber(cpa.hourlyRate)}/hr",
                        fontSize: 12,
                      ),
                      const SizedBox(height: 8),
                      if (cpa.specialties.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: cpa.specialties.take(3).map((tag) {
                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.1),
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
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    goToChatScreen(cpa.data, shouldCloseBefore: false);
                  },
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
