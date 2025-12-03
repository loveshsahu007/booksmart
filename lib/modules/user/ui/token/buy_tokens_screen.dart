import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

void goToBuyTokensScreen({bool shouldCloseBefore = false}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back(); // close previous dialog
    }
    customDialog(
      child: const BuyTokensScreen(),
      title: 'Buy Tokens',
      barrierDismissible: true,
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => const BuyTokensScreen());
    } else {
      Get.to(() => const BuyTokensScreen());
    }
  }
}

class BuyTokensScreen extends StatelessWidget {
  const BuyTokensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("Buy Tokens")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _tokenCard(context, "100", "\$1.99", "assets/icons/coin.png"),
              _tokenCard(context, "500", "\$4.99", "assets/icons/coin.png"),
              _tokenCard(context, "1,000", "\$9.99", "assets/icons/coin.png"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tokenCard(
    BuildContext context,
    String amount,
    String price,
    String iconPath,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBackground = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerLowest;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Icon + Token Amount
          Row(
            children: [
              Image.asset(iconPath, width: 40, height: 40),
              const SizedBox(width: 16),
              AppText(
                amount,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ],
          ),

          // Right: Price
          AppText(
            price,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}
