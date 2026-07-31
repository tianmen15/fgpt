import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/wallpaper_scaffold.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> with TickerProviderStateMixin {
  String _currentPath = '';
  List<FileSystemEntity> _items = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  List<String> _pathHistory = [];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _initPath();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _initPath() async {
    try {
      final status = await Permission.storage.request();
      if (status.isGranted || status.isLimited) {
        final dir = await getExternalStorageDirectory();
        String path = dir?.path ?? '/storage/emulated/0';
        // Go up to a reasonable root
        if (path.contains('Android')) {
          path = '/storage/emulated/0';
        }
        _loadDirectory(path);
      } else {
        // Fallback to app directory
        final dir = await getApplicationDocumentsDirectory();
        _loadDirectory(dir.path);
      }
    } catch (e) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        _loadDirectory(dir.path);
      } catch (e2) {
        if (mounted) {
          setState(() {
            _error = '无法访问文件系统';
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _loadDirectory(String path) async {
    setState(() => _isLoading = true);
    _animCtrl.reset();
    _animCtrl.forward();
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        final items = await dir.list().toList();
        items.sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir && !bIsDir) return -1;
          if (!aIsDir && bIsDir) return 1;
          final aName = a.path.split('/').last.toLowerCase();
          final bName = b.path.split('/').last.toLowerCase();
          return aName.compareTo(bName);
        });
        if (mounted) {
          setState(() {
            _currentPath = path;
            _items = items;
            _isLoading = false;
            _error = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = '目录不存在';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '访问被拒绝: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateTo(String path) {
    _pathHistory.add(_currentPath);
    _loadDirectory(path);
  }

  void _goBack() {
    if (_pathHistory.isNotEmpty) {
      _loadDirectory(_pathHistory.removeLast());
    } else {
      final parent = Directory(_currentPath).parent.path;
      if (parent != _currentPath) {
        _loadDirectory(parent);
      }
    }
  }

  bool _canGoBack() {
    return _pathHistory.isNotEmpty || Directory(_currentPath).parent.path != _currentPath;
  }

  IconData _fileIcon(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (FileSystemEntity.isDirectorySync(path)) return Icons.folder;
    switch (ext) {
      case 'mp4': case 'mkv': case 'avi': case 'mov': case 'webm': return Icons.movie;
      case 'mp3': case 'wav': case 'flac': case 'aac': case 'ogg': return Icons.music_note;
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'bmp': case 'webp': return Icons.image;
      case 'pdf': return Icons.picture_as_pdf;
      case 'zip': case 'rar': case '7z': case 'tar': case 'gz': return Icons.archive;
      case 'apk': return Icons.android;
      case 'txt': case 'md': case 'json': case 'xml': return Icons.description;
      default: return Icons.insert_drive_file;
    }
  }

  Color _fileColor(String path) {
    if (FileSystemEntity.isDirectorySync(path)) return Colors.amber;
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp4': case 'mkv': case 'avi': return Colors.purpleAccent;
      case 'mp3': case 'wav': case 'flac': return Colors.cyanAccent;
      case 'jpg': case 'png': case 'gif': return Colors.pinkAccent;
      default: return Colors.white54;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showFileInfo(FileSystemEntity entity) async {
    final stat = await entity.stat();
    final name = entity.path.split('/').last;
    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1a1a2e),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Icon(_fileIcon(entity.path), size: 48, color: _fileColor(entity.path)),
              const SizedBox(height: 12),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _infoRow('路径', entity.path),
              _infoRow('大小', _formatSize(stat.size)),
              _infoRow('类型', entity is Directory ? '文件夹' : '文件'),
              _infoRow('修改时间', stat.modified.toString()),
              if (entity is File) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Share.shareXFiles([XFile(entity.path)], text: name);
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('分享'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteDialog(entity);
                        },
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('删除'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  void _showDeleteDialog(FileSystemEntity entity) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text('确定要删除 "${entity.path.split('/').last}" 吗？', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (entity is Directory) {
                  await entity.delete(recursive: true);
                } else {
                  await entity.delete();
                }
                _loadDirectory(_currentPath);
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

  void _showRenameDialog(FileSystemEntity entity) {
    final controller = TextEditingController(text: entity.path.split('/').last);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('重命名', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final newPath = '${Directory(_currentPath).path}/$newName';
                try {
                  await entity.rename(newPath);
                  _loadDirectory(_currentPath);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已重命名'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('重命名失败: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              }
            },
            child: const Text('确定', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: Column(
          children: [
            const Text('文件管理', style: TextStyle(color: Colors.white, fontSize: 18)),
            if (_currentPath.isNotEmpty)
              Text(
                _currentPath.split('/').last,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _canGoBack()
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack)
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => _loadDirectory(_currentPath),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initPath,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.folder_open, size: 64, color: Colors.white24),
                              const SizedBox(height: 16),
                              const Text('此目录为空', style: TextStyle(color: Colors.white38)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _items.length,
                          itemBuilder: (ctx, i) {
                            final item = _items[i];
                            final name = item.path.split('/').last;
                            final isDir = item is Directory;

                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 200 + i * 30),
                              curve: Curves.easeOut,
                              builder: (_, v, __) {
                                return Opacity(
                                  opacity: v,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - v)),
                                    child: Card(
                                      color: Colors.white.withOpacity(0.06),
                                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      child: ListTile(
                                        leading: Icon(_fileIcon(item.path), color: _fileColor(item.path), size: 28),
                                        title: Text(name, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        subtitle: isDir
                                            ? const Text('文件夹', style: TextStyle(color: Colors.white38, fontSize: 11))
                                            : FutureBuilder<FileStat>(
                                                future: item.stat(),
                                                builder: (_, snap) {
                                                  return Text(
                                                    snap.hasData ? _formatSize(snap.data!.size) : '...',
                                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                                  );
                                                },
                                              ),
                                        trailing: PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, color: Colors.white54),
                                          color: const Color(0xFF1a1a2e),
                                          onSelected: (v) {
                                            if (v == 'info') _showFileInfo(item);
                                            if (v == 'rename') _showRenameDialog(item);
                                            if (v == 'share') {
                                              if (item is File) {
                                                Share.shareXFiles([XFile(item.path)], text: name);
                                              }
                                            }
                                            if (v == 'delete') _showDeleteDialog(item);
                                          },
                                          itemBuilder: (ctx) => [
                                            const PopupMenuItem(value: 'info', child: Text('信息', style: TextStyle(color: Colors.white))),
                                            const PopupMenuItem(value: 'rename', child: Text('重命名', style: TextStyle(color: Colors.white))),
                                            if (item is File)
                                              const PopupMenuItem(value: 'share', child: Text('分享', style: TextStyle(color: Colors.white))),
                                            const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.redAccent))),
                                          ],
                                        ),
                                        onTap: () {
                                          if (isDir) {
                                            _navigateTo(item.path);
                                          } else {
                                            _showFileInfo(item);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
    );
  }
}