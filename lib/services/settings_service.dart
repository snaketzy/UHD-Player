import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'app_paths.dart';

/// 应用播放设置，持久化到本地 JSON 文件。
class SettingsService extends ChangeNotifier {
  bool hardwareDecode = true;

  File _storeFile() => File('${appSupportDirPath()}/settings.json');

  Future<void> load() async {
    try {
      final file = _storeFile();
      if (await file.exists()) {
        final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        hardwareDecode = raw['hardwareDecode'] as bool? ?? true;
      }
    } catch (_) {
      // 忽略读取失败，使用默认设置。
    }
    notifyListeners();
  }

  Future<void> setHardwareDecode(bool value) async {
    hardwareDecode = value;
    notifyListeners();
    await _storeFile().writeAsString(jsonEncode({'hardwareDecode': hardwareDecode}));
  }
}
