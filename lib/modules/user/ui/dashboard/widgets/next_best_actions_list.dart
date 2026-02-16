import 'package:flutter/material.dart';
import '../../../../../widgets/app_text.dart';

class NextBestActionsList extends StatelessWidget {
  const NextBestActionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppText(
              'Next Best Actions',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            Row(
              children: [
                Icon(Icons.star_border, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 4),
                const AppText('+975 XP', fontSize: 12, color: Colors.green),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
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
          subtitle: '',
          xp: '+90 XP',
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required String index,
    required String title,
    required String subtitle,
    required String xp,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText('$index. ', fontSize: 13, color: Colors.grey),
              Expanded(
                child: AppText(
                  title,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 15),
                    const Icon(Icons.stars, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    AppText(subtitle, fontSize: 11, color: Colors.grey),
                  ],
                ),
              ],
              Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppText(
                  xp,
                  fontSize: 11,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
