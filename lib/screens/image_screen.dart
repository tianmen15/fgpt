import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../services/image_service.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import '../widgets/wallpaper_scaffold.dart';

class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> with TickerProviderStateMixin {
  // 当前选中的图片来源
  ImageApiSource _currentSource = ImageApiSource.lolicon;
  int _currentCustomApiIndex = 0;

  // 图片列表
  List<ImageResult> _images = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isGridView = true;
  int _currentPage = 1;
  bool _hasMore = true;
  int _selectedImageIndex = -1;

  // Lolicon 参数
  LoliconParams _loliconParams = LoliconParams();
  final _loliconKeywordCtrl = TextEditingController();
  final _loliconTagCtrl = TextEditingController();
  final _loliconUidCtrl = TextEditingController();
  final _loliconDateAfterCtrl = TextEditingController();
  final _loliconDateBeforeCtrl = TextEditingController();

  // 搜索关键词
  final _keywordCtrl = TextEditingController();

  // 自定义 API 列表
  List<CustomImageAPI> _customApis = [];

  // 动画控制器
  late AnimationController _animCtrl;
  late AnimationController _refreshCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _flashCtrl;
  late AnimationController _staggerCtrl;
  late AnimationController _tabSwitchCtrl;

  final ScrollController _scrollCtrl = ScrollController();

  final List<String> _loliconSizeOptions = ['original', 'regular', 'small', 'thumb', 'mini'];
  final List<String> _loliconR18Options = ['非R18', 'R18', '混合'];

