import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/storage_service.dart';
import '../models/models.dart';
import '../widgets/wallpaper_scaffold.dart';
import 'player_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  List<VideoItem> _items = [];
  bool _loading = true;
  late AnimationController _gradientCtrl;
  late AnimationController _timelineCtrl;

  @override
  void initState() {
    super.initState();
    _gradientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _gradientCtrl.repeat(reverse: true);
    _timelineCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _timelineCtrl.repeat(reverse: true);
    _loadHistory();
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _timelineCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final items = await StorageService.getHistory();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  void _playItem(VideoItem item) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(videoItem: item)));
  }

  Future<void> _addToPlaylist(VideoItem item) async {
    await StorageService.addToPlaylist(item);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Row(children: [Icon(Icons.check_circle, color: Colors.greenAccent, size: 18), SizedBox(width: 8), Text('已添加到播放列表')]), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
      );
    }
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
              child: const Text('播放历史', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white54),
              onPressed: () async {
                await StorageService.clearHistory();
                await _loadHistory();
              },
              tooltip: '清空历史',
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 1),
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
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyanAccent.withOpacity(0.1)),
                            child: const Icon(Icons.history, size: 48, color: Colors.white38),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('暂无播放历史', style: TextStyle(color: Colors.white54, fontSize: 16)),
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
                                      animation: _timelineCtrl,
                                      builder: (_, __) => Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: i == 0
                                              ? Color.lerp(Colors.cyanAccent, Colors.purpleAccent, _timelineCtrl.value)
                                              : Colors.cyanAccent.withOpacity(0.4 + _timelineCtrl.value * 0.2),
                                          boxShadow: i == 0
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.cyanAccent.withOpacity(0.3 + _timelineCtrl.value * 0.3),
                                                    blurRadius: 6,
                                                  ),
                                                ]
                                              : [],
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
                                  child: Card(
                                    color: Colors.white.withOpacity(0.08),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _playItem(item),
                                      splashColor: Colors.cyanAccent.withOpacity(0.3),
                                      child: ListTile(
                                        leading: AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.cyanAccent.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.play_circle, color: Colors.cyanAccent),
                                        ),
                                        title: Text(item.title, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        subtitle: Text(item.url, style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        trailing: TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.8, end: 1.0),
                                          duration: Duration(milliseconds: 400 + i * 50),
                                          curve: Curves.elasticOut,
                                          builder: (_, sv, __) => Transform.scale(
                                            scale: sv,
                                            child: IconButton(
                                              icon: const Icon(Icons.playlist_add, color: Colors.cyanAccent),
                                              onPressed: () => _addToPlaylist(item),
                                              tooltip: '添加到播放列表',
                                            ),
                                          ),
                                        ),
                                      ),
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