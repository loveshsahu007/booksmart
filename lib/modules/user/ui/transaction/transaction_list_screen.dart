import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/user/ui/bulk_review/bulk_review_screen.dart';
import 'package:booksmart/modules/user/ui/transaction/add_transaction_manual.dart';
import 'package:booksmart/widgets/date_range_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:get/get.dart';
import '../../../../widgets/custom_drop_down.dart';
import '../../../../widgets/custom_dialog.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  String selectedType = "All";
  String selectedSort = "Date";
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;

  // Filter dropdown keys
  final categoryDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final typeDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final bankDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final statusDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final amountRangeDropdownKey = GlobalKey<DropdownSearchState<String>>();

  final List<Map<String, dynamic>> allTransactions = [
    {
      "title": "Uber Ride",
      "date": "27 Feb 2025",
      "amount": -49.00,
      "category": "Transportation",
      "type": "Personal",
      "deductible": false,
      "bank": "Chase",
      "status": "Completed",
    },
    {
      "title": "Office Rent",
      "date": "26 Feb 2025",
      "amount": -100.00,
      "category": "Operational Costs",
      "type": "Business",
      "deductible": true,
      "bank": "Bank of America",
      "status": "Completed",
    },
    {
      "title": "Freelance Payment",
      "date": "28 Feb 2025",
      "amount": 500.00,
      "category": "Income",
      "type": "Business",
      "deductible": false,
      "bank": "PayPal",
      "status": "Pending",
    },
    {
      "title": "Starbucks Coffee",
      "date": "25 Feb 2025",
      "amount": -12.50,
      "category": "Food & Drink",
      "type": "Personal",
      "deductible": false,
      "bank": "Wells Fargo",
      "status": "Completed",
    },
    {
      "title": "Software Subscription",
      "date": "24 Feb 2025",
      "amount": -29.99,
      "category": "Software",
      "type": "Business",
      "deductible": true,
      "bank": "Chase",
      "status": "Completed",
    },
  ];

  List<Map<String, dynamic>> get filteredTransactions {
    List<Map<String, dynamic>> filtered = List.from(allTransactions);

    // Search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (t) =>
                t["title"].toLowerCase().contains(searchQuery.toLowerCase()) ||
                t["category"].toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                t["bank"].toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Category filter
    final selectedCategory = categoryDropdownKey.currentState?.getSelectedItem;
    if (selectedCategory != null && selectedCategory != "All") {
      filtered = filtered
          .where((t) => t["category"] == selectedCategory)
          .toList();
    }

    // Type filter
    final selectedType = typeDropdownKey.currentState?.getSelectedItem;
    if (selectedType != null && selectedType != "All") {
      filtered = filtered.where((t) => t["type"] == selectedType).toList();
    }

    // Bank filter
    final selectedBank = bankDropdownKey.currentState?.getSelectedItem;
    if (selectedBank != null && selectedBank != "All") {
      filtered = filtered.where((t) => t["bank"] == selectedBank).toList();
    }

    // Status filter
    final selectedStatus = statusDropdownKey.currentState?.getSelectedItem;
    if (selectedStatus != null && selectedStatus != "All") {
      filtered = filtered.where((t) => t["status"] == selectedStatus).toList();
    }

    // Amount range filter
    final selectedAmountRange =
        amountRangeDropdownKey.currentState?.getSelectedItem;
    if (selectedAmountRange != null && selectedAmountRange != "All") {
      switch (selectedAmountRange) {
        case "Under \$50":
          filtered = filtered.where((t) => t["amount"].abs() < 50).toList();
          break;
        case "\$50 - \$200":
          filtered = filtered
              .where((t) => t["amount"].abs() >= 50 && t["amount"].abs() <= 200)
              .toList();
          break;
        case "\$200 - \$500":
          filtered = filtered
              .where((t) => t["amount"].abs() > 200 && t["amount"].abs() <= 500)
              .toList();
          break;
        case "Over \$500":
          filtered = filtered.where((t) => t["amount"].abs() > 500).toList();
          break;
      }
    }

    // Date range filter
    if (startDate != null && endDate != null) {
      filtered = filtered.where((t) {
        final date = DateTime.parse(_formatDate(t["date"]));
        return date.isAfter(startDate!.subtract(const Duration(days: 1))) &&
            date.isBefore(endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort
    if (selectedSort == "Date") {
      filtered.sort(
        (a, b) => DateTime.parse(
          _formatDate(b["date"]),
        ).compareTo(DateTime.parse(_formatDate(a["date"]))),
      );
    } else if (selectedSort == "Amount") {
      filtered.sort((a, b) => b["amount"].compareTo(a["amount"]));
    } else if (selectedSort == "Category") {
      filtered.sort(
        (a, b) => a["category"].toString().compareTo(b["category"].toString()),
      );
    }

    return filtered;
  }

  String _formatDate(String date) {
    final parts = date.split(" ");
    final day = parts[0].padLeft(2, '0');
    final month = {
      "Jan": "01",
      "Feb": "02",
      "Mar": "03",
      "Apr": "04",
      "May": "05",
      "Jun": "06",
      "Jul": "07",
      "Aug": "08",
      "Sep": "09",
      "Oct": "10",
      "Nov": "11",
      "Dec": "12",
    }[parts[1]]!;
    final year = parts[2];
    return "$year-$month-$day";
  }

  Future<void> _showFilterDialog() async {
    await customDialog(
      title: "Filter Transactions",
      child: ListView(
        padding: const EdgeInsets.all(15),
        shrinkWrap: true,
        children: [
          // Category Filter
          _buildFilterDropdown(
            label: "Category",
            items: [
              'All',
              'Transportation',
              'Operational Costs',
              'Income',
              'Food & Drink',
              'Software',
              'Utilities',
              'Entertainment',
              'Travel',
            ],
            dropDownKey: categoryDropdownKey,
          ),
          const SizedBox(height: 16),

          // Type Filter
          _buildFilterDropdown(
            label: "Type",
            items: ['All', 'Personal', 'Business', 'Income', 'Expenses'],
            dropDownKey: typeDropdownKey,
          ),
          const SizedBox(height: 16),

          // Bank Filter
          _buildFilterDropdown(
            label: "Bank",
            items: [
              'All',
              'Chase',
              'Bank of America',
              'Wells Fargo',
              'PayPal',
              'Venmo',
              'Cash App',
            ],
            dropDownKey: bankDropdownKey,
          ),
          const SizedBox(height: 16),

          // Status Filter
          _buildFilterDropdown(
            label: "Status",
            items: ['All', 'Completed', 'Pending', 'Failed', 'Processing'],
            dropDownKey: statusDropdownKey,
          ),
          const SizedBox(height: 16),

          // Amount Range Filter
          _buildFilterDropdown(
            label: "Amount Range",
            items: [
              'All',
              'Under \$50',
              '\$50 - \$200',
              '\$200 - \$500',
              'Over \$500',
            ],
            dropDownKey: amountRangeDropdownKey,
          ),
          const SizedBox(height: 16),

          // Date Range
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText("Date Range", fontWeight: FontWeight.w600, fontSize: 14),
              const SizedBox(height: 8),
              DateRangePickerWidget(
                onDateRangeSelected: (start, end) {
                  setState(() {
                    startDate = start;
                    endDate = end;
                  });
                },
                initialText: startDate == null
                    ? "Select Date Range"
                    : "Custom Range",
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  clearFilters();
                  Get.back();
                },
                child: AppText("Reset", color: Colors.red, fontSize: 14),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => Get.back(),
                child: AppText("Apply", fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    ).then((value) {
      setState(() {});
    });
  }

  Widget _buildFilterDropdown({
    required String label,
    required List<String> items,
    required GlobalKey<DropdownSearchState<String>> dropDownKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, fontWeight: FontWeight.w600, fontSize: 14),
        const SizedBox(height: 8),
        CustomDropDownWidget<String>(
          dropDownKey: dropDownKey,
          label: label,
          hint: "Select $label",
          items: items,
        ),
      ],
    );
  }

  void clearFilters() {
    categoryDropdownKey.currentState?.clear();
    typeDropdownKey.currentState?.clear();
    bankDropdownKey.currentState?.clear();
    statusDropdownKey.currentState?.clear();
    amountRangeDropdownKey.currentState?.clear();
    setState(() {
      startDate = null;
      endDate = null;
    });
  }

  bool get isAnyActiveFilter =>
      categoryDropdownKey.currentState?.getSelectedItem != null ||
      typeDropdownKey.currentState?.getSelectedItem != null ||
      bankDropdownKey.currentState?.getSelectedItem != null ||
      statusDropdownKey.currentState?.getSelectedItem != null ||
      amountRangeDropdownKey.currentState?.getSelectedItem != null ||
      startDate != null;

  Widget _buildActiveFilters() {
    final List<Widget> activeFilters = [];

    // Category filter
    if (categoryDropdownKey.currentState?.getSelectedItem != null) {
      activeFilters.add(
        _buildFilterChip(
          "Category: ${categoryDropdownKey.currentState!.getSelectedItem}",
          onRemove: () {
            setState(() {
              categoryDropdownKey.currentState?.clear();
            });
          },
        ),
      );
    }

    // Type filter
    if (typeDropdownKey.currentState?.getSelectedItem != null) {
      activeFilters.add(
        _buildFilterChip(
          "Type: ${typeDropdownKey.currentState!.getSelectedItem}",
          onRemove: () {
            setState(() {
              typeDropdownKey.currentState?.clear();
            });
          },
        ),
      );
    }

    // Bank filter
    if (bankDropdownKey.currentState?.getSelectedItem != null) {
      activeFilters.add(
        _buildFilterChip(
          "Bank: ${bankDropdownKey.currentState!.getSelectedItem}",
          onRemove: () {
            setState(() {
              bankDropdownKey.currentState?.clear();
            });
          },
        ),
      );
    }

    // Status filter
    if (statusDropdownKey.currentState?.getSelectedItem != null) {
      activeFilters.add(
        _buildFilterChip(
          "Status: ${statusDropdownKey.currentState!.getSelectedItem}",
          onRemove: () {
            setState(() {
              statusDropdownKey.currentState?.clear();
            });
          },
        ),
      );
    }

    // Amount range filter
    if (amountRangeDropdownKey.currentState?.getSelectedItem != null) {
      activeFilters.add(
        _buildFilterChip(
          "Amount: ${amountRangeDropdownKey.currentState!.getSelectedItem}",
          onRemove: () {
            setState(() {
              amountRangeDropdownKey.currentState?.clear();
            });
          },
        ),
      );
    }

    // Date range filter
    if (startDate != null && endDate != null) {
      activeFilters.add(
        _buildFilterChip(
          "Date: ${_formatDisplayDate(startDate!)} - ${_formatDisplayDate(endDate!)}",
          onRemove: () {
            setState(() {
              startDate = null;
              endDate = null;
            });
          },
        ),
      );
    }

    if (activeFilters.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      child: Wrap(spacing: 8, runSpacing: 8, children: activeFilters),
    );
  }

  Widget _buildFilterChip(String label, {required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Get.theme.colorScheme.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(label, fontSize: 12),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: Get.theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDisplayDate(DateTime date) {
    return "${date.day} ${_getMonthAbbreviation(date.month)} ${date.year}";
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with filter icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    "Transaction History",
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    isAnyActiveFilter
                        ? "Showing ${filteredTransactions.length} of ${allTransactions.length} transactions"
                        : "Total ${allTransactions.length} transactions",
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              IconButton(
                icon: Badge(
                  isLabelVisible: isAnyActiveFilter,
                  child: const Icon(Icons.filter_list),
                ),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🔍 Search
          AppTextField(
            hintText: "Search transactions",
            prefixWidget: const Icon(Icons.search),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
          const SizedBox(height: 12),

          // Active Filters
          _buildActiveFilters(),

          // 🔹 Transaction List
          Expanded(
            child: ListView.separated(
              itemCount: filteredTransactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final t = filteredTransactions[index];
                final amountColor = t["amount"] < 0 ? Colors.red : Colors.green;

                return InkWell(
                  onTap: () {
                    goToAddTransactionScreen();
                  },
                  child: Card(
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: AppText(
                        t["title"],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            "${t["date"]} • ${t["category"]}",
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 2),
                          AppText(
                            "${t["bank"]} • ${t["status"]}",
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      trailing: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AppText(
                              "${t["amount"] < 0 ? '-' : '+'}\$${t["amount"].abs().toStringAsFixed(2)}",
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: amountColor,
                            ),
                            if (t["deductible"])
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade300,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const AppText(
                                  "Deductible",
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ➕ Bottom Buttons
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        goToBulkReviewScreen(shouldCloseBefore: false),
                    icon: const Icon(
                      Icons.category_outlined,
                      color: Colors.black,
                    ),
                    label: const AppText(
                      "AI Categorization",
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      goToAddTransactionScreen();
                    },
                    icon: const Icon(Icons.add, color: Colors.black),
                    label: const AppText(
                      "Add Transaction",
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
