import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/storage_service.dart';
import '../models/models.dart';
import '../widgets/wallpaper_scaffold.dart';
import 'player_screen.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> with TickerProviderStateMixin {
  List<VideoItem> _items = [];
  bool _loading = true;
  late AnimationController _gradientCtrl;
  late AnimationController _dotCtrl;
  late AnimationController _deleteParticleCtrl;

  @override
  void initState() {
    super.initState();
    _gradientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _gradientCtrl.repeat(reverse: true);
    _dotCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _dotCtrl.repeat(reverse: true);
    _deleteParticleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadPlaylist();
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _dotCtrl.dispose();
    _deleteParticleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylist() async {
    final items = await StorageService.getPlaylist();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  Future<void> _deleteItem(VideoItem item) async {
    await StorageService.removeFromPlaylist(item.url);
    await _loadPlaylist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Row(children: [Icon(Icons.delete, color: Colors.white70, size: 18), SizedBox(width: 8), Text('已从列表移除')]), backgroundColor: Colors.redAccent, duration: Duration(seconds: 1)),
      );
    }
  }

  void _playItem(VideoItem item) {
    StorageService.addToHistory(item);
    Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(videoItem: item)));
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, v, __) => Transform.scale(
            scale: v,
            child: AnimatedBuilder(
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
              child: const Text('播放列表', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_items.isNotEmpty)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '${_items.length}项',
                key: ValueKey(_items.length),
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 1),
                curve: Curves.elasticOut,
                builder: (_, v, __) => CircularProgressIndicator(value: v, color: Colors.cyanAccent),
              ),
            )
          : _items.isEmpty
              ? Center(
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
                            animation: _gradientCtrl,
                            builder: (_, child) => Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.cyanAccent.withOpacity(0.05 + _gradientCtrl.value * 0.05),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.05 + _gradientCtrl.value * 0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                            child: const Icon(Icons.playlist_play, size: 48, color: Colors.white38),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('播放列表为空', style: TextStyle(color: Colors.white54, fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text('在首页播放视频后可添加到列表', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _items.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (ctx, i) {
                    final item = _items[i];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 400 + i * 80),
                      curve: Curves.easeOut,
                      builder: (_, v, __) => Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - v)),
                          child: Transform.scale(
                            scale: 0.9 + v * 0.1,
                            child: Row(
                              children: [
                                // 时间线点
                                Column(
                                  children: [
                                    AnimatedBuilder(
                                      animation: _dotCtrl,
                                      builder: (_, __) => Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color.lerp(Colors.cyanAccent, Colors.purpleAccent, _dotCtrl.value),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.cyanAccent.withOpacity(0.3 + _dotCtrl.value * 0.3),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (i < _items.length - 1)
                                      Container(
                                        width: 2,
                                        height: 40,
                                        color: Colors.cyanAccent.withOpacity(0.2),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Dismissible(
                                    key: Key(item.url),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.transparent, Colors.redAccent.withOpacity(0.4)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    confirmDismiss: (_) async {
                                      _deleteParticleCtrl.reset();
                                      _deleteParticleCtrl.forward();
                                      await _deleteItem(item);
                                      return false;
                                    },
                                    child: Stack(
                                      children: [
                                        Card(
                                          color: Colors.white.withOpacity(0.08),
                                          margin: const EdgeInsets.only(bottom: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () => _playItem(item),
                                            onLongPress: () => _deleteItem(item),
                                            splashColor: Colors.cyanAccent.withOpacity(0.3),
                                            child: ListTile(
                                              leading: AnimatedContainer(
                                                duration: const Duration(milliseconds: 300),
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.cyanAccent.withOpacity(0.15),
                                                      Colors.cyanAccent.withOpacity(0.05),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(Icons.video_library, color: Colors.cyanAccent),
                                              ),
                                              title: Text(item.title, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              subtitle: Text(item.url, style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              trailing: AnimatedSwitcher(
                                                duration: const Duration(milliseconds: 200),
                                                child: IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                  onPressed: () => _deleteItem(item),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // 删除粒子效果
                                        if (_deleteParticleCtrl.isAnimating || _deleteParticleCtrl.value > 0)
                                          AnimatedBuilder(
                                            animation: _deleteParticleCtrl,
                                            builder: (_, __) => Positioned.fill(
                                              child: IgnorePointer(
                                                child: CustomPaint(
                                                  painter: _DeleteParticlePainter(_deleteParticleCtrl.value),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// 删除粒子画笔
class _DeleteParticlePainter extends CustomPainter {
  final double progress;
  _DeleteParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(24);
    final colors = [Colors.redAccent, Colors.orangeAccent, Colors.amber];
    for (int i = 0; i < 12; i++) {
      final angle = rng.nextDouble() * 6.28318;
      final distance = progress * size.width * 0.4;
      final x = size.width / 2 + math.cos(angle) * distance;
      final y = size.height / 2 + math.sin(angle) * distance;
      final paint = Paint()
        ..color = colors[rng.nextInt(colors.length)].withOpacity(1 - progress)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 2 + rng.nextDouble() * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DeleteParticlePainter old) => old.progress != progress;
}