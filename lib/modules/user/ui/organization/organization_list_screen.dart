import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/controllers/organization_controller.dart';
import 'package:booksmart/widgets/confirmation_dialog.dart';
import 'package:booksmart/widgets/custom_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../models/organization_model.dart';
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
  late OrganizationController orgController;

  @override
  void initState() {
    if (Get.isRegistered<OrganizationController>()) {
      orgController = Get.find<OrganizationController>();
    } else {
      // it will never happen, as we initilize this controller at the appStart
      orgController = Get.put(OrganizationController([]), permanent: true);
      orgController.refreshOrganizations();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(title: const Text('Organizations')),
      body: GetBuilder<OrganizationController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.organizations.isEmpty) {
            return const Center(child: Text("No organizations found"));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: context.screenWidth * 0.02,
            ),
            child: Column(
              children: controller.organizations.map((OrganizationModel org) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.business),
                    title: Text(org.name),
                    subtitle: Text(org.einTin),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () {
                            showConfirmationDialog(
                              title: "Delete Organization",
                              description:
                                  "Are you sure you want to delete '${org.name}'?",
                              onYes: () async {
                                controller.deleteOrganization(org.id);
                                Get.back();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
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
