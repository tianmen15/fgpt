import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/wallpaper_scaffold.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with TickerProviderStateMixin {
  List<DownloadItem> _downloads = [];
  bool _isLoading = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadDownloads();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    _animCtrl.reset();
    _animCtrl.forward();

    try {
      final downloads = <DownloadItem>[];
      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/music');
      final imagesDir = Directory('${dir.path}/images');

      // Scan music downloads
      if (await musicDir.exists()) {
        await for (final entity in musicDir.list()) {
          if (entity is File) {
            final stat = await entity.stat();
            downloads.add(DownloadItem(
              path: entity.path,
              name: entity.path.split('/').last,
              size: stat.size,
              modified: stat.modified,
              type: 'music',
            ));
          }
        }
      }

      // Scan image downloads
      if (await imagesDir.exists()) {
        await for (final entity in imagesDir.list()) {
          if (entity is File) {
            final stat = await entity.stat();
            downloads.add(DownloadItem(
              path: entity.path,
              name: entity.path.split('/').last,
              size: stat.size,
              modified: stat.modified,
              type: 'image',
            ));
          }
        }
      }

      // Also scan Downloads directory
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            await for (final entity in downloadDir.list()) {
              if (entity is File) {
                final ext = entity.path.split('.').last.toLowerCase();
                if (['mp3', 'wav', 'flac', 'aac', 'ogg', 'jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mkv']
                    .contains(ext)) {
                  final stat = await entity.stat();
                  downloads.add(DownloadItem(
                    path: entity.path,
                    name: entity.path.split('/').last,
                    size: stat.size,
                    modified: stat.modified,
                    type: ext.startsWith('mp') || ext == 'wav' || ext == 'flac' || ext == 'aac' || ext == 'ogg' ? 'music' : 'image',
                  ));
                }
              }
            }
          }
        }
      } catch (_) {}

      downloads.sort((a, b) => b.modified.compareTo(a.modified));

      if (mounted) {
        setState(() {
          _downloads = downloads;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _typeIcon(String type, String name) {
    final ext = name.split('.').last.toLowerCase();
    if (type == 'music') return Icons.music_note;
    if (type == 'image') return Icons.image;
    if (['mp4', 'mkv', 'avi'].contains(ext)) return Icons.movie;
    return Icons.insert_drive_file;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'music': return Colors.cyanAccent;
      case 'image': return Colors.pinkAccent;
      default: return Colors.purpleAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: const Text('下载管理', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadDownloads,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _downloads.isEmpty
              ? _buildEmpty()
              : _buildDownloadsList(),
    );
  }

  Widget _buildEmpty() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(seconds: 1),
              curve: Curves.elasticOut,
              builder: (_, v, __) => Transform.scale(
                scale: v,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyanAccent.withOpacity(0.1),
                  ),
                  child: const Icon(Icons.download_done, size: 64, color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('暂无下载文件', style: TextStyle(color: Colors.white38, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('下载的音乐和图片会显示在这里', style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadsList() {
    final musicItems = _downloads.where((d) => d.type == 'music').toList();
    final imageItems = _downloads.where((d) => d.type == 'image').toList();
    final otherItems = _downloads.where((d) => d.type != 'music' && d.type != 'image').toList();

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (musicItems.isNotEmpty) ...[
            _sectionHeader('音乐 (${musicItems.length})', Icons.music_note),
            ...musicItems.map((item) => _buildItemCard(item, musicItems.indexOf(item))),
          ],
          if (imageItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionHeader('图片 (${imageItems.length})', Icons.image),
            ...imageItems.map((item) => _buildItemCard(item, imageItems.indexOf(item))),
          ],
          if (otherItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionHeader('其他 (${otherItems.length})', Icons.folder),
            ...otherItems.map((item) => _buildItemCard(item, otherItems.indexOf(item))),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 18),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildItemCard(DownloadItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOut,
      builder: (_, v, __) {
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - v)),
            child: Card(
              color: Colors.white.withOpacity(0.08),
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _typeColor(item.type).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_typeIcon(item.type, item.name), color: _typeColor(item.type), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(_formatSize(item.size), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              const SizedBox(width: 10),
                              Text(_formatDate(item.modified), style: const TextStyle(color: Colors.white24, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                      color: const Color(0xFF1a1a2e),
                      onSelected: (v) {
                        if (v == 'share') {
                          final file = File(item.path);
                          if (file.existsSync()) {
                            Share.shareXFiles([XFile(item.path)], text: item.name);
                          }
                        }
                        if (v == 'delete') {
                          _deleteItem(item);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'share', child: Text('分享', style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteItem(DownloadItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text('删除 "${item.name}"？', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final file = File(item.path);
                if (await file.exists()) {
                  await file.delete();
                }
                _loadDownloads();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已删除'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class DownloadItem {
  final String path;
  final String name;
  final int size;
  final DateTime modified;
  final String type;

  DownloadItem({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
    required this.type,
  });
}