import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  final String appName;
  final String? copyright;

  const AboutPage({super.key, required this.appName, this.copyright});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = 'Loading...';
  String _flutterVersion = 'Loading...';
  String _dartVersion = 'Loading...';
  String _osVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _flutterVersion = _getFlutterVersion();
        _dartVersion = _getDartVersion();
        _osVersion = _getOSVersion();
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Unknown';
        _flutterVersion = _getFlutterVersion();
        _dartVersion = _getDartVersion();
        _osVersion = _getOSVersion();
      });
    }
  }

  String _getFlutterVersion() {
    // Flutter version is embedded in the framework
    // We can extract it from the Platform.version string or use a constant
    // For now, return the version from build-time constant
    return const String.fromEnvironment(
      'FLUTTER_VERSION',
      defaultValue: '3.35.5',
    );
  }

  String _getDartVersion() {
    try {
      final version = Platform.version;
      return version.split(' ').first;
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getOSVersion() {
    try {
      if (kIsWeb) {
        return 'Web';
      }

      final rawVersion = Platform.operatingSystemVersion;

      if (Platform.isWindows) {
        return _formatWindowsVersion(rawVersion);
      }

      return '${Platform.operatingSystem} $rawVersion';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatWindowsVersion(String rawVersion) {
    // Extract build number from various formats:
    // "Windows 10 Home China" 10.0 (Build 26200)
    // 10.0.26200
    final buildMatch = RegExp(r'Build\s+(\d+)|\.(\d{5,})').firstMatch(rawVersion);
    if (buildMatch == null) {
      return rawVersion;
    }

    final build = int.tryParse(buildMatch.group(1) ?? buildMatch.group(2) ?? '0') ?? 0;

    // Version mapping table (sorted by build number descending)
    final versionMap = [
      (26200, 'Windows 11', '24H2'),
      (26100, 'Windows 11', '25H2'),
      (22631, 'Windows 11', '23H2'),
      (22621, 'Windows 11', '22H2'),
      (22000, 'Windows 11', '21H2'),
      (19045, 'Windows 10', '22H2'),
      (19044, 'Windows 10', '21H2'),
      (19043, 'Windows 10', '21H1'),
      (19042, 'Windows 10', '20H2'),
    ];

    for (final (minBuild, osName, release) in versionMap) {
      if (build >= minBuild) {
        return '$osName 版本 $release (OS 内部版本 $build)';
      }
    }

    return 'Windows (OS 内部版本 $build)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/icons/alouette_rounded.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // App Name
                Text(
                  widget.appName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 40),

                // Version Information
                _buildInfoCard(context, [
                  _buildInfoRow(context, '应用版本', _appVersion),
                  _buildInfoRow(context, 'Flutter版本', _flutterVersion),
                  _buildInfoRow(context, 'Dart版本', _dartVersion),
                  _buildInfoRow(context, 'OS版本', _osVersion),
                ]),
                const SizedBox(height: 40),

                // Copyright
                if (widget.copyright != null)
                  Text(
                    widget.copyright!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
