import 'dart:io';

import '../models/disc_title.dart';
import '../models/media_item.dart';

/// 识别蓝光/DVD 原盘文件夹结构，并扫描出可播放的"标题"列表。
class DiscScanner {
  DiscScanner._();

  /// 判断给定文件夹是否是蓝光原盘结构（包含 BDMV 目录）。
  static bool isBlurayFolder(String folderPath) {
    final dir = Directory(folderPath);
    if (dir.existsSync() && _basename(folderPath) == 'BDMV') return true;
    return Directory('$folderPath/BDMV').existsSync();
  }

  /// 判断给定文件夹是否是 DVD 原盘结构（包含 VIDEO_TS 目录）。
  static bool isDvdFolder(String folderPath) {
    if (_basename(folderPath) == 'VIDEO_TS') return true;
    return Directory('$folderPath/VIDEO_TS').existsSync();
  }

  /// 根据文件夹结构判断媒体类型，返回 null 表示既不是蓝光也不是 DVD。
  static MediaKind? detectDiscKind(String folderPath) {
    if (isBlurayFolder(folderPath)) return MediaKind.blurayFolder;
    if (isDvdFolder(folderPath)) return MediaKind.dvdFolder;
    return null;
  }

  static String _basename(String path) {
    final normalized = path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;
    final idx = normalized.lastIndexOf('/');
    return idx == -1 ? normalized : normalized.substring(idx + 1);
  }

  /// 扫描指定原盘根目录下所有可播放标题。
  static List<DiscTitle> scanTitles(String rootPath, MediaKind kind) {
    switch (kind) {
      case MediaKind.blurayFolder:
        return _scanBluray(rootPath);
      case MediaKind.dvdFolder:
        return _scanDvd(rootPath);
      default:
        return const [];
    }
  }

  static List<DiscTitle> _scanBluray(String rootPath) {
    final streamDir = _basename(rootPath) == 'BDMV'
        ? Directory('$rootPath/STREAM')
        : Directory('$rootPath/BDMV/STREAM');
    if (!streamDir.existsSync()) return const [];

    final files = streamDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.m2ts'))
        .toList();

    final entries = files.map((f) => (f.path, f.lengthSync())).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    return List.generate(entries.length, (i) {
      final (path, size) = entries[i];
      return DiscTitle(
        index: i + 1,
        label: '标题 ${i + 1}',
        sizeBytes: size,
        filePaths: [path],
      );
    });
  }

  static List<DiscTitle> _scanDvd(String rootPath) {
    final videoTsDir = _basename(rootPath) == 'VIDEO_TS'
        ? Directory(rootPath)
        : Directory('$rootPath/VIDEO_TS');
    if (!videoTsDir.existsSync()) return const [];

    // 文件名形如 VTS_01_1.VOB，第一段数字是标题集编号，第二段是分段序号。
    // 分段 0（VTS_01_0.VOB）通常是菜单/IFO 预览数据，播放时跳过。
    final vtsPattern = RegExp(r'^VTS_(\d+)_(\d+)\.VOB$', caseSensitive: false);

    final byTitleSet = <int, List<(int part, File file)>>{};
    for (final entity in videoTsDir.listSync()) {
      if (entity is! File) continue;
      final match = vtsPattern.firstMatch(_basename(entity.path));
      if (match == null) continue;
      final titleSet = int.parse(match.group(1)!);
      final part = int.parse(match.group(2)!);
      if (part == 0) continue;
      byTitleSet.putIfAbsent(titleSet, () => []).add((part, entity));
    }

    final titles = <DiscTitle>[];
    for (final titleSet in byTitleSet.keys) {
      final parts = byTitleSet[titleSet]!..sort((a, b) => a.$1.compareTo(b.$1));
      final totalSize =
          parts.fold<int>(0, (sum, p) => sum + p.$2.lengthSync());
      titles.add(DiscTitle(
        index: titleSet,
        label: '标题 $titleSet',
        sizeBytes: totalSize,
        filePaths: parts.map((p) => p.$2.path).toList(),
      ));
    }

    titles.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return titles;
  }
}
