import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:math' as math;
import '../services/storage_service.dart';
import '../models/models.dart';

class WallpaperScreen extends StatefulWidget {
  const WallpaperScreen({super.key});

  @override
  State<WallpaperScreen> createState() => _WallpaperScreenState();
}

class _WallpaperScreenState extends State<WallpaperScreen> with TickerProviderStateMixin {
  WallpaperConfig _config = WallpaperConfig(type: 'api', apiUrl: 'https://api.dujin.org/bing/1920.php');
  final _urlController = TextEditingController();
  final _apiUrlController = TextEditingController();
  final _picker = ImagePicker();
  bool _loading = true;
  String? _previewUrl;
  bool _isFetchingApi = false;
  late AnimationController _kenBurnsCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _gradientCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _flipCtrl;
  late AnimationController _waveGradientCtrl;

  @override
  void initState() {
    super.initState();
    _kenBurnsCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _kenBurnsCtrl.repeat(reverse: true);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _glowCtrl.repeat(reverse: true);
    _gradientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _gradientCtrl.repeat(reverse: true);
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _particleCtrl.repeat();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _waveGradientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _waveGradientCtrl.repeat(reverse: true);
    _loadConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiUrlController.dispose();
    _kenBurnsCtrl.dispose();
    _glowCtrl.dispose();
    _gradientCtrl.dispose();
    _particleCtrl.dispose();
    _flipCtrl.dispose();
    _waveGradientCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await StorageService.getWallpaperConfig();
    setState(() {
      _config = config;
      _urlController.text = config.imageUrl ?? '';
      _apiUrlController.text = config.apiUrl ?? 'https://api.dujin.org/bing/1920.php';
      _loading = false;
    });
  }

