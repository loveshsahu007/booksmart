import 'package:booksmart/modules/user/ui/dashboard/widgets/business_challenges_card.dart';
import 'package:booksmart/modules/user/ui/dashboard/widgets/business_power_score_card.dart';
import 'package:booksmart/modules/user/ui/dashboard/widgets/missions_list.dart';
import 'package:booksmart/modules/user/ui/dashboard/widgets/ai_strategy_insight_list.dart';
import 'package:booksmart/modules/user/ui/dashboard/widgets/stats_header.dart';
import 'package:booksmart/modules/user/ui/dashboard/widgets/achievements_grid.dart';
import 'package:booksmart/modules/user/ui/dashboard/widgets/secondary_stats_cards.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1200) {
            return _buildDesktopLayout(context);
          } else if (constraints.maxWidth > 800) {
            return _buildTabletLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const StatsHeader(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    const BusinessPowerScoreCard(),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(child: MissionsList()),
                        const SizedBox(width: 24),
                        const Expanded(child: AiStrategyInsightList()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(child: AchievementsGrid()),
                        const SizedBox(width: 24),
                        const Expanded(child: BusinessChallengesCard()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              const SizedBox(width: 350, child: SecondaryStatsCards()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const StatsHeader(),
          const SizedBox(height: 20),
          const BusinessPowerScoreCard(),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  children: [
                    MissionsList(),
                    SizedBox(height: 20),
                    AchievementsGrid(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  children: [
                    AiStrategyInsightList(),
                    SizedBox(height: 20),
                    BusinessChallengesCard(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SecondaryStatsCards(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const StatsHeader(),
          const SizedBox(height: 16),
          const BusinessPowerScoreCard(),
          const SizedBox(height: 16),
          const MissionsList(),
          const SizedBox(height: 16),
          const AiStrategyInsightList(),
          const SizedBox(height: 16),
          const AchievementsGrid(),
          const SizedBox(height: 16),
          const BusinessChallengesCard(),
          const SizedBox(height: 16),
          const SecondaryStatsCards(),
        ],
      ),
    );
  }
}
