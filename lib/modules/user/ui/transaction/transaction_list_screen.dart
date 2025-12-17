import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/controllers/transaction_controller.dart';
import 'package:booksmart/models/transaction_model.dart';
import 'package:booksmart/modules/user/ui/bulk_review/bulk_review_screen.dart';
import 'package:booksmart/modules/user/ui/transaction/add_transaction_manual.dart';
import 'package:booksmart/widgets/date_range_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:get/get.dart';
import '../../../../controllers/organization_controller.dart';
import '../../../../widgets/custom_drop_down.dart';
import '../../../../widgets/custom_dialog.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;

  // Filter dropdown keys
  final categoryDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final typeDropdownKey = GlobalKey<DropdownSearchState<String>>();
  final amountRangeDropdownKey = GlobalKey<DropdownSearchState<String>>();

  /// Filtered transactions based on model
  List<TransactionModel> get filteredTransactions {
    List<TransactionModel> filtered = transactionC.transactions.toList();

    // Search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (t) =>
                t.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                t.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
                t.subcategory.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Category filter
    final selectedCategory = categoryDropdownKey.currentState?.getSelectedItem;
    if (selectedCategory != null && selectedCategory != "All") {
      filtered = filtered.where((t) => t.category == selectedCategory).toList();
    }

    // Type filter
    final selectedType = typeDropdownKey.currentState?.getSelectedItem;
    if (selectedType != null && selectedType != "All") {
      filtered = filtered.where((t) => t.type == selectedType).toList();
    }

    // Amount range filter
    final selectedAmountRange =
        amountRangeDropdownKey.currentState?.getSelectedItem;
    if (selectedAmountRange != null && selectedAmountRange != "All") {
      switch (selectedAmountRange) {
        case "Under \$50":
          filtered = filtered.where((t) => t.amount.abs() < 50).toList();
          break;
        case "\$50 - \$200":
          filtered = filtered
              .where((t) => t.amount.abs() >= 50 && t.amount.abs() <= 200)
              .toList();
          break;
        case "\$200 - \$500":
          filtered = filtered
              .where((t) => t.amount.abs() > 200 && t.amount.abs() <= 500)
              .toList();
          break;
        case "Over \$500":
          filtered = filtered.where((t) => t.amount.abs() > 500).toList();
          break;
      }
    }

    // Date range filter
    if (startDate != null && endDate != null) {
      filtered = filtered.where((t) {
        final date = DateTime.parse(t.date); // yyyy-MM-dd in model
        return date.isAfter(startDate!.subtract(const Duration(days: 1))) &&
            date.isBefore(endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort by date descending
    filtered.sort(
      (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
    ); // latest first

    return filtered;
  }

  Future<void> _showFilterDialog() async {
    await customDialog(
      title: "Filter Transactions",
      child: ListView(
        padding: const EdgeInsets.all(15),
        shrinkWrap: true,
        children: [
          // Category filter
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

          // Type filter
          _buildFilterDropdown(
            label: "Type",
            items: ['All', 'Personal', 'Business'],
            dropDownKey: typeDropdownKey,
          ),
          const SizedBox(height: 16),

          // Amount Range filter
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

          // Date range
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
    ).then((_) => setState(() {}));
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
    amountRangeDropdownKey.currentState?.clear();
    setState(() {
      startDate = null;
      endDate = null;
      searchQuery = "";
    });
  }

  bool get isAnyActiveFilter =>
      categoryDropdownKey.currentState?.getSelectedItem != null ||
      typeDropdownKey.currentState?.getSelectedItem != null ||
      amountRangeDropdownKey.currentState?.getSelectedItem != null ||
      startDate != null ||
      searchQuery.isNotEmpty;

  late TransactionController transactionC;

  @override
  void initState() {
    if (Get.isRegistered<TransactionController>()) {
      transactionC = Get.find<TransactionController>(
        tag: getCurrentOrganization!.id.toString(),
      );
    } else {
      transactionC = Get.put(
        TransactionController(),
        tag: getCurrentOrganization!.id.toString(),
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final transactions = filteredTransactions;

      return Scaffold(
        appBar: AppBar(title: const Text("Transaction History")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    isAnyActiveFilter
                        ? "Showing ${transactions.length} transactions"
                        : "Total ${transactionC.transactions.length} transactions",
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
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
              const SizedBox(height: 12),

              // Search
              AppTextField(
                hintText: "Search transactions",
                prefixWidget: const Icon(Icons.search),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GetBuilder<TransactionController>(
                  tag: getCurrentOrganization!.id.toString(),
                  builder: (controller) {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.transactions.isEmpty) {
                      return const Center(child: Text("No transactions found"));
                    }

                    final allTransactions = controller.transactions;

                    return ListView.separated(
                      itemCount: allTransactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final t = allTransactions[index];
                        final amountColor = t.amount < 0
                            ? Colors.red
                            : Colors.green;

                        return InkWell(
                          onTap: () => goToAddTransactionScreen(),
                          child: Card(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: AppText(
                                t.title,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    "${t.date} • ${t.category}",
                                    fontSize: 12,
                                  ),
                                  AppText(
                                    "${t.type} • ${t.deductible ? "Deductible" : ""}",
                                    fontSize: 11,
                                  ),
                                ],
                              ),
                              trailing: AppText(
                                "\$${t.amount.toStringAsFixed(2)}",
                                color: amountColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Bottom buttons
              const SizedBox(height: 16),
              Row(
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
                      onPressed: () => goToAddTransactionScreen(),
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
            ],
          ),
        ),
      );
    });
  }
}