  Future<void> _saveConfig() async {
    await StorageService.saveWallpaperConfig(_config);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [Icon(Icons.check_circle, color: Colors.greenAccent), SizedBox(width: 8), Text('壁纸设置已保存，即时生效')]),
          backgroundColor: Color(0xFF1e1e3a),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _config = WallpaperConfig(type: 'local', localPath: image.path, opacity: _config.opacity);
        });
        await _saveConfig();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _setUrlWallpaper() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入图片链接'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() {
      _config = WallpaperConfig(type: 'url', imageUrl: url, opacity: _config.opacity);
    });
    await _saveConfig();
  }

  Future<void> _setApiWallpaper() async {
    final apiUrl = _apiUrlController.text.trim();
    if (apiUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入API地址'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() {
      _config = WallpaperConfig(type: 'api', apiUrl: apiUrl, opacity: _config.opacity);
    });
    await _saveConfig();
  }

  Future<void> _fetchDailyImage() async {
    setState(() => _isFetchingApi = true);
    final url = await DailyImageService.getDailyImage(customApiUrl: _config.apiUrl);
    setState(() {
      _previewUrl = url;
      _isFetchingApi = false;
    });
    if (url == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('获取每日图片失败，请检查网络或API地址'), backgroundColor: Colors.orange),
      );
    } else if (url != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('每日图片获取成功'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _loading
          ? Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 1),
                curve: Curves.elasticOut,
                builder: (_, v, __) => CircularProgressIndicator(value: v, color: Colors.cyanAccent),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPreview(),
                  const SizedBox(height: 20),
                  _buildOpacitySlider(),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _gradientCtrl,
                    builder: (_, child) => ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Color.lerp(Colors.white, Colors.cyanAccent, _gradientCtrl.value)!,
                          Color.lerp(Colors.cyanAccent, Colors.white, _gradientCtrl.value)!,
                        ],
                      ).createShader(bounds),
                      child: child,
                    ),
                    child: const Text('壁纸来源', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  _buildSourceCard('本地图片', '从相册选择图片', Icons.photo_library, _config.type == 'local', _pickImage),
                  _buildSourceCard('图片链接', '使用网络图片链接', Icons.link, _config.type == 'url', () => _showUrlDialog()),
                  _buildSourceCard('API每日图片', '先输入API地址，再获取图片', Icons.auto_awesome, _config.type == 'api', () => _showApiDialog()),
                  const SizedBox(height: 20),
                  if (_config.type == 'api')
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (_, v, __) => Transform.scale(
                        scale: v,
                        child: _isFetchingApi
                            ? Center(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(seconds: 1),
                                  builder: (_, sv, __) => CircularProgressIndicator(value: sv, color: Colors.cyanAccent),
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: _fetchDailyImage,
                                icon: AnimatedRotation(
                                  turns: _isFetchingApi ? 1 : 0,
                                  duration: const Duration(milliseconds: 600),
                                  child: const Icon(Icons.refresh),
                                ),
                                label: const Text('获取/刷新每日图片'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.cyanAccent,
                                  side: const BorderSide(color: Colors.cyanAccent),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildPreview() {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color.lerp(
              Colors.white24,
              Colors.cyanAccent.withOpacity(0.3),
              _glowCtrl.value,
            )!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.1 + _glowCtrl.value * 0.05),
              blurRadius: 20 + _glowCtrl.value * 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
            // 浮动粒子
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) {
                return CustomPaint(
                  painter: _ParticlePainter(_particleCtrl.value),
                  size: Size.infinite,
                );
              },
            ),
          ],
        ),
      ),
      child: _buildPreviewImage(),
    );
  }

  Widget _buildPreviewImage() {
    Widget imageWidget;
    switch (_config.type) {
      case 'local':
        if (_config.localPath != null && _config.localPath!.isNotEmpty) {
          imageWidget = Image.file(File(_config.localPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _previewPlaceholder());
        } else {
          return _previewPlaceholder();
        }
        break;
      case 'url':
        if (_config.imageUrl != null && _config.imageUrl!.isNotEmpty) {
          imageWidget = CachedNetworkImage(
            imageUrl: _config.imageUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _previewPlaceholder(),
            placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
          );
        } else {
          return _previewPlaceholder();
        }
        break;
      case 'api':
        if (_previewUrl != null) {
          imageWidget = CachedNetworkImage(
            imageUrl: _previewUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _previewPlaceholder(),
            placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
          );
        } else {
          return _previewPlaceholder();
        }
        break;
      default:
        return _previewPlaceholder();
    }

    // Ken Burns 效果
    return AnimatedBuilder(
      animation: _kenBurnsCtrl,
      builder: (_, child) => Transform.scale(
        scale: 1.0 + _kenBurnsCtrl.value * 0.1,
        child: Transform.translate(
          offset: Offset(
            math.sin(_kenBurnsCtrl.value * 6.28318) * 5,
            math.cos(_kenBurnsCtrl.value * 6.28318) * 5,
          ),
          child: Opacity(opacity: _config.opacity, child: child),
        ),
      ),
      child: imageWidget,
    );
  }

  Widget _previewPlaceholder() {
    return Container(
      color: const Color(0xFF1a1a2e),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(seconds: 2),
              curve: Curves.elasticOut,
              builder: (_, v, __) => Transform.scale(
                scale: v,
                child: AnimatedBuilder(
                  animation: _gradientCtrl,
                  builder: (_, child) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.05 + _gradientCtrl.value * 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  child: const Icon(Icons.wallpaper, size: 48, color: Colors.white38),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _gradientCtrl,
              builder: (_, child) => ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Color.lerp(Colors.white38, Colors.cyanAccent, _gradientCtrl.value)!,
                    Color.lerp(Colors.cyanAccent, Colors.white38, _gradientCtrl.value)!,
                  ],
                ).createShader(bounds),
                child: child,
              ),
              child: const Text('壁纸预览', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
            const Text('选择壁纸来源并设置', style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildOpacitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('壁纸透明度', style: TextStyle(color: Colors.white)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: AnimatedBuilder(
                animation: _waveGradientCtrl,
                builder: (_, child) => ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Color.lerp(Colors.cyanAccent, Colors.purpleAccent, _waveGradientCtrl.value)!,
                      Color.lerp(Colors.purpleAccent, Colors.cyanAccent, _waveGradientCtrl.value)!,
                    ],
                  ).createShader(bounds),
                  child: child,
                ),
                child: Text('${(_config.opacity * 100).round()}%', key: ValueKey(_config.opacity), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.cyanAccent,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.cyanAccent,
            overlayColor: Colors.cyanAccent.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: AnimatedBuilder(
            animation: _waveGradientCtrl,
            builder: (_, child) => child!,
            child: Slider(
              value: _config.opacity,
              min: 0.05,
              max: 1.0,
              divisions: 19,
              onChanged: (v) {
                setState(() => _config = WallpaperConfig(
                  type: _config.type, localPath: _config.localPath, imageUrl: _config.imageUrl,
                  apiUrl: _config.apiUrl, opacity: v,
                ));
                _saveConfig();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceCard(String title, String subtitle, IconData icon, bool selected, VoidCallback onTap) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (_, v, __) => Transform(
        transform: Matrix4.rotationY((1 - v) * 0.5),
        alignment: Alignment.center,
        child: Transform.scale(
          scale: v,
          child: Card(
            color: selected ? Colors.cyanAccent.withOpacity(0.15) : Colors.white.withOpacity(0.08),
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected
                    ? Color.lerp(Colors.cyanAccent, Colors.cyanAccent.withOpacity(0.5), _glowCtrl.value)!
                    : Colors.transparent,
              ),
            ),
            elevation: selected ? 4 : 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _flipCtrl.reset();
                _flipCtrl.forward();
                onTap();
              },
              splashColor: Colors.cyanAccent.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _flipCtrl,
                      builder: (_, child) => Transform(
                        transform: Matrix4.rotationY(_flipCtrl.value * 3.14159),
                        alignment: Alignment.center,
                        child: _flipCtrl.value < 0.5 ? child : Icon(icon, color: selected ? Colors.cyanAccent : Colors.white70),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selected ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: selected
                              ? [BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.1 + _glowCtrl.value * 0.1),
                                  blurRadius: 8,
                                )]
                              : [],
                        ),
                        child: Icon(icon, color: selected ? Colors.cyanAccent : Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: TextStyle(color: selected ? Colors.cyanAccent : Colors.white, fontWeight: FontWeight.w500)),
                          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: RotationTransition(turns: Tween<double>(begin: 0.5, end: 0).animate(anim), child: child)),
                      child: selected
                          ? const Icon(Icons.check_circle, color: Colors.cyanAccent, key: ValueKey('check'))
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUrlDialog() {
    showDialog(
      context: context,
      builder: (ctx) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1e1e3a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [Icon(Icons.link, color: Colors.cyanAccent), SizedBox(width: 8), Text('设置图片链接', style: TextStyle(color: Colors.white))]),
          content: TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '输入图片URL...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true, fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () { Navigator.pop(ctx); _setUrlWallpaper(); },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiDialog() {
    showDialog(
      context: context,
      builder: (ctx) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1e1e3a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [Icon(Icons.auto_awesome, color: Colors.cyanAccent), SizedBox(width: 8), Text('设置API地址', style: TextStyle(color: Colors.white))]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _apiUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '输入API URL...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true, fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              const Text('推荐API源：', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ...['https://api.dujin.org/bing/1920.php', 'https://picsum.photos/1920/1080', 'https://api.ixiaowai.cn/api/api.php'].map((api) =>
                InkWell(
                  onTap: () { _apiUrlController.text = api; Navigator.pop(ctx); _setApiWallpaper(); },
                  splashColor: Colors.cyanAccent.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(api, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () { Navigator.pop(ctx); _setApiWallpaper(); },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    final rng = math.Random(42);

    for (int i = 0; i < 15; i++) {
      final x = (rng.nextDouble() * size.width);
      final y = (rng.nextDouble() * size.height);
      final opacity = (math.sin((progress + i * 0.3) * 6.28318) + 1) * 0.15;
      paint.color = Colors.cyanAccent.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => oldDelegate.progress != progress;
}