import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';

/// 平台信息显示组件
/// 在应用状态栏右侧显示当前运行平台信息
class PlatformInfoWidget extends StatelessWidget {
  final bool showIcon;
  final TextStyle? textStyle;
  final Color? iconColor;

  const PlatformInfoWidget({
    super.key,
    this.showIcon = true,
    this.textStyle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platformInfo = _getPlatformInfo();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            platformInfo['icon'],
            size: 14,
            color: iconColor ?? theme.textTheme.bodySmall?.color?.withValues(alpha:0.7),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          platformInfo['name'],
          style: textStyle ?? TextStyle(
            fontSize: 11,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha:0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 获取平台信息
  /// 复用 lib 库的平台检测逻辑，添加 UI 相关的图标和显示名称
  Map<String, dynamic> _getPlatformInfo() {
    final platformName = PlatformUtils.platformName;
    
    switch (platformName) {
      case 'web':
        return {
          'name': 'Web',
          'icon': Icons.web,
        };
      case 'windows':
        return {
          'name': 'Windows',
          'icon': Icons.desktop_windows,
        };
      case 'macos':
        return {
          'name': 'macOS',
          'icon': Icons.desktop_mac,
        };
      case 'linux':
        return {
          'name': 'Linux',
          'icon': Icons.computer,
        };
      case 'android':
        return {
          'name': 'Android',
          'icon': Icons.android,
        };
      case 'ios':
        return {
          'name': 'iOS',
          'icon': Icons.phone_iphone,
        };
      default:
        return {
          'name': 'Unknown',
          'icon': Icons.device_unknown,
        };
    }
  }
}