  // 图片来源映射
  static const Map<ImageApiSource, _SourceInfo> _sourceInfoMap = {
    ImageApiSource.lolicon: _SourceInfo('Lolicon', 'Pixiv 图片', Icons.image_search, Color(0xFFf12711)),
    ImageApiSource.picsum: _SourceInfo('Picsum', 'Lorem Picsum', Icons.landscape, Color(0xFF00b4db)),
    ImageApiSource.unsplash: _SourceInfo('Unsplash', '免费高质量图片', Icons.photo_camera, Color(0xFF000000)),
    ImageApiSource.waifu: _SourceInfo('Waifu.pics', '动漫图片', Icons.favorite, Color(0xFFe91e63)),
    ImageApiSource.nekos: _SourceInfo('Nekos', '猫娘图片', Icons.pets, Color(0xFF9c27b0)),
    ImageApiSource.loremflickr: _SourceInfo('LoremFlickr', '分类图片', Icons.category, Color(0xFFff9800)),
    ImageApiSource.thecatapi: _SourceInfo('TheCatAPI', '猫咪图片', Icons.pets, Color(0xFFff5722)),
    ImageApiSource.custom: _SourceInfo('自定义', '自定义 API', Icons.api, Color(0xFF4caf50)),
  };

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _refreshCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _flashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _staggerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _tabSwitchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _scrollCtrl.addListener(_onScroll);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _loliconParams = await StorageService.getLoliconConfig();
    _loliconKeywordCtrl.text = _loliconParams.keyword;
    _loliconTagCtrl.text = _loliconParams.tag.join('|');
    _loliconUidCtrl.text = _loliconParams.uid;
    _loliconDateAfterCtrl.text = _loliconParams.dateAfter;
    _loliconDateBeforeCtrl.text = _loliconParams.dateBefore;
    _customApis = await StorageService.getCustomImageAPIs();
    final savedTab = await StorageService.getImageTabIndex();
    if (savedTab < ImageApiSource.values.length) {
      _currentSource = ImageApiSource.values[savedTab];
    }
    if (mounted) {
      setState(() {});
      _fetchImages();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _refreshCtrl.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _flashCtrl.dispose();
    _staggerCtrl.dispose();
    _tabSwitchCtrl.dispose();
    _scrollCtrl.dispose();
    _keywordCtrl.dispose();
    _loliconKeywordCtrl.dispose();
    _loliconTagCtrl.dispose();
    _loliconUidCtrl.dispose();
    _loliconDateAfterCtrl.dispose();
    _loliconDateBeforeCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_isLoadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _fetchImages() async {
    _refreshCtrl.reset();
    _refreshCtrl.forward();
    setState(() { _isLoading = true; _images = []; _selectedImageIndex = -1; _currentPage = 1; _hasMore = true; });
    _animCtrl.reset();

    final results = await _doFetch(page: 1);
    if (mounted) {
      setState(() {
        _images = results;
        _isLoading = false;
      });
      _animCtrl.forward();
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未获取到图片，请重试'), backgroundColor: Colors.orange),
        );
      } else {
        _cacheImages(results);
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    _currentPage++;
    final results = await _doFetch(page: _currentPage);
    if (mounted) {
      setState(() {
        _images.addAll(results);
        _isLoadingMore = false;
        if (results.isEmpty) _hasMore = false;
      });
    }
  }

  Future<List<ImageResult>> _doFetch({required int page}) async {
    CustomImageAPI? customApi;
    if (_currentSource == ImageApiSource.custom && _customApis.isNotEmpty && _currentCustomApiIndex < _customApis.length) {
      customApi = _customApis[_currentCustomApiIndex];
    }

    return ImageService.fetchImages(
      source: _currentSource,
      loliconParams: _currentSource == ImageApiSource.lolicon ? _loliconParams : null,
      page: page,
      limit: 30,
      keyword: _keywordCtrl.text.trim(),
      customApi: customApi,
    );
  }

  void _cacheImages(List<ImageResult> images) {
    final limited = images.take(50).toList();
    StorageService.saveImageCache(limited);
  }

  void _switchSource(ImageApiSource source) {
    if (source == _currentSource) return;
    _tabSwitchCtrl.reset();
    _tabSwitchCtrl.forward();
    setState(() {
      _currentSource = source;
      _currentCustomApiIndex = 0;
      _selectedImageIndex = -1;
    });
    StorageService.saveImageTabIndex(ImageApiSource.values.indexOf(source));
    _fetchImages();
  }

  void _setAsWallpaper(ImageResult image) {
    _flashCtrl.reset();
    _flashCtrl.forward();
    StorageService.saveWallpaperConfig(WallpaperConfig(type: 'url', imageUrl: image.imageUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已设为壁纸'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
    );
  }

  Future<void> _downloadImage(ImageResult image) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ext = image.imageUrl.split('.').last.split('?').first;
      final filename = 'image_${DateTime.now().millisecondsSinceEpoch}.${ext.isNotEmpty && ext.length <= 5 ? ext : 'jpg'}';
      final file = File('${dir.path}/$filename');

      final response = await http.get(Uri.parse(image.imageUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('图片已保存到: ${file.path}'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('下载失败'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============ UI 构建 ============

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) => ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Color.lerp(Colors.white, Colors.cyanAccent, _pulseCtrl.value)!,
                Color.lerp(Colors.cyanAccent, Colors.white, _pulseCtrl.value)!,
              ],
            ).createShader(bounds),
            child: child,
          ),
          child: const Text('图片浏览', style: TextStyle(color: Colors.white)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: RotationTransition(turns: Tween<double>(begin: 0.5, end: 0).animate(anim), child: child)),
            child: IconButton(
              key: ValueKey(_isGridView),
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: Colors.white),
              onPressed: () => setState(() => _isGridView = !_isGridView),
              tooltip: _isGridView ? '列表视图' : '网格视图',
            ),
          ),
          if (_currentSource == ImageApiSource.lolicon)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _showLoliconSettings,
              tooltip: 'Lolicon 参数设置',
            ),
          if (_currentSource == ImageApiSource.custom)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showCustomApiForm(),
              tooltip: '添加自定义 API',
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildSourceTabBar(),
                if (_currentSource == ImageApiSource.custom) _buildCustomApiSelector(),
                if (_currentSource == ImageApiSource.unsplash || _currentSource == ImageApiSource.lolicon) _buildSearchBar(),
                const SizedBox(height: 8),
                Expanded(child: _isLoading ? _buildLoading() : _images.isEmpty ? _buildEmpty() : _buildImageBody()),
              ],
            ),
            if (_flashCtrl.isAnimating || _flashCtrl.value > 0)
              AnimatedBuilder(
                animation: _flashCtrl,
                builder: (_, __) => Container(
                  color: Colors.cyanAccent.withOpacity((1 - _flashCtrl.value) * 0.3),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTabBar() {
    final sources = ImageApiSource.values;
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: sources.length,
        itemBuilder: (ctx, i) {
          final source = sources[i];
          final info = _sourceInfoMap[source]!;
          final isSelected = source == _currentSource;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: Duration(milliseconds: 300 + i * 60),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: ChoiceChip(
                  label: Text(info.name, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)),
                  selected: isSelected,
                  selectedColor: info.color.withOpacity(0.6),
                  backgroundColor: Colors.white.withOpacity(0.08),
                  side: BorderSide(
                    color: isSelected ? info.color.withOpacity(0.8) : Colors.white.withOpacity(0.1),
                    width: isSelected ? 1.5 : 1,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (_) => _switchSource(source),
                  avatar: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isSelected
                        ? Icon(info.icon, size: 16, color: Colors.white, key: const ValueKey('sel'))
                        : Icon(info.icon, size: 16, color: Colors.white54, key: const ValueKey('unsel')),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomApiSelector() {
    if (_customApis.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: OutlinedButton.icon(
          onPressed: () => _showCustomApiForm(),
          icon: const Icon(Icons.add, color: Colors.cyanAccent),
          label: const Text('添加自定义 API', style: TextStyle(color: Colors.cyanAccent)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.cyanAccent.withOpacity(0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _customApis.length + 1,
        itemBuilder: (ctx, i) {
          if (i == _customApis.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ActionChip(
                avatar: const Icon(Icons.add, size: 16, color: Colors.cyanAccent),
                label: const Text('添加', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                backgroundColor: Colors.white.withOpacity(0.08),
                side: BorderSide(color: Colors.cyanAccent.withOpacity(0.3)),
                onPressed: () => _showCustomApiForm(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
            );
          }
          final api = _customApis[i];
          final isSelected = i == _currentCustomApiIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onLongPress: () => _showCustomApiForm(editIndex: i),
              child: ChoiceChip(
                label: Text(api.name, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.white70)),
                selected: isSelected,
                selectedColor: const Color(0xFF4caf50).withOpacity(0.5),
                backgroundColor: Colors.white.withOpacity(0.08),
                side: BorderSide(color: isSelected ? Colors.greenAccent.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (_) {
                  setState(() => _currentCustomApiIndex = i);
                  _fetchImages();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _keywordCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: _currentSource == ImageApiSource.lolicon ? '搜索关键词（Lolicon）' : '搜索关键词（Unsplash）',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  suffixIcon: _keywordCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                          onPressed: () { _keywordCtrl.clear(); setState(() {}); },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.cyanAccent, width: 1)),
                ),
                onSubmitted: (_) {
                  if (_currentSource == ImageApiSource.lolicon) {
                    setState(() => _loliconParams = LoliconParams(
                      r18: _loliconParams.r18, num: _loliconParams.num, size: _loliconParams.size,
                      keyword: _keywordCtrl.text.trim(), tag: _loliconParams.tag,
                      uid: _loliconParams.uid, dsc: _loliconParams.dsc, excludeAI: _loliconParams.excludeAI,
                    ));
                    _loliconKeywordCtrl.text = _keywordCtrl.text.trim();
                    StorageService.saveLoliconConfig(_loliconParams);
                  }
                  _fetchImages();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton(
                onPressed: _isLoading ? null : () {
                  if (_currentSource == ImageApiSource.lolicon) {
                    setState(() => _loliconParams = LoliconParams(
                      r18: _loliconParams.r18, num: _loliconParams.num, size: _loliconParams.size,
                      keyword: _keywordCtrl.text.trim(), tag: _loliconParams.tag,
                      uid: _loliconParams.uid, dsc: _loliconParams.dsc, excludeAI: _loliconParams.excludeAI,
                    ));
                    _loliconKeywordCtrl.text = _keywordCtrl.text.trim();
                    StorageService.saveLoliconConfig(_loliconParams);
                  }
                  _fetchImages();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 3,
                ),
                child: const Icon(Icons.search, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBody() {
    return RefreshIndicator(
      color: Colors.cyanAccent,
      onRefresh: _fetchImages,
      child: _isGridView ? _buildGridView() : _buildListView(),
    );
  }

  Widget _buildGridView() {
    return FadeTransition(
      opacity: _animCtrl,
      child: GridView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _images.length + (_isLoadingMore ? 2 : 0),
        itemBuilder: (ctx, i) {
          if (i >= _images.length) return _buildGridLoadingShimmer();
          return _buildImageCard(i);
        },
      ),
    );
  }

  Widget _buildListView() {
    return FadeTransition(
      opacity: _animCtrl,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(8),
        itemCount: _images.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i >= _images.length) return _buildListLoadingIndicator();
          return _buildImageListItem(i);
        },
      ),
    );
  }

  Widget _buildImageCard(int index) {
    final image = _images[index];
    final isSelected = _selectedImageIndex == index;
    final info = _sourceInfoMap[_currentSource]!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOut,
      builder: (_, v, __) {
        final staggerOffset = (index % 2 == 0)
            ? math.sin((_staggerCtrl.value + index * 0.3) * 6.28318) * 4
            : math.cos((_staggerCtrl.value + index * 0.3) * 6.28318) * 4;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - v) + staggerOffset),
            child: Transform(
              transform: Matrix4.rotationY((1 - v) * 0.5),
              alignment: Alignment.center,
              child: Card(
                color: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? BorderSide(color: Color.lerp(Colors.cyanAccent, info.color, _pulseCtrl.value)!, width: 2)
                      : BorderSide.none,
                ),
                clipBehavior: Clip.antiAlias,
                elevation: isSelected ? 8 : (v * 4),
                child: InkWell(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  onLongPress: () => _showImageDetail(image),
                  splashColor: info.color.withOpacity(0.3),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'img_${image.id}',
                        child: CachedNetworkImage(
                          imageUrl: image.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: const Color(0xFF2a2a4a)),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF2a2a4a),
                            child: const Icon(Icons.broken_image, color: Colors.white38),
                          ),
                        ),
                      ),
                      if (isSelected)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [info.color.withOpacity(0.15), Colors.transparent, Colors.black.withOpacity(0.4)],
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.8)]),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (image.title.isNotEmpty)
                                Text(image.title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (image.author.isNotEmpty)
                                Text(image.author, style: const TextStyle(color: Colors.white54, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4, right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: info.color.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(info.name, style: const TextStyle(color: Colors.white, fontSize: 9)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageListItem(int index) {
    final image = _images[index];
    final info = _sourceInfoMap[_currentSource]!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOut,
      builder: (_, v, __) {
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - v)),
            child: Card(
              color: Colors.white.withOpacity(0.08),
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: v * 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showImageDetail(image),
                onLongPress: () => _setAsWallpaper(image),
                splashColor: info.color.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 100, height: 100,
                          child: Hero(
                            tag: 'img_${image.id}',
                            child: CachedNetworkImage(
                              imageUrl: image.thumbnailUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: const Color(0xFF2a2a4a)),
                              errorWidget: (_, __, ___) => Container(color: const Color(0xFF2a2a4a), child: const Icon(Icons.broken_image, color: Colors.white38)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (image.title.isNotEmpty)
                              Text(image.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (image.author.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('作者: ${image.author}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: info.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(info.name, style: TextStyle(color: info.color, fontSize: 10)),
                                ),
                                if (image.width > 0 && image.height > 0) ...[
                                  const SizedBox(width: 6),
                                  Text('${image.width}x${image.height}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                ],
                              ],
                            ),
                            if (image.tags.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4, runSpacing: 2,
                                children: image.tags.take(4).map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
                                  ),
                                  child: Text(t, style: const TextStyle(color: Colors.cyanAccent, fontSize: 9)),
                                )).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        color: const Color(0xFF1e1e3a),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (v) {
                          if (v == 'wallpaper') _setAsWallpaper(image);
                          if (v == 'detail') _showImageDetail(image);
                          if (v == 'download') _downloadImage(image);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'detail', child: Text('查看详情', style: TextStyle(color: Colors.white))),
                          const PopupMenuItem(value: 'wallpaper', child: Text('设为壁纸', style: TextStyle(color: Colors.white))),
                          const PopupMenuItem(value: 'download', child: Text('下载图片', style: TextStyle(color: Colors.white))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridLoadingShimmer() {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) => Card(
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _shimmerCtrl.value * 2, 0),
              end: Alignment(_shimmerCtrl.value * 2, 0),
              colors: [
                Colors.white.withOpacity(0.03),
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.03),
              ],
            ),
          ),
          child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))),
        ),
      ),
    );
  }

  Widget _buildListLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200, height: 280,
            child: AnimatedBuilder(
              animation: _shimmerCtrl,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + _shimmerCtrl.value * 2, 0),
                    end: Alignment(_shimmerCtrl.value * 2, 0),
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('正在加载图片...', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(seconds: 2),
            curve: Curves.elasticOut,
            builder: (_, v, __) => Transform.scale(
              scale: v,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, child) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyanAccent.withOpacity(0.05 + _pulseCtrl.value * 0.05),
                    boxShadow: [
                      BoxShadow(color: Colors.cyanAccent.withOpacity(0.05 + _pulseCtrl.value * 0.05), blurRadius: 10),
                    ],
                  ),
                  child: child,
                ),
                child: Icon(Icons.image_search, size: 48, color: Colors.cyanAccent.withOpacity(0.5)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('点击顶部标签切换图片源', style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _refreshCtrl,
            builder: (_, child) => Transform.rotate(angle: _refreshCtrl.value * 6.28318, child: child),
            child: const Icon(Icons.refresh, color: Colors.cyanAccent, size: 32),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _fetchImages,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Transform.scale(scale: 1.0 + _pulseCtrl.value * 0.1, child: child),
              child: const Text('点击刷新', style: TextStyle(color: Colors.cyanAccent)),
            ),
          ),
        ],
      ),
    );
  }

  // ============ 图片详情弹窗 ============

  void _showImageDetail(ImageResult image) {
    showDialog(
      context: context,
      builder: (ctx) => _ImageDetailDialog(
        image: image,
        onWallpaper: () { _setAsWallpaper(image); Navigator.pop(ctx); },
        onDownload: () => _downloadImage(image),
      ),
    );
  }

  // ============ Lolicon 参数设置 ============

  void _showLoliconSettings() {
    int tempR18 = _loliconParams.r18;
    String tempSize = _loliconParams.size;
    int tempNum = _loliconParams.num;
    bool tempDsc = _loliconParams.dsc;
    bool tempExcludeAI = _loliconParams.excludeAI;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: AlertDialog(
            backgroundColor: const Color(0xFF1e1e3a),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) => Transform.rotate(angle: _pulseCtrl.value * 0.2, child: child),
                  child: const Icon(Icons.settings, color: Colors.cyanAccent),
                ),
                const SizedBox(width: 8),
                const Text('Lolicon 参数设置', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSettingRow('内容分级',
                    DropdownButton<int>(
                      value: tempR18,
                      dropdownColor: const Color(0xFF2a2a4a),
                      style: const TextStyle(color: Colors.white),
                      items: _loliconR18Options.asMap().entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setDialogState(() => tempR18 = v!),
                    ),
                  ),
                  _buildSettingRow('获取数量',
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.remove, color: Colors.cyanAccent), onPressed: () => setDialogState(() { if (tempNum > 1) tempNum--; })),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: Text('$tempNum', key: ValueKey(tempNum), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(icon: const Icon(Icons.add, color: Colors.cyanAccent), onPressed: () => setDialogState(() { if (tempNum < 20) tempNum++; })),
                      ],
                    ),
                  ),
                  _buildSettingRow('图片尺寸',
                    DropdownButton<String>(
                      value: tempSize,
                      dropdownColor: const Color(0xFF2a2a4a),
                      style: const TextStyle(color: Colors.white),
                      items: _loliconSizeOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setDialogState(() => tempSize = v!),
                    ),
                  ),
                  _buildSettingRow('关键词',
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _loliconKeywordCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(hintText: '搜索关键词', hintStyle: TextStyle(color: Colors.white38), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                  ),
                  _buildSettingRow('标签',
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _loliconTagCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(hintText: '用|分隔', hintStyle: TextStyle(color: Colors.white38), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                  ),
                  _buildSettingRow('指定UID',
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _loliconUidCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(hintText: 'Pixiv UID', hintStyle: TextStyle(color: Colors.white38), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                  ),
                  _buildSettingRow('起始日期',
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _loliconDateAfterCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(hintText: '如 2024-01-01', hintStyle: TextStyle(color: Colors.white38), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                  ),
                  _buildSettingRow('结束日期',
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _loliconDateBeforeCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(hintText: '如 2024-12-31', hintStyle: TextStyle(color: Colors.white38), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('降序排列', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: tempDsc, activeColor: Colors.cyanAccent, dense: true,
                    onChanged: (v) => setDialogState(() => tempDsc = v),
                  ),
                  SwitchListTile(
                    title: const Text('排除AI作品', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: tempExcludeAI, activeColor: Colors.cyanAccent, dense: true,
                    onChanged: (v) => setDialogState(() => tempExcludeAI = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loliconParams = LoliconParams(
                      r18: tempR18, num: tempNum, uid: _loliconUidCtrl.text.trim(),
                      keyword: _loliconKeywordCtrl.text.trim(),
                      tag: _loliconTagCtrl.text.trim().isNotEmpty ? _loliconTagCtrl.text.trim().split('|') : [],
                      size: tempSize, dateAfter: _loliconDateAfterCtrl.text.trim(), dateBefore: _loliconDateBeforeCtrl.text.trim(),
                      dsc: tempDsc, excludeAI: tempExcludeAI,
                    );
                    _keywordCtrl.text = _loliconKeywordCtrl.text.trim();
                  });
                  StorageService.saveLoliconConfig(_loliconParams);
                  Navigator.pop(ctx);
                  _fetchImages();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                child: const Text('保存并刷新'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          child,
        ],
      ),
    );
  }

  // ============ 自定义 API 表单 ============

  void _showCustomApiForm({int? editIndex}) {
    final isEdit = editIndex != null;
    final api = isEdit ? _customApis[editIndex] : CustomImageAPI(name: '', baseUrl: '');

    final nameCtrl = TextEditingController(text: api.name);
    final urlCtrl = TextEditingController(text: api.baseUrl);
    final pathCtrl = TextEditingController(text: api.responseImagePath);
    bool isJsonArr = api.isJsonArray;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: AlertDialog(
            backgroundColor: const Color(0xFF1e1e3a),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(isEdit ? '编辑 API' : '添加自定义 API', style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'API 名称', labelStyle: TextStyle(color: Colors.white54),
                      hintText: '如: My API', hintStyle: TextStyle(color: Colors.white38),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'API URL', labelStyle: TextStyle(color: Colors.white54),
                      hintText: 'https://api.example.com/images', hintStyle: TextStyle(color: Colors.white38),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pathCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: '返回数据中图片URL的JSON路径', labelStyle: TextStyle(color: Colors.white54),
                      hintText: '如: data.0.url (留空自动检测)', hintStyle: TextStyle(color: Colors.white38),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('JSON 数组格式', style: TextStyle(color: Colors.white, fontSize: 13)),
                    subtitle: const Text('API返回的是数组还是对象', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    value: isJsonArr,
                    activeColor: Colors.cyanAccent,
                    dense: true,
                    onChanged: (v) => setDialogState(() => isJsonArr = v),
                  ),
                  if (isEdit)
                    TextButton(
                      onPressed: () {
                        StorageService.removeCustomImageAPI(editIndex);
                        Navigator.pop(ctx);
                        setState(() {
                          _customApis.removeAt(editIndex);
                          if (_currentCustomApiIndex >= _customApis.length) _currentCustomApiIndex = 0;
                        });
                        if (_currentSource == ImageApiSource.custom && _customApis.isNotEmpty) _fetchImages();
                      },
                      child: const Text('删除此 API', style: TextStyle(color: Colors.redAccent)),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final url = urlCtrl.text.trim();
                  if (name.isEmpty || url.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('名称和URL不能为空'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  final newApi = CustomImageAPI(
                    name: name, baseUrl: url,
                    responseImagePath: pathCtrl.text.trim(),
                    isJsonArray: isJsonArr,
                  );
                  if (isEdit) {
                    await StorageService.updateCustomImageAPI(editIndex, newApi);
                  } else {
                    await StorageService.addCustomImageAPI(newApi);
                  }
                  Navigator.pop(ctx);
                  final apis = await StorageService.getCustomImageAPIs();
                  setState(() {
                    _customApis = apis;
                    if (!isEdit) _currentCustomApiIndex = apis.length - 1;
                  });
                  if (_currentSource == ImageApiSource.custom) _fetchImages();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                child: Text(isEdit ? '保存' : '添加'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ 图片来源信息类 ============
class _SourceInfo {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _SourceInfo(this.name, this.subtitle, this.icon, this.color);
}

// ============ 图片详情弹窗 ============
class _ImageDetailDialog extends StatelessWidget {
  final ImageResult image;
  final VoidCallback onWallpaper;
  final VoidCallback onDownload;

  const _ImageDetailDialog({
    required this.image,
    required this.onWallpaper,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Hero(
                      tag: 'img_${image.id}',
                      child: CachedNetworkImage(
                        imageUrl: image.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                        ),
                        errorWidget: (_, __, ___) => const SizedBox(
                          height: 200,
                          child: Center(child: Icon(Icons.broken_image, color: Colors.white38, size: 48)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1e1e3a),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    if (image.title.isNotEmpty)
                      Text(image.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    if (image.author.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('作者: ${image.author} | 来源: ${image.source}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
                    if (image.width > 0 && image.height > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('尺寸: ${image.width} x ${image.height}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
                    if (image.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4, runSpacing: 4,
                        children: image.tags.map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 10)),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                          builder: (_, sv, __) => Transform.scale(
                            scale: sv,
                            child: ElevatedButton.icon(
                              onPressed: onWallpaper,
                              icon: const Icon(Icons.wallpaper, size: 18),
                              label: const Text('设为壁纸'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                                foregroundColor: Colors.black,
                                elevation: 4,
                                shadowColor: Colors.cyanAccent.withOpacity(0.3),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.elasticOut,
                          builder: (_, sv, __) => Transform.scale(
                            scale: sv,
                            child: ElevatedButton.icon(
                              onPressed: onDownload,
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('下载'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purpleAccent,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: Colors.purpleAccent.withOpacity(0.3),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}