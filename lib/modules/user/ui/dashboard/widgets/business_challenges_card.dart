import 'package:flutter/material.dart';
import '../../../../../widgets/app_text.dart';

class BusinessChallengesCard extends StatelessWidget {
  const BusinessChallengesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Business Challenges',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Cashflow Warrior Challenge',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        AppText(
                          'Goal: increase cashflow by 10%',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  _ChallengeStat(label: 'Progress', value: '5/10 Tasks'),
                  SizedBox(width: 24),
                  _ChallengeStat(label: 'Reward', value: 'Expert Badge'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const AppText(
                        'Fix This',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const AppText('Details', fontSize: 12),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChallengeStat extends StatelessWidget {
  final String label;
  final String value;

  const _ChallengeStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, fontSize: 10, color: Colors.grey),
        AppText(value, fontSize: 12, fontWeight: FontWeight.bold),
      ],
    );
  }
}
