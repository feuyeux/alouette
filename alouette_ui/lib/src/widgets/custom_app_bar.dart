import 'package:flutter/material.dart';
import '../tokens/dimension_tokens.dart';
import 'platform_info_widget.dart';

const _logoAssetPath = 'packages/alouette_ui/assets/icons/alouette_rounded.png';

/// 现代化的应用栏组件，为所有Alouette应用提供一致的顶部导航栏
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool showLogo;
  final VoidCallback? onTitleTap;
  final PreferredSizeWidget? bottom;
  final Widget? statusWidget; // 新增：状态组件
  final bool showPlatformInfo; // 新增：是否显示平台信息

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.showLogo = true,
    this.onTitleTap,
    this.bottom,
    this.statusWidget, // 新增参数
    this.showPlatformInfo = true, // 新增参数，默认显示
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: statusWidget != null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showLogo) ...[
                  _buildLogo(size: DimensionTokens.iconM + 4),
                  const SizedBox(width: 8),
                ],
                Expanded(child: statusWidget!),
              ],
            )
          : GestureDetector(
              onTap: onTitleTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showLogo) ...[
                    _buildLogo(size: DimensionTokens.iconM + 8),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          foregroundColor ??
                          (isDark ? Colors.white : const Color(0xFF1F2937)),
                    ),
                  ),
                ],
              ),
            ),
      centerTitle: statusWidget != null ? false : centerTitle, // 有状态组件时不居中
      backgroundColor:
          backgroundColor ?? (isDark ? const Color(0xFF1F2937) : Colors.white),
      elevation: elevation,
      scrolledUnderElevation: elevation > 0 ? elevation + 1 : 1,
      actions: [
        ...?actions,
        if (showPlatformInfo) ...[
          const SizedBox(width: 8),
          const PlatformInfoWidget(),
          const SizedBox(width: 16),
        ],
      ],
      leading: leading,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      bottom: bottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(SpacingTokens.xs),
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  Widget _buildLogo({required double size}) {
    return Image.asset(
      _logoAssetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.translate, size: size),
    );
  }
}
