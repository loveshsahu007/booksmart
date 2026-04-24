import 'package:flutter/material.dart';

const Map<String, String> _kpiTooltipCopyByTitle = {
  'Gross Profit':
      'What you keep after paying to deliver your product or service.\n'
          'Goal: Higher is better.\n'
          'Watch out: Low or negative means you are not covering your core costs.',
  'Margins':
      'How much you keep from every \$1 you make.\n'
          'Good: 20%+\n'
          'Strong: 40%+\n'
          'Watch out: Below 10% means most of your money is being spent.',
  '% Margin':
      'How much you keep from every \$1 you make.\n'
          'Good: 20%+\n'
          'Strong: 40%+\n'
          'Watch out: Below 10% means most of your money is being spent.',
  'Current Ratio':
      'Can you pay your bills soon with what you have right now?\n'
          'Good: 1.5 to 3\n'
          'Watch out: Below 1 means you may not cover short term bills.',
  'Debt / Equity Ratio':
      'How much you owe vs what you own.\n'
          'Good: Below 1\n'
          'Strong: Below 0.5\n'
          'Watch out: Above 2 means heavy reliance on debt.',
  'Return on Equity':
      'How well your money is turning into profit.\n'
          'Good: 10%+\n'
          'Strong: 20%+\n'
          'Watch out: Low or negative means your money is not working well.',
  'Return on Equity (ROE)':
      'How well your money is turning into profit.\n'
          'Good: 10%+\n'
          'Strong: 20%+\n'
          'Watch out: Low or negative means your money is not working well.',
  'Total Assets':
      'Everything your business owns that has value.\n'
          'Goal: Growing over time.\n'
          'Watch out: Flat or shrinking may signal slow growth.',
  'Money In':
      'All the cash coming into your business.\n'
          'Goal: Consistently increasing.\n'
          'Watch out: Drops can signal revenue issues.',
  'Money Out':
      'All the cash leaving your business.\n'
          'Goal: Controlled and aligned with growth.\n'
          'Watch out: Growing faster than Money In reduces profit.',
};

String? kpiTooltipTextForTitle(String title) => _kpiTooltipCopyByTitle[title];

class KpiInfoTooltipIcon extends StatefulWidget {
  const KpiInfoTooltipIcon({
    required this.message,
    required this.semanticLabel,
    super.key,
  });

  final String message;
  final String semanticLabel;

  @override
  State<KpiInfoTooltipIcon> createState() => _KpiInfoTooltipIconState();
}

class _KpiInfoTooltipIconState extends State<KpiInfoTooltipIcon> {
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();

  void _showTooltip() {
    _tooltipKey.currentState?.ensureTooltipVisible();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: Tooltip(
        key: _tooltipKey,
        message: widget.message,
        waitDuration: const Duration(milliseconds: 220),
        showDuration: const Duration(seconds: 5),
        preferBelow: false,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          height: 1.25,
        ),
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowFocusHighlight: (isFocused) {
            if (isFocused) {
              _showTooltip();
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showTooltip,
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}
