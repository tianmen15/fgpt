import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';
import '../widgets/wallpaper_scaffold.dart';
import '../services/storage_service.dart';

class PlayerScreen extends StatefulWidget {
  final VideoItem videoItem;
  final String? localPath;

  const PlayerScreen({super.key, required this.videoItem, this.localPath});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  double _volume = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLooping = false;
  double _playbackSpeed = 1.0;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  Timer? _controlsTimer;
  bool _isLoading = false;
  bool _isLocalVideoLoading = false;
  bool _initCancelled = false;

  // 动画控制器
  late AnimationController _controlsAnimCtrl;
  late Animation<double> _controlsFade;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _loadingCtrl;
  late Animation<double> _loadingAnim;
  late AnimationController _rippleCtrl;
  late AnimationController _gradientCtrl;
  late AnimationController _breatheCtrl;
  late AnimationController _cinemaCtrl;
  late AnimationController _volBarsCtrl;
  late AnimationController _edgeGlowCtrl;
  bool _isFullscreen = false;

  // 手势控制
  Offset? _dragStart;
  bool _isDragging = false;
  String _dragMode = ''; // 'brightness', 'volume', 'seek', ''
  double _dragStartBrightness = 0.0;
  double _dragStartVolume = 0.0;
  Duration _dragStartPosition = Duration.zero;
  double _brightnessOverlay = 0.0;
  double _volumeOverlay = 0.0;
  double _seekOverlay = 0.0;
  bool _showBrightnessIndicator = false;
  bool _showVolumeIndicator = false;
  bool _showSeekIndicator = false;
  Timer? _indicatorTimer;

  // 画面比例
  int _aspectRatioIndex = 0;
  final List<BoxFit> _aspectRatioModes = [BoxFit.contain, BoxFit.fill, BoxFit.cover];
  final List<String> _aspectRatioLabels = ['适应', '拉伸', '裁剪'];

  // 锁定方向
  bool _isLocked = false;

  // 截图
  final GlobalKey _videoKey = GlobalKey();
  bool _isCapturing = false;

