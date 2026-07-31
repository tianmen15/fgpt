import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/wallpaper_scaffold.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with TickerProviderStateMixin {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  String _searchQuery = '';
  bool _isSearching = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.repeat(reverse: true);
    _loadNotes();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('notes');
    if (data != null) {
      final list = (jsonDecode(data) as List).map((e) => Note.fromJson(e)).toList();
      if (mounted) {
        setState(() {
          _notes = list;
          _filterNotes();
        });
      }
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes', jsonEncode(_notes.map((e) => e.toJson()).toList()));
  }

  void _filterNotes() {
    if (_searchQuery.isEmpty) {
      _filteredNotes = List.from(_notes);
    } else {
      _filteredNotes = _notes.where((n) =>
        n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        n.content.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    setState(() {});
  }

  Future<void> _addOrEditNote({Note? existing}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _NoteEditorScreen(note: existing)),
    );
    if (result == true) {
      _animCtrl.reset();
      _animCtrl.forward();
      _loadNotes();
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('删除笔记', style: TextStyle(color: Colors.white)),
        content: Text('确定要删除 "${note.title}" 吗？', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      _notes.removeWhere((n) => n.id == note.id);
      await _saveNotes();
      _filterNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('笔记已删除'), backgroundColor: Colors.redAccent, duration: Duration(seconds: 1)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSearching
              ? TextField(
                  key: const ValueKey('search'),
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '搜索笔记...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                  onChanged: (v) {
                    _searchQuery = v;
                    _filterNotes();
                  },
                )
              : const Text('记事本', key: ValueKey('title'), style: TextStyle(color: Colors.white)),
        ),
        centerTitle: !_isSearching,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                _searchQuery = '';
                _filterNotes();
              });
            },
          ),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.cyanAccent, size: 28),
              onPressed: () => _addOrEditNote(),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        elevation: 8,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_filteredNotes.isEmpty) {
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
                      gradient: LinearGradient(
                        colors: [Colors.cyanAccent.withOpacity(0.1), Colors.purpleAccent.withOpacity(0.1)],
                      ),
                    ),
                    child: Icon(Icons.note_add, size: 64, color: _searchQuery.isNotEmpty ? Colors.white24 : Colors.cyanAccent.withOpacity(0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _searchQuery.isNotEmpty ? '未找到匹配的笔记' : '还没有笔记',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty ? '尝试其他关键词' : '点击右下角按钮创建笔记',
                style: const TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredNotes.length,
        itemBuilder: (ctx, i) {
          final note = _filteredNotes[i];
          return _buildNoteCard(note, i);
        },
      ),
    );
  }

  Widget _buildNoteCard(Note note, int index) {
    final preview = note.content.length > 80 ? '${note.content.substring(0, 80)}...' : note.content;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 60),
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
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _addOrEditNote(existing: note),
                  splashColor: Colors.cyanAccent.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF6a11cb), Color(0xFF2575fc)]),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.notes, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                note.title.isNotEmpty ? note.title : '无标题',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatDate(note.updatedAt),
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                        if (preview.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              preview,
                              style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.cyanAccent, size: 18),
                              onPressed: () => _addOrEditNote(existing: note),
                              tooltip: '编辑',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                              onPressed: () => _deleteNote(note),
                              tooltip: '删除',
                            ),
                          ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}/${date.day}';
  }
}

class _NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const _NoteEditorScreen({this.note});

  @override
  State<_NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<_NoteEditorScreen> with TickerProviderStateMixin {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.note?.content ?? '');
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('notes');
    List<Note> notes = [];
    if (data != null) {
      notes = (jsonDecode(data) as List).map((e) => Note.fromJson(e)).toList();
    }

    if (widget.note != null) {
      final idx = notes.indexWhere((n) => n.id == widget.note!.id);
      if (idx >= 0) {
        notes[idx] = Note(
          id: widget.note!.id,
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          createdAt: widget.note!.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    } else {
      notes.insert(0, Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    await prefs.setString('notes', jsonEncode(notes.map((e) => e.toJson()).toList()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('笔记已保存'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a1a),
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: Text(widget.note != null ? '编辑笔记' : '新建笔记', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check, color: Colors.cyanAccent),
            label: const Text('保存', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '标题',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (_) => setState(() => _hasChanges = true),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _contentCtrl,
                  style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
                  decoration: InputDecoration(
                    hintText: '开始输入...',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    contentPadding: const EdgeInsets.all(16),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (_) => setState(() => _hasChanges = true),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '字数: ${_contentCtrl.text.length} | 字符: ${_contentCtrl.text.characters.length}',
                style: const TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}