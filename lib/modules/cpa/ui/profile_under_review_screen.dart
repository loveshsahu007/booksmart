import 'package:booksmart/constant/exports.dart';
import 'package:get/get.dart';

class ProfileUnderReviewScreenCPA extends StatelessWidget {
  const ProfileUnderReviewScreenCPA({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWeb = width > 900;
    final isTablet = width > 600 && width <= 900;

    return Scaffold(
      appBar: AppBar(title: const Text("Registration Submitted!")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.amber,
              size: isWeb ? 80 : (isTablet ? 70 : 60),
            ),

            SizedBox(height: 20),

            const AppText(
              "Thank you for joining the BookSmart CPA Network. Your information is under review.",
              textAlign: TextAlign.center,
              fontSize: 14,
            ),

            SizedBox(height: 25),

            Card(
              elevation: 1,

              child: Padding(
                padding: EdgeInsets.all(isWeb ? 20 : (isTablet ? 18 : 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      "Verification Status",
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),

                    SizedBox(height: 15),

                    _buildStatusRow("License Number", "CPA-CA-112345"),
                    SizedBox(height: 10),
                    _buildStatusRow("Certification", "CPA"),
                    SizedBox(height: 10),
                    _buildStatusRow("State", "California"),
                    SizedBox(height: 10),
                    _buildStatusRow(
                      "License Verification",
                      "Pending Verification via License Database",
                      color: Colors.amber,
                    ),
                    SizedBox(height: 10),
                    _buildStatusRow(
                      "Profile Status",
                      "Pending Activation",
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            Card(
              child: Padding(
                padding: EdgeInsets.all(isWeb ? 20 : (isTablet ? 18 : 16)),
                child: Row(
                  children: [
                    CircleAvatar(radius: 30),
                    SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            "Laura Green",
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          SizedBox(height: 5),
                          AppText("CPA, EA", fontSize: 12),
                          SizedBox(height: 5),
                          AppText(
                            "With 12 years of experience helping small business owners...",
                            fontSize: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 25),

            AppButton(
              buttonText: "Edit Profile",
              onTapFunction: () {},
              buttonColor: const Color.fromARGB(255, 19, 44, 82),
              fontSize: 14,
              textColor: Colors.white,
              radius: 8,
            ),
            SizedBox(height: 20),

            AppButton(
              buttonText: "Dashboard (Temp)",
              onTapFunction: () {
                Get.offAllNamed(Routes.dashboardCPA);
              },
              // buttonColor: orangeColor,
              // textColor: Colors.black,
              radius: 8,
              fontSize: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String title, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(flex: 2, child: AppText(title, fontSize: 13)),
        Expanded(
          flex: 3,
          child: AppText(
            value,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
