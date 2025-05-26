import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/values/app_assets.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  
  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.leading,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading ?? (automaticallyImplyLeading ? IconButton(
        icon: Icon(AppAssets.getIcon('back')),
        onPressed: () => Get.back(),
      ) : null),
      actions: actions,
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 