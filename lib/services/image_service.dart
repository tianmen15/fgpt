import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ImageService {
  static const _loliconBaseUrl = 'https://api.lolicon.app/setu/v2';
  static const _picsumBaseUrl = 'https://picsum.photos/v2/list';
  static const _unsplashBaseUrl = 'https://source.unsplash.com/random/800x1200';
  static const _waifuBaseUrl = 'https://api.waifu.pics/sfw/waifu';
  static const _nekosBaseUrl = 'https://api.nekosapi.com/v4/images/random';
  static const _loremflickrBaseUrl = 'https://loremflickr.com';
  static const _thecatapiBaseUrl = 'https://api.thecatapi.com/v1/images/search';

  // ============ Lolicon API ============
  static Future<List<ImageResult>> fetchLolicon({
    LoliconParams? params,
    int page = 1,
    int timeoutSeconds = 10,
  }) async {
    try {
      final p = params ?? LoliconParams();
      final queryParams = <String, String>{
        'r18': p.r18.toString(),
        'num': p.num.toString(),
        'size': p.size,
      };
      if (p.uid.isNotEmpty) queryParams['uid'] = p.uid;
      if (p.keyword.isNotEmpty) queryParams['keyword'] = p.keyword;
      if (p.tag.isNotEmpty) queryParams['tag'] = p.tag.join('|');
      if (p.proxy.isNotEmpty) queryParams['proxy'] = p.proxy;
      if (p.dateAfter.isNotEmpty) queryParams['dateAfter'] = p.dateAfter;
      if (p.dateBefore.isNotEmpty) queryParams['dateBefore'] = p.dateBefore;
      if (p.dsc) queryParams['dsc'] = 'true';
      if (p.excludeAI) queryParams['excludeAI'] = 'true';

      final uri = Uri.parse(_loliconBaseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          final list = data['data'] as List;
          return list.map((e) {
            final img = LoliconImage.fromJson(e as Map<String, dynamic>);
            final url = img.urls[p.size] ?? img.urls['regular'] ?? '';
            return ImageResult(
              id: 'lolicon_${img.pid}',
              imageUrl: url,
              thumbnailUrl: img.urls['thumb'] ?? img.urls['small'] ?? url,
              title: img.title,
              author: img.author,
              source: 'Lolicon',
              tags: img.tags,
              rawData: e,
            );
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  // ============ Picsum Photos API ============
  static Future<List<ImageResult>> fetchPicsum({
    int page = 1,
    int limit = 30,
    int timeoutSeconds = 10,
  }) async {
    try {
      final uri = Uri.parse(_picsumBaseUrl).replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });
      final response = await http.get(uri).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) {
          final map = e as Map<String, dynamic>;
          final id = map['id']?.toString() ?? '';
          final width = (map['width'] as num?)?.toInt() ?? 0;
          final height = (map['height'] as num?)?.toInt() ?? 0;
          return ImageResult(
            id: 'picsum_$id',
            imageUrl: map['download_url'] as String? ?? 'https://picsum.photos/id/$id/$width/$height',
            thumbnailUrl: 'https://picsum.photos/id/$id/300/300',
            title: 'Image by ${map['author'] ?? 'Unknown'}',
            author: map['author'] as String? ?? 'Unknown',
            source: 'Picsum',
            width: width,
            height: height,
            rawData: map,
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // ============ Unsplash API (source.unsplash.com) ============
  static Future<List<ImageResult>> fetchUnsplash({
    int count = 30,
    String query = '',
    int timeoutSeconds = 10,
  }) async {
    try {
      final results = <ImageResult>[];
      for (int i = 0; i < count; i++) {
        final url = query.isNotEmpty
            ? 'https://source.unsplash.com/featured/800x1200/?$query&sig=${math.Random().nextInt(99999)}'
            : 'https://source.unsplash.com/random/800x1200?sig=${math.Random().nextInt(99999)}';
        results.add(ImageResult(
          id: 'unsplash_${DateTime.now().millisecondsSinceEpoch}_$i',
          imageUrl: url,
          thumbnailUrl: 'https://source.unsplash.com/random/300x300?sig=${math.Random().nextInt(99999)}',
          title: query.isNotEmpty ? query : 'Unsplash Random',
          author: 'Unsplash',
          source: 'Unsplash',
        ));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  // ============ Waifu.pics API ============
  static Future<List<ImageResult>> fetchWaifu({
    int count = 30,
    int timeoutSeconds = 10,
  }) async {
    try {
      final results = <ImageResult>[];
      final categories = ['waifu', 'neko', 'shinobu', 'megumin', 'bully', 'cuddle', 'cry', 'hug', 'awoo', 'kiss', 'lick', 'pat', 'smug', 'bonk', 'yeet', 'blush', 'smile', 'wave', 'highfive', 'handhold', 'nom', 'bite', 'glomp', 'slap', 'kill', 'kick', 'happy', 'wink', 'poke', 'dance', 'cringe'];

      for (int i = 0; i < count; i++) {
        final cat = categories[i % categories.length];
        final uri = Uri.parse('https://api.waifu.pics/sfw/$cat');
        final response = await http.get(uri).timeout(Duration(seconds: timeoutSeconds));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final imageUrl = data['url'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            results.add(ImageResult(
              id: 'waifu_${DateTime.now().millisecondsSinceEpoch}_$i',
              imageUrl: imageUrl,
              title: cat,
              author: 'Waifu.pics',
              source: 'Waifu.pics',
              tags: [cat],
              rawData: data,
            ));
          }
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  // ============ Nekos API ============
  static Future<List<ImageResult>> fetchNekos({
    int limit = 30,
    int timeoutSeconds = 10,
  }) async {
    try {
      final uri = Uri.parse(_nekosBaseUrl).replace(queryParameters: {
        'limit': limit.toString(),
      });
      final response = await http.get(uri).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List? ?? [];
        return items.map((e) {
          final map = e as Map<String, dynamic>;
          final id = map['id']?.toString() ?? '';
          final imageUrl = map['sample_url'] as String? ?? map['url'] as String? ?? '';
          final thumbnailUrl = map['thumbnail_url'] as String? ?? imageUrl;
          final tags = (map['tags'] as List?)?.map((t) => t.toString()).toList() ?? [];
          return ImageResult(
            id: 'nekos_$id',
            imageUrl: imageUrl,
            thumbnailUrl: thumbnailUrl,
            title: map['title'] as String? ?? tags.join(', '),
            author: map['artist_name'] as String? ?? 'Nekos',
            source: 'Nekos',
            tags: tags,
            rawData: map,
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // ============ LoremFlickr API ============
  static Future<List<ImageResult>> fetchLoremFlickr({
    int count = 30,
    String keyword = '',
    int timeoutSeconds = 10,
  }) async {
    try {
      final results = <ImageResult>[];
      final categories = ['nature', 'city', 'food', 'people', 'animals', 'abstract', 'night', 'sports', 'cats', 'dogs', 'fashion', 'technics'];
      for (int i = 0; i < count; i++) {
        final cat = keyword.isNotEmpty ? keyword : categories[i % categories.length];
        final url = '$_loremflickrBaseUrl/640/960/$cat?random=${math.Random().nextInt(99999)}';
        results.add(ImageResult(
          id: 'loremflickr_${DateTime.now().millisecondsSinceEpoch}_$i',
          imageUrl: url,
          thumbnailUrl: '$_loremflickrBaseUrl/320/320/$cat?random=${math.Random().nextInt(99999)}',
          title: cat,
          author: 'LoremFlickr',
          source: 'LoremFlickr',
          tags: [cat],
        ));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  // ============ TheCatAPI ============
  static Future<List<ImageResult>> fetchTheCatApi({
    int limit = 30,
    int timeoutSeconds = 10,
  }) async {
    try {
      final results = <ImageResult>[];
      for (int i = 0; i < limit; i++) {
        final uri = Uri.parse(_thecatapiBaseUrl).replace(queryParameters: {
          'limit': '1',
          'size': 'med',
        });
        final response = await http.get(uri, headers: {
          'x-api-key': 'DEMO-API-KEY',
        }).timeout(Duration(seconds: timeoutSeconds));
        if (response.statusCode == 200) {
          final list = jsonDecode(response.body) as List;
          if (list.isNotEmpty) {
            final map = list[0] as Map<String, dynamic>;
            final imageUrl = map['url'] as String? ?? '';
            final id = map['id']?.toString() ?? '';
            final breeds = (map['breeds'] as List?)?.map((b) => (b as Map<String, dynamic>)['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList() ?? [];
            results.add(ImageResult(
              id: 'cat_${id}_$i',
              imageUrl: imageUrl,
              title: breeds.isNotEmpty ? breeds.join(', ') : 'Cat',
              author: 'TheCatAPI',
              source: 'TheCatAPI',
              tags: breeds,
              rawData: map,
            ));
          }
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  // ============ Custom API ============
  static Future<List<ImageResult>> fetchCustom({
    required CustomImageAPI apiConfig,
    Map<String, String> extraParams = const {},
    int timeoutSeconds = 10,
  }) async {
    try {
      final allParams = <String, String>{...apiConfig.defaultParams, ...extraParams};
      final uri = Uri.parse(apiConfig.baseUrl).replace(queryParameters: allParams.isNotEmpty ? allParams : null);
      final response = await http.get(uri).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final body = response.body;
        final decoded = jsonDecode(body);

        List<dynamic> items;
        if (apiConfig.isJsonArray) {
          items = decoded is List ? decoded : [];
        } else {
          final obj = decoded as Map<String, dynamic>;
          final pathValue = _extractJsonPath(obj, apiConfig.responseImagePath);
          if (pathValue is List) {
            items = pathValue;
          } else if (pathValue is String) {
            items = [pathValue];
          } else {
            items = [obj];
          }
        }

        return items.map((item) {
          if (item is String) {
            return ImageResult(
              id: 'custom_${DateTime.now().millisecondsSinceEpoch}_${items.indexOf(item)}',
              imageUrl: item,
              title: apiConfig.name,
              author: 'Custom API',
              source: apiConfig.name,
            );
          }
          final map = item as Map<String, dynamic>;
          String imageUrl = '';
          if (apiConfig.responseImagePath.isNotEmpty) {
            final extracted = _extractJsonPath(map, apiConfig.responseImagePath);
            imageUrl = extracted?.toString() ?? '';
          }
          if (imageUrl.isEmpty) {
            imageUrl = map['url']?.toString() ?? map['image']?.toString() ?? map['src']?.toString() ?? map['link']?.toString() ?? '';
          }
          return ImageResult(
            id: 'custom_${DateTime.now().millisecondsSinceEpoch}_${items.indexOf(item)}',
            imageUrl: imageUrl,
            title: map['title']?.toString() ?? map['name']?.toString() ?? apiConfig.name,
            author: map['author']?.toString() ?? map['artist']?.toString() ?? 'Custom API',
            source: apiConfig.name,
            rawData: map,
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // ============ 统一获取入口 ============
  static Future<List<ImageResult>> fetchImages({
    required ImageApiSource source,
    LoliconParams? loliconParams,
    int page = 1,
    int limit = 30,
    String keyword = '',
    CustomImageAPI? customApi,
    int timeoutSeconds = 10,
  }) async {
    switch (source) {
      case ImageApiSource.lolicon:
        return fetchLolicon(params: loliconParams, page: page, timeoutSeconds: timeoutSeconds);
      case ImageApiSource.picsum:
        return fetchPicsum(page: page, limit: limit, timeoutSeconds: timeoutSeconds);
      case ImageApiSource.unsplash:
        return fetchUnsplash(count: limit, query: keyword, timeoutSeconds: timeoutSeconds);
      case ImageApiSource.waifu:
        return fetchWaifu(count: limit, timeoutSeconds: timeoutSeconds);
      case ImageApiSource.nekos:
        return fetchNekos(limit: limit, timeoutSeconds: timeoutSeconds);
      case ImageApiSource.loremflickr:
        return fetchLoremFlickr(count: limit, keyword: keyword, timeoutSeconds: timeoutSeconds);
      case ImageApiSource.thecatapi:
        return fetchTheCatApi(limit: limit, timeoutSeconds: timeoutSeconds);
      case ImageApiSource.custom:
        if (customApi != null) {
          return fetchCustom(apiConfig: customApi, extraParams: keyword.isNotEmpty ? {'query': keyword, 'q': keyword, 'search': keyword} : {}, timeoutSeconds: timeoutSeconds);
        }
        return [];
    }
  }

  // ============ 辅助：从 JSON 中按路径提取值 ============
  static dynamic _extractJsonPath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return json;
    try {
      final parts = path.split('.');
      dynamic current = json;
      for (final part in parts) {
        if (current is Map<String, dynamic>) {
          current = current[part];
        } else if (current is List) {
          final idx = int.tryParse(part);
          if (idx != null && idx < current.length) {
            current = current[idx];
          } else {
            return null;
          }
        } else {
          return null;
        }
      }
      return current;
    } catch (_) {
      return null;
    }
  }
}

// ============ 兼容旧 LoliconService 的桥接类 ============
class LoliconService {
  static const _baseUrl = 'https://api.lolicon.app/setu/v2';

  static Future<List<LoliconImage>> getImages({
    required LoliconParams params,
    int timeoutSeconds = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'r18': params.r18.toString(),
        'num': params.num.toString(),
        'size': params.size,
      };
      if (params.uid.isNotEmpty) queryParams['uid'] = params.uid;
      if (params.keyword.isNotEmpty) queryParams['keyword'] = params.keyword;
      if (params.tag.isNotEmpty) queryParams['tag'] = params.tag.join('|');
      if (params.proxy.isNotEmpty) queryParams['proxy'] = params.proxy;
      if (params.dateAfter.isNotEmpty) queryParams['dateAfter'] = params.dateAfter;
      if (params.dateBefore.isNotEmpty) queryParams['dateBefore'] = params.dateBefore;
      if (params.dsc) queryParams['dsc'] = 'true';
      if (params.excludeAI) queryParams['excludeAI'] = 'true';

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          final list = data['data'] as List;
          return list.map((e) => LoliconImage.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}