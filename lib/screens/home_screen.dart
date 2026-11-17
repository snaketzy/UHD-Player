import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../services/library_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/media_card.dart';
import 'player_screen.dart';
import 'title_select_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.library,
    required this.settings,
  });

  final LibraryService library;
  final SettingsService settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.library.addListener(_onChanged);
    widget.settings.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.library.removeListener(_onChanged);
    widget.settings.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _addVideoFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'mov', 'ts', 'm2ts', 'webm', 'flv', 'wmv', 'iso'],
    );
    if (result == null) return;
    var anyFailed = false;
    for (final file in result.files) {
      if (file.path == null) continue;
      final ok = await widget.library.addPath(file.path!);
      if (!ok) anyFailed = true;
    }
    if (anyFailed && mounted) _showUnrecognized();
  }

  Future<void> _addFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    final ok = await widget.library.addPath(path);
    if (!ok && mounted) _showUnrecognized();
  }

  void _showUnrecognized() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('未能识别为视频文件 / 蓝光原盘(含 BDMV) / DVD 原盘(含 VIDEO_TS) / ISO 镜像'),
    ));
  }

  void _openItem(MediaItem item) {
    widget.library.markPlayed(item.id);
    if (item.kind.isDisc) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TitleSelectScreen(item: item, settings: widget.settings),
      ));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: item.title,
          sources: [item.path],
          settings: widget.settings,
        ),
      ));
    }
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('设置'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('硬件解码'),
                  subtitle: const Text('开启可降低 CPU 占用，兼容性问题时可关闭'),
                  value: widget.settings.hardwareDecode,
                  onChanged: (v) {
                    widget.settings.setHardwareDecode(v);
                    setDialogState(() {});
                  },
                ),
                const Divider(),
                const Text(
                  '播放引擎：VLCKit (libVLC)\n'
                  '说明：蓝光/DVD 原盘播放为直接定位正片流文件播放，'
                  '不支持原盘菜单交互；HDR/杜比视界画面直通效果取决于 VLCKit 能力，不保证完全等同专业播放器。',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.library.items;
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildToolbar(),
                const Divider(height: 1),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Text(
                            '媒体库为空\n点击上方按钮添加视频文件 / 原盘文件夹 / ISO 镜像',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 180,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return MediaCard(
                              item: item,
                              onTap: () => _openItem(item),
                              onRemove: () => widget.library.remove(item.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 200,
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Row(
              children: [
                Icon(Icons.ondemand_video, color: AppTheme.accent),
                SizedBox(width: 8),
                Text(
                  'UHD Player',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.video_library, color: AppTheme.accent),
            title: const Text('媒体库'),
            selected: true,
            selectedTileColor: AppTheme.surfaceVariant,
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('设置'),
            onTap: _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('媒体库', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _addFolder,
            icon: const Icon(Icons.folder_open),
            label: const Text('添加原盘文件夹'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _addVideoFiles,
            icon: const Icon(Icons.add),
            label: const Text('添加文件 / ISO'),
          ),
        ],
      ),
    );
  }
}
