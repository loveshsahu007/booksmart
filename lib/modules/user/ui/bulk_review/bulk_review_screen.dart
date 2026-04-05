import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:booksmart/widgets/date_range_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';


import '../../../../widgets/custom_drop_down.dart';
import 'package:booksmart/helpers/date_formatter.dart';

void goToBulkReviewScreen({bool shouldCloseBefore = false}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back(); // close previous dialog
    }
    customDialog(
      child: const BulkReviewScreen(),
      title: 'Bulk Review',
      barrierDismissible: true,
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => const BulkReviewScreen());
    } else {
      Get.to(() => const BulkReviewScreen());
    }
  }
}

class BulkReviewScreen extends StatefulWidget {
  const BulkReviewScreen({super.key});

  @override
  State<BulkReviewScreen> createState() => _BulkReviewScreenState();
}

class _BulkReviewScreenState extends State<BulkReviewScreen> {
  bool selectAll = false;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];

  final TextEditingController searchController = TextEditingController();
  String selectedSort = "Newest";
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();

    // Dummy data
    transactions = [
      {
        "merchant": "Amazon",
        "category": "Internet Expenses",
        "date": DateTime(2024, 4, 19),
        "selected": true,
      },
      {
        "merchant": "Hydro Pub",
        "category": "Meals & Entertainment",
        "date": DateTime(2024, 4, 19),
        "selected": true,
      },
      {
        "merchant": "Taxi",
        "category": "Travel",
        "date": DateTime(2024, 4, 17),
        "selected": false,
      },
      {
        "merchant": "Netflix",
        "category": "Subscriptions",
        "date": DateTime(2024, 4, 15),
        "selected": false,
      },
    ];

    filteredTransactions = List.from(transactions);
  }

  // 🔍 Search filter
  void _filterTransactions() {
    final query = searchController.text.toLowerCase();

    List<Map<String, dynamic>> filtered = transactions.where((t) {
      final name = t['merchant'].toString().toLowerCase();
      final category = t['category'].toString().toLowerCase();

      final matchesQuery =
          query.isEmpty || name.contains(query) || category.contains(query);

      final withinDateRange =
          selectedDateRange == null ||
          (t['date'].isAfter(selectedDateRange!.start) &&
              t['date'].isBefore(selectedDateRange!.end));

      return matchesQuery && withinDateRange;
    }).toList();

    _sortTransactions(filtered);
  }

  // 🧭 Sort logic
  void _sortTransactions(List<Map<String, dynamic>> list) {
    switch (selectedSort) {
      case "Oldest":
        list.sort((a, b) => a['date'].compareTo(b['date']));
        break;
      case "A–Z":
        list.sort(
          (a, b) =>
              a['merchant'].toString().compareTo(b['merchant'].toString()),
        );
        break;
      case "Z–A":
        list.sort(
          (a, b) =>
              b['merchant'].toString().compareTo(a['merchant'].toString()),
        );
        break;
      case "Highest Amount":
      case "Lowest Amount":
        // Placeholder for amount sorting if added later
        break;
      case "Newest":
      default:
        list.sort((a, b) => b['date'].compareTo(a['date']));
    }

    setState(() => filteredTransactions = list);
  }

  void toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      for (var t in filteredTransactions) {
        t['selected'] = selectAll;
      }
    });
  }

  final _sortDropDownKey = GlobalKey<DropdownSearchState<String>>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text("Bulk Review")),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔍 Search Bar
                  AppTextField(
                    hintText: "Search transactions",
                    controller: searchController,
                  ),
                  // TextField(
                  //   controller: searchController,
                  //   onChanged: (_) => _filterTransactions(),
                  //   decoration: InputDecoration(
                  //     hintText: "Search transactions",
                  //     prefixIcon: const Icon(Icons.search, color: orangeColor),
                  //     filled: true,
                  //     fillColor: isDark
                  //         ? colorScheme.surface
                  //         : Colors.grey.shade100,
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(10),
                  //       borderSide: BorderSide(
                  //         color: colorScheme.secondary,
                  //         width: 1,
                  //       ),
                  //     ),
                  //     hintStyle: TextStyle(
                  //       color: colorScheme.onSurface.withValues(alpha: 0.6),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 16),

                  // 🧭 Filters Row
                  Row(
                    children: [
                      // Sort Filter
                      Expanded(
                        child: CustomDropDownWidget<String>(
                          dropDownKey: _sortDropDownKey,
                          selectedItem: selectedSort,
                          label: "Sort",
                          items: const [
                            "Newest",
                            "Oldest",
                            "A - Z",
                            "Z - A",
                            "Highest Amount",
                            "Lowest Amount",
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Date Filter
                      DateRangePickerWidget(
                        onDateRangeSelected: (start, end) {
                          selectedDateRange = DateTimeRange(
                            start: start,
                            end: end,
                          );
                          _filterTransactions();
                        },
                        initialText: "",
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ✅ Select All
                  InkWell(
                    onTap: toggleSelectAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.secondary),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: selectAll,
                            onChanged: (val) => toggleSelectAll(),
                            activeColor: colorScheme.secondary,
                            checkColor: Colors.white,
                          ),
                          AppText(
                            "Select All",
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ Transaction List
                  Expanded(
                    child: filteredTransactions.isEmpty
                        ? Center(
                            child: AppText(
                              "No transactions found for selected filters.",

                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 14,
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final t = filteredTransactions[index];
                              final formattedDate = formatDate(t['date']);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.secondary,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: t['selected'],
                                      onChanged: (val) {
                                        setState(() {
                                          t['selected'] = val!;
                                        });
                                      },
                                      activeColor: colorScheme.secondary,
                                      checkColor: Colors.white,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AppText(
                                            t['merchant'],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: greenColor,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: AppText(
                                              t['category'],
                                              fontSize: 12,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AppText(
                                      formattedDate,
                                      fontSize: 14,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // ✅ Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {},
                          child: const AppText(
                            "Approve",
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {},
                          child: const AppText(
                            "Reclassify",
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
