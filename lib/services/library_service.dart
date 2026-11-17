import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/media_item.dart';
import 'app_paths.dart';
import 'disc_scanner.dart';

const _videoExtensions = {
  '.mp4', '.mkv', '.avi', '.mov', '.ts', '.m2ts', '.webm', '.flv', '.wmv',
};

/// 媒体库：维护用户添加的媒体条目列表，并持久化到本地 JSON 文件。
class LibraryService extends ChangeNotifier {
  final List<MediaItem> _items = [];
  bool _loaded = false;

  List<MediaItem> get items => List.unmodifiable(_items);
  bool get isLoaded => _loaded;

  File _storeFile() => File('${appSupportDirPath()}/library.json');

  Future<void> load() async {
    try {
      final file = _storeFile();
      if (await file.exists()) {
        final raw = await file.readAsString();
        final list = jsonDecode(raw) as List<dynamic>;
        _items
          ..clear()
          ..addAll(list.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {
      // 读取失败时保持空库，不阻塞应用启动。
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    await _storeFile().writeAsString(jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  /// 识别媒体类型。返回 null 表示该路径不是可识别的媒体（既非视频文件，也非原盘文件夹/ISO）。
  static MediaKind? detectKind(String path) {
    final entityType = FileSystemEntity.typeSync(path);
    if (entityType == FileSystemEntityType.directory) {
      return DiscScanner.detectDiscKind(path);
    }
    if (entityType == FileSystemEntityType.file) {
      final lower = path.toLowerCase();
      if (lower.endsWith('.iso')) return MediaKind.iso;
      final dotIdx = lower.lastIndexOf('.');
      final ext = dotIdx == -1 ? '' : lower.substring(dotIdx);
      if (_videoExtensions.contains(ext)) return MediaKind.videoFile;
    }
    return null;
  }

  static String _titleFromPath(String path) {
    final normalized =
        path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    final base = normalized.substring(normalized.lastIndexOf('/') + 1);
    final dotIdx = base.lastIndexOf('.');
    if (dotIdx > 0) return base.substring(0, dotIdx);
    return base;
  }

  /// 添加一个路径到媒体库，自动识别类型。返回 false 表示识别失败或已存在。
  Future<bool> addPath(String path) async {
    if (_items.any((e) => e.path == path)) return false;
    final kind = detectKind(path);
    if (kind == null) return false;

    final item = MediaItem(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      title: _titleFromPath(path),
      path: path,
      kind: kind,
      addedAt: DateTime.now(),
    );
    _items.insert(0, item);
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> markPlayed(String id) async {
    final item = _items.firstWhere((e) => e.id == id, orElse: () => _items.first);
    item.lastPlayedAt = DateTime.now();
    notifyListeners();
    await _save();
  }
}
