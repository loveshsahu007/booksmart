import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../widgets/app_text.dart';

class AiStrategyInsightList extends StatelessWidget {
  const AiStrategyInsightList({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,

      child: Container(
        padding: const EdgeInsets.all(15),
        height: 315,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (MediaQuery.sizeOf(context).width > 800) ...{
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText(
                    'AI strategy Insights',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.star_border,
                        color: Colors.greenAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const AppText(
                        '+975 XP',
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
            },
            Column(
              spacing: 25,
              children: [
                _buildActionItem(
                  index: '1',
                  title: 'You have \$2,100 in missed deductions',
                  subtitle: '\$25 XP in missed coins',
                  xp: '+20 XP',
                ),
                _buildActionItem(
                  index: '2',
                  title: 'Pay \$480 to boost score',
                  subtitle: 'Your score will increase by 5 points',
                  xp: '+100 XP',
                ),
                _buildActionItem(
                  index: '3',
                  title: 'Get your tax score: \$4,900',
                  subtitle: 'Your score will increase by 5 points',
                  xp: '+90 XP',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required String index,
    required String title,
    required String subtitle,
    required String xp,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedText('$index.', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 5),
                    Expanded(
                      child: AppText(
                        title,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const SizedBox(width: 15),
                      Icon(
                        Icons.stars,
                        color: Get.theme.primaryColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      AppText(subtitle, fontSize: 11, color: Colors.grey),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(5),
            width: 70,
            decoration: BoxDecoration(
              color: Get.theme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: AppText(
              xp,
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
