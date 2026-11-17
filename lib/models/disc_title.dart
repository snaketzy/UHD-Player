/// 从蓝光/DVD 原盘结构中扫描出的一个"标题"（Title）。
///
/// 由于播放引擎未暴露原盘菜单交互（BD-J / IFO 菜单选择）接口，
/// 这里用"标题列表"代替原盘菜单，让用户直接选择要播放的正片/花絮，
/// 跳过菜单直接播放对应的底层流文件。
class DiscTitle {
  DiscTitle({
    required this.index,
    required this.label,
    required this.sizeBytes,
    required this.filePaths,
  });

  final int index;
  final String label;
  final int sizeBytes;

  /// 该标题对应的底层文件，按播放顺序排列。
  /// 蓝光标题通常只有 1 个 .m2ts 文件；
  /// DVD 标题可能由多个 VTS_xx_n.VOB 分段组成，会按顺序整体播放。
  final List<String> filePaths;

  String get sizeLabel {
    final mb = sizeBytes / (1024 * 1024);
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(0)} MB';
  }
}
