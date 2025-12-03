import 'package:booksmart/constant/exports.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BillingScreenCPA extends StatefulWidget {
  const BillingScreenCPA({super.key});

  @override
  State<BillingScreenCPA> createState() => _BillingScreenCPAState();
}

class _BillingScreenCPAState extends State<BillingScreenCPA> {
  final List<Map<String, dynamic>> transactions = [
    {
      "date": "04/21",
      "title": "Lead purchase",
      "amount": "\$50",
      "status": true,
    },
    {"date": "04/17", "title": "Payout", "amount": "-\$175", "status": false},
    {
      "date": "04/10",
      "title": "Lead purchase",
      "amount": "\$75",
      "status": true,
    },
    {
      "date": "04/03",
      "title": "Lead purchase",
      "amount": "\$25",
      "status": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final isDesktop = width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const AppText('Billing & Payouts'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Earnings Overview Cards
            const AppText(
              'Earnings Overview',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 16),

            // Responsive grid for earnings cards
            isDesktop
                ? _buildDesktopEarningsGrid(scheme)
                : isTablet
                ? _buildTabletEarningsGrid(scheme)
                : _buildMobileEarningsGrid(scheme),

            SizedBox(height: 24),

            // 🔹 Stats Card
            _buildClickableCard(
              onTap: () => _navigateToLeadAnalytics(),
              child: Container(
                padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 18 : 16)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amberAccent, Colors.orangeAccent],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.barChart3,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          AppText(
                            'Leads Purchased',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          AppText(
                            'Accepted',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        AppText('8', fontSize: 16, fontWeight: FontWeight.bold),
                        AppText('5', fontSize: 16, fontWeight: FontWeight.bold),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // 🧾 Transaction History
            const AppText(
              'Transaction History',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 12),

            _buildClickableCard(
              onTap: () => _navigateToTransactionDetails(),
              child: Container(
                padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 18 : 16)),
                child: Column(
                  children: transactions.map((tx) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 8 : 4,
                        vertical: isDesktop ? 12 : 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: AppText(
                              tx["date"],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: AppText(tx["title"], fontSize: 14),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: AppText(
                                tx["amount"],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            tx["status"]
                                ? Icons.check_circle_outline
                                : Icons.remove_circle_outline,
                            color: tx["status"]
                                ? Colors.green
                                : Colors.redAccent,
                            size: 18,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            SizedBox(height: 28),

            // ➕ Add Funds button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                buttonText: "Add Funds",
                onTapFunction: () => _navigateToAddFunds(),
              ),
            ),

            SizedBox(height: 12),
            const Center(
              child: AppText(
                'Auto-refill lead credits',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📱 Mobile Earnings Grid
  Widget _buildMobileEarningsGrid(ColorScheme scheme) {
    return Column(
      children: [
        _buildEarningsCard(
          title: "Total Earnings",
          amount: "\$2,450",
          subtitle: "Last 30 days",
          icon: LucideIcons.dollarSign,
          gradient: [Colors.greenAccent, Colors.green],
          onTap: () => _navigateToProfitLoss(),
        ),
        SizedBox(height: 12),
        _buildEarningsCard(
          title: "Pending Payouts",
          amount: "\$850",
          subtitle: "Available balance",
          icon: LucideIcons.clock,
          gradient: [Colors.orangeAccent, Colors.orange],
          onTap: () => _navigateToPendingPayouts(),
        ),
        SizedBox(height: 12),
        _buildEarningsCard(
          title: "Lead Expenses",
          amount: "\$325",
          subtitle: "This month",
          icon: LucideIcons.trendingDown,
          gradient: [Colors.redAccent, Colors.red],
          onTap: () => _navigateToExpenses(),
        ),
      ],
    );
  }

  // 📟 Tablet Earnings Grid
  Widget _buildTabletEarningsGrid(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: _buildEarningsCard(
            title: "Total Earnings",
            amount: "\$2,450",
            subtitle: "Last 30 days",
            icon: LucideIcons.dollarSign,
            gradient: [Colors.greenAccent, Colors.green],
            onTap: () => _navigateToProfitLoss(),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildEarningsCard(
            title: "Pending Payouts",
            amount: "\$850",
            subtitle: "Available balance",
            icon: LucideIcons.clock,
            gradient: [Colors.orangeAccent, Colors.orange],
            onTap: () => _navigateToPendingPayouts(),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildEarningsCard(
            title: "Lead Expenses",
            amount: "\$325",
            subtitle: "This month",
            icon: LucideIcons.trendingDown,
            gradient: [Colors.redAccent, Colors.red],
            onTap: () => _navigateToExpenses(),
          ),
        ),
      ],
    );
  }

  // 🖥️ Desktop Earnings Grid
  Widget _buildDesktopEarningsGrid(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: _buildEarningsCard(
            title: "Total Earnings",
            amount: "\$2,450",
            subtitle: "Last 30 days",
            icon: LucideIcons.dollarSign,
            gradient: [Colors.greenAccent, Colors.green],
            onTap: () => _navigateToProfitLoss(),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildEarningsCard(
            title: "Pending Payouts",
            amount: "\$850",
            subtitle: "Available balance",
            icon: LucideIcons.clock,
            gradient: [Colors.orangeAccent, Colors.orange],
            onTap: () => _navigateToPendingPayouts(),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildEarningsCard(
            title: "Lead Expenses",
            amount: "\$325",
            subtitle: "This month",
            icon: LucideIcons.trendingDown,
            gradient: [Colors.redAccent, Colors.red],
            onTap: () => _navigateToExpenses(),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildEarningsCard(
            title: "Net Profit",
            amount: "\$1,275",
            subtitle: "After expenses",
            icon: LucideIcons.trendingUp,
            gradient: [Colors.blueAccent, Colors.blue],
            onTap: () => _navigateToNetProfit(),
          ),
        ),
      ],
    );
  }

  // 💰 Earnings Card Widget
  Widget _buildEarningsCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return _buildClickableCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            SizedBox(height: 12),
            AppText(amount, fontSize: 20, fontWeight: FontWeight.bold),
            SizedBox(height: 4),
            AppText(title, fontSize: 14, fontWeight: FontWeight.w600),
            SizedBox(height: 4),
            AppText(subtitle, fontSize: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // 🎯 Clickable Card Wrapper
  Widget _buildClickableCard({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: child,
          ),
        ),
      ),
    );
  }

  // 🧭 Navigation Methods
  void _navigateToProfitLoss() {
    // Navigate to Profit & Loss screen
    //  Get.to(() => const ProfitLossScreen());
  }

  void _navigateToPendingPayouts() {
    // Navigate to Pending Payouts screen
    // Get.to(() => const PendingPayoutsScreen());
  }

  void _navigateToExpenses() {
    // Navigate to Expenses screen
    //  Get.to(() => const ExpensesScreen());
  }

  void _navigateToNetProfit() {
    // Navigate to Net Profit breakdown
    // Get.to(() => const NetProfitScreen());
  }

  void _navigateToLeadAnalytics() {
    // Navigate to Lead Analytics
    // Get.to(() => const LeadAnalyticsScreen());
  }

  void _navigateToTransactionDetails() {
    // Navigate to Transaction Details
    // Get.to(() => const TransactionDetailsScreen());
  }

  void _navigateToAddFunds() {
    // Navigate to Add Funds screen
    // Get.to(() => const AddFundsScreen());
  }
}
