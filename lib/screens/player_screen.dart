import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:vlc_player/vlc_player.dart';

import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// 播放器界面：承载 VLC 播放视图与自定义控制条。
///
/// [sources] 为按播放顺序排列的本地文件路径；长度 > 1 时（如 DVD 的多段 VOB）
/// 会以播放列表形式自动连续播放。
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.title,
    required this.sources,
    required this.settings,
  });

  final String title;
  final List<String> sources;
  final SettingsService settings;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final VlcPlayerController _controller;
  Timer? _hideTimer;
  bool _controlsVisible = true;
  List<VlcTrackDescription> _audioTracks = [];
  List<VlcTrackDescription> _subtitleTracks = [];
  bool _tracksLoaded = false;

  @override
  void initState() {
    super.initState();
    final options = [
      '--avcodec-hw=${widget.settings.hardwareDecode ? 'any' : 'none'}',
    ];
    final mediaSources = widget.sources
        .map((p) => VlcMediaSource(uri: Uri.file(p)))
        .toList();

    if (mediaSources.length == 1) {
      _controller = VlcPlayerController(
        mediaSource: mediaSources.first,
        autoPlay: true,
        options: options,
      );
    } else {
      _controller = VlcPlayerController(options: options);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.setPlaylist(
          mediaSources,
          autoPlay: true,
          autoAdvance: true,
        );
      });
    }
    _controller.addListener(_onValueChanged);
    _resetHideTimer();
  }

  void _onValueChanged() {
    if (!_tracksLoaded && _controller.value.isReady) {
      _tracksLoaded = true;
      _loadTracks();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadTracks() async {
    try {
      final audio = await _controller.getAudioTracks();
      final subs = await _controller.getSubtitleTracks();
      if (!mounted) return;
      setState(() {
        _audioTracks = audio;
        _subtitleTracks = subs;
      });
    } catch (_) {
      // 部分媒体可能不支持轨道查询，忽略即可。
    }
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeListener(_onValueChanged);
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.value;
    return Scaffold(
      backgroundColor: Colors.black,
      body: MouseRegion(
        onHover: (_) => _resetHideTimer(),
        child: GestureDetector(
          onTap: () {
            if (_controlsVisible) {
              _hideTimer?.cancel();
              setState(() => _controlsVisible = false);
            } else {
              _resetHideTimer();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: VlcPlayer(
                  controller: _controller,
                  fit: VlcVideoFit.contain,
                ),
              ),
              if (value.isBuffering || value.state == VlcPlaybackState.opening)
                const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
              if (value.hasError)
                Center(
                  child: Text(
                    '播放失败：${value.errorDescription ?? '未知错误'}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              _buildTopBar(),
              _buildBottomBar(value),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: _controlsVisible ? 0 : -60,
      left: 0,
      right: 0,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(VlcPlayerValue value) {
    final duration = value.duration;
    final position = value.position;
    final maxMs = duration.inMilliseconds.toDouble();
    final posMs = position.inMilliseconds
        .toDouble()
        .clamp(0, maxMs <= 0 ? 1 : maxMs)
        .toDouble();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: _controlsVisible ? 0 : -120,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(_formatDuration(position),
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: maxMs <= 0 ? 0 : posMs,
                    max: maxMs <= 0 ? 1 : maxMs,
                    onChanged: value.isSeekable && maxMs > 0
                        ? (v) => _controller.seekTo(
                            Duration(milliseconds: v.round()))
                        : null,
                  ),
                ),
                Text(_formatDuration(duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    value.isPlaying ? _controller.pause() : _controller.play();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.white),
                  onPressed: () {},
                ),
                SizedBox(
                  width: 100,
                  child: Slider(
                    value: value.volume.clamp(0, 200).toDouble(),
                    max: 200,
                    onChanged: (v) => _controller.setVolume(v.round()),
                  ),
                ),
                const Spacer(),
                _trackMenuButton(
                  icon: Icons.audiotrack,
                  tooltip: '音轨',
                  tracks: _audioTracks,
                  onSelect: (id) => _controller.setAudioTrack(id),
                ),
                _subtitleMenuButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _trackMenuButton({
    required IconData icon,
    required String tooltip,
    required List<VlcTrackDescription> tracks,
    required ValueChanged<int> onSelect,
  }) {
    return PopupMenuButton<int>(
      tooltip: tooltip,
      icon: Icon(icon, color: Colors.white),
      enabled: tracks.isNotEmpty,
      itemBuilder: (context) => tracks
          .map((t) => PopupMenuItem(
                value: t.id,
                child: Text(t.language != null ? '${t.name} (${t.language})' : t.name),
              ))
          .toList(),
      onSelected: onSelect,
    );
  }

  Widget _subtitleMenuButton() {
    return PopupMenuButton<String>(
      tooltip: '字幕',
      icon: const Icon(Icons.subtitles, color: Colors.white),
      itemBuilder: (context) => [
        const PopupMenuItem(value: '__off__', child: Text('关闭字幕')),
        ..._subtitleTracks.map((t) => PopupMenuItem(
              value: 't:${t.id}',
              child: Text(t.language != null ? '${t.name} (${t.language})' : t.name),
            )),
        const PopupMenuItem(value: '__load__', child: Text('加载字幕文件...')),
      ],
      onSelected: (value) async {
        if (value == '__off__') {
          await _controller.disableSubtitle();
        } else if (value == '__load__') {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['srt', 'ass', 'ssa', 'sub'],
          );
          final path = result?.files.single.path;
          if (path != null) {
            await _controller.addSubtitle(Uri.file(path));
          }
        } else if (value.startsWith('t:')) {
          await _controller.setSubtitleTrack(int.parse(value.substring(2)));
        }
      },
    );
  }
}
