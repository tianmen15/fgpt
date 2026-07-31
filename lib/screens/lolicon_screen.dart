import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../services/lolicon_service.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import '../widgets/wallpaper_scaffold.dart';

class LoliconScreen extends StatefulWidget {
  const LoliconScreen({super.key});

  @override
  State<LoliconScreen> createState() => _LoliconScreenState();
}

class _LoliconScreenState extends State<LoliconScreen> with TickerProviderStateMixin {
  LoliconParams _params = LoliconParams();
  List<LoliconImage> _images = [];
  bool _isLoading = false;
  bool _isGridView = true;
  int _selectedImageIndex = -1;
  late AnimationController _animCtrl;
  late AnimationController _refreshCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _flashCtrl;
  late AnimationController _staggerCtrl;

  final _uidController = TextEditingController();
  final _keywordController = TextEditingController();
  final _tagController = TextEditingController();
  final _dateAfterController = TextEditingController();
  final _dateBeforeController = TextEditingController();

  final List<String> _sizeOptions = ['original', 'regular', 'small', 'thumb', 'mini'];
  final List<String> _r18Options = ['非R18', 'R18', '混合'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _refreshCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _shimmerCtrl.repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseCtrl.repeat(reverse: true);
    _flashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _staggerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _staggerCtrl.repeat(reverse: true);
    _loadConfig();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _refreshCtrl.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _flashCtrl.dispose();
    _staggerCtrl.dispose();
    _uidController.dispose();
    _keywordController.dispose();
    _tagController.dispose();
    _dateAfterController.dispose();
    _dateBeforeController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await StorageService.getLoliconConfig();
    setState(() {
      _params = config;
      _uidController.text = config.uid;
      _keywordController.text = config.keyword;
      _tagController.text = config.tag.join('|');
      _dateAfterController.text = config.dateAfter;
      _dateBeforeController.text = config.dateBefore;
    });
  }

  Future<void> _saveConfig() async {
    await StorageService.saveLoliconConfig(_params);
  }

