import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:path/path.dart' as p;

class UpdateService {
  static const String _repo =
      "https://api.github.com/repos/bartkepl/partdb_scanner/releases/latest";

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    final response = await Dio().get(_repo);

    if (response.statusCode == 200) {
      final data = response.data;
      final latestTag = data['tag_name'];
      final assets = data['assets'];

      if (assets.isEmpty) return null;

      final apkUrl = assets[0]['browser_download_url'];

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final latestVersion = latestTag.replaceAll('v', '');

      if (_isNewer(latestVersion, currentVersion)) {
        return {
          "tag": latestTag,
          "apkUrl": apkUrl,
        };
      }
    }

    return null;
  }

  static Future<void> downloadAndInstall(
      String url,
      Function(double progress) onProgress,
      ) async {
    final dir = await getTemporaryDirectory();
    final filePath = "${dir.path}/partdb_scanner.apk";

    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }

    await Dio().download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          onProgress(received / total);
        }
      },
    );

    if (Platform.isAndroid) {
      final authority = "com.example.partdb_scanner.provider";

      final intent = AndroidIntent(
        action: 'action_view',
        data: "content://$authority/cache/partdb_scanner.apk",
        type: "application/vnd.android.package-archive",
        flags: <int>[
          Flag.FLAG_ACTIVITY_NEW_TASK,
          Flag.FLAG_GRANT_READ_URI_PERMISSION,
        ],
      );

      await intent.launch();
    }
  }


  static bool _isNewer(String latest, String current) {
    List<int> l = latest.split('.').map(int.parse).toList();
    List<int> c = current.split('.').map(int.parse).toList();

    for (int i = 0; i < l.length; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }
}
