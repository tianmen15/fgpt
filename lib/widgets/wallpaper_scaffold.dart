import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../services/storage_service.dart';
import '../models/models.dart';

class WallpaperScaffold extends StatefulWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const WallpaperScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  State<WallpaperScaffold> createState() => _WallpaperScaffoldState();
}

class _WallpaperScaffoldState extends State<WallpaperScaffold> with TickerProviderStateMixin {
  WallpaperConfig? _config;
  String? _dailyImageUrl;
  bool _loading = true;
  late AnimationController _transitionCtrl;
  late Animation<double> _transitionAnim;
  late AnimationController _gradientCtrl;

  @override
  void initState() {
    super.initState();
    _transitionCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _transitionAnim = CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeInOut);
    _transitionCtrl.forward();
    _gradientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _gradientCtrl.repeat(reverse: true);
    _loadWallpaper();
    WallpaperNotifier().addListener(_onWallpaperChanged);
  }

  @override
  void dispose() {
    WallpaperNotifier().removeListener(_onWallpaperChanged);
    _transitionCtrl.dispose();
    _gradientCtrl.dispose();
    super.dispose();
  }

  void _onWallpaperChanged() {
    _transitionCtrl.reset();
    _transitionCtrl.forward();
    _loadWallpaper();
  }

  Future<void> _loadWallpaper() async {
    try {
      final config = await StorageService.getWallpaperConfig();
      String? dailyUrl;
      if (config.type == 'api') {
        dailyUrl = await DailyImageService.getDailyImage(customApiUrl: config.apiUrl);
      }
      if (mounted) {
        setState(() {
          _config = config;
          _dailyImageUrl = dailyUrl;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _config = WallpaperConfig(type: 'url', imageUrl: '');
          _loading = false;
        });
      }
    }
  }

  Widget _buildBackground() {
    if (_config == null) return _fallbackBg();

    final config = _config!;
    Widget imageWidget;

    switch (config.type) {
      case 'local':
        if (config.localPath != null && config.localPath!.isNotEmpty && File(config.localPath!).existsSync()) {
          imageWidget = Image.file(
            File(config.localPath!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _fallbackBg(),
          );
        } else {
          imageWidget = _fallbackBg();
        }
        break;
      case 'url':
        if (config.imageUrl != null && config.imageUrl!.isNotEmpty) {
          imageWidget = CachedNetworkImage(
            imageUrl: config.imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => _fallbackBg(),
            errorWidget: (_, __, ___) => _fallbackBg(),
          );
        } else {
          imageWidget = _fallbackBg();
        }
        break;
      case 'api':
        if (_dailyImageUrl != null && _dailyImageUrl!.isNotEmpty) {
          imageWidget = CachedNetworkImage(
            imageUrl: _dailyImageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => _fallbackBg(),
            errorWidget: (_, __, ___) => _fallbackBg(),
          );
        } else {
          imageWidget = _fallbackBg();
        }
        break;
      default:
        imageWidget = _fallbackBg();
    }

    return FadeTransition(
      opacity: _transitionAnim,
      child: Opacity(
        opacity: config.opacity,
        child: imageWidget,
      ),
    );
  }

  Widget _fallbackBg() {
    return AnimatedBuilder(
      animation: _gradientCtrl,
      builder: (_, __) {
        final t = _gradientCtrl.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.5 + t * 0.5, -0.8 + t * 0.4),
              end: Alignment(0.8 - t * 0.6, 0.6 + t * 0.3),
              colors: [
                const Color(0xFF0a0a1a),
                Color.lerp(const Color(0xFF0f0f2d), const Color(0xFF16213e), t)!,
                Color.lerp(const Color(0xFF1a1a3e), const Color(0xFF0f3460), t)!,
                Color.lerp(const Color(0xFF0a0a1a), const Color(0xFF1a0a2e), t)!,
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        appBar: widget.appBar,
        body: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 1),
            builder: (_, v, __) => CircularProgressIndicator(value: v, color: const Color(0xFF00d4ff)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: widget.appBar,
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          Positioned.fill(child: widget.body),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}