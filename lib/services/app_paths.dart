import 'dart:io';

/// 应用本地数据目录（替代 path_provider，避免引入其 macOS 原生依赖链）。
///
/// 直接基于 HOME 环境变量拼接 `~/Library/Application Support/UHDPlayer`，
/// 不依赖任何需要原生框架加载的插件。
String appSupportDirPath() {
  final home = Platform.environment['HOME'] ?? Directory.current.path;
  final dir = Directory('$home/Library/Application Support/UHDPlayer');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir.path;
}
