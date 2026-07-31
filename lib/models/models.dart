class VideoItem {
  final String title;
  final String url;
  final bool isLocal;
  final String? localPath;
  final DateTime addedAt;

  VideoItem({
    required this.title,
    required this.url,
    this.isLocal = false,
    this.localPath,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'isLocal': isLocal,
        'localPath': localPath,
        'addedAt': addedAt.toIso8601String(),
      };

  factory VideoItem.fromJson(Map<String, dynamic> json) => VideoItem(
        title: json['title'] as String,
        url: json['url'] as String,
        isLocal: json['isLocal'] as bool? ?? false,
        localPath: json['localPath'] as String?,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}

class WallpaperConfig {
  final String type; // 'local', 'url', 'api'
  final String? localPath;
  final String? imageUrl;
  final String? apiUrl;
  final double opacity;

  WallpaperConfig({
    this.type = 'url',
    this.localPath,
    this.imageUrl,
    this.apiUrl,
    this.opacity = 0.3,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'localPath': localPath,
        'imageUrl': imageUrl,
        'apiUrl': apiUrl,
        'opacity': opacity,
      };

  factory WallpaperConfig.fromJson(Map<String, dynamic> json) => WallpaperConfig(
        type: json['type'] as String? ?? 'url',
        localPath: json['localPath'] as String?,
        imageUrl: json['imageUrl'] as String?,
        apiUrl: json['apiUrl'] as String?,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 0.3,
      );
}

// 音乐相关模型
class SongItem {
  final int id;
  final String song;
  final String singer;
  final String album;
  final String time;
  final String quality;
  final String cover;
  final String interval;
  final String link;
  final String size;
  final String kbps;
  final String url;
  final String? lrc;

  SongItem({
    required this.id,
    required this.song,
    required this.singer,
    required this.album,
    required this.time,
    required this.quality,
    required this.cover,
    required this.interval,
    required this.link,
    required this.size,
    required this.kbps,
    required this.url,
    this.lrc,
  });

  SongItem copyWith({
    int? id,
    String? song,
    String? singer,
    String? album,
    String? time,
    String? quality,
    String? cover,
    String? interval,
    String? link,
    String? size,
    String? kbps,
    String? url,
    String? lrc,
  }) {
    return SongItem(
      id: id ?? this.id,
      song: song ?? this.song,
      singer: singer ?? this.singer,
      album: album ?? this.album,
      time: time ?? this.time,
      quality: quality ?? this.quality,
      cover: cover ?? this.cover,
      interval: interval ?? this.interval,
      link: link ?? this.link,
      size: size ?? this.size,
      kbps: kbps ?? this.kbps,
      url: url ?? this.url,
      lrc: lrc ?? this.lrc,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'song': song,
        'singer': singer,
        'album': album,
        'time': time,
        'quality': quality,
        'cover': cover,
        'interval': interval,
        'link': link,
        'size': size,
        'kbps': kbps,
        'url': url,
        'lrc': lrc,
      };

  factory SongItem.fromJson(Map<String, dynamic> json) => SongItem(
        id: json['id'] as int,
        song: json['song'] as String? ?? '',
        singer: json['singer'] as String? ?? '',
        album: json['album'] as String? ?? '',
        time: json['time'] as String? ?? '',
        quality: json['quality'] as String? ?? '',
        cover: json['cover'] as String? ?? '',
        interval: json['interval'] as String? ?? '',
        link: json['link'] as String? ?? '',
        size: json['size'] as String? ?? '',
        kbps: json['kbps'] as String? ?? '',
        url: json['url'] as String? ?? '',
        lrc: json['lrc'] as String?,
      );

  /// 从新API /song/url/v1 响应解析播放URL
  /// 响应格式: {"code":200, "data":[{"id":xxx, "url":"...", "level":"exhigh", "time":xxx, "type":"...", "size":xxx}]}
  /// 返回歌曲URL，失败返回null
  static String? parseUrlFromNewApi(Map<String, dynamic> data) {
    if (data['code'] != 200) return null;
    final list = data['data'];
    if (list is List && list.isNotEmpty) {
      final item = list[0] as Map<String, dynamic>;
      return item['url'] as String?;
    }
    return null;
  }

  /// 从新API /song/detail 响应解析歌曲详情
  /// 响应格式: {"code":200, "data":{"songs":[{"id":xxx, "name":"...", "ar":[{"name":"..."}], "al":{"name":"...", "picUrl":"..."}, "dt":xxx, ...}]}}
  /// 返回更新后的SongItem（合并了旧数据和新数据），失败返回null
  static SongItem? mergeDetailFromNewApi(Map<String, dynamic> data, SongItem existing) {
    if (data['code'] != 200) return null;
    final songsData = data['data'];
    if (songsData == null) return null;
    final songs = songsData['songs'];
    if (songs is! List || songs.isEmpty) return null;
    final detail = songs[0] as Map<String, dynamic>;

    final name = detail['name'] as String? ?? existing.song;
    final arList = detail['ar'] as List?;
    final singer = (arList != null && arList.isNotEmpty)
        ? (arList.map((a) => (a as Map<String, dynamic>)['name'] as String? ?? '').toList()..removeWhere((e) => e.isEmpty)).join('/')
        : existing.singer;
    final al = detail['al'] as Map<String, dynamic>?;
    final album = al?['name'] as String? ?? existing.album;
    final cover = al?['picUrl'] as String? ?? existing.cover;
    final dt = detail['dt'] as int?; // 毫秒
    final interval = dt != null ? _formatDurationMs(dt) : existing.interval;
    final time = dt != null ? _formatDurationMs(dt) : existing.time;

    return existing.copyWith(
      song: name.isNotEmpty ? name : existing.song,
      singer: singer.isNotEmpty ? singer : existing.singer,
      album: album.isNotEmpty ? album : existing.album,
      cover: cover.isNotEmpty ? cover : existing.cover,
      interval: interval,
      time: time,
    );
  }

  static String _formatDurationMs(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// Lolicon API 参数模型
class LoliconParams {
  int r18; // 0=非R18, 1=R18, 2=混合
  int num; // 获取数量
  String uid; // 指定uid
  String keyword; // 关键词
  List<String> tag; // 标签
  String size; // 图片尺寸: original, regular, small, thumb, mini
  String proxy; // 代理
  String dateAfter; // 起始日期
  String dateBefore; // 结束日期
  bool dsc; // 是否降序
  bool excludeAI; // 排除AI作品

  LoliconParams({
    this.r18 = 0,
    this.num = 1,
    this.uid = '',
    this.keyword = '',
    this.tag = const [],
    this.size = 'regular',
    this.proxy = '',
    this.dateAfter = '',
    this.dateBefore = '',
    this.dsc = false,
    this.excludeAI = false,
  });

  Map<String, dynamic> toJson() => {
        'r18': r18,
        'num': num,
        'uid': uid,
        'keyword': keyword,
        'tag': tag,
        'size': size,
        'proxy': proxy,
        'dateAfter': dateAfter,
        'dateBefore': dateBefore,
        'dsc': dsc,
        'excludeAI': excludeAI,
      };

  factory LoliconParams.fromJson(Map<String, dynamic> json) => LoliconParams(
        r18: (json['r18'] as int?) ?? 0,
        num: (json['num'] as int?) ?? 1,
        uid: json['uid'] as String? ?? '',
        keyword: json['keyword'] as String? ?? '',
        tag: (json['tag'] as List?)?.map((e) => e.toString()).toList() ?? [],
        size: json['size'] as String? ?? 'regular',
        proxy: json['proxy'] as String? ?? '',
        dateAfter: json['dateAfter'] as String? ?? '',
        dateBefore: json['dateBefore'] as String? ?? '',
        dsc: json['dsc'] as bool? ?? false,
        excludeAI: json['excludeAI'] as bool? ?? false,
      );
}

// Lolicon API 返回图片模型
class LoliconImage {
  final int pid;
  final int p;
  final int uid;
  final String title;
  final String author;
  final bool r18;
  final List<String> tags;
  final String ext;
  final int aiType;
  final int uploadDate;
  final Map<String, String> urls;

  LoliconImage({
    required this.pid,
    required this.p,
    required this.uid,
    required this.title,
    required this.author,
    required this.r18,
    required this.tags,
    required this.ext,
    required this.aiType,
    required this.uploadDate,
    required this.urls,
  });

  Map<String, dynamic> toJson() => {
        'pid': pid,
        'p': p,
        'uid': uid,
        'title': title,
        'author': author,
        'r18': r18,
        'tags': tags,
        'ext': ext,
        'aiType': aiType,
        'uploadDate': uploadDate,
        'urls': urls,
      };

  factory LoliconImage.fromJson(Map<String, dynamic> json) => LoliconImage(
        pid: json['pid'] as int,
        p: json['p'] as int,
        uid: json['uid'] as int,
        title: json['title'] as String? ?? '',
        author: json['author'] as String? ?? '',
        r18: json['r18'] as bool? ?? false,
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        ext: json['ext'] as String? ?? '',
        aiType: (json['aiType'] as num?)?.toInt() ?? 0,
        uploadDate: (json['uploadDate'] as num?)?.toInt() ?? 0,
        urls: (json['urls'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
      );
}

// ============ 统一图片源枚举 ============
enum ImageApiSource {
  lolicon,
  picsum,
  unsplash,
  waifu,
  nekos,
  loremflickr,
  thecatapi,
  custom,
}

// ============ 统一图片结果模型 ============
class ImageResult {
  final String id;
  final String imageUrl;
  final String thumbnailUrl;
  final String title;
  final String author;
  final String source;
  final int width;
  final int height;
  final List<String> tags;
  final Map<String, dynamic> rawData;

  ImageResult({
    required this.id,
    required this.imageUrl,
    String? thumbnailUrl,
    this.title = '',
    this.author = '',
    this.source = '',
    this.width = 0,
    this.height = 0,
    this.tags = const [],
    this.rawData = const {},
  }) : thumbnailUrl = thumbnailUrl ?? imageUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'thumbnailUrl': thumbnailUrl,
        'title': title,
        'author': author,
        'source': source,
        'width': width,
        'height': height,
        'tags': tags,
        'rawData': rawData,
      };

  factory ImageResult.fromJson(Map<String, dynamic> json) => ImageResult(
        id: json['id'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        thumbnailUrl: json['thumbnailUrl'] as String?,
        title: json['title'] as String? ?? '',
        author: json['author'] as String? ?? '',
        source: json['source'] as String? ?? '',
        width: (json['width'] as num?)?.toInt() ?? 0,
        height: (json['height'] as num?)?.toInt() ?? 0,
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        rawData: (json['rawData'] as Map<String, dynamic>?) ?? {},
      );
}

// ============ 自定义 API 配置模型 ============
class CustomImageAPI {
  String name;
  String baseUrl;
  Map<String, String> defaultParams;
  String responseImagePath;
  bool isJsonArray;

  CustomImageAPI({
    required this.name,
    required this.baseUrl,
    this.defaultParams = const {},
    this.responseImagePath = '',
    this.isJsonArray = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'baseUrl': baseUrl,
        'defaultParams': defaultParams,
        'responseImagePath': responseImagePath,
        'isJsonArray': isJsonArray,
      };

  factory CustomImageAPI.fromJson(Map<String, dynamic> json) => CustomImageAPI(
        name: json['name'] as String? ?? '',
        baseUrl: json['baseUrl'] as String? ?? '',
        defaultParams: (json['defaultParams'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
        responseImagePath: json['responseImagePath'] as String? ?? '',
        isJsonArray: json['isJsonArray'] as bool? ?? true,
      );
}