import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../../../../widgets/app_text.dart';

class BusinessPowerScoreCard extends StatelessWidget {
  const BusinessPowerScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              'Business Power Score (BPS)',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: SfRadialGauge(
                          axes: <RadialAxis>[
                            RadialAxis(
                              minimum: 0,
                              maximum: 100,
                              startAngle: 150,
                              endAngle: 30,
                              radiusFactor: 0.95,
                              showLastLabel: true,
                              labelFormat: '{value}',
                              axisLabelStyle: GaugeTextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontFamily:
                                    theme.textTheme.bodyMedium?.fontFamily,
                              ),
                              majorTickStyle: const MajorTickStyle(
                                length: 0.1,
                                thickness: 1.5,
                                color: Colors.white54,
                              ),
                              minorTickStyle: const MinorTickStyle(
                                length: 0.05,
                                thickness: 1,
                                color: Colors.white24,
                              ),
                              axisLineStyle: const AxisLineStyle(
                                thickness: 0.12,
                                thicknessUnit: GaugeSizeUnit.factor,
                                cornerStyle: CornerStyle.bothCurve,
                                color: Colors.black12,
                              ),
                              pointers: const <GaugePointer>[
                                RangePointer(
                                  value: 80,
                                  width: 0.12,
                                  sizeUnit: GaugeSizeUnit.factor,
                                  cornerStyle: CornerStyle.bothCurve,
                                  gradient: SweepGradient(
                                    colors: <Color>[
                                      Colors.redAccent,
                                      Colors.orange,
                                      Colors.yellow,
                                      Colors.greenAccent,
                                      Colors.cyan,
                                    ],
                                    stops: <double>[0.0, 0.25, 0.5, 0.75, 1.0],
                                  ),
                                ),
                                MarkerPointer(
                                  value: 80,
                                  markerType: MarkerType.circle,
                                  color: Colors.white,
                                  markerWidth: 8,
                                  markerHeight: 8,
                                ),
                              ],
                              annotations: <GaugeAnnotation>[
                                GaugeAnnotation(
                                  angle: 90,
                                  positionFactor: 0.2,
                                  widget: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const AppText(
                                        '80',
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      AppText(
                                        'Good',
                                        fontSize: 16,
                                        color: Colors.grey[400],
                                      ),
                                    ],
                                  ),
                                ),
                                GaugeAnnotation(
                                  angle: 90,
                                  positionFactor: 0.8,
                                  widget: AppText(
                                    '\$ 4725.0004',
                                    fontSize: 12,
                                    color: Colors.white30,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const AppText(
                            'Level 8',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(width: 8),
                          AppText(
                            'Entrepreneur',
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                          const Spacer(),
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.wallet,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          const AppText(
                            'Eforei',
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: 0.75,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.orangeAccent,
                        ),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 20),
                      const AppText(
                        'Cashflow Builder',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: 0.6,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.amber,
                        ),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            'Next rank: Profit Machine',
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                          AppText(
                            'Streak: 3.500',
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText(
                                'Todays XP Potential:',
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              AppText(
                                '+340 XP',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