  // 亮度控制 MethodChannel
  static const _brightnessChannel = MethodChannel('com.example.video_app/brightness');
  static const _pipChannel = MethodChannel('com.example.video_app/pip');
  double _systemBrightness = 0.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controlsAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _controlsFade = CurvedAnimation(parent: _controlsAnimCtrl, curve: Curves.easeInOut);
    _controlsAnimCtrl.value = 1.0;

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut));

    _loadingCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _loadingAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _loadingCtrl, curve: Curves.linear));
    _loadingCtrl.repeat();

    _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _gradientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _gradientCtrl.repeat(reverse: true);
    _breatheCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _breatheCtrl.repeat(reverse: true);
    _cinemaCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _volBarsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _volBarsCtrl.repeat(reverse: true);
    _edgeGlowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _edgeGlowCtrl.repeat(reverse: true);

    _getSystemBrightness();
    _initPlayer();
  }

  Future<void> _getSystemBrightness() async {
    try {
      final brightness = await _brightnessChannel.invokeMethod<double>('getBrightness');
      if (brightness != null && mounted) {
        setState(() => _systemBrightness = brightness);
      }
    } catch (_) {
      _systemBrightness = 0.5;
    }
  }

  Future<void> _setSystemBrightness(double value) async {
    try {
      await _brightnessChannel.invokeMethod('setBrightness', value.clamp(0.01, 1.0));
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlsTimer?.cancel();
    _indicatorTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controlsAnimCtrl.dispose();
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    _loadingCtrl.dispose();
    _rippleCtrl.dispose();
    _gradientCtrl.dispose();
    _breatheCtrl.dispose();
    _cinemaCtrl.dispose();
    _volBarsCtrl.dispose();
    _edgeGlowCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;
    if (state == AppLifecycleState.paused) {
      _controller!.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_isPlaying) {
        _controller!.play();
      }
    }
  }

  bool get _isLocalVideo => widget.videoItem.isLocal || widget.localPath != null;
  String get _localVideoPath => widget.localPath ?? widget.videoItem.localPath ?? '';

  Future<void> _initPlayer() async {
    // 取消之前正在进行的初始化
    _initCancelled = true;
    // 等待一帧确保之前的初始化看到取消信号
    await Future.microtask(() {});
    _initCancelled = false;

    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
      _controller = null;
    }

    setState(() {
      _isLoading = true;
      _isLocalVideoLoading = _isLocalVideo;
      _hasError = false;
      _errorMessage = '';
      _isInitialized = false;
      _isPlaying = false;
      _isBuffering = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    try {
      if (_isLocalVideo) {
        // 延迟一小段时间让 UI 先渲染加载状态，避免阻塞 UI 线程
        await Future.delayed(const Duration(milliseconds: 100));
        if (_initCancelled || !mounted) return;

        final path = _localVideoPath;
        if (path.isEmpty) {
          throw Exception('本地视频路径为空');
        }

        try {
          final file = File(path);
          if (!await file.exists()) {
            throw Exception('本地视频文件不存在: $path');
          }
          if (_initCancelled || !mounted) return;
          _controller = VideoPlayerController.file(
            file,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
        } catch (fileError) {
          if (_initCancelled || !mounted) return;
          // 如果 VideoPlayerController.file 失败，尝试使用 file:// URI 作为回退
          try {
            _controller = VideoPlayerController.networkUrl(
              Uri.parse('file://$path'),
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            );
          } catch (networkFallbackError) {
            // 检查常见编解码器问题
            final errorStr = fileError.toString();
            if (errorStr.contains('codec') || errorStr.contains('Codec') || errorStr.contains('format')) {
              throw Exception('视频编解码器不支持，请尝试其他格式的视频文件（如 MP4/H.264）');
            }
            if (errorStr.contains('太大') || errorStr.contains('large') || errorStr.contains('memory')) {
              throw Exception('视频文件过大，无法加载');
            }
            rethrow;
          }
        }
      } else {
        if (_initCancelled || !mounted) return;
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoItem.url),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }

      _controller!.addListener(_videoListener);

      if (_initCancelled || !mounted) {
        _controller?.dispose();
        _controller = null;
        return;
      }

      final timeoutSeconds = _isLocalVideo ? 60 : 30;
      await _controller!.initialize().timeout(Duration(seconds: timeoutSeconds));

      if (_initCancelled || !mounted) {
        _controller?.dispose();
        _controller = null;
        return;
      }

      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _isLocalVideoLoading = false;
        _duration = _controller!.value.duration;
        _retryCount = 0;
      });

      _controller!.play();
      setState(() => _isPlaying = true);
      _controller!.setLooping(_isLooping);
      _controller!.setVolume(_volume);
    } catch (e) {
      if (_initCancelled || !mounted) return;
      setState(() {
        _isLoading = false;
        _isLocalVideoLoading = false;
      });
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(milliseconds: 500 * _retryCount));
        if (!_initCancelled && mounted) {
          _initPlayer();
        }
        return;
      }
      _shakeCtrl.forward();
      setState(() {
        _hasError = true;
        _errorMessage = _parseError(e.toString());
      });
    }
  }

  void _cancelLocalVideoLoading() {
    _initCancelled = true;
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controller = null;
    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _parseError(String error) {
    if (error.contains('timeout') || error.contains('Timeout')) return '连接超时，请检查网络后重试';
    if (error.contains('403') || error.contains('Forbidden')) return '视频链接无法访问(403)，请检查链接是否有效';
    if (error.contains('404') || error.contains('Not Found')) return '视频链接不存在(404)';
    if (error.contains('Connection') || error.contains('SocketException')) return '网络连接失败，请检查网络';
    if (error.contains('本地视频文件不存在')) return '本地视频文件不存在，文件可能已被移动或删除';
    if (error.contains('Permission denied')) return '没有读取文件的权限';
    if (error.contains('编解码器') || error.contains('codec') || error.contains('Codec')) return '视频编解码器不支持，请尝试 MP4/H.264 格式';
    if (error.contains('过大') || error.contains('large') || error.contains('memory')) return '视频文件过大，无法加载';
    return '播放失败，请尝试其他视频链接';
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;
    if (!_isInitialized && value.isInitialized) {
      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _duration = value.duration;
      });
    }
    setState(() {
      _isPlaying = value.isPlaying;
      _isBuffering = value.isBuffering;
      _position = value.position;
      _duration = value.duration;
    });
    if (_isPlaying && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!_isPlaying) {
      _pulseCtrl.stop();
    }
    if (value.hasError) {
      _shakeCtrl.forward();
      setState(() {
        _hasError = true;
        _errorMessage = _parseError(value.errorDescription ?? '未知错误');
      });
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    _rippleCtrl.reset();
    _rippleCtrl.forward();
    if (_isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    setState(() => _isPlaying = !_isPlaying);
    _resetControlsTimer();
  }

  void _toggleControls() {
    if (_showControls) {
      _controlsAnimCtrl.reverse();
      _cinemaCtrl.reverse();
    } else {
      _controlsAnimCtrl.forward();
      _cinemaCtrl.forward();
    }
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _resetControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && _isPlaying) {
        _controlsAnimCtrl.reverse();
        _cinemaCtrl.reverse();
        setState(() => _showControls = false);
      }
    });
  }

  void _seekTo(Duration position) {
    if (_controller == null || !_isInitialized) return;
    _controller!.seekTo(position);
  }

  void _seekRelative(double seconds) {
    if (_controller == null || !_isInitialized) return;
    final newPos = _position + Duration(milliseconds: (seconds * 1000).round());
    if (newPos < Duration.zero) {
      _controller!.seekTo(Duration.zero);
    } else if (newPos > _duration) {
      _controller!.seekTo(_duration);
    } else {
      _controller!.seekTo(newPos);
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isInitialized = false;
      _retryCount = 0;
    });
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controller = null;
    _initPlayer();
  }

  // ========== 手势控制 ==========

  void _onDragStart(DragStartDetails details, BoxConstraints constraints) {
    if (_controller == null || !_isInitialized) return;
    _dragStart = details.localPosition;
    _dragStartBrightness = _systemBrightness;
    _dragStartVolume = _volume;
    _dragStartPosition = _position;
    _isDragging = true;
    _dragMode = '';
  }

  void _onDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_controller == null || !_isInitialized || _dragStart == null) return;

    final delta = details.localPosition - _dragStart!;
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    if (_dragMode.isEmpty) {
      if (delta.dx.abs() > delta.dy.abs() && delta.dx.abs() > 10) {
        _dragMode = 'seek';
      } else if (delta.dy.abs() > 10) {
        if (_dragStart!.dx < screenWidth / 2) {
          _dragMode = 'brightness';
        } else {
          _dragMode = 'volume';
        }
      }
    }

    switch (_dragMode) {
      case 'brightness':
        final change = -delta.dy / screenHeight;
        final newBrightness = (_dragStartBrightness + change).clamp(0.01, 1.0);
        _systemBrightness = newBrightness;
        _setSystemBrightness(newBrightness);
        setState(() {
          _brightnessOverlay = newBrightness;
          _showBrightnessIndicator = true;
        });
        _indicatorTimer?.cancel();
        _indicatorTimer = Timer(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _showBrightnessIndicator = false);
        });
        break;
      case 'volume':
        final change = -delta.dy / screenHeight;
        final newVolume = (_dragStartVolume + change).clamp(0.0, 1.0);
        _volume = newVolume;
        _controller!.setVolume(newVolume);
        setState(() {
          _volumeOverlay = newVolume;
          _showVolumeIndicator = true;
        });
        _indicatorTimer?.cancel();
        _indicatorTimer = Timer(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _showVolumeIndicator = false);
        });
        break;
      case 'seek':
        final seekDelta = delta.dx / screenWidth * _duration.inMilliseconds.toDouble();
        final newPositionMs = (_dragStartPosition.inMilliseconds + seekDelta).clamp(0.0, _duration.inMilliseconds.toDouble());
        final newPosition = Duration(milliseconds: newPositionMs.round());
        _seekTo(newPosition);
        setState(() {
          _seekOverlay = newPositionMs / _duration.inMilliseconds.toDouble().clamp(1.0, double.infinity);
          _showSeekIndicator = true;
        });
        _indicatorTimer?.cancel();
        _indicatorTimer = Timer(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _showSeekIndicator = false);
        });
        break;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
    _dragStart = null;
    _dragMode = '';
  }

  void _onDoubleTap() {
    _togglePlayPause();
  }

  // ========== 截图 ==========

  Future<void> _captureScreenshot() async {
    if (_isCapturing || !_isInitialized) return;
    setState(() => _isCapturing = true);

    try {
      final boundary = _videoKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _isCapturing = false);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) setState(() => _isCapturing = false);
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${dir.path}/screenshot_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('截图已保存: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('截图失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ========== 画面比例切换 ==========

  void _toggleAspectRatio() {
    setState(() {
      _aspectRatioIndex = (_aspectRatioIndex + 1) % _aspectRatioModes.length;
    });
  }

  // ========== 循环播放 ==========

  void _toggleLoop() {
    setState(() => _isLooping = !_isLooping);
    _controller?.setLooping(_isLooping);
  }

  // ========== 画中画 ==========

  Future<void> _enterPictureInPicture() async {
    try {
      await _pipChannel.invokeMethod('enterPictureInPicture');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已进入画中画模式'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画中画模式不支持: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ========== 锁定方向 ==========

  void _toggleOrientationLock() {
    setState(() => _isLocked = !_isLocked);
    if (_isLocked) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  // ========== 播放速度 ==========

  void _setPlaybackSpeed(double speed) {
    _controller?.setPlaybackSpeed(speed);
    setState(() => _playbackSpeed = speed);
  }

  // ========== 添加到播放列表 ==========

  Future<void> _addToPlaylist() async {
    await StorageService.addToPlaylist(widget.videoItem);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加到播放列表'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
      );
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _hasError ? _buildErrorView() : _buildPlayer(),
    );
  }

  Widget _buildErrorView() {
    return WallpaperScaffold(
      body: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(8 * (1 - _shakeAnim.value) * (_shakeAnim.value < 0.5 ? 1 : -1), 0),
          child: child,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (_, v, __) => Transform.scale(
                    scale: v,
                    child: AnimatedBuilder(
                      animation: _breatheCtrl,
                      builder: (_, child) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent.withOpacity(0.1 + _breatheCtrl.value * 0.05),
                          boxShadow: [
                            BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 10 + _breatheCtrl.value * 10),
                          ],
                        ),
                        child: child,
                      ),
                      child: const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('播放出错', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  _isLocalVideo ? _localVideoPath : widget.videoItem.url,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 30),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (_, v, __) => Transform.scale(
                      scale: v,
                      child: ElevatedButton.icon(
                        onPressed: _retry, icon: const Icon(Icons.refresh), label: const Text('重试'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back), label: const Text('返回'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white30)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return GestureDetector(
      onTap: () {
        if (!_isDragging) {
          _toggleControls();
        }
      },
      onDoubleTap: _onDoubleTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanStart: (d) => _onDragStart(d, constraints),
            onPanUpdate: (d) => _onDragUpdate(d, constraints),
            onPanEnd: _onDragEnd,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 视频区域
                if (_isInitialized && _controller != null)
                  AnimatedBuilder(
                    animation: _gradientCtrl,
                    builder: (_, child) => Center(
                      child: AnimatedBuilder(
                        animation: _edgeGlowCtrl,
                        builder: (_, child) => Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.05 + _edgeGlowCtrl.value * 0.08),
                                blurRadius: 30 + _edgeGlowCtrl.value * 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                        child: RepaintBoundary(
                          key: _videoKey,
                          child: ClipRect(
                            child: FittedBox(
                              fit: _aspectRatioModes[_aspectRatioIndex],
                              child: SizedBox(
                                width: _controller!.value.size.width,
                                height: _controller!.value.size.height,
                                child: VideoPlayer(_controller!),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _loadingAnim,
                          builder: (_, __) => Transform.rotate(
                            angle: _loadingAnim.value * 6.28318,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    Colors.cyanAccent.withOpacity(0.1),
                                    Colors.cyanAccent,
                                    Colors.cyanAccent.withOpacity(0.1),
                                  ],
                                ),
                              ),
                              child: const CircularProgressIndicator(
                                color: Colors.transparent,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: _breatheCtrl,
                          builder: (_, child) => Opacity(
                            opacity: 0.5 + _breatheCtrl.value * 0.5,
                            child: child,
                          ),
                          child: Text(
                            _isLocalVideoLoading ? '加载本地视频...\n（大文件可能需要较长时间）' : (_isLoading ? '加载中...' : '准备中...'),
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ),
                        if (_retryCount > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            '重试中 ($_retryCount/$_maxRetries)...',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                        if (_isLocalVideoLoading) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _cancelLocalVideoLoading,
                            icon: const Icon(Icons.cancel, color: Colors.white54, size: 18),
                            label: const Text('取消加载', style: TextStyle(color: Colors.white54)),
                          ),
                        ],
                      ],
                    ),
                  ),

                // 亮度指示器
                if (_showBrightnessIndicator)
                  Positioned(
                    left: 20,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _showBrightnessIndicator ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _brightnessOverlay > 0.5 ? Icons.brightness_high : Icons.brightness_low,
                                color: Colors.yellow,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_brightnessOverlay * 100).round()}%',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 4,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 80 * _brightnessOverlay,
                                    decoration: BoxDecoration(
                                      color: Colors.yellow,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 音量指示器
                if (_showVolumeIndicator)
                  Positioned(
                    right: 20,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _showVolumeIndicator ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _volumeOverlay > 0 ? Icons.volume_up : Icons.volume_off,
                                color: Colors.greenAccent,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_volumeOverlay * 100).round()}%',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 4,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 80 * _volumeOverlay,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 快进/快退指示器
                if (_showSeekIndicator)
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _showSeekIndicator ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _seekOverlay > (_position.inMilliseconds / _duration.inMilliseconds.toDouble().clamp(1.0, double.infinity))
                                    ? Icons.fast_forward
                                    : Icons.fast_rewind,
                                color: Colors.cyanAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_formatDuration(Duration(milliseconds: (_seekOverlay * _duration.inMilliseconds).round()))} / ${_formatDuration(_duration)}',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 影院遮幅（上下黑条）
                AnimatedBuilder(
                  animation: _cinemaCtrl,
                  builder: (_, __) {
                    final h = _cinemaCtrl.value * 40;
                    return Column(
                      children: [
                        Container(height: h, color: Colors.black),
                        const Spacer(),
                        Container(height: h, color: Colors.black),
                      ],
                    );
                  },
                ),

                // 缓冲指示器
                if (_isBuffering && _isInitialized)
                  Center(
                    child: AnimatedBuilder(
                      animation: _loadingAnim,
                      builder: (_, __) => TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        builder: (_, v, __) => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                            boxShadow: [
                              BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 12),
                            ],
                          ),
                          child: SizedBox(
                            width: 36, height: 36,
                            child: CircularProgressIndicator(value: v, color: Colors.cyanAccent, strokeWidth: 3),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 顶部栏
                FadeTransition(
                  opacity: _controlsFade,
                  child: Positioned(
                    top: 0, left: 0, right: 0,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(_controlsAnimCtrl),
                      child: Container(
                        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 8, right: 8, bottom: 8),
                        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black87, Colors.transparent])),
                        child: Row(
                          children: [
                            IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                            Expanded(
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
                                child: Text(widget.videoItem.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            // 截图按钮
                            IconButton(
                              icon: Icon(
                                _isCapturing ? Icons.hourglass_top : Icons.camera_alt,
                                color: Colors.white,
                              ),
                              onPressed: _isCapturing ? null : _captureScreenshot,
                              tooltip: '截图',
                            ),
                            // 画面比例按钮
                            IconButton(
                              icon: Icon(Icons.aspect_ratio, color: Colors.white),
                              onPressed: _toggleAspectRatio,
                              tooltip: '画面比例: ${_aspectRatioLabels[_aspectRatioIndex]}',
                            ),
                            // 画中画按钮
                            IconButton(
                              icon: Icon(Icons.picture_in_picture, color: Colors.white),
                              onPressed: _enterPictureInPicture,
                              tooltip: '画中画',
                            ),
                            // 锁定方向按钮
                            IconButton(
                              icon: Icon(
                                _isLocked ? Icons.screen_lock_rotation : Icons.screen_rotation,
                                color: _isLocked ? Colors.cyanAccent : Colors.white,
                              ),
                              onPressed: _toggleOrientationLock,
                              tooltip: _isLocked ? '解锁方向' : '锁定方向',
                            ),
                            // 全屏按钮
                            IconButton(
                              icon: Icon(
                                _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                color: _isFullscreen ? Colors.cyanAccent : Colors.white,
                              ),
                              onPressed: _toggleFullscreen,
                              tooltip: _isFullscreen ? '退出全屏' : '全屏',
                            ),
                            IconButton(
                              icon: Icon(Icons.playlist_add, color: Colors.white),
                              onPressed: _addToPlaylist,
                              tooltip: '添加到列表',
                            ),
                            AnimatedRotation(
                              turns: _isLooping ? 0.25 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: IconButton(
                                icon: Icon(_isLooping ? Icons.repeat_one : Icons.repeat, color: _isLooping ? Colors.cyanAccent : Colors.white),
                                onPressed: _toggleLoop,
                                tooltip: '循环播放',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 底部控制栏
                FadeTransition(
                  opacity: _controlsFade,
                  child: Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(_controlsAnimCtrl),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent])),
                        child: _isInitialized ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 进度条
                            Row(children: [
                              Text(_formatDuration(_position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                    activeTrackColor: Colors.cyanAccent, inactiveTrackColor: Colors.white24, thumbColor: Colors.cyanAccent,
                                    overlayColor: Colors.cyanAccent.withOpacity(0.2),
                                  ),
                                  child: Slider(
                                    min: 0, max: _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                                    value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble()),
                                    onChanged: (v) => _seekTo(Duration(milliseconds: v.round())),
                                  ),
                                ),
                              ),
                              Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ]),
                            // 控制按钮
                            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                              IconButton(icon: const Icon(Icons.replay_10, color: Colors.white), onPressed: () => _seekRelative(-10), tooltip: '后退10秒'),
                              // 脉冲播放按钮带涟漪
                              AnimatedBuilder(
                                animation: _rippleCtrl,
                                builder: (_, child) => Transform.scale(
                                  scale: 1.0 + _rippleCtrl.value * 0.3,
                                  child: Opacity(
                                    opacity: 1.0 - _rippleCtrl.value,
                                    child: child,
                                  ),
                                ),
                                child: AnimatedBuilder(
                                  animation: _pulseAnim,
                                  builder: (_, child) => Transform.scale(
                                    scale: _isPlaying ? _pulseAnim.value : 1.0,
                                    child: child,
                                  ),
                                  child: IconButton(
                                    icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white, size: 48),
                                    onPressed: _togglePlayPause,
                                  ),
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.forward_10, color: Colors.white), onPressed: () => _seekRelative(10), tooltip: '前进10秒'),
                              PopupMenuButton<double>(
                                icon: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text('${_playbackSpeed}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                color: Colors.black87,
                                onSelected: _setPlaybackSpeed,
                                itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) => PopupMenuItem(
                                  value: s, child: Text('${s}x', style: TextStyle(color: s == _playbackSpeed ? Colors.cyanAccent : Colors.white)),
                                )).toList(),
                              ),
                              // 音量按钮带动画指示器
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(_volume > 0 ? Icons.volume_up : Icons.volume_off, color: Colors.white),
                                    onPressed: () {
                                      if (_volume > 0) { _controller?.setVolume(0); setState(() => _volume = 0); }
                                      else { _controller?.setVolume(1.0); setState(() => _volume = 1.0); }
                                    },
                                  ),
                                  // 音量条动画
                                  if (_volume > 0)
                                    Positioned(
                                      bottom: 4,
                                      child: AnimatedBuilder(
                                        animation: _volBarsCtrl,
                                        builder: (_, __) => Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(5, (i) {
                                            final barH = (i < (_volume * 5).round()) ? (3.0 + _volBarsCtrl.value * 5 * (i + 1) / 5) : 1.0;
                                            return Container(
                                              width: 2,
                                              height: barH,
                                              margin: const EdgeInsets.symmetric(horizontal: 1),
                                              decoration: BoxDecoration(
                                                color: _volume > 0.5 ? Colors.greenAccent.withOpacity(0.7 + _volBarsCtrl.value * 0.3) : Colors.orangeAccent.withOpacity(0.7 + _volBarsCtrl.value * 0.3),
                                                borderRadius: BorderRadius.circular(1),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ]),
                          ],
                        ) : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),

                // 中间播放按钮
                if (!_isPlaying && _showControls && _isInitialized)
                  FadeTransition(
                    opacity: _controlsFade,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _breatheCtrl,
                        builder: (_, child) => Transform.scale(
                          scale: 1.0 + _breatheCtrl.value * 0.05,
                          child: child,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: IconButton(
                            icon: const Icon(Icons.play_circle_fill, size: 72, color: Colors.white70),
                            onPressed: _togglePlayPause,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}