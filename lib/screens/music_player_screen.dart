import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import '../services/music_service.dart';
import '../services/storage_service.dart';
import '../models/models.dart';
import '../widgets/wallpaper_scaffold.dart';

/// LRC歌词行
class _LyricLine {
  final Duration timestamp;
  final String text;
  const _LyricLine({required this.timestamp, required this.text});
}

/// 解析LRC格式歌词
List<_LyricLine> _parseLyric(String lrc) {
  final lines = <_LyricLine>[];
  final regex = RegExp(r'\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]');
  for (final line in lrc.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final matches = regex.allMatches(trimmed).toList();
    if (matches.isEmpty) continue;
    final text = trimmed.substring(matches.last.end).trim();
    if (text.isEmpty) continue;
    for (final match in matches) {
      final min = int.parse(match.group(1)!);
      final sec = int.parse(match.group(2)!);
      final ms = match.group(3) != null
          ? int.parse(match.group(3)!.padRight(3, '0').substring(0, 3))
          : 0;
      final duration = Duration(minutes: min, seconds: sec, milliseconds: ms);
      lines.add(_LyricLine(timestamp: duration, text: text));
    }
  }
  lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return lines;
}

/// 10段均衡器频段定义
class _EqBand {
  final String freq;
  final String label;
  const _EqBand({required this.freq, required this.label});
}

const List<_EqBand> _eqBandsDef = [
  _EqBand(freq: '32Hz', label: '超低音'),
  _EqBand(freq: '64Hz', label: '低音'),
  _EqBand(freq: '125Hz', label: '中低音'),
  _EqBand(freq: '250Hz', label: '低中音'),
  _EqBand(freq: '500Hz', label: '中音'),
  _EqBand(freq: '1kHz', label: '中高音'),
  _EqBand(freq: '2kHz', label: '高音'),
  _EqBand(freq: '4kHz', label: '超高音'),
  _EqBand(freq: '8kHz', label: '极高频'),
  _EqBand(freq: '16kHz', label: '空气感'),
];

