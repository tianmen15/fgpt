import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class MusicService {
  static const _searchBaseUrl = 'https://api.vkeys.cn/v2/music/netease';
  static const _newApiBase = 'https://musicapi.qijieya.cn';

  /// 搜索歌曲 - 使用旧API
  static Future<List<SongItem>> searchSongs({
    required String keyword,
    int page = 1,
    int num = 10,
    int quality = 9,
    int timeoutSeconds = 10,
  }) async {
    try {
      final uri = Uri.parse(_searchBaseUrl).replace(queryParameters: {
        'word': keyword,
        'page': page.toString(),
        'num': num.toString(),
        'quality': quality.toString(),
      });

      final response = await http.get(uri).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final songsData = data['data'];
          if (songsData is List) {
            return songsData
                .map((s) => SongItem.fromJson(s as Map<String, dynamic>))
                .toList();
          } else if (songsData is Map<String, dynamic>) {
            return [SongItem.fromJson(songsData)];
          }
        }
      }
    } catch (_) {}
    return [];
  }

  /// 根据ID获取歌曲播放URL - 使用新API
  /// 新API: https://musicapi.qijieya.cn/song/url/v1?id=xxx&level=exhigh
  /// 返回格式: {"code":200, "data":[{"id":xxx, "url":"...", "level":"exhigh", "time":xxx, "type":"...", "size":xxx}]}
  static Future<SongItem?> getSongById({
    required int id,
    int quality = 9,
    int timeoutSeconds = 10,
  }) async {
    try {
      final uri = Uri.parse('$_newApiBase/song/url/v1').replace(queryParameters: {
        'id': id.toString(),
        'level': 'exhigh',
      });

      final response = await http.get(uri).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = SongItem.parseUrlFromNewApi(data as Map<String, dynamic>);
        if (url != null && url.isNotEmpty) {
          return SongItem(
            id: id,
            song: '',
            singer: '',
            album: '',
            time: '',
            quality: 'exhigh',
            cover: '',
            interval: '',
            link: '',
            size: '',
            kbps: '',
            url: url,
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 获取歌词 - 使用新API
  /// 新API: https://musicapi.qijieya.cn/meting/?type=lrc&id=xxx
  /// 返回纯文本LRC格式歌词
  static Future<String?> getLyric({
    required int id,
    int timeoutSeconds = 8,
  }) async {
    try {
      final uri = Uri.parse('$_newApiBase/meting/').replace(queryParameters: {
        'type': 'lrc',
        'id': id.toString(),
      });

      final response = await http.get(uri).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final body = response.body;
        if (body.isNotEmpty && !body.startsWith('{') && !body.startsWith('<')) {
          return body;
        }
      }
    } catch (_) {}
    return null;
  }

  /// 获取歌曲详情（封面、歌手、专辑等） - 使用新API
  /// 新API: https://musicapi.qijieya.cn/song/detail?ids=xxx
  /// 返回格式: {"code":200, "data":{"songs":[{"id":xxx, "name":"...", "ar":[{"name":"..."}], "al":{"name":"...", "picUrl":"..."}, "dt":xxx, ...}]}}
  static Future<SongItem?> getSongDetail({
    required SongItem existing,
    int timeoutSeconds = 8,
  }) async {
    try {
      final uri = Uri.parse('$_newApiBase/song/detail').replace(queryParameters: {
        'ids': existing.id.toString(),
      });

      final response = await http.get(uri).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SongItem.mergeDetailFromNewApi(data as Map<String, dynamic>, existing);
      }
    } catch (_) {}
    return null;
  }

  /// 获取歌曲封面 - 使用新API
  /// 新API: https://musicapi.qijieya.cn/meting/?type=pic&id=xxx
  /// 返回封面图片URL（HTTP重定向或直接返回图片数据）
  static Future<String?> getSongCover({
    required int id,
    int timeoutSeconds = 8,
  }) async {
    try {
      final uri = Uri.parse('$_newApiBase/meting/').replace(queryParameters: {
        'type': 'pic',
        'id': id.toString(),
      });

      final response = await http.get(uri).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        return uri.toString();
      }
    } catch (_) {}
    return null;
  }
}