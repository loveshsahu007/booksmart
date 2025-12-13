import 'package:booksmart/controllers/organization_controler.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showSwitchOrganizationDialog() {
  final OrganizationController controller = Get.put(OrganizationController());

  Get.generalDialog(
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Get.isDarkMode
                ? Get.theme.colorScheme.surface
                : Colors.white,
          ),
          constraints: const BoxConstraints(maxWidth: 350),
          child: Material(
            color: Colors.transparent,
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (controller.organizations.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text("No organizations available")),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: controller.organizations.map((org) {
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.business),
                          title: Text(org.name),
                          subtitle: Text(org.industry),
                          onTap: () {
                            Get.back();
                            showSnackBar('Switched to ${org.name}');
                            // TODO: Save selected organization in app state if needed
                          },
                        ),
                        const Divider(thickness: 0.1),
                      ],
                    );
                  }).toList(),
                ),
              );
            }),
          ),
        ),
      );
    },
    barrierDismissible: true,
    barrierLabel: "showSwitchOrganizationDialog",
  );
}
