import 'package:flutter/material.dart';

import '../models/disc_title.dart';
import '../models/media_item.dart';
import '../services/disc_scanner.dart';
import '../services/iso_mount_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

/// 原盘标题选择界面：挂载 ISO（如需要）→ 扫描 BDMV/VIDEO_TS 结构 → 列出可播放标题。
///
/// 播放引擎未提供原盘菜单交互能力，这里用标题列表代替原盘菜单，
/// 通常体积最大的标题即为正片。
class TitleSelectScreen extends StatefulWidget {
  const TitleSelectScreen({
    super.key,
    required this.item,
    required this.settings,
  });

  final MediaItem item;
  final SettingsService settings;

  @override
  State<TitleSelectScreen> createState() => _TitleSelectScreenState();
}

class _TitleSelectScreenState extends State<TitleSelectScreen> {
  String? _mountPoint;
  List<DiscTitle> _titles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      String discRoot = widget.item.path;
      MediaKind kind = widget.item.kind;

      if (kind == MediaKind.iso) {
        _mountPoint = await IsoMountService.mount(widget.item.path);
        final detected = DiscScanner.detectDiscKind(_mountPoint!);
        if (detected == null) {
          throw StateError('未能在 ISO 中识别到 BDMV 或 VIDEO_TS 结构');
        }
        discRoot = _mountPoint!;
        kind = detected;
      }

      final titles = DiscScanner.scanTitles(discRoot, kind);
      if (!mounted) return;
      setState(() {
        _titles = titles;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    if (_mountPoint != null) {
      IsoMountService.unmount(_mountPoint!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('选择标题 - ${widget.item.title}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? Center(
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                )
              : _titles.isEmpty
                  ? const Center(child: Text('未扫描到任何可播放标题'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _titles.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final title = _titles[index];
                        return ListTile(
                          leading: const Icon(Icons.play_circle_outline,
                              color: AppTheme.accent),
                          title: Text(
                            index == 0 ? '${title.label} (推测为正片)' : title.label,
                          ),
                          subtitle: Text('大小约 ${title.sizeLabel} · ${title.filePaths.length} 个分段'),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => PlayerScreen(
                                title: '${widget.item.title} - ${title.label}',
                                sources: title.filePaths,
                                settings: widget.settings,
                              ),
                            ));
                          },
                        );
                      },
                    ),
    );
  }
}
