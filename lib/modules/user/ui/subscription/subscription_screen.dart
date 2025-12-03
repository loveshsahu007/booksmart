import 'package:flutter/material.dart';
import 'package:booksmart/widgets/app_text.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool isMonthly = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Subscription",
        
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText(
                "Upgrade Your Benefits",
                fontSize: 22,
                textAlign: TextAlign.center,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 24),

              // Feature Comparison
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _featureColumn(
                    title: "Free",
                    color: colorScheme.onSurface,
                    features: const [
                      "✔ Tax Filing Add-On",
                      "✔ AI Insights Add-On",
                      "✔ Quarterly Filing Add-On",
                    ],
                  ),
                  _featureColumn(
                    title: "Premium",
                    color: colorScheme.primary,
                    features: const [
                      "✔ Monthly Monitoring",
                      "✔ Unlimited Chat Support",
                      "✔ Multiple Businesses",
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Subscription Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _subscriptionCard(
                    context,
                    title: "Monthly Review",
                    price: "\$19.99",
                    subtitle: "/mo",
                    description:
                        "Get detailed insights\nafter each month’s close",
                    colorScheme: colorScheme,
                  ),
                  _subscriptionCard(
                    context,
                    title: "Quarterly Filing",
                    price: "\$39.99",
                    subtitle: "/quarter",
                    description: "Discounted rate for\n4 filings year round",
                    colorScheme: colorScheme,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Billing Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _toggleButton("Monthly", isMonthly, colorScheme),
                  const SizedBox(width: 10),
                  _toggleButton("Yearly", !isMonthly, colorScheme),
                  const SizedBox(width: 10),
                  AppText(
                    "Save 20%",
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),

              const SizedBox(height: 30),
              AppText(
                "Compliance with applicable tax laws is the responsibility of the user.",
                textAlign: TextAlign.center,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Feature column builder
  Widget _featureColumn({
    required String title,
    required Color color,
    required List<String> features,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(title, fontSize: 18, fontWeight: FontWeight.bold, color: color),
        const SizedBox(height: 12),
        ...features.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: AppText(f, color: color.withValues(alpha: 0.8)),
          ),
        ),
      ],
    );
  }

  // ✅ Subscription card
  Widget _subscriptionCard(
    BuildContext context, {
    required String title,
    required String price,
    required String subtitle,
    required String description,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary),
      ),
      child: Column(
        children: [
          AppText(
            title,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          const SizedBox(height: 12),
          AppText(
            price,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          AppText(subtitle, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          AppText(
            description,
            fontSize: 13,
            textAlign: TextAlign.center,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {},
            child: AppText(
              "Subscribe",
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Toggle button
  Widget _toggleButton(String text, bool active, ColorScheme colorScheme) {
    return InkWell(
      onTap: () {
        setState(() {
          isMonthly = text == "Monthly";
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AppText(
          text,
          color: active ? colorScheme.onPrimary : colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
