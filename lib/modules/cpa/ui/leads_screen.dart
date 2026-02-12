import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/cpa/ui/leads_detail_screen.dart';
import 'package:booksmart/modules/user/controllers/order_controller.dart';
import 'package:booksmart/modules/user/ui/cpa/components/cpa_order_card.dart';
import 'package:get/get.dart';

class LeadsScreenCPA extends StatefulWidget {
  const LeadsScreenCPA({super.key});

  @override
  State<LeadsScreenCPA> createState() => _LeadsScreenCPAState();
}

class _LeadsScreenCPAState extends State<LeadsScreenCPA>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> leads = [
    {
      'initials': 'RK',
      'name': 'Sarah Johnson',
      'role': 'Real Estate Agent',
      'location': 'California',
      'tag': 'CA',
      'priority': 'Normal',
      'description': 'Has receipts + prior return uploaded',
      'received': 'Just now',
    },
    {
      'initials': 'VC',
      'name': 'VC Consultant',
      'role': 'Consultant',
      'location': 'via LinkedIn',
      'tag': 'Medium',
      'priority': 'Medium',
      'description': 'Has receipts + prior return uploaded',
      'received': 'Just now',
    },
    {
      'initials': 'MB',
      'name': 'MB Pasty Chef',
      'role': 'Chef',
      'location': 'Massachusetts',
      'tag': 'High',
      'priority': 'High',
      'description': 'Prior return uploaded',
      'received': 'Just now',
    },
  ];

  final List<Map<String, dynamic>> acceptedLeads = [
    {
      'initials': 'RF',
      'name': 'Robert Fox',
      'email': 'robert.fox@example.com',
      'phone': '(123) 456-7890',
      'message':
          'Hello, I\'d like to connect and discuss how I can support your tax planning needs.',
    },
    {
      'initials': 'JW',
      'name': 'Jenny Wilson',
      'email': 'jenny.wilson@exammmle.com',
      'phone': '(555) 987-6543',
      'message':
          'I\'m looking forward to working together on your tax filings.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TabBar
          TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            labelPadding: const EdgeInsets.symmetric(horizontal: 5),
            indicatorColor: Get.theme.colorScheme.primary,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            tabs: const [
              Tab(text: 'Leads'), // users who contacted CPA
              // show order cards on both on-going and pendings screen
              // on clicking show order detail screen
              Tab(text: 'Orders'), // Orders
            ],
          ),
          const SizedBox(height: 20),

          // TabBar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildLeadsTab(), _buildOrderTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- LEADS TAB -----------------
  Widget _buildLeadsTab() {
    ColorScheme colorScheme = Get.theme.colorScheme;
    return ListView.separated(
      itemCount: leads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final lead = leads[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              goToLeadDetailScreen();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              child: Row(
                spacing: 10,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.9),
                    child: AppText(
                      lead['initials'],
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          lead['name'],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        Wrap(
                          children: [
                            AppText(lead['role'], fontSize: 12),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getTagColor(
                                  lead['priority'],
                                  colorScheme,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: AppText(
                                lead['tag'],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            AppText(lead['location'], fontSize: 12),
                          ],
                        ),
                        const SizedBox(height: 4),
                        AppText(lead['description'], fontSize: 12),
                        const SizedBox(height: 4),
                        AppText('Received: ${lead['received']}', fontSize: 12),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.chat_bubble_outline),
                    tooltip: 'Chat',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ----------------orders -----------------
  Widget _buildOrderTab() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: GetX<OrderController>(
        init: OrderController(),
        initState: (_) {
          Get.find<OrderController>().fetchActiveOrders();
        },
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.activeOrders.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text("No orders")),
            );
          }
          return Column(
            children: controller.activeOrders
                .map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: OrderCard(order: order),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Color _getTagColor(String priority, ColorScheme colorScheme) {
    switch (priority) {
      case 'High':
        return Colors.redAccent.withValues(alpha: 0.7);
      case 'Medium':
        return Colors.orangeAccent.withValues(alpha: 0.7);
      default:
        return colorScheme.primary.withValues(alpha: 0.7);
    }
  }
}
