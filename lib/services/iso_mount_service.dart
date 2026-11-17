import 'dart:io';

/// 使用系统自带的 hdiutil 挂载/卸载 ISO 镜像。
///
/// 仅处理未加密的 ISO 镜像结构识别与访问，不包含任何 AACS/CSS 拷贝保护
/// 解密逻辑；受保护的商业光盘镜像需用户自行预先解密。
class IsoMountService {
  IsoMountService._();

  /// 挂载 ISO，返回挂载后的卷路径（形如 /Volumes/XXXX）。
  static Future<String> mount(String isoPath) async {
    final result = await Process.run(
      'hdiutil',
      ['attach', '-nobrowse', '-readonly', isoPath],
    );
    if (result.exitCode != 0) {
      throw StateError('挂载 ISO 失败: ${result.stderr}');
    }
    final output = (result.stdout as String).trim();
    final line = output.split('\n').lastWhere(
          (l) => l.contains('/Volumes/'),
          orElse: () => '',
        );
    final idx = line.indexOf('/Volumes/');
    if (idx == -1) {
      throw StateError('无法解析 ISO 挂载路径，hdiutil 输出：\n$output');
    }
    return line.substring(idx).trim();
  }

  /// 卸载指定挂载点。
  static Future<void> unmount(String mountPoint) async {
    await Process.run('hdiutil', ['detach', mountPoint, '-quiet']);
  }
}
