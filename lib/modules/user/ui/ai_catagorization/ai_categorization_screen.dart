import 'package:booksmart/constant/app_colors.dart';
import 'package:booksmart/widgets/app_text.dart';
import 'package:flutter/material.dart';

class AICategorizationScreen extends StatelessWidget {
  const AICategorizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {"name": "Amazon", "date": "Apr 21, 2024", "tag": "Internet Expenses"},
      {
        "name": "Uber Eats",
        "date": "Apr 19, 2024",
        "tag": "Meals & Entertainment",
      },
      {
        "name": "Hydro Pub",
        "date": "Apr 19, 2024",
        "tag": "Meals & Entertainment",
      },
      {"name": "Best Buy", "date": "Apr 17, 2024", "tag": "Office Supplies"},
      {"name": "Delta", "date": "Apr 15, 2024", "tag": "Travel"},
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                "AI Categorization",
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              SizedBox(height: 20),

              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  items[index]["name"]!,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: greenColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: AppText(
                                    items[index]["tag"]!,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppText(
                            items[index]["date"]!,
                            fontSize: 15,
                            color: Colors.grey.shade300,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Approve All button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {},
                  child: AppText(
                    "Approve All",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
