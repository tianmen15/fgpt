import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/music_service.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import '../widgets/wallpaper_scaffold.dart';
import 'music_player_screen.dart';
import 'dart:math' as math;

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  List<SongItem> _searchResults = [];
  List<SongItem> _favorites = [];
  bool _isSearching = false;
  bool _showFavorites = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _waveCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;
  late AnimationController _spectrumCtrl;
  late AnimationController _gradientCtrl;
  late AnimationController _noteCtrl;
  late AnimationController _highlightCtrl;
  late AnimationController _visualizerCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();

    _waveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _waveCtrl.repeat(reverse: true);

    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _floatAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _floatCtrl.repeat(reverse: true);

    _spectrumCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _spectrumCtrl.repeat(reverse: true);

    _gradientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _gradientCtrl.repeat(reverse: true);

    _noteCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _noteCtrl.repeat();

    _highlightCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _highlightCtrl.repeat(reverse: true);

    _visualizerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _visualizerCtrl.repeat(reverse: true);

    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animCtrl.dispose();
    _waveCtrl.dispose();
    _floatCtrl.dispose();
    _spectrumCtrl.dispose();
    _gradientCtrl.dispose();
    _noteCtrl.dispose();
    _highlightCtrl.dispose();
    _visualizerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favs = await StorageService.getMusicFavorites();
    if (mounted) setState(() => _favorites = favs);
  }

  Future<void> _search() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;
    setState(() => _isSearching = true);
    _animCtrl.reset();
    _animCtrl.forward();
    final results = await MusicService.searchSongs(keyword: keyword);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _showFavorites = false;
      });
    }
  }

  Future<void> _toggleFavorite(SongItem song) async {
    final isFav = await StorageService.isMusicFavorite(song.id);
    if (isFav) {
      await StorageService.removeMusicFavorite(song.id);
    } else {
      await StorageService.addMusicFavorite(song);
    }
    await _loadFavorites();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            AnimatedRotation(turns: isFav ? 0.2 : 0, duration: const Duration(milliseconds: 300), child: Icon(isFav ? Icons.favorite_border : Icons.favorite, color: Colors.white, size: 18)),
            const SizedBox(width: 8),
            Text(isFav ? '已取消收藏' : '已添加到收藏'),
          ]),
          backgroundColor: isFav ? Colors.grey : Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _playSong(SongItem song) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => MusicPlayerScreen(song: song)));
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim), child: child)),
          child: Text(_showFavorites ? '我的收藏' : '音乐搜索', key: ValueKey(_showFavorites), style: const TextStyle(color: Colors.white)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (_, v, __) => Transform.scale(
              scale: v,
              child: IconButton(
                icon: Icon(_showFavorites ? Icons.search : Icons.favorite, color: _showFavorites ? const Color(0xFF00d4ff) : Colors.white),
                onPressed: () {
                  setState(() => _showFavorites = !_showFavorites);
                  _animCtrl.reset();
                  _animCtrl.forward();
                },
                tooltip: _showFavorites ? '搜索' : '收藏',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 浮动音符背景
            AnimatedBuilder(
              animation: _noteCtrl,
              builder: (_, __) => CustomPaint(
                painter: _FloatingNotePainter(_noteCtrl.value),
                size: Size.infinite,
              ),
            ),
            Column(
              children: [
                if (!_showFavorites) _buildSearchBar(),
                const SizedBox(height: 8),
                Expanded(child: _showFavorites ? _buildFavoritesList() : _buildSearchResults()),
                // 底部声波可视化
                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AnimatedBuilder(
                      animation: _visualizerCtrl,
                      builder: (_, __) => _buildSoundWave(),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedBuilder(
        animation: _waveCtrl,
        builder: (_, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00d4ff).withOpacity(0.05 + _waveCtrl.value * 0.1),
                blurRadius: 12 + _waveCtrl.value * 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
        child: Row(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Color.lerp(
                      const Color(0xFF00d4ff).withOpacity(0.2),
                      const Color(0xFF00d4ff).withOpacity(0.5),
                      _waveCtrl.value,
                    )!,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '搜索歌曲名、歌手...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: _isSearching
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: AnimatedBuilder(
                              animation: _spectrumCtrl,
                              builder: (_, __) => _buildMiniSpectrum(),
                            ),
                          )
                        : AnimatedBuilder(
                            animation: _floatAnim,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(0, math.sin(_floatAnim.value * 6.28318) * 3),
                              child: child,
                            ),
                            child: const Icon(Icons.music_note, color: Color(0xFF00d4ff)),
                          ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, color: Colors.white54), onPressed: () => setState(() => _searchController.clear()))
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _search(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _spectrumCtrl,
              builder: (_, child) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Material(
                  color: const Color(0xFF00d4ff),
                  borderRadius: BorderRadius.circular(24),
                  elevation: 4 + _spectrumCtrl.value * 4,
                  shadowColor: const Color(0xFF00d4ff).withOpacity(0.3 + _spectrumCtrl.value * 0.2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _isSearching ? null : _search,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      child: _isSearching
                          ? SizedBox(
                              width: 24, height: 24,
                              child: AnimatedBuilder(
                                animation: _spectrumCtrl,
                                builder: (_, __) => CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                  value: 0.3 + _spectrumCtrl.value * 0.7,
                                ),
                              ),
                            )
                          : const Icon(Icons.search, color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniSpectrum() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final h = 8.0 + math.sin((_spectrumCtrl.value + i * 0.25) * 6.28318).abs() * 8;
        return Container(
          width: 2,
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF00d4ff).withOpacity(0.5 + i * 0.1),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && !_isSearching) {
      return FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, child) => Transform.translate(offset: Offset(0, math.sin(_floatAnim.value * 6.28318) * 10), child: child),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 频谱动画
                AnimatedBuilder(
                  animation: _spectrumCtrl,
                  builder: (_, __) => _buildCenterSpectrum(),
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1.0),
                  duration: const Duration(seconds: 2),
                  builder: (_, v, __) => Transform.scale(
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
                      child: Icon(Icons.music_note, size: 72, color: const Color(0xFF00d4ff).withOpacity(0.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('搜索你喜欢的音乐', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _gradientCtrl,
                  builder: (_, child) => ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Color.lerp(Colors.white38, const Color(0xFF00d4ff), _gradientCtrl.value)!,
                        Color.lerp(const Color(0xFF00d4ff), Colors.white38, _gradientCtrl.value)!,
                      ],
                    ).createShader(bounds),
                    child: child,
                  ),
                  child: const Text('支持网易云音乐曲库', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _searchResults.length,
        itemBuilder: (ctx, i) {
          final song = _searchResults[i];
          return _buildSongTile(song, i);
        },
      ),
    );
  }

  Widget _buildCenterSpectrum() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(9, (i) {
        final phase = i * 0.15;
        final h = 15.0 + math.sin((_spectrumCtrl.value + phase) * 6.28318).abs() * 25;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 4,
            height: h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF00d4ff).withOpacity(0.3 + i * 0.07),
                  const Color(0xFFb388ff).withOpacity(0.2 + i * 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFavoritesList() {
    if (_favorites.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnim,
        child: Center(
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
                    animation: _breatheCtrl,
                    builder: (_, child) => Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent.withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(color: Colors.redAccent.withOpacity(0.1), blurRadius: 10),
                        ],
                      ),
                      child: child,
                    ),
                    child: const Icon(Icons.favorite_border, size: 48, color: Colors.redAccent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _gradientCtrl,
                builder: (_, child) => ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Color.lerp(Colors.white54, const Color(0xFF00d4ff), _gradientCtrl.value)!,
                      Color.lerp(const Color(0xFF00d4ff), Colors.white54, _gradientCtrl.value)!,
                    ],
                  ).createShader(bounds),
                  child: child,
                ),
                child: const Text('收藏列表为空', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const Text('搜索歌曲并添加到收藏', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _favorites.length,
        itemBuilder: (ctx, i) {
          final song = _favorites[i];
          return _buildSongTile(song, i);
        },
      ),
    );
  }

  Widget _buildSongTile(SongItem song, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOut,
      builder: (_, v, __) {
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - v)),
            child: Transform.scale(
              scale: 0.9 + v * 0.1,
              child: Card(
                color: const Color(0xFF1a1a2e).withOpacity(0.8),
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.06)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _playSong(song),
                  splashColor: const Color(0xFF00d4ff).withOpacity(0.15),
                  highlightColor: const Color(0xFF00d4ff).withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // 封面带动画边框
                        AnimatedBuilder(
                          animation: _waveCtrl,
                          builder: (_, child) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF00d4ff).withOpacity(0.2 + _waveCtrl.value * 0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00d4ff).withOpacity(0.06 + _waveCtrl.value * 0.06),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  song.cover.isNotEmpty
                                      ? CachedNetworkImage(imageUrl: song.cover, fit: BoxFit.cover, errorWidget: (_, __, ___) => _musicIcon())
                                      : _musicIcon(),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF00d4ff).withOpacity(0.08),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedBuilder(
                                animation: _highlightCtrl,
                                builder: (_, child) => ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    begin: Alignment(-1.0 + _highlightCtrl.value * 2, 0),
                                    end: Alignment(_highlightCtrl.value * 2, 0),
                                    colors: [
                                      Colors.white,
                                      Color.lerp(Colors.white, const Color(0xFF00d4ff), _highlightCtrl.value)!,
                                      Colors.white,
                                    ],
                                  ).createShader(bounds),
                                  child: child,
                                ),
                                child: Text(song.song, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(height: 3),
                              Text(song.singer, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(song.album, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        // 播放按钮带缩放动画
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.0),
                          duration: Duration(milliseconds: 400 + index * 50),
                          curve: Curves.elasticOut,
                          builder: (_, sv, __) => Transform.scale(
                            scale: sv,
                            child: AnimatedBuilder(
                              animation: _spectrumCtrl,
                              builder: (_, child) => Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00d4ff).withOpacity(0.1 + _spectrumCtrl.value * 0.15),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: child,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.play_circle_fill, color: Color(0xFF00d4ff), size: 32),
                                onPressed: () => _playSong(song),
                              ),
                            ),
                          ),
                        ),
                        FutureBuilder<bool>(
                          future: StorageService.isMusicFavorite(song.id),
                          builder: (_, snap) {
                            final isFav = snap.data ?? false;
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: RotationTransition(turns: Tween<double>(begin: 0.5, end: 0).animate(anim), child: child)),
                              child: IconButton(
                                key: ValueKey(isFav),
                                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : Colors.white54, size: 22),
                                onPressed: () => _toggleFavorite(song),
                              ),
                            );
                          },
                        ),
                      ],
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

  Widget _musicIcon() {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF16213e), Color(0xFF0f3460)])),
      child: const Icon(Icons.music_note, color: Color(0xFF00d4ff), size: 28),
    );
  }

  Widget _buildSoundWave() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(20, (i) {
        final phase = i * 0.15;
        final h = 8.0 + math.sin((_visualizerCtrl.value + phase) * 6.28318).abs() * 20;
        return Container(
          width: 2,
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF00d4ff).withOpacity(0.5 + i * 0.02),
                const Color(0xFFb388ff).withOpacity(0.3 + i * 0.01),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  // _breatheCtrl getter for the favorites empty state
  AnimationController get _breatheCtrl => _floatCtrl;
}

// 浮动音符背景画笔
class _FloatingNotePainter extends CustomPainter {
  final double progress;
  _FloatingNotePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(13);
    for (int i = 0; i < 8; i++) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final y = (baseY - progress * size.height * 0.4) % size.height;
      final opacity = 0.03 + math.sin((progress + i * 0.7) * 6.28318).abs() * 0.04;
      final paint = Paint()
        ..color = const Color(0xFF00d4ff).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final noteSize = 10 + rng.nextDouble() * 10;
      // 画简单的音符形状
      canvas.drawCircle(Offset(x, y + noteSize * 0.6), noteSize * 0.35, paint);
      canvas.drawLine(Offset(x + noteSize * 0.35, y + noteSize * 0.6), Offset(x + noteSize * 0.35, y - noteSize * 0.4), paint);
      canvas.drawLine(Offset(x + noteSize * 0.35, y - noteSize * 0.4), Offset(x + noteSize * 0.7, y - noteSize * 0.2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingNotePainter old) => old.progress != progress;
}