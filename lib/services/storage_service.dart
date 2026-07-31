import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

// 全局壁纸刷新通知 - 解决壁纸不即时更新问题
class WallpaperNotifier extends ChangeNotifier {
  static final WallpaperNotifier _instance = WallpaperNotifier._();
  factory WallpaperNotifier() => _instance;
  WallpaperNotifier._();

  void refresh() => notifyListeners();
}

class StorageService {
  static const _playlistKey = 'playlist';
  static const _wallpaperKey = 'wallpaper';
  static const _historyKey = 'history';
  static const _musicFavKey = 'music_favorites';
  static const _loliconConfigKey = 'lolicon_config';
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============ 视频播放列表 ============
  static Future<List<VideoItem>> getPlaylist() async {
    try {
      final data = _prefs.getString(_playlistKey);
      if (data == null) return [];
      final list = jsonDecode(data) as List;
      return list.map((e) => VideoItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePlaylist(List<VideoItem> items) async {
    try {
      final data = jsonEncode(items.map((e) => e.toJson()).toList());
      await _prefs.setString(_playlistKey, data);
    } catch (_) {}
  }

  static Future<void> addToPlaylist(VideoItem item) async {
    final list = await getPlaylist();
    list.insert(0, item);
    await savePlaylist(list);
  }

  static Future<void> removeFromPlaylist(String url) async {
    final list = await getPlaylist();
    list.removeWhere((e) => e.url == url);
    await savePlaylist(list);
  }

  // ============ 壁纸配置 ============
  static Future<WallpaperConfig> getWallpaperConfig() async {
    try {
      final data = _prefs.getString(_wallpaperKey);
      if (data == null) {
        return WallpaperConfig(
          type: 'api',
          apiUrl: 'https://api.dujin.org/bing/1920.php',
        );
      }
      return WallpaperConfig.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return WallpaperConfig(
        type: 'api',
        apiUrl: 'https://api.dujin.org/bing/1920.php',
      );
    }
  }

  static Future<void> saveWallpaperConfig(WallpaperConfig config) async {
    try {
      await _prefs.setString(_wallpaperKey, jsonEncode(config.toJson()));
      // 通知所有监听者刷新壁纸
      WallpaperNotifier().refresh();
    } catch (_) {}
  }

  // ============ 历史记录 ============
  static Future<List<VideoItem>> getHistory() async {
    try {
      final data = _prefs.getString(_historyKey);
      if (data == null) return [];
      final list = jsonDecode(data) as List;
      return list.map((e) => VideoItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addToHistory(VideoItem item) async {
    try {
      final list = await getHistory();
      list.removeWhere((e) => e.url == item.url);
      list.insert(0, item);
      if (list.length > 50) list.removeRange(50, list.length);
      await _prefs.setString(_historyKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> clearHistory() async {
    try {
      await _prefs.remove(_historyKey);
    } catch (_) {}
  }

  // ============ 音乐收藏 ============
  static Future<List<SongItem>> getMusicFavorites() async {
    try {
      final data = _prefs.getString(_musicFavKey);
      if (data == null) return [];
      final list = jsonDecode(data) as List;
      return list.map((e) => SongItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addMusicFavorite(SongItem song) async {
    try {
      final list = await getMusicFavorites();
      list.removeWhere((e) => e.id == song.id);
      list.insert(0, song);
      await _prefs.setString(_musicFavKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> removeMusicFavorite(int id) async {
    try {
      final list = await getMusicFavorites();
      list.removeWhere((e) => e.id == id);
      await _prefs.setString(_musicFavKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<bool> isMusicFavorite(int id) async {
    final list = await getMusicFavorites();
    return list.any((e) => e.id == id);
  }

  // ============ Lolicon 配置 ============
  static Future<LoliconParams> getLoliconConfig() async {
    try {
      final data = _prefs.getString(_loliconConfigKey);
      if (data == null) return LoliconParams();
      return LoliconParams.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return LoliconParams();
    }
  }

  static Future<void> saveLoliconConfig(LoliconParams params) async {
    try {
      await _prefs.setString(_loliconConfigKey, jsonEncode(params.toJson()));
    } catch (_) {}
  }

  // ============ 自定义 API 配置 ============
  static const _customApisKey = 'custom_image_apis';

  static Future<List<CustomImageAPI>> getCustomImageAPIs() async {
    try {
      final data = _prefs.getString(_customApisKey);
      if (data == null) return [];
      final list = jsonDecode(data) as List;
      return list.map((e) => CustomImageAPI.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomImageAPIs(List<CustomImageAPI> apis) async {
    try {
      final data = jsonEncode(apis.map((e) => e.toJson()).toList());
      await _prefs.setString(_customApisKey, data);
    } catch (_) {}
  }

  static Future<void> addCustomImageAPI(CustomImageAPI api) async {
    final list = await getCustomImageAPIs();
    list.add(api);
    await saveCustomImageAPIs(list);
  }

  static Future<void> updateCustomImageAPI(int index, CustomImageAPI api) async {
    final list = await getCustomImageAPIs();
    if (index >= 0 && index < list.length) {
      list[index] = api;
      await saveCustomImageAPIs(list);
    }
  }

  static Future<void> removeCustomImageAPI(int index) async {
    final list = await getCustomImageAPIs();
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await saveCustomImageAPIs(list);
    }
  }

  // ============ 图片页面最后使用的 Tab 记录 ============
  static const _imageTabKey = 'image_tab_index';

  static Future<int> getImageTabIndex() async {
    return _prefs.getInt(_imageTabKey) ?? 0;
  }

  static Future<void> saveImageTabIndex(int index) async {
    await _prefs.setInt(_imageTabKey, index);
  }

  // ============ 图片缓存（用于离线浏览） ============
  static const _imageCacheKey = 'image_cache';

  static Future<List<ImageResult>> getImageCache() async {
    try {
      final data = _prefs.getString(_imageCacheKey);
      if (data == null) return [];
      final list = jsonDecode(data) as List;
      return list.map((e) => ImageResult.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveImageCache(List<ImageResult> images) async {
    try {
      final data = jsonEncode(images.map((e) => e.toJson()).toList());
      await _prefs.setString(_imageCacheKey, data);
    } catch (_) {}
  }
}

// API每日图片服务 - 多源自动切换
class DailyImageService {
  static Future<String?> getDailyImage({String? customApiUrl, int timeoutSeconds = 5}) async {
    final List<String> sources = [];

    if (customApiUrl != null && customApiUrl.isNotEmpty) {
      sources.add(customApiUrl);
    }

    sources.addAll([
      'https://api.dujin.org/bing/1920.php',
      'https://api.dujin.org/bing/1366.php',
      'https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1',
      'https://picsum.photos/1920/1080',
    ]);

    for (final source in sources) {
      try {
        final response = await http.get(Uri.parse(source)).timeout(
          Duration(seconds: timeoutSeconds),
        );

        if (response.statusCode == 200) {
          if (source.contains('bing.com')) {
            final data = jsonDecode(response.body);
            final images = data['images'] as List;
            if (images.isNotEmpty) {
              return 'https://www.bing.com${images[0]['url']}';
            }
          } else {
            return source;
          }
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}