  Future<void> _fetchImages() async {
    _refreshCtrl.reset();
    _refreshCtrl.forward();
    setState(() { _isLoading = true; _images = []; _selectedImageIndex = -1; });
    _animCtrl.reset();
    final images = await LoliconService.getImages(params: _params);
    if (mounted) {
      setState(() {
        _images = images;
        _isLoading = false;
      });
      _animCtrl.forward();
      if (images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未获取到图片，请调整参数重试'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _setAsWallpaper(LoliconImage image) {
    final url = image.urls[_params.size] ?? image.urls['regular'] ?? '';
    if (url.isNotEmpty) {
      _flashCtrl.reset();
      _flashCtrl.forward();
      StorageService.saveWallpaperConfig(WallpaperConfig(type: 'url', imageUrl: url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已设为壁纸'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
      );
    }
  }

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
                Color.lerp(Colors.white, Colors.pinkAccent, _pulseCtrl.value)!,
                Color.lerp(Colors.pinkAccent, Colors.white, _pulseCtrl.value)!,
              ],
            ).createShader(bounds),
            child: child,
          ),
          child: const Text('随机图片', style: TextStyle(color: Colors.white)),
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
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
            tooltip: '参数设置',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildParamBar(),
                const SizedBox(height: 8),
                Expanded(child: _isLoading ? _buildLoading() : _images.isEmpty ? _buildEmpty() : _buildImageGrid()),
              ],
            ),
            // 闪光效果
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

  Widget _buildParamBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _params.keyword.isNotEmpty ? '关键词: ${_params.keyword}' : '随机获取',
                key: ValueKey(_params.keyword),
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _refreshCtrl,
            builder: (_, child) => Transform.rotate(
              angle: _refreshCtrl.value * 6.28318,
              child: child,
            ),
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _fetchImages,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('获取图片'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4 + _pulseCtrl.value * 2,
                    shadowColor: Colors.cyanAccent.withOpacity(0.2 + _pulseCtrl.value * 0.15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图片骨架加载动画
          SizedBox(
            width: 200,
            height: 280,
            child: AnimatedBuilder(
              animation: _shimmerCtrl,
              builder: (_, __) {
                return Container(
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
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('正在获取图片...', style: TextStyle(color: Colors.white54)),
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
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.05 + _pulseCtrl.value * 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: Icon(Icons.image_search, size: 48, color: Colors.cyanAccent.withOpacity(0.5)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('点击获取随机图片', style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('点击右上角设置图标调整参数', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    if (_isGridView) {
      return FadeTransition(
        opacity: _animCtrl,
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _images.length,
          itemBuilder: (ctx, i) => _buildImageCard(i),
        ),
      );
    }

    return FadeTransition(
      opacity: _animCtrl,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _images.length,
        itemBuilder: (ctx, i) => _buildImageListItem(i),
      ),
    );
  }

  Widget _buildImageCard(int index) {
    final image = _images[index];
    final url = image.urls[_params.size] ?? image.urls['regular'] ?? '';
    final isSelected = _selectedImageIndex == index;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 100),
      curve: Curves.easeOut,
      builder: (_, v, __) {
        final staggerOffset = (index % 2 == 0) 
            ? math.sin((_staggerCtrl.value + index * 0.3) * 6.28318) * 5
            : math.cos((_staggerCtrl.value + index * 0.3) * 6.28318) * 5;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - v) + staggerOffset),
            child: Transform(
              transform: Matrix4.rotationY((1 - v) * 0.6),
              alignment: Alignment.center,
              child: Card(
                color: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? BorderSide(
                          color: Color.lerp(Colors.cyanAccent, Colors.pinkAccent, _pulseCtrl.value)!,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                clipBehavior: Clip.antiAlias,
                elevation: isSelected ? 8 : (v * 4),
                child: InkWell(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  onLongPress: () => _setAsWallpaper(image),
                  splashColor: Colors.cyanAccent.withOpacity(0.3),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (url.isNotEmpty)
                        Hero(
                          tag: 'lolicon_${image.pid}',
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: const Color(0xFF2a2a4a)),
                            errorWidget: (_, __, ___) => Container(color: const Color(0xFF2a2a4a), child: const Icon(Icons.broken_image, color: Colors.white38)),
                          ),
                        ),
                      // 选中时的覆盖层
                      if (isSelected)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.cyanAccent.withOpacity(0.1),
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
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
                              Text(image.title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(image.author, style: const TextStyle(color: Colors.white54, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                      if (image.r18)
                        Positioned(
                          top: 4, right: 4,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            builder: (_, sv, __) => Transform.scale(
                              scale: sv,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 4),
                                  ],
                                ),
                                child: const Text('R18', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                      if (image.aiType == 2)
                        Positioned(
                          top: 4, left: 4,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            builder: (_, sv, __) => Transform.scale(
                              scale: sv,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 4),
                                  ],
                                ),
                                child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            ),
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
    final url = image.urls[_params.size] ?? image.urls['regular'] ?? '';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 100),
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
                splashColor: Colors.cyanAccent.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: url.isNotEmpty
                              ? Hero(
                                  tag: 'lolicon_${image.pid}',
                                  child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, placeholder: (_, __) => Container(color: const Color(0xFF2a2a4a))))
                              : Container(color: const Color(0xFF2a2a4a), child: const Icon(Icons.broken_image, color: Colors.white38)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(image.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('作者: ${image.author}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: image.tags.take(3).map((t) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
                                ),
                                child: Text(t, style: const TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        color: const Color(0xFF1e1e3a),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (v) {
                          if (v == 'wallpaper') _setAsWallpaper(image);
                          if (v == 'detail') _showImageDetail(image);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'detail', child: Text('查看详情', style: TextStyle(color: Colors.white))),
                          const PopupMenuItem(value: 'wallpaper', child: Text('设为壁纸', style: TextStyle(color: Colors.white))),
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

  void _showImageDetail(LoliconImage image) {
    final url = image.urls['original'] ?? image.urls['regular'] ?? '';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const SizedBox(
                              height: 300,
                              child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                            ),
                          )
                        : const SizedBox(height: 100),
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
                      onPressed: () => Navigator.pop(ctx),
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
                    Text(image.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('PID: ${image.pid} | 作者: ${image.author}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: image.tags.map((t) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Chip(
                          label: Text(t, style: const TextStyle(color: Colors.white, fontSize: 10)),
                          backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (_, sv, __) => Transform.scale(
                        scale: sv,
                        child: ElevatedButton.icon(
                          onPressed: () { _setAsWallpaper(image); Navigator.pop(ctx); },
                          icon: const Icon(Icons.wallpaper, size: 18),
                          label: const Text('设为壁纸'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            elevation: 4,
                            shadowColor: Colors.cyanAccent.withOpacity(0.3),
                          ),
                        ),
                      ),
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

  void _showSettingsDialog() {
    int tempR18 = _params.r18;
    String tempSize = _params.size;
    int tempNum = _params.num;
    bool tempDsc = _params.dsc;
    bool tempExcludeAI = _params.excludeAI;

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
                const Text('参数设置', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSettingRow('内容分级', DropdownButton<int>(
                    value: tempR18,
                    dropdownColor: const Color(0xFF2a2a4a),
                    style: const TextStyle(color: Colors.white),
                    items: _r18Options.asMap().entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (v) => setDialogState(() => tempR18 = v!),
                  )),
                  _buildSettingRow('获取数量', Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.cyanAccent),
                        onPressed: () => setDialogState(() { if (tempNum > 1) tempNum--; }),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Text('$tempNum', key: ValueKey(tempNum), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.cyanAccent),
                        onPressed: () => setDialogState(() { if (tempNum < 20) tempNum++; }),
                      ),
                    ],
                  )),
                  _buildSettingRow('图片尺寸', DropdownButton<String>(
                    value: tempSize,
                    dropdownColor: const Color(0xFF2a2a4a),
                    style: const TextStyle(color: Colors.white),
                    items: _sizeOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setDialogState(() => tempSize = v!),
                  )),
                  _buildSettingRow('关键词', SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _keywordController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(hintText: '搜索关键词', hintStyle: TextStyle(color: Colors.white38), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  )),
                  _buildSettingRow('标签', SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _tagController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(hintText: '用|分隔', hintStyle: TextStyle(color: Colors.white38), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  )),
                  _buildSettingRow('指定UID', SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _uidController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(hintText: 'Pixiv UID', hintStyle: TextStyle(color: Colors.white38), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  )),
                  _buildSettingRow('起始日期', SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _dateAfterController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(hintText: '如 2024-01-01', hintStyle: TextStyle(color: Colors.white38), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  )),
                  _buildSettingRow('结束日期', SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _dateBeforeController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(hintText: '如 2024-12-31', hintStyle: TextStyle(color: Colors.white38), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  )),
                  SwitchListTile(
                    title: const Text('降序排列', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: tempDsc,
                    activeColor: Colors.cyanAccent,
                    dense: true,
                    onChanged: (v) => setDialogState(() => tempDsc = v),
                  ),
                  SwitchListTile(
                    title: const Text('排除AI作品', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: tempExcludeAI,
                    activeColor: Colors.cyanAccent,
                    dense: true,
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
                    _params = LoliconParams(
                      r18: tempR18, num: tempNum, uid: _uidController.text.trim(),
                      keyword: _keywordController.text.trim(), tag: _tagController.text.trim().isNotEmpty ? _tagController.text.trim().split('|') : [],
                      size: tempSize, dateAfter: _dateAfterController.text.trim(), dateBefore: _dateBeforeController.text.trim(),
                      dsc: tempDsc, excludeAI: tempExcludeAI,
                    );
                  });
                  _saveConfig();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                child: const Text('保存'),
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
}