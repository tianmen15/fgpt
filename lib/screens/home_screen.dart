import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/wallpaper_scaffold.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import 'player_screen.dart';
import 'wallpaper_screen.dart';
import 'playlist_screen.dart';
import 'history_screen.dart';
import 'music_screen.dart';
import 'image_screen.dart';
import 'qr_scanner_screen.dart';
import 'notes_screen.dart';
import 'calculator_screen.dart';
import 'weather_screen.dart';
import 'tools_screen.dart';
import 'file_manager_screen.dart';
import 'downloads_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _tabAnimCtrl;
  late Animation<double> _tabScaleAnim;

  final List<Widget> _pages = const [
    _HomeContent(),
    PlaylistScreen(),
    HistoryScreen(),
    MusicScreen(),
    ImageScreen(),
    WallpaperScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _tabScaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _tabAnimCtrl, curve: Curves.elasticOut));
    _tabAnimCtrl.forward();
  }

  @override
  void dispose() {
    _tabAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              backgroundColor: Colors.black54,
              title: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (_, v, c) => Transform.scale(scale: v, child: c),
                child: const Text('万能视频播放器', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.black87),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            _tabAnimCtrl.reset();
            _tabAnimCtrl.forward();
            setState(() => _currentIndex = i);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF00d4ff),
          unselectedItemColor: Colors.white54,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: [
            _buildNavItem(Icons.home, '首页', 0),
            _buildNavItem(Icons.playlist_play, '列表', 1),
            _buildNavItem(Icons.history, '历史', 2),
            _buildNavItem(Icons.music_note, '音乐', 3),
            _buildNavItem(Icons.image, '图片', 4),
            _buildNavItem(Icons.wallpaper, '壁纸', 5),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    final selected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        builder: (_, v, __) => Transform.scale(
          scale: selected ? v : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: selected
                ? ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF00d4ff), Color(0xFFb388ff), Color(0xFF00d4ff)],
                    ).createShader(bounds),
                    child: Icon(icon, color: Colors.white),
                  )
                : Icon(icon),
          ),
        ),
      ),
      label: label,
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> with TickerProviderStateMixin {
  final _urlController = TextEditingController();
  final _searchController = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;
  late AnimationController _particleCtrl;
  late AnimationController _gradientCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _bubbleCtrl;
  late AnimationController _confettiCtrl;
  late AnimationController _typingCtrl;
  late AnimationController _ringCtrl;
  int _confettiTrigger = 0;
  bool _showSearch = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.repeat(reverse: true);

    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
    _shimmerCtrl.repeat();

    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _particleCtrl.repeat();

    _gradientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _gradientCtrl.repeat(reverse: true);

    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _waveCtrl.repeat(reverse: true);

    _bubbleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6));
    _bubbleCtrl.repeat();

    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _confettiCtrl.addStatusListener((s) { if (s == AnimationStatus.completed) _confettiCtrl.reset(); });

    _typingCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _typingCtrl.repeat(reverse: true);

    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _ringCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    _animCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _particleCtrl.dispose();
    _gradientCtrl.dispose();
    _waveCtrl.dispose();
    _bubbleCtrl.dispose();
    _confettiCtrl.dispose();
    _typingCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  Future<void> _playVideo(BuildContext context, String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入视频链接'), backgroundColor: Colors.orange),
      );
      return;
    }

    final title = _extractTitle(url);
    final item = VideoItem(title: title, url: url.trim());
    await StorageService.addToHistory(item);

    if (mounted) {
      _confettiTrigger++;
      _confettiCtrl.forward();
      Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(videoItem: item)));
    }
  }

  String _extractTitle(String url) {
    try {
      final uri = Uri.parse(url.trim());
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final last = segments.last;
        if (last.contains('.')) return last.split('.').first;
        return last;
      }
    } catch (_) {}
    return url.trim().length > 30 ? '${url.trim().substring(0, 30)}...' : url.trim();
  }

  Future<void> _pickAndPlayLocalVideo() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickVideo(source: ImageSource.gallery);
      if (xFile == null) return;

      final file = File(xFile.path);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('所选视频文件不存在'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      final fileName = xFile.name.isNotEmpty ? xFile.name : xFile.path.split('/').last;
      final title = fileName.contains('.') ? fileName.split('.').first : fileName;
      final item = VideoItem(
        title: title,
        url: xFile.path,
        isLocal: true,
        localPath: xFile.path,
      );
      await StorageService.addToHistory(item);

      if (mounted) {
        _confettiTrigger++;
        _confettiCtrl.forward();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PlayerScreen(videoItem: item, localPath: xFile.path),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择视频失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Stack(
            children: [
              // 气泡背景动画
              AnimatedBuilder(
                animation: _bubbleCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _BubblePainter(_bubbleCtrl.value),
                  size: Size.infinite,
                ),
              ),
              // 彩纸爆炸效果
              if (_confettiCtrl.isAnimating || _confettiCtrl.value > 0)
                AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _ConfettiPainter(_confettiCtrl.value, _confettiTrigger),
                    size: Size.infinite,
                  ),
                ),
              // 主内容
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // 粒子环绕Logo + 光晕扩散环
                    _buildParticleLogo(),
                    const SizedBox(height: 20),
                    _buildAnimatedTitle(),
                    const SizedBox(height: 30),
                    // 带波浪动画边框的输入框
                    _buildWaveInput(),
                    const SizedBox(height: 16),
                    // 播放按钮带弹性动画及光晕
                    _buildPlayButton(),
                    const SizedBox(height: 12),
                    // 本地视频按钮
                    _buildLocalVideoButton(),
                    const SizedBox(height: 30),
                    _sectionHeader('快速测试链接', Icons.movie),
                    const SizedBox(height: 10),
                    _quickLink('Big Buck Bunny', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4', 0),
                    _quickLink('Elephant Dream', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4', 1),
                    _quickLink('Sintel', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4', 2),
                    _quickLink('Tears of Steel', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4', 3),
                    const SizedBox(height: 30),
                    _sectionHeader('功能模块', Icons.apps),
                    const SizedBox(height: 10),
                    _buildFeatureSearch(),
                    const SizedBox(height: 10),
                    _featureGrid(),
                    const SizedBox(height: 30),
                    _sectionHeader('更多工具', Icons.build),
                    const SizedBox(height: 10),
                    _moreToolsGrid(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (_, v, c) => Transform.scale(
        scale: v,
        child: AnimatedBuilder(
          animation: _gradientCtrl,
          builder: (_, child) => ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Color.lerp(const Color(0xFF00d4ff), const Color(0xFFb388ff), _gradientCtrl.value)!,
                Color.lerp(const Color(0xFFb388ff), const Color(0xFF00d4ff), _gradientCtrl.value)!,
              ],
            ).createShader(bounds),
            child: child,
          ),
          child: AnimatedBuilder(
            animation: _typingCtrl,
            builder: (_, child) {
              final cursor = _typingCtrl.value > 0.5 ? '|' : ' ';
              return Text(
                '输入视频链接开始播放$cursor',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildParticleLogo() {
    return AnimatedBuilder(
      animation: _particleCtrl,
      builder: (_, child) {
        final particles = <Widget>[];
        for (int i = 0; i < 6; i++) {
          final angle = (_particleCtrl.value * 6.28318) + (i * 6.28318 / 6);
          final radius = 55.0 + math.sin(_particleCtrl.value * 6.28318 + i) * 8;
          final dx = math.cos(angle) * radius;
          final dy = math.sin(angle) * radius;
          particles.add(
            Positioned(
              left: 45 + dx,
              top: 45 + dy,
              child: Transform.scale(
                scale: 0.5 + math.sin(_particleCtrl.value * 12.56636 + i) * 0.3,
                child: Container(
                  width: 4 + (i % 2 == 0 ? 2 : 0),
                  height: 4 + (i % 2 == 0 ? 2 : 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i % 2 == 0 ? const Color(0xFF00d4ff).withOpacity(0.8) : const Color(0xFFb388ff).withOpacity(0.6),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00d4ff).withOpacity(0.4), blurRadius: 4, spreadRadius: 1),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 光晕扩散环
              AnimatedBuilder(
                animation: _ringCtrl,
                builder: (_, __) => Container(
                  width: 60 + _ringCtrl.value * 30,
                  height: 60 + _ringCtrl.value * 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00d4ff).withOpacity(0.3 * (1 - _ringCtrl.value)),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _ringCtrl,
                builder: (_, __) => Container(
                  width: 40 + _ringCtrl.value * 50,
                  height: 40 + _ringCtrl.value * 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00d4ff).withOpacity(0.15 * (1 - _ringCtrl.value)),
                      width: 1,
                    ),
                  ),
                ),
              ),
              ...particles,
              // 脉冲动画Logo
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: child,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00d4ff), Color(0xFF0077be), Color(0xFFb388ff)],
                    ),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00d4ff).withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
                    ],
                  ),
                  child: const Icon(Icons.play_circle_outline, size: 50, color: Colors.black),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaveInput() {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (_, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFF00d4ff).withOpacity(0.3),
                const Color(0xFF00d4ff).withOpacity(0.7),
                _waveCtrl.value,
              )!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00d4ff).withOpacity(0.05 + _waveCtrl.value * 0.1),
                blurRadius: 15 + _waveCtrl.value * 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: TextField(
        controller: _urlController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: '粘贴视频链接...',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(scale: 0.9 + (_pulseAnim.value - 0.85) * 0.5, child: child),
            child: const Icon(Icons.link, color: Color(0xFF00d4ff)),
          ),
          suffixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _urlController.text.isNotEmpty
                ? IconButton(
                    key: const ValueKey('clear'),
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () => setState(() => _urlController.clear()),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF00d4ff), width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (url) => _playVideo(context, url),
      ),
    );
  }

  Widget _buildPlayButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (_, v, __) => Transform.scale(
        scale: v,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00d4ff).withOpacity(0.3 + _pulseAnim.value * 0.2 - 0.17),
                blurRadius: 20 + (_pulseAnim.value - 0.85) * 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _playVideo(context, _urlController.text),
            icon: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(scale: 0.9 + (_pulseAnim.value - 0.85) * 0.3, child: child),
              child: const Icon(Icons.play_arrow),
            ),
            label: AnimatedBuilder(
              animation: _gradientCtrl,
              builder: (_, child) => ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.black,
                    Color.lerp(Colors.black, const Color(0xFF1a237e), _gradientCtrl.value)!,
                  ],
                ).createShader(bounds),
                child: child,
              ),
              child: const Text('播放', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00d4ff),
              foregroundColor: const Color(0xFF003545),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              shadowColor: const Color(0xFF00d4ff).withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalVideoButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (_, v, __) => Transform.scale(
        scale: v,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: ElevatedButton.icon(
            onPressed: _pickAndPlayLocalVideo,
            icon: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(scale: 0.9 + (_pulseAnim.value - 0.85) * 0.3, child: child),
              child: const Icon(Icons.folder_open, color: Colors.white),
            ),
            label: const Text('本地视频', style: TextStyle(fontSize: 16, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.12),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, child) => Transform.rotate(
            angle: _waveCtrl.value * 0.3,
            child: child,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (_, v, __) => Transform.rotate(angle: (1 - v) * 0.5, child: Icon(icon, color: const Color(0xFF00d4ff), size: 20)),
          ),
        ),
        const SizedBox(width: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (_, v, __) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(20 * (1 - v), 0),
              child: AnimatedBuilder(
                animation: _gradientCtrl,
                builder: (_, child) => ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Color.lerp(Colors.white70, const Color(0xFF00d4ff), _gradientCtrl.value)!,
                      Color.lerp(const Color(0xFF00d4ff), Colors.white70, _gradientCtrl.value)!,
                    ],
                  ).createShader(bounds),
                  child: child,
                ),
                child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickLink(String title, String url, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 100),
      curve: Curves.easeOut,
      builder: (_, v, __) {
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - v)),
            child: Transform.scale(
              scale: 0.9 + v * 0.1,
              child: Card(
                color: Colors.white.withOpacity(0.08),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _playVideo(context, url),
                  onLongPress: () async {
                    await StorageService.addToPlaylist(VideoItem(title: title, url: url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已添加到播放列表'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
                      );
                    }
                  },
                  splashColor: const Color(0xFF00d4ff).withOpacity(0.3),
                  highlightColor: const Color(0xFF00d4ff).withOpacity(0.1),
                  child: ListTile(
                    leading: AnimatedBuilder(
                      animation: _waveCtrl,
                      builder: (_, child) => Transform.scale(
                        scale: 1.0 + math.sin(_waveCtrl.value * 6.28318 + index) * 0.1,
                        child: child,
                      ),
                      child: const Icon(Icons.movie, color: Color(0xFF00d4ff)),
                    ),
                    title: Text(title, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(url, style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.play_arrow, color: Color(0xFF00d4ff)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureSearch() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: '搜索功能...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF00d4ff), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _featureGrid() {
    final features = [
      {'icon': Icons.music_note, 'title': '音乐搜索', 'sub': '10段EQ+歌词', 'color': Colors.purpleAccent, 'gradient': const [Color(0xFF6a11cb), Color(0xFF2575fc)], 'screen': 'music'},
      {'icon': Icons.image, 'title': '随机图片', 'sub': 'Lolicon API', 'color': Colors.pinkAccent, 'gradient': const [Color(0xFFf12711), Color(0xFFf5af19)], 'screen': 'image'},
      {'icon': Icons.wallpaper, 'title': '自定义壁纸', 'sub': '本地/链接/API', 'color': Colors.cyanAccent, 'gradient': const [Color(0xFF00b4db), Color(0xFF0083b0)], 'screen': 'wallpaper'},
      {'icon': Icons.playlist_play, 'title': '播放列表', 'sub': '管理收藏', 'color': Colors.orangeAccent, 'gradient': const [Color(0xFFf12711), Color(0xFFf5af19)], 'screen': 'playlist'},
    ];

    final filtered = _searchQuery.isEmpty
        ? features
        : features.where((f) =>
            (f['title'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (f['sub'] as String).toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    final allFiltered = _searchQuery.isEmpty ? features : [...filtered];
    if (allFiltered.isEmpty && _searchQuery.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text('未找到匹配功能', style: TextStyle(color: Colors.white.withOpacity(0.5)), textAlign: TextAlign.center),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: List.generate(allFiltered.length, (i) {
        final f = allFiltered[i];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 500 + i * 120),
          curve: Curves.easeOut,
          builder: (_, v, __) {
            return Opacity(
              opacity: v,
              child: Transform.scale(
                scale: 0.8 + v * 0.2,
                child: Transform(
                  transform: Matrix4.rotationY((1 - v) * 0.8),
                  alignment: Alignment.center,
                  child: _buildFeatureCard(
                    icon: f['icon'] as IconData,
                    title: f['title'] as String,
                    sub: f['sub'] as String,
                    color: f['color'] as Color,
                    gradient: f['gradient'] as List<Color>,
                    onTap: () {
                      final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                      switch (f['screen']) {
                        case 'music': homeState?.setState(() => homeState._currentIndex = 3); break;
                        case 'image': homeState?.setState(() => homeState._currentIndex = 4); break;
                        case 'wallpaper': homeState?.setState(() => homeState._currentIndex = 5); break;
                        case 'playlist': homeState?.setState(() => homeState._currentIndex = 1); break;
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _moreToolsGrid() {
    final tools = [
      {'icon': Icons.qr_code_scanner, 'title': '扫码', 'sub': '二维码/条码', 'color': Color(0xFF00b4db), 'gradient': [Color(0xFF00b4db), Color(0xFF0083b0)], 'screen': 'qr'},
      {'icon': Icons.note_alt, 'title': '记事本', 'sub': '笔记管理', 'color': Color(0xFF6a11cb), 'gradient': [Color(0xFF6a11cb), Color(0xFF2575fc)], 'screen': 'notes'},
      {'icon': Icons.calculate, 'title': '计算器', 'sub': '科学计算', 'color': Color(0xFF11998e), 'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)], 'screen': 'calc'},
      {'icon': Icons.cloud, 'title': '天气', 'sub': '实时预报', 'color': Color(0xFFfc4a1a), 'gradient': [Color(0xFFfc4a1a), Color(0xFFf7b733)], 'screen': 'weather'},
      {'icon': Icons.build, 'title': '工具箱', 'sub': '55+实用工具', 'color': Color(0xFF7b2ff7), 'gradient': [Color(0xFF7b2ff7), Color(0xFFf12711)], 'screen': 'tools'},
      {'icon': Icons.folder, 'title': '文件管理', 'sub': '浏览/管理', 'color': Color(0xFFe53935), 'gradient': [Color(0xFFe53935), Color(0xFFe35d5b)], 'screen': 'files'},
      {'icon': Icons.download, 'title': '下载管理', 'sub': '查看下载', 'color': Color(0xFF0083b0), 'gradient': [Color(0xFF0083b0), Color(0xFF00b4db)], 'screen': 'downloads'},
    ];

    final filtered = _searchQuery.isEmpty
        ? tools
        : tools.where((t) =>
            (t['title'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (t['sub'] as String).toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    final display = _searchQuery.isEmpty ? tools : filtered;
    if (display.isEmpty && _searchQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: List.generate(display.length, (i) {
        final t = display[i];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 500 + i * 120),
          curve: Curves.easeOut,
          builder: (_, v, __) {
            return Opacity(
              opacity: v,
              child: Transform.scale(
                scale: 0.8 + v * 0.2,
                child: Transform(
                  transform: Matrix4.rotationY((1 - v) * 0.8),
                  alignment: Alignment.center,
                  child: _buildFeatureCard(
                    icon: t['icon'] as IconData,
                    title: t['title'] as String,
                    sub: t['sub'] as String,
                    color: t['color'] as Color,
                    gradient: t['gradient'] as List<Color>,
                    onTap: () {
                      switch (t['screen']) {
                        case 'qr': Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())); break;
                        case 'notes': Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen())); break;
                        case 'calc': Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorScreen())); break;
                        case 'weather': Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherScreen())); break;
                        case 'tools': Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsScreen())); break;
                        case 'files': Navigator.push(context, MaterialPageRoute(builder: (_) => const FileManagerScreen())); break;
                        case 'downloads': Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen())); break;
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String sub,
    required Color color,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFF1a1a2e).withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.15),
          highlightColor: color.withOpacity(0.05),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _gradientCtrl,
                  builder: (_, child) => AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient.map((c) => c.withOpacity(0.25 + _gradientCtrl.value * 0.2)).toList(),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.15 + _gradientCtrl.value * 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 气泡背景画笔
class _BubblePainter extends CustomPainter {
  final double progress;
  _BubblePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    for (int i = 0; i < 12; i++) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final y = (baseY - progress * size.height * 0.3) % size.height;
      final radius = 5 + rng.nextDouble() * 15;
      final opacity = 0.02 + math.sin((progress + i * 0.5) * 6.28318).abs() * 0.04;
      final paint = Paint()
        ..color = const Color(0xFF00d4ff).withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y < 0 ? y + size.height : y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.progress != progress;
}

// 彩纸爆炸画笔
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final int seed;
  _ConfettiPainter(this.progress, this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed * 42);
    final colors = [const Color(0xFF00d4ff), const Color(0xFFb388ff), Colors.pinkAccent, Colors.amber, Colors.greenAccent, Colors.orangeAccent];
    final centerX = size.width / 2;
    final centerY = size.height * 0.3;

    for (int i = 0; i < 30; i++) {
      final angle = rng.nextDouble() * 6.28318;
      final distance = progress * (size.width * 0.7);
      final x = centerX + math.cos(angle) * distance;
      final y = centerY + math.sin(angle) * distance - progress * 100;
      final rotation = progress * 6.28318 * (rng.nextDouble() * 2 - 1);
      final scale = (1 - progress) * (0.5 + rng.nextDouble() * 0.5);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.scale(scale);

      final paint = Paint()
        ..color = colors[rng.nextInt(colors.length)].withOpacity(1 - progress)
        ..style = PaintingStyle.fill;
      final w = 4 + rng.nextDouble() * 6;
      canvas.drawRRect(RRect.fromLTRBR(-w / 2, -w / 4, w / 2, w / 4, const Radius.circular(1)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress || old.seed != seed;
}