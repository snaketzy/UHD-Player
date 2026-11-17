/// 媒体库中条目的类型。
enum MediaKind {
  /// 普通视频文件（mp4/mkv/avi 等）。
  videoFile,

  /// 蓝光原盘文件夹（包含 BDMV 目录）。
  blurayFolder,

  /// DVD 原盘文件夹（包含 VIDEO_TS 目录）。
  dvdFolder,

  /// ISO 镜像文件（内部可能是蓝光或 DVD 结构，播放前挂载后再判定）。
  iso,
}

extension MediaKindX on MediaKind {
  bool get isDisc =>
      this == MediaKind.blurayFolder ||
      this == MediaKind.dvdFolder ||
      this == MediaKind.iso;

  String get label {
    switch (this) {
      case MediaKind.videoFile:
        return '视频文件';
      case MediaKind.blurayFolder:
        return '蓝光原盘';
      case MediaKind.dvdFolder:
        return 'DVD 原盘';
      case MediaKind.iso:
        return 'ISO 镜像';
    }
  }
}

/// 媒体库中的一条记录。
class MediaItem {
  MediaItem({
    required this.id,
    required this.title,
    required this.path,
    required this.kind,
    required this.addedAt,
    this.lastPlayedAt,
  });

  final String id;
  final String title;

  /// 本地绝对路径：文件路径 / 光盘文件夹路径 / ISO 文件路径。
  final String path;
  final MediaKind kind;
  final DateTime addedAt;
  DateTime? lastPlayedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'path': path,
        'kind': kind.name,
        'addedAt': addedAt.toIso8601String(),
        'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      };

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      path: json['path'] as String,
      kind: MediaKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => MediaKind.videoFile,
      ),
      addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ??
          DateTime.now(),
      lastPlayedAt: json['lastPlayedAt'] == null
          ? null
          : DateTime.tryParse(json['lastPlayedAt'] as String),
    );
  }
}
