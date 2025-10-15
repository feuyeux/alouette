import 'package:flutter/material.dart';
import '../pages/about_page.dart';

/// Helper class for showing About page across platforms
class AboutHelper {
  /// Show About page with the given app information
  static void showAbout(
    BuildContext context, {
    required String appName,
    String? copyright,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AboutPage(appName: appName, copyright: copyright),
      ),
    );
  }

  /// Create an About menu item for PopupMenuButton
  static PopupMenuItem<String> createAboutMenuItem() {
    return const PopupMenuItem<String>(
      value: 'about',
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20),
          SizedBox(width: 12),
          Text('关于'),
        ],
      ),
    );
  }

  /// Create an About IconButton
  static Widget createAboutButton(
    BuildContext context, {
    required String appName,
    String? copyright,
  }) {
    return IconButton(
      icon: const Icon(Icons.info_outline),
      tooltip: '关于',
      onPressed: () =>
          showAbout(context, appName: appName, copyright: copyright),
    );
  }
}
