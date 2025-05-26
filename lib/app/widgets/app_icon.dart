import 'package:flutter/material.dart';
import '../core/values/app_assets.dart';

class AppIcon extends StatelessWidget {
  final String name;
  final double? size;
  final Color? color;
  
  const AppIcon(
    this.name, {
    Key? key,
    this.size,
    this.color,
  }) : super(key: key);
  
  // Static instances untuk ikon umum
  static IconData get home => Icons.home;
  static IconData get note => Icons.note;
  static IconData get book => Icons.book;
  static IconData get settings => Icons.settings;
  static IconData get person => Icons.person;
  static IconData get edit => Icons.edit;
  static IconData get delete => Icons.delete;
  static IconData get add => Icons.add;
  static IconData get search => Icons.search;
  static IconData get filter => Icons.filter_list;
  static IconData get bookmark => Icons.bookmark;
  static IconData get more => Icons.more_vert;
  static IconData get user => Icons.person;
  static IconData get cog => Icons.settings;
  static IconData get plusCircle => Icons.add_circle;
  static IconData get verticalEllipsis => Icons.more_vert;
  
  @override
  Widget build(BuildContext context) {
    return Icon(
      AppAssets.getIcon(name),
      size: size,
      color: color,
    );
  }
} 