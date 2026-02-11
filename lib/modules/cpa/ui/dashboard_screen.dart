import 'package:booksmart/constant/exports.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreenCPA extends StatefulWidget {
  const DashboardScreenCPA({super.key});

  @override
  State<DashboardScreenCPA> createState() => _DashboardScreenCPAState();
}

class _DashboardScreenCPAState extends State<DashboardScreenCPA> {
  final List<Map<String, dynamic>> leads = [
    {
      'name': 'Sarah Johnson',
      'job': 'Self-Employed (Rideshare)',
      'details': 'Individual + Business Filing',
      'image': '',
      'action': 'Accept Intro',
    },
    {
      'name': 'Mark Smith',
      'job': 'Real Estate Investor',
      'details': 'Individual + Business Filing',
      'image': '',
      'action': 'View Profile',
    },
    {
      'name': 'Lisa Miller',
      'job': 'E-Commerce',
      'details': 'Individual + Business Filing',
      'image': '',
      'action': 'Chat',
    },
  ];

  final List<Map<String, dynamic>> chartData = [
    {'month': 'Apr', 'leads': 10.0, 'orders': 6.0},
    {'month': 'May', 'leads': 14.0, 'orders': 8.0},
    {'month': 'Jun', 'leads': 12.0, 'orders': 10.0},
    {'month': 'Jul', 'leads': 15.0, 'orders': 12.0},
    {'month': 'Aug', 'leads': 13.0, 'orders': 9.0},
    {'month': 'Sep', 'leads': 16.0, 'orders': 13.0},
    {'month': 'Oct', 'leads': 18.0, 'orders': 15.0},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==== STATS GRID ====
            LayoutBuilder(
              builder: (context, constraints) {
                int crossCount = width > 1000
                    ? 4
                    : width > 700
                    ? 2
                    : 2;
                return GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: crossCount,
                  childAspectRatio: width > 1000
                      ? 2
                      : width > 700
                      ? 3
                      : 1.5,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      'Total Leads',
                      '15',
                      Colors.amber,
                      Icons.leaderboard,
                    ),
                    _buildStatCard(
                      'Pending Intros',
                      '5',
                      Colors.orangeAccent,
                      Icons.pending_actions,
                    ),
                    _buildStatCard(
                      'Accepted Clients',
                      '8',
                      Colors.green,
                      Icons.verified_user,
                    ),
                    _buildStatCard(
                      'Conversion Rate',
                      '53%',
                      Colors.blue,
                      Icons.percent,
                    ),
                  ],
                );
              },
            ),

            // const SizedBox(height: 24),

            // Wrap(
            //   spacing: 10,
            //   children: [
            //     ElevatedButton(
            //       onPressed: () {
            //         goToOrderDetailScreenCPA();
            //       },
            //       child: const AppText(
            //         "Order Detail Screen (Temp)",
            //         fontSize: 14,
            //         color: Colors.black,
            //       ),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 24),

            // ==== LEADS MANAGEMENT CHART ====
            Container(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Leads vs Orders (Monthly)',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        backgroundColor: Colors.transparent,
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index < 0 || index >= chartData.length) {
                                  return const SizedBox();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: AppText(
                                    chartData[index]['month'],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                              reservedSize: 28,
                            ),
                          ),
                        ),
                        barGroups: chartData.asMap().entries.map((entry) {
                          int index = entry.key;
                          double leads = entry.value['leads'];
                          double orders = entry.value['orders'];

                          return BarChartGroupData(
                            x: index,
                            barsSpace: 6,
                            barRods: [
                              BarChartRodData(
                                toY: leads,
                                gradient: const LinearGradient(
                                  colors: [Colors.amberAccent, Colors.amber],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                width: 12,
                              ),
                              BarChartRodData(
                                toY: orders,
                                gradient: const LinearGradient(
                                  colors: [Colors.blueAccent, Colors.blue],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                width: 12,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(Colors.amber, 'Leads'),
                      const SizedBox(width: 20),
                      _buildLegend(Colors.blueAccent, 'Orders'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==== LEADS MANAGEMENT LIST ====
            const AppText(
              'Recent Leads',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lead = leads[index];
                return _buildLeadTile(context, lead, scheme);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==== STAT CARD ====
  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedText(
                    title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  AppText(
                    value,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==== LEGEND ====
  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        AppText(label, fontSize: 12, fontWeight: FontWeight.w500),
      ],
    );
  }

  // ==== LEAD CARD ====
  Widget _buildLeadTile(
    BuildContext context,
    Map<String, dynamic> lead,
    ColorScheme scheme,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(radius: 26, backgroundColor: Colors.grey.shade300),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    lead['name'],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  AppText(lead['job'], fontSize: 12),
                  AppText(lead['details'], fontSize: 12, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: AppText(
                lead['action'],
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
