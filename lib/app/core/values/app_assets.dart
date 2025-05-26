import 'package:flutter/material.dart';

/// Kelas untuk mengelola semua asset dalam aplikasi
class AppAssets {
  // Paths untuk image assets
  static const String _imagePath = 'assets/images/';
  static const String _iconPath = 'assets/icons/';
  
  // Logo
  static const String logo = '${_imagePath}logo.png';
  static const String appIcon = '${_iconPath}app_icon.png';
  
  // Metode untuk mendapatkan ikon dari Material Icons
  static IconData getIcon(String name) {
    switch (name) {
      case 'menu':
        return Icons.menu;
      case 'home':
        return Icons.home;
      case 'book':
        return Icons.book;
      case 'note':
        return Icons.note;
      case 'settings':
        return Icons.settings;
      case 'person':
        return Icons.person;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'add':
        return Icons.add;
      case 'search':
        return Icons.search;
      case 'filter':
        return Icons.filter_list;
      case 'bookmark':
        return Icons.bookmark;
      case 'public':
        return Icons.public;
      case 'private':
        return Icons.lock;
      case 'visibility':
        return Icons.visibility;
      case 'visibility_off':
        return Icons.visibility_off;
      case 'more':
        return Icons.more_vert;
      case 'inbox':
        return Icons.inbox;
      case 'comment':
        return Icons.comment;
      case 'time':
        return Icons.access_time;
      case 'back':
        return Icons.arrow_back;
      case 'share':
        return Icons.share;
      case 'image':
        return Icons.image;
      case 'camera':
        return Icons.camera_alt;
      case 'photo_library':
        return Icons.photo_library;
      case 'music':
        return Icons.music_note;
      case 'play':
        return Icons.play_arrow;
      case 'pause':
        return Icons.pause;
      case 'stop':
        return Icons.stop;
      case 'close':
        return Icons.close;
      case 'check':
        return Icons.check;
      default:
        return Icons.help_outline; // Ikon default jika nama tidak ditemukan
    }
  }
} 