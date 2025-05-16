import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';

class AuthView extends StatelessWidget {
  const AuthView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Redirect to login by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute == Routes.AUTH) {
        Get.toNamed(Routes.LOGIN);
      }
    });

    return Scaffold(
      body: GetRouterOutlet(
        anchorRoute: Routes.AUTH,
        initialRoute: Routes.LOGIN,
      ),
    );
  }
} 