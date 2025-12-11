import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constant/app_colors.dart';
import '../../../routes/pages.dart';
import '../../../routes/routes.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, this.isLogInType = true});
  final bool isLogInType;
  @override
  Widget build(BuildContext context) {
    double thisScreenWidth = MediaQuery.of(context).size.width;
    double thisScreenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: orangeColor,
      child: SizedBox(
        width: thisScreenWidth,
        height: thisScreenHeight,
        child: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              width: thisScreenWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.offNamed(getHomeScreenRoute());
                    },
                    child: const Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isLogInType
                        ? 'Please Login To Continue!'
                        : "Sorry\nThis Route Does'nt Exist!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (isLogInType)
                    SizedBox(
                      width: 130,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 30,
                          ),
                        ),
                        onPressed: () {
                          Get.offNamed(Routes.login);
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.login_rounded),
                            SizedBox(width: 5),
                            Text('Login'),
                          ],
                        ),
                      ),
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
