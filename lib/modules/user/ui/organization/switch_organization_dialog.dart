import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/widgets/snackbar.dart';
import 'package:get/get.dart';

void showSwitchOrganizationDialog() {
  Get.generalDialog(
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Get.isDarkMode
                ? Get.theme.colorScheme.surface
                : Colors.white,
          ),
          constraints: BoxConstraints(maxWidth: 350),
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.business),
                    title: Text('Organization 1'),
                    subtitle: Text('Description of Organization 1'),
                    onTap: () {
                      Get.back();
                      showSnackBar('Switched to Organization 3');
                    },
                  ),
                  Divider(thickness: 0.1),
                  ListTile(
                    leading: Icon(Icons.business),
                    title: Text('Organization 2'),
                    subtitle: Text('Description of Organization 2'),
                    onTap: () {
                      Get.back();
                      showSnackBar('Switched to Organization 3');
                    },
                  ),
                  Divider(thickness: 0.1),
                  ListTile(
                    leading: Icon(Icons.business),
                    title: Text('Organization 3'),
                    subtitle: Text('Description of Organization 3'),
                    onTap: () {
                      Get.back();
                      showSnackBar('Switched to Organization 3');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    barrierDismissible: true,
    barrierLabel: "showSwitchOrganizationDialog",
  );
}
