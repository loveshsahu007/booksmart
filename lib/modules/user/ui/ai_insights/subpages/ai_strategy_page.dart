import 'package:booksmart/constant/exports.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class AiStrategyPage extends StatefulWidget {
  const AiStrategyPage({super.key});

  @override
  State<AiStrategyPage> createState() => _AiStrategyPageState();
}

class _AiStrategyPageState extends State<AiStrategyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                child: Column(
                  children: [
                    AppText(
                      "Deduction Optimization Level",
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    CircularPercentIndicator(
                      radius: 80.0,
                      lineWidth: 12.0,
                      percent: 0.62,
                      animation: true,
                      animationDuration: 1200,
                      circularStrokeCap: CircularStrokeCap.round,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText(
                            "62%",
                            fontWeight: FontWeight.bold,
                            fontSize: 22,

                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          AppText(
                            "38% of deductions\nnot yet utilized",
                            fontSize: 11,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      // backgroundColor: scheme.primary.withValues(alpha:
                      //   0.1,
                      // ), // light ring
                      progressColor: greenColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  context,
                  title: "Additional Deductions Found",
                  amount: "\$8,700",
                  color: greenColor,
                ),
                _buildStatCard(
                  context,
                  title: "Potential Tax Savings",
                  amount: "\$2,100",
                  color: greenColor,
                ),
              ],
            ),
            const SizedBox(height: 15),

            /// ---------- Tax Strategies ----------
            Align(
              alignment: Alignment.centerLeft,
              child: AppText(
                "Tax Strategies & Insights",
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),

            _buildStrategyTile(
              context,
              amount: "\$650",
              description:
                  "Contribute to a retirement account to increase your deductions",
              buttonLabel: "Ask BookSmart AI",
              color: greenColor,
            ),
            const SizedBox(height: 15),
            _buildStrategyTile(
              context,
              amount: "\$2,500",
              description:
                  "Utilize accelerated depreciation to lower your taxable income",
              buttonLabel: "Ask BookSmart AI",
              color: greenColor,
            ),
            const SizedBox(height: 15),
            _buildStrategyTile(
              context,
              amount: "\$400",
              description:
                  "Contribute to a retirement account to increase your deductions",
              buttonLabel: "Ask BookSmart AI",
              color: greenColor,
            ),
            const SizedBox(height: 15),
            _buildStrategyTile(
              context,
              amount: "\$8,500",
              description:
                  "Utilize accelerated depreciation to lower your taxable income",
              buttonLabel: "Ask BookSmart AI",
              color: greenColor,
            ),
          ],
        ),
      ),
    );
  }

  /// ---------- Widget: Stat Card ----------
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String amount,
    required Color color,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,

        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 12),

          child: Column(
            children: [
              AppText(
                title,
                fontSize: 12,
                textAlign: TextAlign.center,
                color: scheme.onSurface.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 8),
              AppText(
                amount,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                textAlign: TextAlign.center,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ---------- Widget: Strategy Tile ----------
  Widget _buildStrategyTile(
    BuildContext context, {
    required String amount,
    required String description,
    String? buttonLabel,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,

      child: Container(
        padding: const EdgeInsets.all(14),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              child: FittedText(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color ?? scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
                description,
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            if (buttonLabel != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: SizedBox(
                  height: 34,
                  child: AppButton(
                    buttonText: buttonLabel,
                    onTapFunction: () {},
                    fontSize: 12,
                    radius: 8,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
