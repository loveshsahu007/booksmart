import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/user/controllers/order_controller.dart';
import 'package:booksmart/modules/user/ui/cpa/components/cpa_order_card.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import '../../common/controllers/chat_controller.dart';
import '../controllers/leads_controller.dart';

class LeadsScreenCPA extends StatefulWidget {
  const LeadsScreenCPA({super.key});

  @override
  State<LeadsScreenCPA> createState() => _LeadsScreenCPAState();
}

class _LeadsScreenCPAState extends State<LeadsScreenCPA>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // final List<Map<String, dynamic>> leads = [
  //   {
  //     'initials': 'RK',
  //     'name': 'Sarah Johnson',
  //     'role': 'Real Estate Agent',
  //     'location': 'California',
  //     'tag': 'CA',
  //     'priority': 'Normal',
  //     'description': 'Has receipts + prior return uploaded',
  //     'received': 'Just now',
  //   },
  //   {
  //     'initials': 'VC',
  //     'name': 'VC Consultant',
  //     'role': 'Consultant',
  //     'location': 'via LinkedIn',
  //     'tag': 'Medium',
  //     'priority': 'Medium',
  //     'description': 'Has receipts + prior return uploaded',
  //     'received': 'Just now',
  //   },
  //   {
  //     'initials': 'MB',
  //     'name': 'MB Pasty Chef',
  //     'role': 'Chef',
  //     'location': 'Massachusetts',
  //     'tag': 'High',
  //     'priority': 'High',
  //     'description': 'Prior return uploaded',
  //     'received': 'Just now',
  //   },
  // ];

  // final List<Map<String, dynamic>> acceptedLeads = [
  //   {
  //     'initials': 'RF',
  //     'name': 'Robert Fox',
  //     'email': 'robert.fox@example.com',
  //     'phone': '(123) 456-7890',
  //     'message':
  //         'Hello, I\'d like to connect and discuss how I can support your tax planning needs.',
  //   },
  //   {
  //     'initials': 'JW',
  //     'name': 'Jenny Wilson',
  //     'email': 'jenny.wilson@exammmle.com',
  //     'phone': '(555) 987-6543',
  //     'message':
  //         'I\'m looking forward to working together on your tax filings.',
  //   },
  // ];

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
    return GetX<LeadsController>(
      init: LeadsController(),
      builder: (controller) {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.leads.isEmpty) {
          return const Center(child: AppText("No leads yet"));
        }

        return ListView.separated(
          itemCount: controller.leads.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final lead = controller.leads[index];
            final user = lead.userWrapper;
            final initials = user != null
                ? "${user['first_name']?[0] ?? ''}${user['last_name']?[0] ?? ''}"
                      .toUpperCase()
                : "?";
            final name = user != null
                ? "${user['first_name']} ${user['last_name']}"
                : "Unknown User";

            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  // Navigate to lead details, passing lead model if needed
                  // goToLeadDetailScreen();
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: 0.9,
                        ),
                        child: AppText(
                          initials,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              name,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            AppText(
                              'Received: ${Jiffy.parseFromDateTime(lead.createdAt.toLocal()).fromNow()}',
                              fontSize: 12,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Start chat with user
                          // We need ChatController
                          Get.find<ChatController>().loadChat(lead.userId);
                          // Then navigate... skipping for now as `goToChatScreen` is not imported or requires context/setup
                        },
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
}