/// EQ预设: 每个值范围0.0~1.0，映射到-12dB~+12dB（0.5=0dB）
const Map<String, List<double>> _eqPresets = {
  '正常': [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
  '古典': [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.4, 0.4, 0.35, 0.35],
  '舞曲': [0.65, 0.6, 0.5, 0.55, 0.6, 0.6, 0.55, 0.5, 0.5, 0.5],
  '电子': [0.7, 0.65, 0.5, 0.4, 0.5, 0.6, 0.7, 0.65, 0.6, 0.55],
  '嘻哈': [0.7, 0.65, 0.5, 0.4, 0.45, 0.5, 0.55, 0.5, 0.5, 0.5],
  '爵士': [0.55, 0.55, 0.5, 0.55, 0.55, 0.5, 0.45, 0.4, 0.35, 0.35],
  '流行': [0.45, 0.5, 0.55, 0.6, 0.55, 0.5, 0.45, 0.45, 0.45, 0.45],
  '摇滚': [0.6, 0.55, 0.4, 0.5, 0.55, 0.6, 0.6, 0.55, 0.5, 0.5],
  '人声': [0.45, 0.5, 0.55, 0.6, 0.65, 0.6, 0.5, 0.45, 0.4, 0.4],
  '低音增强': [0.75, 0.7, 0.6, 0.5, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45],
};

class MusicPlayerScreen extends StatefulWidget {
  final SongItem song;
  final List<SongItem>? songList;
  final int? currentIndex;

  const MusicPlayerScreen({
    super.key,
    required this.song,
    this.songList,
    this.currentIndex,
  });

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _lyricRaw;
  List<_LyricLine> _lyricLines = [];
  bool _showLyricFullscreen = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  bool _isFavorite = false;
  bool _showQueue = false;
  bool _showEqPanel = false;

  late SongItem _currentSong;
  late List<SongItem> _songList;
  late int _currentIndex;

  // 播放速度
  double _playbackSpeed = 1.0;
  static const List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  // 睡眠定时器
  Timer? _sleepTimer;
  int _sleepMinutesLeft = 0;
  static const List<int> _sleepOptions = [15, 30, 45, 60, 90, 120];

  // 10段均衡器 (0.0~1.0 映射到 -12dB~+12dB, 0.5=0dB)
  List<double> _eqBands = List.filled(10, 0.5);
  String _selectedPreset = '正常';

  // Replay Gain & Crossfade
  bool _replayGainEnabled = false;
  double _crossfadeDuration = 0.0; // 秒

  // 频谱可视化器数据
  List<double> _spectrumData = List.filled(32, 0.05);
  Timer? _spectrumTimer;
  final math.Random _random = math.Random();

  // 动画控制器
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _gradientController;
  late AnimationController _glowController;
  late AnimationController _eqBarsController;
  late AnimationController _waveController;
  late AnimationController _lyricFadeController;
  late AnimationController _beatPulseController;
  late AnimationController _spectrumAnimController;

  // 歌词滚动
  final ScrollController _lyricScrollController = ScrollController();
  int _currentLyricIndex = -1;
  bool _isLyricAutoScroll = true;
  Timer? _lyricScrollDebounce;

  // 进度条
  double _positionSeconds = 0;
  double _durationSeconds = 0;
  bool _isSeeking = false;

  // 歌词卡拉OK填充进度
  double _lyricFillProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _currentSong = widget.song;
    _songList = widget.songList ?? [widget.song];
    _currentIndex = widget.currentIndex ?? 0;

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _eqBarsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _lyricFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _beatPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _spectrumAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _loadSong();
    _checkFavorite();
    _setupAudioListeners();
    _startSpectrumSimulation();
  }

  void _startSpectrumSimulation() {
    _spectrumTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _spectrumData.length; i++) {
          final base = _isPlaying ? 0.15 : 0.03;
          final variation = _isPlaying ? _random.nextDouble() * 0.85 : _random.nextDouble() * 0.1;
          _spectrumData[i] = _spectrumData[i] * 0.7 + (base + variation) * 0.3;
        }
      });
    });
  }

  void _setupAudioListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
      if (state.playing) {
        _rotateController.repeat();
        _pulseController.repeat(reverse: true);
        _beatPulseController.repeat(reverse: true);
      } else {
        _rotateController.stop();
        _pulseController.stop();
        _beatPulseController.stop();
        _beatPulseController.value = 0;
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (!mounted) return;
      if (!_isSeeking) {
        setState(() => _positionSeconds = position.inMilliseconds / 1000.0);
      }
      _updateLyricPosition(position);
      // 更新歌词卡拉OK填充进度 (基于当前歌词行的时间)
      _updateLyricFillProgress(position);
    });

    _audioPlayer.durationStream.listen((duration) {
      if (!mounted) return;
      if (duration != null) {
        setState(() => _durationSeconds = duration.inMilliseconds / 1000.0);
      }
    });

    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  void _updateLyricFillProgress(Duration position) {
    if (_lyricLines.isEmpty || _currentLyricIndex < 0) {
      _lyricFillProgress = 0;
      return;
    }
    final current = _lyricLines[_currentLyricIndex];
    final nextIndex = _currentLyricIndex + 1;
    final Duration nextTimestamp;
    if (nextIndex < _lyricLines.length) {
      nextTimestamp = _lyricLines[nextIndex].timestamp;
    } else {
      nextTimestamp = current.timestamp + const Duration(seconds: 5);
    }
    final total = nextTimestamp.inMilliseconds - current.timestamp.inMilliseconds;
    if (total <= 0) {
      _lyricFillProgress = 1.0;
      return;
    }
    final elapsed = position.inMilliseconds - current.timestamp.inMilliseconds;
    _lyricFillProgress = (elapsed / total).clamp(0.0, 1.0);
  }

  void _updateLyricPosition(Duration position) {
    if (_lyricLines.isEmpty) return;
    int newIndex = -1;
    for (int i = _lyricLines.length - 1; i >= 0; i--) {
      if (position >= _lyricLines[i].timestamp) {
        newIndex = i;
        break;
      }
    }
    if (newIndex != _currentLyricIndex) {
      setState(() {
        _currentLyricIndex = newIndex;
        _lyricFillProgress = 0.0;
      });
      if (_isLyricAutoScroll && _lyricScrollController.hasClients) {
        _lyricScrollDebounce?.cancel();
        _lyricScrollDebounce = Timer(const Duration(milliseconds: 50), () {
          if (_isLyricAutoScroll && _lyricScrollController.hasClients) {
            final targetOffset = (math.max(0, (newIndex * 56.0) - 120)).toDouble();
            _lyricScrollController.animateTo(
              targetOffset,
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
            );
          }
        });
      }
    }
  }

  Future<void> _loadSong() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        MusicService.getSongById(id: _currentSong.id),
        MusicService.getLyric(id: _currentSong.id),
        MusicService.getSongDetail(existing: _currentSong),
      ]);

      final songUrl = results[0] as SongItem?;
      final lyric = results[1] as String?;
      final songDetail = results[2] as SongItem?;

      if (songUrl != null && songUrl.url.isNotEmpty) {
        _currentSong = _currentSong.copyWith(url: songUrl.url, quality: 'exhigh');
      }
      if (songDetail != null) {
        _currentSong = songDetail.copyWith(url: _currentSong.url);
      }
      if (lyric != null && lyric.isNotEmpty) {
        _lyricRaw = lyric;
        _lyricLines = _parseLyric(lyric);
      }

      if (_currentSong.url.isNotEmpty) {
        try {
          await _audioPlayer.setUrl(_currentSong.url).timeout(const Duration(seconds: 15));
        } catch (_) {}
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkFavorite() async {
    final fav = await StorageService.isMusicFavorite(_currentSong.id);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await StorageService.removeMusicFavorite(_currentSong.id);
    } else {
      await StorageService.addMusicFavorite(_currentSong);
    }
    if (mounted) {
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? '已添加到收藏' : '已取消收藏'),
          backgroundColor: _isFavorite ? Colors.green : Colors.grey,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> _playPrevious() async {
    if (_currentIndex > 0) {
      _switchToSong(_currentIndex - 1);
    } else {
      await _audioPlayer.seek(Duration.zero);
    }
  }

  Future<void> _playNext() async {
    if (_currentIndex < _songList.length - 1) {
      _switchToSong(_currentIndex + 1);
    }
  }

  Future<void> _switchToSong(int index) async {
    if (index < 0 || index >= _songList.length) return;
    setState(() {
      _currentIndex = index;
      _currentSong = _songList[index];
      _lyricRaw = null;
      _lyricLines = [];
      _currentLyricIndex = -1;
      _positionSeconds = 0;
      _durationSeconds = 0;
      _lyricFillProgress = 0;
    });
    await _audioPlayer.stop();
    await _loadSong();
    await _checkFavorite();
    if (_isPlaying) {
      await _audioPlayer.play();
    }
  }

  void _setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      _audioPlayer.pause();
      if (mounted) {
        setState(() {
          _sleepMinutesLeft = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('睡眠定时结束，播放已暂停'),
            backgroundColor: Colors.indigo,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
    setState(() {
      _sleepMinutesLeft = minutes;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('睡眠定时器已设置: $minutes 分钟'),
        backgroundColor: Colors.indigo,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    setState(() => _sleepMinutesLeft = 0);
  }

  void _setPlaybackSpeed(double speed) {
    _audioPlayer.setSpeed(speed);
    setState(() {
      _playbackSpeed = speed;
    });
  }

  void _applyEqPreset(String presetName) {
    final preset = _eqPresets[presetName];
    if (preset != null) {
      setState(() {
        _eqBands = List.from(preset);
        _selectedPreset = presetName;
      });
    }
  }

  double _eqBandToDb(double value) => (value - 0.5) * 24; // 0.5→0dB, 0→-12dB, 1→+12dB
  double _dbToEqBand(double db) => (db / 24) + 0.5;

  Future<void> _downloadSong() async {
    if (_currentSong.url.isEmpty) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final ext = _currentSong.url.split('.').last.split('?').first;
      final safeExt = ext.length <= 5 ? ext : 'mp3';
      final filePath =
          '${dir.path}/${_currentSong.song} - ${_currentSong.singer}.$safeExt';

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_currentSong.url));
      final response =
          await client.send(request).timeout(const Duration(seconds: 120));

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final file = File(filePath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0 && mounted) {
          setState(() => _downloadProgress = receivedBytes / totalBytes);
        }
      }

      await sink.close();
      client.close();

      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载完成: ${_currentSong.song}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareSong() async {
    final text = '${_currentSong.song} - ${_currentSong.singer}\n${_currentSong.url}';
    final uri = Uri.encodeComponent(text);
    final url = Uri.parse('https://t.me/share/url?url=$uri');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  String _formatTime(double seconds) {
    final totalSecs = seconds.toInt();
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _lyricScrollDebounce?.cancel();
    _spectrumTimer?.cancel();
    _audioPlayer.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _gradientController.dispose();
    _glowController.dispose();
    _eqBarsController.dispose();
    _waveController.dispose();
    _lyricFadeController.dispose();
    _beatPulseController.dispose();
    _spectrumAnimController.dispose();
    _lyricScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingView() : _buildPlayerBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black54,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentSong.song.isNotEmpty ? _currentSong.song : '未知歌曲',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          if (_currentSong.singer.isNotEmpty)
            Text(
              _currentSong.singer,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      centerTitle: true,
      actions: [
        if (_sleepMinutesLeft > 0)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_sleepMinutesLeft}分',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white70),
          onPressed: _shareSong,
          tooltip: '分享',
        ),
        IconButton(
          icon: Icon(
            _isDownloading ? Icons.downloading : Icons.file_download,
            color: _isDownloading ? Colors.orange : Colors.white70,
          ),
          onPressed: _isDownloading ? null : _downloadSong,
          tooltip: '下载',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          color: const Color(0xFF1e1e2e),
          onSelected: (value) {
            switch (value) {
              case 'speed':
                _showSpeedMenu();
                break;
              case 'sleep':
                _showSleepTimerDialog();
                break;
              case 'eq':
                setState(() => _showEqPanel = !_showEqPanel);
                break;
              case 'queue':
                setState(() => _showQueue = !_showQueue);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'speed', child: ListTile(leading: Icon(Icons.speed, color: Colors.white70), title: Text('播放速度', style: TextStyle(color: Colors.white)), dense: true)),
            const PopupMenuItem(value: 'sleep', child: ListTile(leading: Icon(Icons.bedtime, color: Colors.white70), title: Text('睡眠定时', style: TextStyle(color: Colors.white)), dense: true)),
            const PopupMenuItem(value: 'eq', child: ListTile(leading: Icon(Icons.equalizer, color: Colors.white70), title: Text('均衡器', style: TextStyle(color: Colors.white)), dense: true)),
            const PopupMenuItem(value: 'queue', child: ListTile(leading: Icon(Icons.queue_music, color: Colors.white70), title: Text('播放队列', style: TextStyle(color: Colors.white)), dense: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _eqBarsController,
            builder: (_, __) => _buildMiniEqualizer(),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _glowController,
            builder: (_, child) => Opacity(
              opacity: 0.5 + _glowController.value * 0.5,
              child: child,
            ),
            child: const Text(
              '加载中...',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerBody() {
    return SafeArea(
      child: GestureDetector(
        onVerticalDragUpdate: _showLyricFullscreen ? null : (details) {
          if (details.primaryDelta != null && details.primaryDelta! < -30 && _lyricLines.isNotEmpty) {
            setState(() => _showLyricFullscreen = true);
          }
        },
        child: _showLyricFullscreen
            ? _buildLyricFullscreen()
            : _buildMainPlayer(),
      ),
    );
  }

  // ========== Now Playing 通知栏 ==========
  Widget _buildNowPlayingBar() {
    return AnimatedBuilder(
      animation: _beatPulseController,
      builder: (_, __) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.cyanAccent.withOpacity(0.08 + _beatPulseController.value * 0.04),
                Colors.purpleAccent.withOpacity(0.06 + _beatPulseController.value * 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.cyanAccent.withOpacity(0.15 + _beatPulseController.value * 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPlaying
                      ? Color.lerp(Colors.cyanAccent, Colors.greenAccent, _beatPulseController.value)
                      : Colors.white38,
                  boxShadow: _isPlaying
                      ? [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.5 + _beatPulseController.value * 0.3),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.music_note, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Text(
                '正在播放',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_replayGainEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'RG',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              if (_replayGainEnabled && _crossfadeDuration > 0) const SizedBox(width: 4),
              if (_crossfadeDuration > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'XF ${_crossfadeDuration.toStringAsFixed(1)}s',
                    style: const TextStyle(color: Colors.purpleAccent, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ========== 主播放界面 ==========
  Widget _buildMainPlayer() {
    return Column(
      children: [
        _buildNowPlayingBar(),
        if (_isDownloading) _buildDownloadProgress(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                _buildAlbumArt(),
                const SizedBox(height: 20),
                _buildSongInfo(),
                const SizedBox(height: 6),
                _buildSpectrumVisualizer(),
                const SizedBox(height: 4),
                _buildLyricPreview(),
              ],
            ),
          ),
        ),
        _buildProgressBar(),
        _buildPlaybackControls(),
        _buildBottomActionBar(),
        if (_showEqPanel) _buildGraphicEqPanel(),
        if (_showQueue) _buildQueuePanel(),
        const SizedBox(height: 8),
      ],
    );
  }

  // ========== 专辑封面（带节拍脉冲） ==========
  Widget _buildAlbumArt() {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotateController, _beatPulseController]),
      builder: (_, child) {
        final beatScale = _isPlaying ? (1.0 + _beatPulseController.value * 0.04) : 1.0;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _isPlaying
                        ? Color.lerp(
                            Colors.cyanAccent.withOpacity(0.3),
                            Colors.purpleAccent.withOpacity(0.35),
                            _beatPulseController.value,
                          )!
                        : Colors.cyanAccent.withOpacity(0.08),
                    blurRadius: _isPlaying ? 50 + _beatPulseController.value * 15 : 25,
                    spreadRadius: _isPlaying ? 10 + _beatPulseController.value * 5 : 0,
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: beatScale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 2,
                  ),
                ),
                child: Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi,
                  child: ClipOval(
                    child: _currentSong.cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _currentSong.cover,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _defaultAlbumCover(),
                            errorWidget: (_, __, ___) => _defaultAlbumCover(),
                          )
                        : _defaultAlbumCover(),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _beatPulseController,
              builder: (_, child) => Transform.scale(
                scale: _isPlaying ? (1.0 + _beatPulseController.value * 0.08) : 1.0,
                child: child,
              ),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0a0a0a),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: const Center(
                  child: Icon(Icons.music_note, size: 16, color: Colors.white54),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _defaultAlbumCover() {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1a1a4e),
                const Color(0xFF0f3460),
                Color.lerp(const Color(0xFF1a1a4e), const Color(0xFF16213e), _gradientController.value)!,
                const Color(0xFF0f3460),
              ],
            ),
          ),
          child: const Center(
            child: Icon(Icons.music_note, size: 80, color: Colors.cyanAccent),
          ),
        );
      },
    );
  }

  // ========== 歌曲信息 ==========
  Widget _buildSongInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _gradientController,
            builder: (_, child) => ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Color.lerp(Colors.white, Colors.cyanAccent, _gradientController.value)!,
                  Color.lerp(Colors.cyanAccent, Colors.purpleAccent, _gradientController.value)!,
                ],
              ).createShader(bounds),
              child: child,
            ),
            child: Text(
              _currentSong.song.isNotEmpty ? _currentSong.song : '未知歌曲',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentSong.singer.isNotEmpty ? _currentSong.singer : '未知歌手',
            style: const TextStyle(color: Colors.white60, fontSize: 15),
          ),
          const SizedBox(height: 2),
          if (_currentSong.album.isNotEmpty)
            Text(
              _currentSong.album,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          const SizedBox(height: 8),
          if (_currentSong.quality.isNotEmpty || _currentSong.interval.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentSong.quality.isNotEmpty)
                  _tagChip(_currentSong.quality, Icons.music_note),
                if (_currentSong.quality.isNotEmpty && _currentSong.interval.isNotEmpty)
                  const SizedBox(width: 8),
                if (_currentSong.interval.isNotEmpty)
                  _tagChip(_currentSong.interval, Icons.timer),
                if (_currentSong.size.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _tagChip(_currentSong.size, Icons.storage),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _tagChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white54),
          const SizedBox(width: 3),
          Text(text, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  // ========== 频谱可视化器 ==========
  Widget _buildSpectrumVisualizer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(_spectrumData.length, (i) {
            final height = math.max(4, _spectrumData[i] * 48);
            final hue = (i / _spectrumData.length * 360).toInt();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
                width: math.max(2, (MediaQuery.of(context).size.width - 60) / _spectrumData.length - 2),
                height: height.toDouble(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      HSLColor.fromAHSL(1.0, hue.toDouble(), 0.8, 0.6).toColor(),
                      HSLColor.fromAHSL(0.5, hue.toDouble(), 0.6, 0.5).toColor(),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ========== 均衡器预览 ==========
  Widget _buildEqualizerPreview() {
    return AnimatedBuilder(
      animation: _eqBarsController,
      builder: (_, __) => _buildMiniEqualizer(),
    );
  }

  Widget _buildMiniEqualizer() {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(20, (i) {
          final phase = i * 0.15;
          final height = 10 +
              math.sin((_eqBarsController.value + phase) * 6.28318).abs() *
                  26;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: 2.5,
              height: height.toDouble(),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.cyanAccent.withOpacity(0.5 + i * 0.025),
                    Colors.purpleAccent.withOpacity(0.3 + i * 0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ========== 歌词预览 ==========
  Widget _buildLyricPreview() {
    if (_lyricLines.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => setState(() => _showLyricFullscreen = true),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _currentLyricIndex >= 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_currentLyricIndex > 0)
                          Opacity(
                            opacity: 0.4,
                            child: Text(
                              _lyricLines[_currentLyricIndex - 1].text,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (_, v, __) => Transform.scale(
                            scale: v,
                            child: _buildKaraokeText(
                              _lyricLines[_currentLyricIndex].text,
                              _lyricFillProgress,
                              fontSize: 16,
                              isActive: true,
                            ),
                          ),
                        ),
                        if (_currentLyricIndex < _lyricLines.length - 1)
                          Opacity(
                            opacity: 0.3,
                            child: Text(
                              _lyricLines[_currentLyricIndex + 1].text,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    _lyricLines.isNotEmpty ? _lyricLines.first.text : '',
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ),
    );
  }

  /// 卡拉OK风格的歌词文字填充效果
  Widget _buildKaraokeText(String text, double progress, {double fontSize = 16, bool isActive = true}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 底层：未填充的灰色文字
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // 上层：填充的青色文字（从左到右裁剪）
        ClipRect(
          clipper: _ProgressClipper(progress),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: Colors.cyanAccent.withOpacity(0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  // ========== 进度条 ==========
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: Colors.cyanAccent,
              inactiveTrackColor: Colors.white.withOpacity(0.15),
              thumbColor: Colors.cyanAccent,
              overlayColor: Colors.cyanAccent.withOpacity(0.15),
            ),
            child: Slider(
              min: 0,
              max: _durationSeconds > 0 ? _durationSeconds : 1.0,
              value: _positionSeconds.clamp(0, _durationSeconds > 0 ? _durationSeconds : 1.0),
              onChanged: (v) {
                setState(() {
                  _positionSeconds = v;
                  _isSeeking = true;
                });
              },
              onChangeEnd: (v) {
                _audioPlayer.seek(Duration(milliseconds: (v * 1000).toInt()));
                setState(() => _isSeeking = false);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(_positionSeconds),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                Text(
                  _formatTime(_durationSeconds),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== 播放控制 ==========
  Widget _buildPlaybackControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.shuffle, color: Colors.white38, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 38),
            onPressed: _playPrevious,
          ),
          AnimatedBuilder(
            animation: _beatPulseController,
            builder: (_, child) => Transform.scale(
              scale: _isPlaying ? (1.0 + _beatPulseController.value * 0.08) : 1.0,
              child: child,
            ),
            child: GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.cyanAccent, Color(0xFF00bcd4)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(_isPlaying ? 0.5 : 0.2),
                      blurRadius: _isPlaying ? 30 : 15,
                      spreadRadius: _isPlaying ? 4 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
                  size: 40,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 38),
            onPressed: _playNext,
          ),
          IconButton(
            icon: const Icon(Icons.repeat, color: Colors.white38, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ========== 底部操作栏 ==========
  Widget _buildBottomActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton(
            icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.redAccent : Colors.white54,
            onTap: _toggleFavorite,
            tooltip: '收藏',
          ),
          _actionButton(
            icon: Icons.speed,
            color: _playbackSpeed != 1.0 ? Colors.cyanAccent : Colors.white54,
            label: '${_playbackSpeed}x',
            onTap: _showSpeedMenu,
            tooltip: '播放速度',
          ),
          _actionButton(
            icon: Icons.bedtime,
            color: _sleepMinutesLeft > 0 ? Colors.indigo : Colors.white54,
            label: _sleepMinutesLeft > 0 ? '${_sleepMinutesLeft}分' : null,
            onTap: _showSleepTimerDialog,
            tooltip: '睡眠定时',
          ),
          _actionButton(
            icon: Icons.equalizer,
            color: _showEqPanel ? Colors.cyanAccent : Colors.white54,
            onTap: () => setState(() => _showEqPanel = !_showEqPanel),
            tooltip: '均衡器',
          ),
          _actionButton(
            icon: Icons.queue_music,
            color: _showQueue ? Colors.cyanAccent : Colors.white54,
            onTap: () => setState(() => _showQueue = !_showQueue),
            tooltip: '播放队列',
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    String? label,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            if (label != null)
              Text(
                label,
                style: TextStyle(color: color, fontSize: 9),
              ),
          ],
        ),
      ),
    );
  }

  // ========== 下载进度 ==========
  Widget _buildDownloadProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(Colors.cyanAccent),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '下载中 ${(_downloadProgress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ========== 歌词全屏（Apple Music风格） ==========
  Widget _buildLyricFullscreen() {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
          setState(() => _showLyricFullscreen = false);
        }
      },
      child: AnimatedBuilder(
        animation: _gradientController,
        builder: (_, __) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF0a0a1a), const Color(0xFF1a0a2e), _gradientController.value)!,
                  Color.lerp(const Color(0xFF0f0f2e), const Color(0xFF16213e), _gradientController.value)!,
                  Color.lerp(const Color(0xFF0a0a1a), const Color(0xFF0f3460), _gradientController.value)!,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                          onPressed: () => setState(() => _showLyricFullscreen = false),
                        ),
                        Text(
                          _currentSong.song,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _lyricLines.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无歌词',
                              style: TextStyle(color: Colors.white38, fontSize: 16),
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollStartNotification &&
                                  notification.dragDetails != null) {
                                setState(() => _isLyricAutoScroll = false);
                                _lyricScrollDebounce?.cancel();
                                _lyricScrollDebounce =
                                    Timer(const Duration(seconds: 3), () {
                                  if (mounted) {
                                    setState(() => _isLyricAutoScroll = true);
                                  }
                                });
                              }
                              return false;
                            },
                            child: ListView.builder(
                              controller: _lyricScrollController,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 120, horizontal: 24),
                              itemCount: _lyricLines.length,
                              itemBuilder: (context, index) {
                                final line = _lyricLines[index];
                                final isCurrent = index == _currentLyricIndex;
                                final isNearby = (index - _currentLyricIndex).abs() <= 1;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                  child: isCurrent
                                      ? _buildKaraokeText(
                                          line.text,
                                          _lyricFillProgress,
                                          fontSize: 20,
                                          isActive: true,
                                        )
                                      : AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 300),
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              isNearby ? 0.45 : 0.25),
                                            fontSize: isNearby ? 16 : 14,
                                            fontWeight: isNearby ? FontWeight.w500 : FontWeight.w400,
                                          ),
                                          child: Text(
                                            line.text,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ========== 10段图形均衡器面板 ==========
  Widget _buildGraphicEqPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.75),
            Colors.black.withOpacity(0.45),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '图形均衡器',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  // Replay Gain 开关
                  GestureDetector(
                    onTap: () => setState(() => _replayGainEnabled = !_replayGainEnabled),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _replayGainEnabled
                            ? Colors.orangeAccent.withOpacity(0.25)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _replayGainEnabled
                              ? Colors.orangeAccent.withOpacity(0.5)
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune,
                            size: 12,
                            color: _replayGainEnabled ? Colors.orangeAccent : Colors.white38,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Replay Gain',
                            style: TextStyle(
                              fontSize: 10,
                              color: _replayGainEnabled ? Colors.orangeAccent : Colors.white38,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showEqPanel = false),
                    child: const Icon(Icons.close, color: Colors.white54, size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // EQ预设选择器
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _eqPresets.keys.map((presetName) {
                final isSelected = _selectedPreset == presetName;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _applyEqPreset(presetName),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.cyanAccent.withOpacity(0.2)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.cyanAccent.withOpacity(0.5)
                              : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          presetName,
                          style: TextStyle(
                            color: isSelected ? Colors.cyanAccent : Colors.white54,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // 10段均衡器滑块
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(10, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // dB值显示
                        Text(
                          '${_eqBandToDb(_eqBands[i]).toStringAsFixed(1)}dB',
                          style: TextStyle(
                            color: _getEqBandColor(i).withOpacity(0.8),
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 垂直滑块
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                activeTrackColor: _getEqBandColor(i),
                                inactiveTrackColor: Colors.white.withOpacity(0.08),
                                thumbColor: _getEqBandColor(i),
                                overlayColor: _getEqBandColor(i).withOpacity(0.15),
                              ),
                              child: Slider(
                                value: _eqBands[i],
                                min: 0.0,
                                max: 1.0,
                                onChanged: (v) {
                                  setState(() {
                                    _eqBands[i] = v;
                                    _selectedPreset = '自定义';
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 频段标签
                        Text(
                          _eqBandsDef[i].freq,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _eqBandsDef[i].label,
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 7,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),

          // Crossfade 设置
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, color: Colors.white38, size: 16),
                const SizedBox(width: 6),
                const Text(
                  '交叉淡入淡出',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      activeTrackColor: Colors.purpleAccent,
                      inactiveTrackColor: Colors.white.withOpacity(0.08),
                      thumbColor: Colors.purpleAccent,
                      overlayColor: Colors.purpleAccent.withOpacity(0.15),
                    ),
                    child: Slider(
                      value: _crossfadeDuration,
                      min: 0,
                      max: 12.0,
                      divisions: 12,
                      onChanged: (v) => setState(() => _crossfadeDuration = v),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    _crossfadeDuration == 0
                        ? '关闭'
                        : '${_crossfadeDuration.toStringAsFixed(1)}s',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 重置按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _eqBands = List.filled(10, 0.5);
                  _selectedPreset = '正常';
                });
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重置均衡器'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.08),
                foregroundColor: Colors.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEqBandColor(int index) {
    final colors = [
      Colors.orangeAccent,   // 32Hz
      Colors.deepOrangeAccent, // 64Hz
      Colors.amberAccent,    // 125Hz
      Colors.yellowAccent,   // 250Hz
      Colors.lightGreenAccent, // 500Hz
      Colors.greenAccent,    // 1kHz
      Colors.cyanAccent,     // 2kHz
      Colors.lightBlueAccent, // 4kHz
      Colors.purpleAccent,   // 8kHz
      Colors.pinkAccent,     // 16kHz
    ];
    return colors[index % colors.length];
  }

  // ========== 播放队列 ==========
  Widget _buildQueuePanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      constraints: const BoxConstraints(maxHeight: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '播放队列 (${_songList.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showQueue = false),
                child: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _songList.length,
              itemBuilder: (context, index) {
                final song = _songList[index];
                final isActive = index == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    if (index != _currentIndex) {
                      _switchToSong(index);
                    }
                    setState(() => _showQueue = false);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.cyanAccent.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: song.cover.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: song.cover,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        const Icon(Icons.music_note,
                                            color: Colors.white38, size: 20),
                                  )
                                : const Icon(Icons.music_note,
                                    color: Colors.white38, size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.song,
                                style: TextStyle(
                                  color: isActive ? Colors.cyanAccent : Colors.white,
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.singer,
                                style: TextStyle(
                                  color: isActive ? Colors.cyanAccent.withOpacity(0.7) : Colors.white54,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isActive)
                          const Icon(Icons.play_arrow, color: Colors.cyanAccent, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ========== 睡眠定时器 ==========
  void _showSleepTimerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e1e2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.bedtime, color: Colors.indigoAccent),
                  const SizedBox(width: 8),
                  const Text(
                    '睡眠定时器',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_sleepMinutesLeft > 0)
                    TextButton(
                      onPressed: _cancelSleepTimer,
                      child: const Text('取消', style: TextStyle(color: Colors.redAccent)),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _sleepOptions.map((minutes) {
                  final isActive = _sleepMinutesLeft == minutes;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _setSleepTimer(minutes);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.indigoAccent.withOpacity(0.3)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? Colors.indigoAccent
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        '$minutes 分钟',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ========== 播放速度 ==========
  void _showSpeedMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e1e2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '播放速度',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _speedOptions.map((speed) {
                  final isActive = _playbackSpeed == speed;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _setPlaybackSpeed(speed);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? Colors.cyanAccent
                            : Colors.white.withOpacity(0.08),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.4),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${speed}x',
                          style: TextStyle(
                            color: isActive ? Colors.black : Colors.white70,
                            fontSize: 14,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

/// 卡拉OK歌词填充裁切器
class _ProgressClipper extends CustomClipper<Rect> {
  final double progress;
  _ProgressClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(_ProgressClipper oldClipper) => oldClipper.progress != progress;
}