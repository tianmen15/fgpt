import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/wallpaper_scaffold.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with TickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _isTorchOn = false;
  bool _showHistory = false;
  List<ScanHistoryItem> _history = [];
  String? _lastResult;
  late AnimationController _resultAnimCtrl;
  late Animation<double> _resultAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _resultAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _resultAnim = CurvedAnimation(parent: _resultAnimCtrl, curve: Curves.elasticOut);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.repeat(reverse: true);
    _scanLineCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scanLineAnim = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _scanLineCtrl, curve: Curves.linear));
    _scanLineCtrl.repeat();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _resultAnimCtrl.dispose();
    _pulseCtrl.dispose();
    _scanLineCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('qr_history');
    if (data != null) {
      final list = (jsonDecode(data) as List).map((e) => ScanHistoryItem.fromJson(e)).toList();
      if (mounted) setState(() => _history = list);
    }
  }

  Future<void> _saveHistory(String result) async {
    final prefs = await SharedPreferences.getInstance();
    _history.insert(0, ScanHistoryItem(result: result, time: DateTime.now()));
    if (_history.length > 50) _history = _history.sublist(0, 50);
    await prefs.setString('qr_history', jsonEncode(_history.map((e) => e.toJson()).toList()));
    if (mounted) setState(() {});
  }

  void _onDetect(BarcodeCapture capture) {
    if (!mounted) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;
    final rawValue = barcode.rawValue;
    if (rawValue == null || rawValue == _lastResult) return;
    _lastResult = rawValue;
    _saveHistory(rawValue);
    _resultAnimCtrl.reset();
    _resultAnimCtrl.forward();
    HapticFeedback.mediumImpact();
    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _ResultSheet(
          result: rawValue,
          format: barcode.format.name,
          onCopy: () {
            Clipboard.setData(ClipboardData(text: rawValue));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已复制到剪贴板'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
            );
          },
          onClose: () {
            _lastResult = null;
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(_showHistory ? '扫描历史' : '二维码扫描', key: ValueKey(_showHistory), style: const TextStyle(color: Colors.white)),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_showHistory) ...[
            IconButton(
              icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: _isTorchOn ? Colors.amber : Colors.white70),
              onPressed: () {
                _controller.toggleTorch();
                setState(() => _isTorchOn = !_isTorchOn);
              },
            ),
            IconButton(
              icon: const Icon(Icons.cameraswitch, color: Colors.white70),
              onPressed: () => _controller.switchCamera(),
            ),
          ],
          IconButton(
            icon: Icon(_showHistory ? Icons.qr_code_scanner : Icons.history, color: Colors.cyanAccent),
            onPressed: () => setState(() => _showHistory = !_showHistory),
          ),
        ],
      ),
      body: _showHistory ? _buildHistory() : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (ctx, error, child) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
                    child: const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                  ),
                  const SizedBox(height: 16),
                  Text('相机错误: $error', style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _controller.start(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          },
        ),
        // 扫描框
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) {
              return Container(
                width: 260 + (_pulseAnim.value - 0.8) * 40,
                height: 260 + (_pulseAnim.value - 0.8) * 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.2 + (_pulseAnim.value - 0.8) * 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.05 + (_pulseAnim.value - 0.8) * 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedBuilder(
                    animation: _scanLineAnim,
                    builder: (_, __) {
                      return CustomPaint(
                        painter: _ScanLinePainter(_scanLineAnim.value),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        // 角落装饰
        ..._buildCorners(),
        // 底部提示
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Opacity(opacity: 0.5 + (_pulseAnim.value - 0.8) * 1.5, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('将二维码放入框内自动扫描', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCorners() {
    return [
      Positioned(top: 80, left: 40, child: _corner(Alignment.topLeft)),
      Positioned(top: 80, right: 40, child: _corner(Alignment.topRight)),
      Positioned(bottom: 120, left: 40, child: _corner(Alignment.bottomLeft)),
      Positioned(bottom: 120, right: 40, child: _corner(Alignment.bottomRight)),
    ];
  }

  Widget _corner(Alignment align) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          left: align.x < 0 ? BorderSide(color: Colors.cyanAccent, width: 3) : BorderSide.none,
          top: align.y < 0 ? BorderSide(color: Colors.cyanAccent, width: 3) : BorderSide.none,
          right: align.x > 0 ? BorderSide(color: Colors.cyanAccent, width: 3) : BorderSide.none,
          bottom: align.y > 0 ? BorderSide(color: Colors.cyanAccent, width: 3) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: align == Alignment.topLeft ? const Radius.circular(8) : Radius.zero,
          topRight: align == Alignment.topRight ? const Radius.circular(8) : Radius.zero,
          bottomLeft: align == Alignment.bottomLeft ? const Radius.circular(8) : Radius.zero,
          bottomRight: align == Alignment.bottomRight ? const Radius.circular(8) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(seconds: 1),
              curve: Curves.elasticOut,
              builder: (_, v, __) => Transform.scale(
                scale: v,
                child: const Icon(Icons.history, size: 64, color: Colors.white24),
              ),
            ),
            const SizedBox(height: 16),
            const Text('暂无扫描记录', style: TextStyle(color: Colors.white38, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('扫描二维码后会自动记录', style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (ctx, i) {
        final item = _history[i];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + i * 60),
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
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.cyanAccent, Color(0xFF00bcd4)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.qr_code, color: Colors.black, size: 20),
                    ),
                    title: Text(item.result, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(_formatTime(item.time), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.cyanAccent, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: item.result));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new, color: Colors.white54, size: 20),
                          onPressed: () {
                            if (item.result.startsWith('http')) {
                              // can't use url_launcher here easily, just copy
                              Clipboard.setData(ClipboardData(text: item.result));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已复制链接'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _ResultSheet extends StatelessWidget {
  final String result;
  final String format;
  final VoidCallback onCopy;
  final VoidCallback onClose;

  const _ResultSheet({
    required this.result,
    required this.format,
    required this.onCopy,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, v, __) => Transform.scale(
              scale: v,
              child: const Icon(Icons.check_circle, size: 48, color: Colors.greenAccent),
            ),
          ),
          const SizedBox(height: 12),
          const Text('扫描成功', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: Text(result, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 4),
          Text('类型: ${format.toUpperCase()}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy),
                  label: const Text('复制'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  label: const Text('关闭'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  _ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2 + progress * size.height / 2;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.cyanAccent.withOpacity(0),
          Colors.cyanAccent.withOpacity(0.6),
          Colors.cyanAccent.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, y - 1, size.width, 2));

    canvas.drawRect(Rect.fromLTWH(0, y - 1, size.width, 2), paint);

    // Glow
    canvas.drawRect(
      Rect.fromLTWH(0, y - 1, size.width, 2),
      Paint()..color = Colors.cyanAccent.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter old) => old.progress != progress;
}

class ScanHistoryItem {
  final String result;
  final DateTime time;

  ScanHistoryItem({required this.result, required this.time});

  Map<String, dynamic> toJson() => {'result': result, 'time': time.toIso8601String()};

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      result: json['result'] as String,
      time: DateTime.parse(json['time'] as String),
    );
  }
}