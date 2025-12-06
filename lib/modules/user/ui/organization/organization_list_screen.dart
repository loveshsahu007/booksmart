import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'add_organization_screen.dart';

void goToOrganizationListScreen({bool shouldCloseBefore = false}) {
  if (kIsWeb) {
    if (shouldCloseBefore) {
      Get.back(); // close previous dialog
    }
    customDialog(
      child: const OrganizationListScreen(),
      title: 'Organizations',
      barrierDismissible: true,
    );
  } else {
    if (shouldCloseBefore) {
      Get.off(() => const OrganizationListScreen());
    } else {
      Get.to(() => const OrganizationListScreen());
    }
  }
}

class OrganizationListScreen extends StatefulWidget {
  const OrganizationListScreen({super.key});

  @override
  State<OrganizationListScreen> createState() => _OrganizationListScreenState();
}

class _OrganizationListScreenState extends State<OrganizationListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text('Organizations')),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.02),
          child: Column(
            children: const [
              ListTile(
                leading: Icon(Icons.business),
                title: Text('Organization 1'),
                subtitle: Text('3322-24-43'),
              ),
              SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.business),
                title: Text('Organization 2'),
                subtitle: Text('212-324-444'),
              ),
              SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.business),
                title: Text('Organization 3'),
                subtitle: Text('123-234-4234'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          goToAddOrganizationScreen(shouldCloseBefore: true);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
