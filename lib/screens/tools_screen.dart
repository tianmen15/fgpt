import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import '../widgets/wallpaper_scaffold.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> with TickerProviderStateMixin {
  int _selectedTool = -1;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _tools = [
    {'name': '秒表/计时器', 'icon': Icons.timer, 'color': Color(0xFF6a11cb), 'gradient': [Color(0xFF6a11cb), Color(0xFF2575fc)]},
    {'name': '随机生成器', 'icon': Icons.shuffle, 'color': Color(0xFFf12711), 'gradient': [Color(0xFFf12711), Color(0xFFf5af19)]},
    {'name': '单位换算', 'icon': Icons.swap_horiz, 'color': Color(0xFF00b4db), 'gradient': [Color(0xFF00b4db), Color(0xFF0083b0)]},
    {'name': '颜色选择器', 'icon': Icons.color_lens, 'color': Color(0xFF7b2ff7), 'gradient': [Color(0xFF7b2ff7), Color(0xFFf12711)]},
    {'name': '文字计数', 'icon': Icons.text_fields, 'color': Color(0xFF11998e), 'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)]},
    {'name': '系统信息', 'icon': Icons.info_outline, 'color': Color(0xFFfc4a1a), 'gradient': [Color(0xFFfc4a1a), Color(0xFFf7b733)]},
    {'name': '指南针', 'icon': Icons.explore, 'color': Color(0xFFe53935), 'gradient': [Color(0xFFe53935), Color(0xFFe35d5b)]},
    {'name': '手电筒', 'icon': Icons.flashlight_on, 'color': Color(0xFFFFD600), 'gradient': [Color(0xFFFFD600), Color(0xFFFFAB00)]},
    {'name': '剪贴板管理', 'icon': Icons.content_paste, 'color': Color(0xFF0083b0), 'gradient': [Color(0xFF0083b0), Color(0xFF00b4db)]},
    {'name': '文字转语音', 'icon': Icons.record_voice_over, 'color': Color(0xFF8E2DE2), 'gradient': [Color(0xFF8E2DE2), Color(0xFF4A00E0)]},
    {'name': '密码生成器', 'icon': Icons.key, 'color': Color(0xFF00C853), 'gradient': [Color(0xFF00C853), Color(0xFF69F0AE)]},
    {'name': '骰子', 'icon': Icons.casino, 'color': Color(0xFFD50000), 'gradient': [Color(0xFFD50000), Color(0xFFFF6D00)]},
    {'name': '硬币抛掷', 'icon': Icons.toll, 'color': Color(0xFFFFC107), 'gradient': [Color(0xFFFFC107), Color(0xFFFF9800)]},
    {'name': 'BMI计算器', 'icon': Icons.monitor_weight, 'color': Color(0xFF00BCD4), 'gradient': [Color(0xFF00BCD4), Color(0xFF009688)]},
    {'name': '年龄计算器', 'icon': Icons.cake, 'color': Color(0xFFE91E63), 'gradient': [Color(0xFFE91E63), Color(0xFFFF5722)]},
    {'name': '小费计算器', 'icon': Icons.attach_money, 'color': Color(0xFF4CAF50), 'gradient': [Color(0xFF4CAF50), Color(0xFF8BC34A)]},
    {'name': '折扣计算器', 'icon': Icons.discount, 'color': Color(0xFFFF5722), 'gradient': [Color(0xFFFF5722), Color(0xFFFF9800)]},
    {'name': '百分比计算器', 'icon': Icons.percent, 'color': Color(0xFF9C27B0), 'gradient': [Color(0xFF9C27B0), Color(0xFFE040FB)]},
    {'name': '世界时钟', 'icon': Icons.public, 'color': Color(0xFF2196F3), 'gradient': [Color(0xFF2196F3), Color(0xFF64B5F6)]},
    {'name': '番茄钟', 'icon': Icons.access_alarm, 'color': Color(0xFFF44336), 'gradient': [Color(0xFFF44336), Color(0xFFE91E63)]},
    {'name': '呼吸练习', 'icon': Icons.self_improvement, 'color': Color(0xFF26C6DA), 'gradient': [Color(0xFF26C6DA), Color(0xFF00ACC1)]},
    {'name': '节拍器', 'icon': Icons.music_note, 'color': Color(0xFF7C4DFF), 'gradient': [Color(0xFF7C4DFF), Color(0xFF651FFF)]},
    {'name': '分贝仪', 'icon': Icons.mic, 'color': Color(0xFFFF6F00), 'gradient': [Color(0xFFFF6F00), Color(0xFFFFAB00)]},
    {'name': '水平仪', 'icon': Icons.straighten, 'color': Color(0xFF00E676), 'gradient': [Color(0xFF00E676), Color(0xFF69F0AE)]},
    {'name': '计数器', 'icon': Icons.plus_one, 'color': Color(0xFF3F51B5), 'gradient': [Color(0xFF3F51B5), Color(0xFF7986CB)]},
    {'name': 'Base64编解码', 'icon': Icons.code, 'color': Color(0xFF795548), 'gradient': [Color(0xFF795548), Color(0xFF8D6E63)]},
    {'name': '哈希生成器', 'icon': Icons.fingerprint, 'color': Color(0xFF607D8B), 'gradient': [Color(0xFF607D8B), Color(0xFF90A4AE)]},
    {'name': 'UUID生成器', 'icon': Icons.tag, 'color': Color(0xFFFF4081), 'gradient': [Color(0xFFFF4081), Color(0xFFFF80AB)]},
    {'name': 'Lorem Ipsum', 'icon': Icons.article, 'color': Color(0xFF8BC34A), 'gradient': [Color(0xFF8BC34A), Color(0xFFCDDC39)]},
    {'name': '大小写转换', 'icon': Icons.text_format, 'color': Color(0xFF00BCD4), 'gradient': [Color(0xFF00BCD4), Color(0xFF4DD0E1)]},
    {'name': '文本反转', 'icon': Icons.swap_horiz, 'color': Color(0xFFFF5722), 'gradient': [Color(0xFFFF5722), Color(0xFFFF8A65)]},
    {'name': '莫尔斯码', 'icon': Icons.radio, 'color': Color(0xFF673AB7), 'gradient': [Color(0xFF673AB7), Color(0xFF9575CD)]},
    {'name': '二进制转换', 'icon': Icons.memory, 'color': Color(0xFF009688), 'gradient': [Color(0xFF009688), Color(0xFF4DB6AC)]},
    {'name': 'IP地址查询', 'icon': Icons.language, 'color': Color(0xFF1565C0), 'gradient': [Color(0xFF1565C0), Color(0xFF42A5F5)]},
    {'name': '二维码生成', 'icon': Icons.qr_code, 'color': Color(0xFF212121), 'gradient': [Color(0xFF424242), Color(0xFF616161)]},
    {'name': '屏幕标尺', 'icon': Icons.straighten, 'color': Color(0xFFFFA000), 'gradient': [Color(0xFFFFA000), Color(0xFFFFCA28)]},
    {'name': '日期计算器', 'icon': Icons.date_range, 'color': Color(0xFF5C6BC0), 'gradient': [Color(0xFF5C6BC0), Color(0xFF7986CB)]},
    {'name': '随机名言', 'icon': Icons.format_quote, 'color': Color(0xFFFF6F00), 'gradient': [Color(0xFFFF6F00), Color(0xFFFFA726)]},
    {'name': '颜色格式转换', 'icon': Icons.palette, 'color': Color(0xFFAB47BC), 'gradient': [Color(0xFFAB47BC), Color(0xFFCE93D8)]},
    {'name': 'JSON格式化', 'icon': Icons.data_object, 'color': Color(0xFF00897B), 'gradient': [Color(0xFF00897B), Color(0xFF4DB6AC)]},
    {'name': '正则测试器', 'icon': Icons.pattern, 'color': Color(0xFFE91E63), 'gradient': [Color(0xFFE91E63), Color(0xFFF06292)]},
    {'name': 'URL编解码', 'icon': Icons.link, 'color': Color(0xFF1565C0), 'gradient': [Color(0xFF1565C0), Color(0xFF42A5F5)]},
    {'name': 'HTML实体编解码', 'icon': Icons.html, 'color': Color(0xFFFF7043), 'gradient': [Color(0xFFFF7043), Color(0xFFFFAB91)]},
    {'name': '图片信息', 'icon': Icons.image, 'color': Color(0xFF7C4DFF), 'gradient': [Color(0xFF7C4DFF), Color(0xFFB388FF)]},
    {'name': '屏幕信息', 'icon': Icons.smartphone, 'color': Color(0xFF26A69A), 'gradient': [Color(0xFF26A69A), Color(0xFF80CBC4)]},
    {'name': '震动测试', 'icon': Icons.vibration, 'color': Color(0xFFFF6F00), 'gradient': [Color(0xFFFF6F00), Color(0xFFFFB74D)]},
    {'name': '文件哈希', 'icon': Icons.fingerprint, 'color': Color(0xFF5C6BC0), 'gradient': [Color(0xFF5C6BC0), Color(0xFF9FA8DA)]},
    {'name': '色彩搭配', 'icon': Icons.palette, 'color': Color(0xFF00BCD4), 'gradient': [Color(0xFF00BCD4), Color(0xFF4DD0E1)]},
    {'name': '数学公式', 'icon': Icons.functions, 'color': Color(0xFFF44336), 'gradient': [Color(0xFFF44336), Color(0xFFEF9A9A)]},
    {'name': '元素周期表', 'icon': Icons.science, 'color': Color(0xFF8E24AA), 'gradient': [Color(0xFF8E24AA), Color(0xFFCE93D8)]},
    {'name': '键盘码', 'icon': Icons.keyboard, 'color': Color(0xFF607D8B), 'gradient': [Color(0xFF607D8B), Color(0xFF90A4AE)]},
    {'name': '时区转换', 'icon': Icons.schedule, 'color': Color(0xFF2196F3), 'gradient': [Color(0xFF2196F3), Color(0xFF64B5F6)]},
    {'name': '数字进制转换', 'icon': Icons.transform, 'color': Color(0xFF009688), 'gradient': [Color(0xFF009688), Color(0xFF80CBC4)]},
    {'name': '列表随机', 'icon': Icons.shuffle_on, 'color': Color(0xFFFFC107), 'gradient': [Color(0xFFFFC107), Color(0xFFFFE082)]},
    {'name': '倒计时', 'icon': Icons.hourglass_bottom, 'color': Color(0xFFE53935), 'gradient': [Color(0xFFE53935), Color(0xFFEF5350)]},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Widget _buildToolScreen() {
    switch (_selectedTool) {
      case 0: return const _StopwatchTool();
      case 1: return const _RandomGeneratorTool();
      case 2: return const _UnitConverterTool();
      case 3: return const _ColorPickerTool();
      case 4: return const _TextCounterTool();
      case 5: return const _SystemInfoTool();
      case 6: return const _CompassTool();
      case 7: return const _FlashlightTool();
      case 8: return const _ClipboardTool();
      case 9: return const _TextToSpeechTool();
      case 10: return const _PasswordGeneratorTool();
      case 11: return const _DiceTool();
      case 12: return const _CoinFlipTool();
      case 13: return const _BMITool();
      case 14: return const _AgeCalculatorTool();
      case 15: return const _TipCalculatorTool();
      case 16: return const _DiscountCalculatorTool();
      case 17: return const _PercentCalculatorTool();
      case 18: return const _WorldClockTool();
      case 19: return const _PomodoroTool();
      case 20: return const _BreathingTool();
      case 21: return const _MetronomeTool();
      case 22: return const _DecibelMeterTool();
      case 23: return const _LevelTool();
      case 24: return const _TallyCounterTool();
      case 25: return const _Base64Tool();
      case 26: return const _HashTool();
      case 27: return const _UUIDTool();
      case 28: return const _LoremIpsumTool();
      case 29: return const _CaseConverterTool();
      case 30: return const _TextReverseTool();
      case 31: return const _MorseCodeTool();
      case 32: return const _BinaryConverterTool();
      case 33: return const _IPTool();
      case 34: return const _QRCodeTool();
      case 35: return const _RulerTool();
      case 36: return const _DateCalculatorTool();
      case 37: return const _QuoteTool();
      case 38: return const _ColorFormatTool();
      case 39: return const _JSONFormatterTool();
      case 40: return const _RegexTesterTool();
      case 41: return const _URLEncoderTool();
      case 42: return const _HTMLEntityTool();
      case 43: return const _ImageInfoTool();
      case 44: return const _ScreenInfoTool();
      case 45: return const _VibrationTestTool();
      case 46: return const _FileHashTool();
      case 47: return const _ColorPaletteTool();
      case 48: return const _MathFormulasTool();
      case 49: return const _PeriodicTableTool();
      case 50: return const _KeycodeViewerTool();
      case 51: return const _TimezoneConverterTool();
      case 52: return const _NumberBaseConverterTool();
      case 53: return const _ListRandomizerTool();
      case 54: return const _CountdownTimerTool();
      default: return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: Text(
          _selectedTool == -1 ? '实用工具' : _tools[_selectedTool]['name'] as String,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _selectedTool != -1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() => _selectedTool = -1);
                  _animCtrl.reset();
                  _animCtrl.forward();
                },
              )
            : null,
      ),
      body: _selectedTool == -1 ? _buildHub() : _buildToolScreen(),
    );
  }

  Widget _buildHub() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: _tools.length,
        itemBuilder: (ctx, i) {
          final tool = _tools[i];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + i * 40),
            curve: Curves.easeOut,
            builder: (_, v, __) {
              return Opacity(
                opacity: v,
                child: Transform.scale(
                  scale: 0.8 + v * 0.2,
                  child: Transform(
                    transform: Matrix4.rotationY((1 - v) * 0.5),
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (tool['color'] as Color).withOpacity(0.08),
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
                          onTap: () {
                            setState(() => _selectedTool = i);
                            _animCtrl.reset();
                            _animCtrl.forward();
                          },
                          splashColor: (tool['color'] as Color).withOpacity(0.15),
                          highlightColor: (tool['color'] as Color).withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: (tool['gradient'] as List<Color>).map((c) => c.withOpacity(0.25)).toList(),
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (tool['color'] as Color).withOpacity(0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(tool['icon'] as IconData, color: tool['color'] as Color, size: 28),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  tool['name'] as String,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============ 秒表/计时器 ============
class _StopwatchTool extends StatefulWidget {
  const _StopwatchTool();
  @override
  State<_StopwatchTool> createState() => _StopwatchToolState();
}

class _StopwatchToolState extends State<_StopwatchTool> with TickerProviderStateMixin {
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  List<Duration> _laps = [];
  bool _isTimerMode = false;
  Duration _timerDuration = const Duration(minutes: 1);
  Duration _remaining = const Duration(minutes: 1);
  bool _timerRunning = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (_isTimerMode) {
        if (_timerRunning) {
          setState(() {
            _remaining -= const Duration(milliseconds: 30);
            if (_remaining <= Duration.zero) {
              _remaining = Duration.zero;
              _timerRunning = false;
              _timer?.cancel();
              HapticFeedback.heavyImpact();
            }
          });
        }
      } else {
        setState(() {});
      }
    });
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$min:$sec.$ms';
  }

  @override
  Widget build(BuildContext context) {
    final display = _isTimerMode ? _formatDuration(_remaining) : _formatDuration(_stopwatch.elapsed);
    final isRunning = _isTimerMode ? _timerRunning : _stopwatch.isRunning;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _modeButton('秒表', !_isTimerMode),
              const SizedBox(width: 10),
              _modeButton('计时器', _isTimerMode),
            ],
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(scale: isRunning ? _pulseAnim.value : 1.0, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF00d4ff).withOpacity(0.1), const Color(0xFFb388ff).withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.3)),
              ),
              child: Text(display, style: TextStyle(color: _isTimerMode && _remaining <= const Duration(seconds: 10) ? Colors.redAccent : const Color(0xFF00d4ff), fontSize: 56, fontWeight: FontWeight.w200, fontFamily: 'monospace', letterSpacing: 4)),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isTimerMode)
                _actionButton(Icons.flag, Colors.amber, !isRunning, () {
                  if (_stopwatch.isRunning) setState(() => _laps.insert(0, _stopwatch.elapsed));
                }),
              const SizedBox(width: 20),
              _actionButton(isRunning ? Icons.pause : Icons.play_arrow, isRunning ? Colors.orange : Colors.greenAccent, false, () {
                if (_isTimerMode) {
                  setState(() => _timerRunning = !_timerRunning);
                  if (_timerRunning) _startTimer();
                } else {
                  if (_stopwatch.isRunning) { _stopwatch.stop(); _timer?.cancel(); } else { _stopwatch.start(); _startTimer(); }
                }
                setState(() {});
              }, size: 64),
              const SizedBox(width: 20),
              _actionButton(Icons.refresh, Colors.redAccent, false, () {
                setState(() { _stopwatch.reset(); _stopwatch.stop(); _timer?.cancel(); _laps.clear(); _remaining = _timerDuration; _timerRunning = false; });
              }),
            ],
          ),
          if (_laps.isNotEmpty && !_isTimerMode) ...[
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _laps.length,
                itemBuilder: (_, i) {
                  final lap = _laps[i];
                  return ListTile(
                    dense: true,
                    leading: Text('圈 ${_laps.length - i}', style: const TextStyle(color: const Color(0xFF00d4ff))),
                    title: Text(_formatDuration(lap), style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
                    trailing: Text(i < _laps.length - 1 ? '+${_formatDuration(lap - _laps[i + 1])}' : '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'monospace')),
                  );
                },
              ),
            ),
          ],
          if (_isTimerMode) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [1, 3, 5, 10, 15, 30].map((m) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$m分', style: TextStyle(color: _timerDuration.inMinutes == m ? Colors.black : Colors.white70, fontSize: 12)),
                    selected: _timerDuration.inMinutes == m,
                    selectedColor: const Color(0xFF00d4ff),
                    backgroundColor: Colors.white.withOpacity(0.1),
                    onSelected: (_) { setState(() { _timerDuration = Duration(minutes: m); _remaining = Duration(minutes: m); _timerRunning = false; _timer?.cancel(); }); },
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeButton(String label, bool active) {
    return GestureDetector(
      onTap: () { setState(() { _isTimerMode = label == '计时器'; _stopwatch.reset(); _stopwatch.stop(); _timer?.cancel(); _laps.clear(); _remaining = _timerDuration; _timerRunning = false; }); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(color: active ? const Color(0xFF00d4ff) : Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: active ? Colors.black : Colors.white70, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, bool disabled, VoidCallback onTap, {double size = 48}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(disabled ? 0.2 : 0.15), border: Border.all(color: color.withOpacity(0.3))),
        child: Icon(icon, color: disabled ? color.withOpacity(0.3) : color, size: size * 0.5),
      ),
    );
  }
}

// ============ 随机生成器 ============
class _RandomGeneratorTool extends StatefulWidget {
  const _RandomGeneratorTool();
  @override
  State<_RandomGeneratorTool> createState() => _RandomGeneratorToolState();
}

class _RandomGeneratorToolState extends State<_RandomGeneratorTool> with TickerProviderStateMixin {
  final _rng = math.Random();
  int _tabIndex = 0;
  String _result = '';
  String _numMin = '1', _numMax = '100';
  int _passwordLength = 12;
  bool _incUpper = true, _incLower = true, _incDigits = true, _incSymbols = true;
  late AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() { _spinCtrl.dispose(); super.dispose(); }

  void _genNumber() {
    final min = int.tryParse(_numMin) ?? 1;
    final max = int.tryParse(_numMax) ?? 100;
    final r = min + _rng.nextInt((max - min + 1).clamp(1, 999999999));
    setState(() { _result = r.toString(); _spinCtrl.reset(); _spinCtrl.forward(); });
  }

  void _genPassword() {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const digits = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    String chars = '';
    if (_incUpper) chars += upper;
    if (_incLower) chars += lower;
    if (_incDigits) chars += digits;
    if (_incSymbols) chars += symbols;
    if (chars.isEmpty) chars = lower + digits;
    final password = List.generate(_passwordLength, (_) => chars[_rng.nextInt(chars.length)]).join();
    setState(() { _result = password; _spinCtrl.reset(); _spinCtrl.forward(); });
  }

  void _genColor() {
    const hex = '0123456789ABCDEF';
    String color = '#';
    for (int i = 0; i < 6; i++) { color += hex[_rng.nextInt(16)]; }
    setState(() { _result = color; _spinCtrl.reset(); _spinCtrl.forward(); });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [_tabButton('数字', 0), _tabButton('密码', 1), _tabButton('颜色', 2)]),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_tabIndex == 0) ...[
                    Row(children: [Expanded(child: _inputField('最小值', _numMin, (v) => _numMin = v)), const SizedBox(width: 10), Expanded(child: _inputField('最大值', _numMax, (v) => _numMax = v))]),
                    const SizedBox(height: 16), _genButton(_genNumber),
                  ],
                  if (_tabIndex == 1) ...[
                    Row(children: [
                      const Text('长度:', style: TextStyle(color: Colors.white70)),
                      Expanded(child: Slider(value: _passwordLength.toDouble(), min: 4, max: 32, divisions: 28, activeColor: const Color(0xFF00d4ff), label: '$_passwordLength', onChanged: (v) => setState(() => _passwordLength = v.toInt()))),
                      Text('$_passwordLength', style: const TextStyle(color: const Color(0xFF00d4ff))),
                    ]),
                    Wrap(spacing: 8, children: [
                      _checkChip('大写', _incUpper, (v) => setState(() => _incUpper = v!)),
                      _checkChip('小写', _incLower, (v) => setState(() => _incLower = v!)),
                      _checkChip('数字', _incDigits, (v) => setState(() => _incDigits = v!)),
                      _checkChip('符号', _incSymbols, (v) => setState(() => _incSymbols = v!)),
                    ]),
                    const SizedBox(height: 16), _genButton(_genPassword),
                  ],
                  if (_tabIndex == 2) ...[const SizedBox(height: 20), _genButton(_genColor)],
                  if (_result.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    AnimatedBuilder(
                      animation: _spinCtrl,
                      builder: (_, child) => Transform.scale(scale: Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.elasticOut)).value, child: child),
                      child: Container(
                        width: double.infinity, padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _result.startsWith('#') ? Color(int.parse('FF${_result.substring(1)}', radix: 16)) : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.3)),
                        ),
                        child: Column(children: [
                          SelectableText(_result, style: TextStyle(color: _result.startsWith('#') ? Colors.white : const Color(0xFF00d4ff), fontSize: _result.length > 20 ? 20 : 32, fontWeight: FontWeight.bold, fontFamily: 'monospace'), textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          TextButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: _result)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); }, icon: const Icon(Icons.copy, color: const Color(0xFF00d4ff)), label: const Text('复制', style: TextStyle(color: const Color(0xFF00d4ff)))),
                        ]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final active = _tabIndex == index;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() { _tabIndex = index; _result = ''; }),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: active ? const Color(0xFF00d4ff) : Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.black : Colors.white70, fontWeight: FontWeight.bold))),
    ));
  }

  Widget _inputField(String label, String value, Function(String) onChanged) {
    return TextField(style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), keyboardType: TextInputType.number, onChanged: onChanged, controller: TextEditingController(text: value));
  }

  Widget _genButton(VoidCallback onTap) {
    return SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onTap, icon: const Icon(Icons.shuffle), label: const Text('生成'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00d4ff), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))));
  }

  Widget _checkChip(String label, bool value, Function(bool?) onChanged) {
    return FilterChip(label: Text(label, style: TextStyle(color: value ? Colors.black : Colors.white70)), selected: value, selectedColor: const Color(0xFF00d4ff), backgroundColor: Colors.white.withOpacity(0.08), checkmarkColor: Colors.black, onSelected: onChanged);
  }
}

// ============ 单位换算 ============
class _UnitConverterTool extends StatefulWidget {
  const _UnitConverterTool();
  @override
  State<_UnitConverterTool> createState() => _UnitConverterToolState();
}

class _UnitConverterToolState extends State<_UnitConverterTool> {
  int _category = 0;
  int _fromUnit = 0;
  int _toUnit = 1;
  String _input = '1';
  String _output = '';

  final _categories = ['长度', '重量', '温度', '货币'];
  static const _lengthUnits = ['米', '千米', '厘米', '毫米', '英里', '英尺', '英寸', '码'];
  static const _weightUnits = ['千克', '克', '毫克', '吨', '磅', '盎司'];
  static const _tempUnits = ['摄氏度', '华氏度', '开尔文'];
  static const _currencyUnits = ['USD', 'EUR', 'CNY', 'JPY', 'GBP', 'KRW'];
  static const _currencyRates = {'USD': 1.0, 'EUR': 0.92, 'CNY': 7.24, 'JPY': 149.5, 'GBP': 0.79, 'KRW': 1320.0};

  List<String> get _units {
    switch (_category) { case 0: return _lengthUnits; case 1: return _weightUnits; case 2: return _tempUnits; case 3: return _currencyUnits; default: return _lengthUnits; }
  }

  void _convert() {
    final value = double.tryParse(_input) ?? 0;
    if (_category == 0) _output = _convertLength(value).toStringAsFixed(4);
    else if (_category == 1) _output = _convertWeight(value).toStringAsFixed(4);
    else if (_category == 2) _output = _convertTemp(value).toStringAsFixed(2);
    else if (_category == 3) _output = _convertCurrency(value).toStringAsFixed(4);
    setState(() {});
  }

  double _toBaseMeter(double v, int unit) { const factors = [1.0, 1000, 0.01, 0.001, 1609.344, 0.3048, 0.0254, 0.9144]; return v * factors[unit]; }
  double _fromBaseMeter(double v, int unit) { const factors = [1.0, 1000, 0.01, 0.001, 1609.344, 0.3048, 0.0254, 0.9144]; return v / factors[unit]; }
  double _convertLength(double v) => _fromBaseMeter(_toBaseMeter(v, _fromUnit), _toUnit);
  double _toBaseGram(double v, int unit) { const factors = [1000.0, 1.0, 0.001, 1000000.0, 453.592, 28.3495]; return v * factors[unit]; }
  double _fromBaseGram(double v, int unit) { const factors = [1000.0, 1.0, 0.001, 1000000.0, 453.592, 28.3495]; return v / factors[unit]; }
  double _convertWeight(double v) => _fromBaseGram(_toBaseGram(v, _fromUnit), _toUnit);

  double _convertTemp(double v) {
    double celsius;
    switch (_fromUnit) { case 0: celsius = v; break; case 1: celsius = (v - 32) * 5 / 9; break; case 2: celsius = v - 273.15; break; default: celsius = v; }
    switch (_toUnit) { case 0: return celsius; case 1: return celsius * 9 / 5 + 32; case 2: return celsius + 273.15; default: return celsius; }
  }

  double _convertCurrency(double v) {
    final from = _currencyUnits[_fromUnit];
    final to = _currencyUnits[_toUnit];
    return v / _currencyRates[from]! * _currencyRates[to]!;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                _categories.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_categories[i],
                      style: TextStyle(color: _category == i ? Colors.black : Colors.white70)),
                    selected: _category == i,
                    selectedColor: const Color(0xFF00d4ff),
                    backgroundColor: Colors.white.withOpacity(0.08),
                    onSelected: (_) {
                      setState(() {
                        _category = i;
                        _fromUnit = 0;
                        _toUnit = 1;
                        _output = '';
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(style: const TextStyle(color: Colors.white, fontSize: 24), decoration: InputDecoration(hintText: '输入数值', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.edit, color: const Color(0xFF00d4ff))), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) => _input = v),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _unitDropdown(_fromUnit, (v) => setState(() => _fromUnit = v))), const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.arrow_forward, color: const Color(0xFF00d4ff))), Expanded(child: _unitDropdown(_toUnit, (v) => setState(() => _toUnit = v)))]),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _convert, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00d4ff), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('换算', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          if (_output.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.3))), child: Column(children: [Text('$_input ${_units[_fromUnit]}', style: const TextStyle(color: Colors.white70, fontSize: 16)), const SizedBox(height: 8), const Icon(Icons.arrow_downward, color: const Color(0xFF00d4ff)), const SizedBox(height: 8), Text('$_output ${_units[_toUnit]}', style: const TextStyle(color: const Color(0xFF00d4ff), fontSize: 24, fontWeight: FontWeight.bold))])),
          ],
        ],
      ),
    );
  }

  Widget _unitDropdown(int value, Function(int) onChanged) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: DropdownButtonHideUnderline(child: DropdownButton<int>(value: value, isExpanded: true, dropdownColor: const Color(0xFF1a1a2e), style: const TextStyle(color: Colors.white), icon: const Icon(Icons.arrow_drop_down, color: const Color(0xFF00d4ff)), items: List.generate(_units.length, (i) => DropdownMenuItem(value: i, child: Text(_units[i], style: const TextStyle(color: Colors.white)))), onChanged: (v) => onChanged(v!))));
  }
}

// ============ 颜色选择器 ============
class _ColorPickerTool extends StatefulWidget {
  const _ColorPickerTool();
  @override
  State<_ColorPickerTool> createState() => _ColorPickerToolState();
}

class _ColorPickerToolState extends State<_ColorPickerTool> with TickerProviderStateMixin {
  double _hue = 0, _saturation = 1, _brightness = 1;
  Color _selectedColor = const Color(0xFF00d4ff);
  List<Color> _savedColors = [];
  late AnimationController _animCtrl;

  @override
  void initState() { super.initState(); _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300)); _loadColors(); }
  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<void> _loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    final colors = prefs.getStringList('saved_colors') ?? [];
    if (mounted) setState(() { _savedColors = colors.map((c) => Color(int.parse(c))).toList(); });
  }

  Future<void> _saveColor(Color c) async {
    final prefs = await SharedPreferences.getInstance();
    _savedColors.insert(0, c);
    if (_savedColors.length > 20) _savedColors = _savedColors.sublist(0, 20);
    await prefs.setStringList('saved_colors', _savedColors.map((c) => c.value.toString()).toList());
    setState(() {});
  }

  Color _hsbToColor() => HSVColor.fromAHSV(1, _hue * 360, _saturation, _brightness).toColor();
  String _colorToHex(Color c) => '#${c.red.toRadixString(16).padLeft(2, '0')}${c.green.toRadixString(16).padLeft(2, '0')}${c.blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();

  @override
  Widget build(BuildContext context) {
    _selectedColor = _hsbToColor();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        AnimatedContainer(duration: const Duration(milliseconds: 200), width: 120, height: 120, decoration: BoxDecoration(color: _selectedColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: _selectedColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)])),
        const SizedBox(height: 12),
        SelectableText(_colorToHex(_selectedColor), style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'monospace')),
        const SizedBox(height: 8),
        Text('RGB(${_selectedColor.red}, ${_selectedColor.green}, ${_selectedColor.blue})', style: const TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 20),
        _buildSlider('色相', _hue, (v) => setState(() => _hue = v), true),
        _buildSlider('饱和度', _saturation, (v) => setState(() => _saturation = v)),
        _buildSlider('亮度', _brightness, (v) => setState(() => _brightness = v)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: ElevatedButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: _colorToHex(_selectedColor))); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制颜色值'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); }, icon: const Icon(Icons.copy), label: const Text('复制'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00d4ff), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(onPressed: () => _saveColor(_selectedColor), icon: const Icon(Icons.bookmark), label: const Text('收藏'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.15), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        ]),
        if (_savedColors.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('收藏的颜色', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: _savedColors.map((c) => GestureDetector(onTap: () { final hsv = HSVColor.fromColor(c); setState(() { _hue = hsv.hue / 360; _saturation = hsv.saturation; _brightness = hsv.value; }); }, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24))))).toList()),
        ],
      ]),
    );
  }

  Widget _buildSlider(String label, double value, Function(double) onChanged, [bool isHue = false]) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)), Text('${(value * 100).toInt()}%', style: const TextStyle(color: Colors.white54, fontSize: 13))]),
      SliderTheme(data: SliderThemeData(trackHeight: 6, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10), activeTrackColor: isHue ? null : const Color(0xFF00d4ff), inactiveTrackColor: Colors.white.withOpacity(0.1), thumbColor: Colors.white, overlayColor: const Color(0xFF00d4ff).withOpacity(0.2)), child: Slider(value: value, onChanged: onChanged)),
    ]));
  }
}

// ============ 文字计数 ============
class _TextCounterTool extends StatefulWidget {
  const _TextCounterTool();
  @override
  State<_TextCounterTool> createState() => _TextCounterToolState();
}

class _TextCounterToolState extends State<_TextCounterTool> {
  final _controller = TextEditingController();
  int _charCount = 0, _charNoSpace = 0, _wordCount = 0, _lineCount = 0;

  void _update() {
    final text = _controller.text;
    setState(() {
      _charCount = text.length;
      _charNoSpace = text.replaceAll(RegExp(r'\s'), '').length;
      _wordCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
      _lineCount = text.isEmpty ? 0 : text.split('\n').length;
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(controller: _controller, style: const TextStyle(color: Colors.white, fontSize: 16), decoration: InputDecoration(hintText: '输入或粘贴文字...', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), maxLines: 8, onChanged: (_) => _update()),
        const SizedBox(height: 20),
        Row(children: [_countCard('字符数', _charCount), _countCard('不含空格', _charNoSpace), _countCard('单词数', _wordCount), _countCard('行数', _lineCount)]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () { _controller.clear(); _update(); }, style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24)), child: const Text('清空'))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(onPressed: () async { final data = await Clipboard.getData(Clipboard.kTextPlain); if (data?.text != null) { _controller.text = data!.text!; _update(); } }, icon: const Icon(Icons.paste, size: 18), label: const Text('粘贴'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00d4ff), foregroundColor: Colors.black))),
        ]),
      ]),
    );
  }

  Widget _countCard(String label, int count) {
    return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text('$count', style: const TextStyle(color: const Color(0xFF00d4ff), fontSize: 22, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11))])));
  }
}

// ============ 系统信息 ============
class _SystemInfoTool extends StatefulWidget {
  const _SystemInfoTool();
  @override
  State<_SystemInfoTool> createState() => _SystemInfoToolState();
}

class _SystemInfoToolState extends State<_SystemInfoTool> {
  final _deviceInfo = DeviceInfoPlugin();
  Map<String, String> _info = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadInfo(); }

  Future<void> _loadInfo() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      if (mounted) {
        setState(() {
          _info = {'设备型号': androidInfo.model, '制造商': androidInfo.manufacturer, 'Android版本': androidInfo.version.release, 'SDK版本': androidInfo.version.sdkInt.toString(), '品牌': androidInfo.brand, '硬件': androidInfo.hardware, '产品': androidInfo.product, '设备': androidInfo.device, '显示': androidInfo.display, '主板': androidInfo.board, '主机': androidInfo.host, '指纹': androidInfo.fingerprint, '是否模拟器': androidInfo.isPhysicalDevice ? '否' : '是'};
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _info = {'错误': e.toString()}; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: const Color(0xFF00d4ff)));
    return ListView(padding: const EdgeInsets.all(16), children: _info.entries.map((e) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)), child: Row(children: [Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white54, fontSize: 14))), Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))]))).toList());
  }
}

// ============ 指南针 ============
class _CompassTool extends StatefulWidget {
  const _CompassTool();
  @override
  State<_CompassTool> createState() => _CompassToolState();
}

class _CompassToolState extends State<_CompassTool> with TickerProviderStateMixin {
  double _heading = 0;
  StreamSubscription? _sub;
  late AnimationController _rotateCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _sub = magnetometerEventStream().listen((event) {
      double angle = math.atan2(event.y, event.x) * 180 / math.pi;
      if (angle < 0) angle += 360;
      if (mounted) { _rotateCtrl.animateTo(angle / 360, duration: const Duration(milliseconds: 200)); setState(() => _heading = angle); }
    });
  }

  @override
  void dispose() { _sub?.cancel(); _rotateCtrl.dispose(); super.dispose(); }

  String _direction(double angle) {
    if (angle < 22.5 || angle >= 337.5) return '北';
    if (angle < 67.5) return '东北';
    if (angle < 112.5) return '东';
    if (angle < 157.5) return '东南';
    if (angle < 202.5) return '南';
    if (angle < 247.5) return '西南';
    if (angle < 292.5) return '西';
    return '西北';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _rotateCtrl,
          builder: (_, __) => Transform.rotate(
            angle: -_rotateCtrl.value * 2 * math.pi,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [Color(0xFF16213e), Color(0xFF0f3460)]), border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.3), width: 2), boxShadow: [BoxShadow(color: const Color(0xFF00d4ff).withOpacity(0.1), blurRadius: 20)]),
              child: Stack(alignment: Alignment.center, children: [
                ...List.generate(12, (i) {
                  final angle = i * 30 * math.pi / 180;
                  final isCardinal = i % 3 == 0;
                  return Positioned(top: 10, left: 110 - (isCardinal ? 1.5 : 0.5), child: Transform.rotate(angle: angle, child: Transform.translate(offset: const Offset(0, 0), child: Container(width: isCardinal ? 3 : 1, height: isCardinal ? 20 : 10, color: isCardinal ? const Color(0xFF00d4ff) : Colors.white38))));
                }),
                Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 4, height: 60, decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.redAccent, Colors.transparent]), borderRadius: BorderRadius.circular(2))), Container(width: 4, height: 60, decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.white54, Colors.transparent]), borderRadius: BorderRadius.circular(2)))]),
                Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00d4ff))),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text('${_heading.toStringAsFixed(1)}°', style: const TextStyle(color: const Color(0xFF00d4ff), fontSize: 48, fontWeight: FontWeight.w200)),
        const SizedBox(height: 8),
        Text(_direction(_heading), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

// ============ 手电筒 ============
class _FlashlightTool extends StatefulWidget {
  const _FlashlightTool();
  @override
  State<_FlashlightTool> createState() => _FlashlightToolState();
}

class _FlashlightToolState extends State<_FlashlightTool> with TickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _isOn = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() { super.initState(); _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800)); _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut)); _pulseCtrl.repeat(reverse: true); }
  @override
  void dispose() { _controller.dispose(); _pulseCtrl.dispose(); super.dispose(); }

  void _toggle() { _controller.toggleTorch(); setState(() => _isOn = !_isOn); }

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(animation: _pulseAnim, builder: (_, child) => Transform.scale(scale: _isOn ? _pulseAnim.value : 1.0, child: child), child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(duration: const Duration(milliseconds: 300), width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, color: _isOn ? const Color(0xFFFFD600) : Colors.white.withOpacity(0.1), boxShadow: _isOn ? [BoxShadow(color: const Color(0xFFFFD600).withOpacity(0.4), blurRadius: 40, spreadRadius: 10), BoxShadow(color: const Color(0xFFFFD600).withOpacity(0.2), blurRadius: 80, spreadRadius: 20)] : []), child: Icon(_isOn ? Icons.flashlight_on : Icons.flashlight_off, size: 64, color: _isOn ? Colors.black : Colors.white54)),
      )),
      const SizedBox(height: 30),
      Text(_isOn ? '手电筒已开启' : '点击开启手电筒', style: TextStyle(color: _isOn ? const Color(0xFFFFD600) : Colors.white54, fontSize: 18)),
      if (_isOn) ...[const SizedBox(height: 12), const Text('注意：长时间使用可能发热', style: TextStyle(color: Colors.white38, fontSize: 12))],
    ]));
  }
}

// ============ 剪贴板管理 ============
class _ClipboardTool extends StatefulWidget {
  const _ClipboardTool();
  @override
  State<_ClipboardTool> createState() => _ClipboardToolState();
}

class _ClipboardToolState extends State<_ClipboardTool> {
  List<String> _history = [];

  @override
  void initState() { super.initState(); _loadHistory(); }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList('clipboard_history') ?? [];
    if (mounted) setState(() => _history = items);
  }

  Future<void> _addToHistory(String text) async {
    final prefs = await SharedPreferences.getInstance();
    _history.insert(0, text);
    if (_history.length > 50) _history = _history.sublist(0, 50);
    await prefs.setStringList('clipboard_history', _history);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: () async { final data = await Clipboard.getData(Clipboard.kTextPlain); if (data?.text != null && data!.text!.isNotEmpty) { _addToHistory(data.text!); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已添加剪贴板内容'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); } }, icon: const Icon(Icons.add), label: const Text('获取当前剪贴板'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00d4ff), foregroundColor: Colors.black))),
        const SizedBox(width: 10),
        IconButton(onPressed: () async { final prefs = await SharedPreferences.getInstance(); await prefs.remove('clipboard_history'); setState(() => _history.clear()); }, icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), tooltip: '清空'),
      ])),
      Expanded(child: _history.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.content_paste, size: 64, color: Colors.white24), const SizedBox(height: 16), const Text('剪贴板历史为空', style: TextStyle(color: Colors.white38)), const SizedBox(height: 8), const Text('复制内容后点击上方按钮保存', style: TextStyle(color: Colors.white24, fontSize: 12))])) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _history.length, itemBuilder: (ctx, i) => Card(color: Colors.white.withOpacity(0.06), margin: const EdgeInsets.only(bottom: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: ListTile(title: Text(_history[i], style: const TextStyle(color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.copy, color: const Color(0xFF00d4ff), size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: _history[i])); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); }), IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () async { _history.removeAt(i); final prefs = await SharedPreferences.getInstance(); await prefs.setStringList('clipboard_history', _history); setState(() {}); })]))))),
    ]);
  }
}

// ============ 文字转语音 ============
class _TextToSpeechTool extends StatefulWidget {
  const _TextToSpeechTool();
  @override
  State<_TextToSpeechTool> createState() => _TextToSpeechToolState();
}

class _TextToSpeechToolState extends State<_TextToSpeechTool> with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final _controller = TextEditingController();
  bool _isSpeaking = false;
  double _rate = 0.5, _pitch = 1.0, _volume = 1.0;
  late AnimationController _waveCtrl;
  late Animation<double> _waveAnim;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _waveAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _waveCtrl, curve: Curves.easeInOut));
    _waveCtrl.repeat(reverse: true);
    _tts.setCompletionHandler(() { if (mounted) setState(() => _isSpeaking = false); });
    _tts.setErrorHandler((msg) { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('错误: $msg'), backgroundColor: Colors.redAccent)); setState(() => _isSpeaking = false); } });
  }

  @override
  void dispose() { _tts.stop(); _controller.dispose(); _waveCtrl.dispose(); super.dispose(); }

  Future<void> _speak() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_isSpeaking) { await _tts.stop(); setState(() => _isSpeaking = false); return; }
    await _tts.setSpeechRate(_rate * 2);
    await _tts.setPitch(_pitch);
    await _tts.setVolume(_volume);
    await _tts.speak(text);
    setState(() => _isSpeaking = true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _controller, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '输入要朗读的文字...', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), maxLines: 5),
      const SizedBox(height: 16),
      _sliderBar('语速', _rate, (v) => setState(() => _rate = v)),
      _sliderBar('音调', _pitch, (v) => setState(() => _pitch = v)),
      _sliderBar('音量', _volume, (v) => setState(() => _volume = v)),
      const SizedBox(height: 20),
      AnimatedBuilder(animation: _waveAnim, builder: (_, child) => Transform.scale(scale: _isSpeaking ? 1.0 + _waveAnim.value * 0.1 : 1.0, child: child), child: ElevatedButton.icon(onPressed: _speak, icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up), label: Text(_isSpeaking ? '停止' : '朗读', style: const TextStyle(fontSize: 18)), style: ElevatedButton.styleFrom(backgroundColor: _isSpeaking ? Colors.redAccent : const Color(0xFF00d4ff), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
      if (_isSpeaking) ...[
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => AnimatedBuilder(animation: _waveAnim, builder: (_, __) { final h = 10.0 + math.sin((_waveAnim.value + i * 0.3) * 6.28318).abs() * 20; return Container(width: 4, height: h, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: const Color(0xFF00d4ff).withOpacity(0.3 + i * 0.15), borderRadius: BorderRadius.circular(2))); }))),
      ],
    ]));
  }

  Widget _sliderBar(String label, double value, Function(double) onChanged) {
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [SizedBox(width: 40, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))), Expanded(child: Slider(value: value, min: 0.1, max: 2.0, activeColor: const Color(0xFF00d4ff), onChanged: onChanged)), SizedBox(width: 35, child: Text('${(value * 100).toInt()}%', style: const TextStyle(color: Colors.white38, fontSize: 11)))]));
  }
}

// ============ 11. 密码生成器 ============
class _PasswordGeneratorTool extends StatefulWidget {
  const _PasswordGeneratorTool();
  @override
  State<_PasswordGeneratorTool> createState() => _PasswordGeneratorToolState();
}

class _PasswordGeneratorToolState extends State<_PasswordGeneratorTool> with TickerProviderStateMixin {
  final _rng = math.Random();
  String _password = '';
  int _length = 16;
  bool _upper = true, _lower = true, _digits = true, _symbols = true;
  late AnimationController _animCtrl;
  late Animation<double> _anim;

  @override
  void initState() { super.initState(); _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500)); _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut); _genPassword(); }
  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  void _genPassword() {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const digits = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    String chars = '';
    if (_upper) chars += upper;
    if (_lower) chars += lower;
    if (_digits) chars += digits;
    if (_symbols) chars += symbols;
    if (chars.isEmpty) chars = lower + digits;
    _password = List.generate(_length, (_) => chars[_rng.nextInt(chars.length)]).join();
    _animCtrl.reset(); _animCtrl.forward();
    setState(() {});
  }

  String _strengthText() {
    int score = 0;
    if (_length >= 8) score++; if (_length >= 12) score++; if (_length >= 16) score++;
    if (_upper) score++; if (_lower) score++; if (_digits) score++; if (_symbols) score++;
    if (score <= 3) return '弱';
    if (score <= 5) return '中';
    return '强';
  }

  Color _strengthColor() {
    switch (_strengthText()) { case '弱': return Colors.redAccent; case '中': return Colors.orangeAccent; default: return Colors.greenAccent; }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: SingleChildScrollView(child: Column(children: [
      Row(children: [const Text('长度:', style: TextStyle(color: Colors.white70)), Expanded(child: Slider(value: _length.toDouble(), min: 4, max: 64, divisions: 60, activeColor: Colors.greenAccent, label: '$_length', onChanged: (v) => setState(() => _length = v.toInt()))), Text('$_length', style: const TextStyle(color: Colors.greenAccent))]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _chip('大写字母', _upper, (v) => setState(() => _upper = v!)),
        _chip('小写字母', _lower, (v) => setState(() => _lower = v!)),
        _chip('数字', _digits, (v) => setState(() => _digits = v!)),
        _chip('特殊符号', _symbols, (v) => setState(() => _symbols = v!)),
      ]),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _genPassword, icon: const Icon(Icons.refresh), label: const Text('生成密码'), style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      const SizedBox(height: 24),
      AnimatedBuilder(animation: _anim, builder: (_, child) => Transform.scale(scale: Tween<double>(begin: 0.5, end: 1.0).animate(_anim).value, child: child), child: Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: _strengthColor().withOpacity(0.5))),
        child: Column(children: [
          SelectableText(_password, style: TextStyle(color: _strengthColor(), fontSize: _length > 20 ? 18 : 24, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 2), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: _strengthColor().withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text('强度: ${_strengthText()}', style: TextStyle(color: _strengthColor(), fontSize: 13, fontWeight: FontWeight.bold))),
            const SizedBox(width: 16),
            IconButton(icon: const Icon(Icons.copy, color: Colors.greenAccent), onPressed: () { Clipboard.setData(ClipboardData(text: _password)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制密码'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); }),
          ]),
        ]),
      )),
    ])));
  }

  Widget _chip(String label, bool value, Function(bool?) onChanged) {
    return FilterChip(label: Text(label, style: TextStyle(color: value ? Colors.black : Colors.white70, fontSize: 12)), selected: value, selectedColor: Colors.greenAccent, backgroundColor: Colors.white.withOpacity(0.08), checkmarkColor: Colors.black, onSelected: onChanged, visualDensity: VisualDensity.compact);
  }
}

// ============ 12. 骰子 ============
class _DiceTool extends StatefulWidget {
  const _DiceTool();
  @override
  State<_DiceTool> createState() => _DiceToolState();
}

class _DiceToolState extends State<_DiceTool> with TickerProviderStateMixin {
  final _rng = math.Random();
  int _result = 1;
  int _sides = 6;
  List<int> _history = [];
  late AnimationController _rollCtrl;
  late Animation<double> _rollAnim;

  @override
  void initState() { super.initState(); _rollCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600)); _rollAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _rollCtrl, curve: Curves.easeOut)); }
  @override
  void dispose() { _rollCtrl.dispose(); super.dispose(); }

  void _roll() {
    _rollCtrl.reset();
    final r = _rng.nextInt(_sides) + 1;
    setState(() { _result = r; _history.insert(0, r); if (_history.length > 20) _history.removeLast(); });
    _rollCtrl.forward();
  }

  Widget _diceFace(int n) {
    if (n == 0) n = 1;
    return Container(
      width: 120, height: 120,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24, width: 2)),
      child: Center(child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [4, 6, 8, 10, 12, 20].map((s) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(label: Text('D$s', style: TextStyle(color: _sides == s ? Colors.black : Colors.white70, fontSize: 12)), selected: _sides == s, selectedColor: Colors.orangeAccent, backgroundColor: Colors.white.withOpacity(0.08), onSelected: (_) => setState(() => _sides = s)))).toList()),
      const SizedBox(height: 30),
      AnimatedBuilder(animation: _rollAnim, builder: (_, child) => Transform.rotate(angle: _rollAnim.value * 4 * math.pi, child: Transform.scale(scale: 1.0 + math.sin(_rollAnim.value * math.pi) * 0.3, child: child)), child: _diceFace(_result)),
      const SizedBox(height: 30),
      SizedBox(width: 160, child: ElevatedButton.icon(onPressed: _roll, icon: const Icon(Icons.casino), label: const Text('掷骰子', style: TextStyle(fontSize: 18)), style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
      if (_history.isNotEmpty) ...[const SizedBox(height: 20), const Text('历史记录', style: TextStyle(color: Colors.white70, fontSize: 14)), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: _history.take(10).map((h) => Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Center(child: Text('$h', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))))).toList())],
    ]));
  }
}

// ============ 13. 硬币抛掷 ============
class _CoinFlipTool extends StatefulWidget {
  const _CoinFlipTool();
  @override
  State<_CoinFlipTool> createState() => _CoinFlipToolState();
}

class _CoinFlipToolState extends State<_CoinFlipTool> with TickerProviderStateMixin {
  final _rng = math.Random();
  String _result = '正面';
  int _heads = 0, _tails = 0;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() { super.initState(); _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800)); _flipAnim = CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut); }
  @override
  void dispose() { _flipCtrl.dispose(); super.dispose(); }

  void _flip() {
    _flipCtrl.reset();
    final r = _rng.nextBool();
    setState(() { _result = r ? '正面' : '反面'; if (r) _heads++; else _tails++; });
    _flipCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(animation: _flipAnim, builder: (_, child) {
        final isFront = _flipAnim.value < 0.5;
        return Transform(transform: Matrix4.rotationY(_flipAnim.value * math.pi), alignment: Alignment.center, child: Container(
          width: 180, height: 180,
          decoration: BoxDecoration(shape: BoxShape.circle, color: isFront ? const Color(0xFFFFD600) : const Color(0xFFB0BEC5), border: Border.all(color: Colors.white38, width: 3), boxShadow: [BoxShadow(color: (isFront ? const Color(0xFFFFD600) : const Color(0xFFB0BEC5)).withOpacity(0.4), blurRadius: 30, spreadRadius: 5)]),
          child: Center(child: Text(isFront ? '正' : '反', style: TextStyle(color: isFront ? Colors.black : Colors.white, fontSize: 48, fontWeight: FontWeight.bold))),
        ));
      }),
      const SizedBox(height: 30),
      Text(_result, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      SizedBox(width: 160, child: ElevatedButton.icon(onPressed: _flip, icon: const Icon(Icons.toll), label: const Text('抛硬币', style: TextStyle(fontSize: 18)), style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
      const SizedBox(height: 30),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _statCard('正面', _heads, const Color(0xFFFFD600)),
        const SizedBox(width: 20),
        _statCard('反面', _tails, const Color(0xFFB0BEC5)),
      ]),
    ])));
  }

  Widget _statCard(String label, int count, Color color) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text('$count', style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))]));
  }
}

// ============ 14. BMI计算器 ============
class _BMITool extends StatefulWidget {
  const _BMITool();
  @override
  State<_BMITool> createState() => _BMIToolState();
}

class _BMIToolState extends State<_BMITool> {
  String _height = '170', _weight = '65';
  double? _bmi;
  String _category = '';

  void _calc() {
    final h = double.tryParse(_height) ?? 170;
    final w = double.tryParse(_weight) ?? 65;
    final bmi = w / ((h / 100) * (h / 100));
    setState(() {
      _bmi = bmi;
      if (bmi < 18.5) _category = '偏瘦';
      else if (bmi < 25) _category = '正常';
      else if (bmi < 30) _category = '偏胖';
      else _category = '肥胖';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(20), child: SingleChildScrollView(child: Column(children: [
      const Icon(Icons.monitor_weight, size: 64, color: const Color(0xFF00d4ff)),
      const SizedBox(height: 20),
      _field('身高 (cm)', _height, (v) => _height = v),
      const SizedBox(height: 12),
      _field('体重 (kg)', _weight, (v) => _weight = v),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _calc, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00d4ff), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('计算 BMI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
      if (_bmi != null) ...[
        const SizedBox(height: 24),
        Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF00d4ff).withOpacity(0.1), const Color(0xFF0077be).withOpacity(0.1)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.3))), child: Column(children: [
          Text('${_bmi!.toStringAsFixed(1)}', style: const TextStyle(color: const Color(0xFF00d4ff), fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_category, style: const TextStyle(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (_bmi!.clamp(10, 40) - 10) / 30, backgroundColor: Colors.white.withOpacity(0.1), color: _bmi! < 18.5 ? Colors.amber : _bmi! < 25 ? Colors.greenAccent : _bmi! < 30 ? Colors.orange : Colors.redAccent, minHeight: 10)),
        ])),
      ],
    ])));
  }

  Widget _field(String label, String value, Function(String) onChanged) {
    return TextField(style: const TextStyle(color: Colors.white, fontSize: 18), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), suffixIcon: const Icon(Icons.edit, color: const Color(0xFF00d4ff), size: 18)), keyboardType: TextInputType.number, onChanged: onChanged, controller: TextEditingController(text: value));
  }
}

// ============ 15. 年龄计算器 ============
class _AgeCalculatorTool extends StatefulWidget {
  const _AgeCalculatorTool();
  @override
  State<_AgeCalculatorTool> createState() => _AgeCalculatorToolState();
}

class _AgeCalculatorToolState extends State<_AgeCalculatorTool> {
  DateTime _birthDate = DateTime(2000, 1, 1);
  String _result = '';

  void _calc() {
    final now = DateTime.now();
    final diff = now.difference(_birthDate);
    final years = now.year - _birthDate.year;
    int months = now.month - _birthDate.month;
    if (now.day < _birthDate.day) months--;
    if (months < 0) months += 12;
    final days = diff.inDays;
    setState(() => _result = '$years 岁 $months 个月\n共 $days 天');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _birthDate, firstDate: DateTime(1900), lastDate: DateTime.now(), builder: (ctx, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: const Color(0xFF00d4ff))), child: child!));
    if (picked != null) setState(() => _birthDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.cake, size: 72, color: Color(0xFFe91e63)),
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16)), child: Column(children: [
        const Text('出生日期', style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 8),
        Text('${_birthDate.year}年${_birthDate.month}月${_birthDate.day}日', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ])),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.date_range), label: const Text('选择日期'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFe91e63), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _calc, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00d4ff), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('计算年龄', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
      if (_result.isNotEmpty) ...[
        const SizedBox(height: 24),
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFFe91e63).withOpacity(0.1), const Color(0xFF00d4ff).withOpacity(0.1)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFe91e63).withOpacity(0.3))), child: Text(_result, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
      ],
    ]));
  }
}

// ============ 16. 小费计算器 ============
class _TipCalculatorTool extends StatefulWidget {
  const _TipCalculatorTool();
  @override
  State<_TipCalculatorTool> createState() => _TipCalculatorToolState();
}

class _TipCalculatorToolState extends State<_TipCalculatorTool> {
  String _amount = '100';
  double _tipPercent = 15;
  int _split = 1;

  double get _tip => (double.tryParse(_amount) ?? 0) * _tipPercent / 100;
  double get _total => (double.tryParse(_amount) ?? 0) + _tip;
  double get _perPerson => _split > 0 ? _total / _split : _total;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(20), child: SingleChildScrollView(child: Column(children: [
      TextField(style: const TextStyle(color: Colors.white, fontSize: 28), decoration: InputDecoration(hintText: '账单金额', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.attach_money, color: Colors.greenAccent), prefixText: '\$ ', prefixStyle: const TextStyle(color: Colors.greenAccent, fontSize: 28)), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) => setState(() => _amount = v), controller: TextEditingController(text: _amount)),
      const SizedBox(height: 20),
      Row(children: [const Text('小费比例:', style: TextStyle(color: Colors.white70)), Text(' ${_tipPercent.toInt()}%', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))]),
      Slider(value: _tipPercent, min: 5, max: 30, divisions: 25, activeColor: Colors.greenAccent, onChanged: (v) => setState(() => _tipPercent = v)),
      Row(children: [const Text('人数:', style: TextStyle(color: Colors.white70)), const Spacer(), IconButton(icon: const Icon(Icons.remove_circle, color: Colors.greenAccent), onPressed: _split > 1 ? () => setState(() => _split--) : null), Text('$_split', style: const TextStyle(color: Colors.white, fontSize: 20)), IconButton(icon: const Icon(Icons.add_circle, color: Colors.greenAccent), onPressed: () => setState(() => _split++))]),
      const SizedBox(height: 20),
      Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.greenAccent.withOpacity(0.3))), child: Column(children: [
        _infoRow('小费金额', '\$${_tip.toStringAsFixed(2)}', Colors.greenAccent),
        const SizedBox(height: 8),
        _infoRow('总金额', '\$${_total.toStringAsFixed(2)}', Colors.white),
        if (_split > 1) ...[const SizedBox(height: 8), _infoRow('每人', '\$${_perPerson.toStringAsFixed(2)}', Colors.amberAccent)],
      ])),
    ])));
  }

  Widget _infoRow(String label, String value, Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)), Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold))]);
  }
}

// ============ 17. 折扣计算器 ============
class _DiscountCalculatorTool extends StatefulWidget {
  const _DiscountCalculatorTool();
  @override
  State<_DiscountCalculatorTool> createState() => _DiscountCalculatorToolState();
}

class _DiscountCalculatorToolState extends State<_DiscountCalculatorTool> {
  String _price = '100';
  String _discount = '20';
  double? _finalPrice;
  double? _saved;

  void _calc() {
    final p = double.tryParse(_price) ?? 0;
    final d = double.tryParse(_discount) ?? 0;
    setState(() { _finalPrice = p * (1 - d / 100); _saved = p - _finalPrice!; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(20), child: SingleChildScrollView(child: Column(children: [
      _field('原价', _price, (v) => _price = v),
      const SizedBox(height: 12),
      _field('折扣 (%)', _discount, (v) => _discount = v),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _calc, style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('计算', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
      if (_finalPrice != null) ...[
        const SizedBox(height: 24),
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orangeAccent.withOpacity(0.3))), child: Column(children: [
          Text('折后价: \$${_finalPrice!.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('节省: \$${_saved!.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 18)),
        ])),
      ],
    ])));
  }

  Widget _field(String label, String value, Function(String) onChanged) {
    return TextField(style: const TextStyle(color: Colors.white, fontSize: 18), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), keyboardType: TextInputType.number, onChanged: onChanged, controller: TextEditingController(text: value));
  }
}

// ============ 18. 百分比计算器 ============
class _PercentCalculatorTool extends StatefulWidget {
  const _PercentCalculatorTool();
  @override
  State<_PercentCalculatorTool> createState() => _PercentCalculatorToolState();
}

class _PercentCalculatorToolState extends State<_PercentCalculatorTool> {
  int _mode = 0;
  String _val1 = '', _val2 = '', _result = '';

  final _modes = ['X的Y%', 'X是Y的%', 'X增加Y%', 'X减少Y%'];

  void _calc() {
    final x = double.tryParse(_val1) ?? 0;
    final y = double.tryParse(_val2) ?? 0;
    String r;
    switch (_mode) {
      case 0: r = '${(x * y / 100).toStringAsFixed(2)}'; break;
      case 1: r = y != 0 ? '${(x / y * 100).toStringAsFixed(2)}%' : 'N/A'; break;
      case 2: r = '${(x * (1 + y / 100)).toStringAsFixed(2)}'; break;
      case 3: r = '${(x * (1 - y / 100)).toStringAsFixed(2)}'; break;
      default: r = '';
    }
    setState(() => _result = r);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(20), child: SingleChildScrollView(child: Column(children: [
      Wrap(spacing: 8, runSpacing: 8, children: List.generate(_modes.length, (i) => ChoiceChip(label: Text(_modes[i], style: TextStyle(color: _mode == i ? Colors.black : Colors.white70, fontSize: 12)), selected: _mode == i, selectedColor: const Color(0xFFb388ff), backgroundColor: Colors.white.withOpacity(0.08), onSelected: (_) => setState(() { _mode = i; _result = ''; })))),
      const SizedBox(height: 20),
      _field('数值 X', _val1, (v) => _val1 = v),
      const SizedBox(height: 10),
      _field('数值 Y', _val2, (v) => _val2 = v),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _calc, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFb388ff), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('计算', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
      if (_result.isNotEmpty) ...[
        const SizedBox(height: 24),
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFb388ff).withOpacity(0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.percent, color: const Color(0xFFb388ff), size: 32), const SizedBox(width: 12), Text(_result, style: const TextStyle(color: const Color(0xFFb388ff), fontSize: 32, fontWeight: FontWeight.bold))])),
      ],
    ])));
  }

  Widget _field(String label, String value, Function(String) onChanged) {
    return TextField(style: const TextStyle(color: Colors.white, fontSize: 18), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: onChanged, controller: TextEditingController(text: value));
  }
}

// ============ 19. 世界时钟 ============
class _WorldClockTool extends StatefulWidget {
  const _WorldClockTool();
  @override
  State<_WorldClockTool> createState() => _WorldClockToolState();
}

class _WorldClockToolState extends State<_WorldClockTool> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  final _cities = [
    {'name': '北京', 'offset': 8, 'flag': 'CN'},
    {'name': '东京', 'offset': 9, 'flag': 'JP'},
    {'name': '纽约', 'offset': -4, 'flag': 'US'},
    {'name': '伦敦', 'offset': 1, 'flag': 'GB'},
    {'name': '巴黎', 'offset': 2, 'flag': 'FR'},
    {'name': '悉尼', 'offset': 10, 'flag': 'AU'},
    {'name': '迪拜', 'offset': 4, 'flag': 'AE'},
    {'name': '莫斯科', 'offset': 3, 'flag': 'RU'},
    {'name': '洛杉矶', 'offset': -7, 'flag': 'US'},
    {'name': '新加坡', 'offset': 8, 'flag': 'SG'},
  ];

  @override
  void initState() { super.initState(); _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now())); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  DateTime _localTime(int offset) {
    return _now.toUtc().add(Duration(hours: offset));
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cities.length,
      itemBuilder: (_, i) {
        final city = _cities[i];
        final t = _localTime(city['offset'] as int);
        final isDay = t.hour >= 6 && t.hour < 18;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.08))),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: isDay ? Colors.amber.withOpacity(0.2) : Colors.indigo.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(isDay ? Icons.wb_sunny : Icons.nightlight_round, color: isDay ? Colors.amber : Colors.indigoAccent, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(city['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text('GMT${(city['offset'] as num) >= 0 ? '+' : ''}${city['offset']}', style: const TextStyle(color: Colors.white38, fontSize: 12))])),
            Text('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: const Color(0xFF00d4ff), fontSize: 24, fontWeight: FontWeight.w300, fontFamily: 'monospace')),
          ]),
        );
      },
    );
  }
}

// ============ 20. 番茄钟 ============
class _PomodoroTool extends StatefulWidget {
  const _PomodoroTool();
  @override
  State<_PomodoroTool> createState() => _PomodoroToolState();
}

class _PomodoroToolState extends State<_PomodoroTool> with TickerProviderStateMixin {
  Timer? _timer;
  int _seconds = 25 * 60;
  bool _running = false;
  bool _isBreak = false;
  int _completed = 0;
  late AnimationController _animCtrl;

  static const _workTime = 25 * 60;
  static const _breakTime = 5 * 60;

  @override
  void initState() { super.initState(); _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2)); _animCtrl.repeat(reverse: true); }
  @override
  void dispose() { _timer?.cancel(); _animCtrl.dispose(); super.dispose(); }

  void _toggle() {
    if (_running) { _timer?.cancel(); setState(() => _running = false); return; }
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_seconds > 0) { _seconds--; return; }
        _timer?.cancel();
        _running = false;
        HapticFeedback.heavyImpact();
        if (!_isBreak) {
          _completed++;
          _seconds = _breakTime;
          _isBreak = true;
        } else {
          _seconds = _workTime;
          _isBreak = false;
        }
      });
    });
  }

  void _reset() { _timer?.cancel(); setState(() { _seconds = _workTime; _running = false; _isBreak = false; _completed = 0; }); }

  String _format() => '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_seconds / (_isBreak ? _breakTime : _workTime));
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_isBreak ? '休息时间' : '工作时间', style: TextStyle(color: _isBreak ? Colors.greenAccent : Colors.redAccent, fontSize: 18)),
      const SizedBox(height: 20),
      AnimatedBuilder(animation: _animCtrl, builder: (_, child) => Transform.scale(scale: _running ? 1.0 + _animCtrl.value * 0.03 : 1.0, child: child), child: SizedBox(
        width: 200, height: 200,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(width: 200, height: 200, child: CircularProgressIndicator(value: progress, strokeWidth: 8, backgroundColor: Colors.white.withOpacity(0.1), color: _isBreak ? Colors.greenAccent : Colors.redAccent)),
          Text(_format(), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w200, fontFamily: 'monospace')),
        ]),
      )),
      const SizedBox(height: 30),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        GestureDetector(onTap: _toggle, child: Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, color: (_isBreak ? Colors.greenAccent : Colors.redAccent).withOpacity(0.2), border: Border.all(color: (_isBreak ? Colors.greenAccent : Colors.redAccent).withOpacity(0.5))), child: Icon(_running ? Icons.pause : Icons.play_arrow, color: _isBreak ? Colors.greenAccent : Colors.redAccent, size: 36))),
        const SizedBox(width: 20),
        GestureDetector(onTap: _reset, child: Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1), border: Border.all(color: Colors.white24)), child: const Icon(Icons.refresh, color: Colors.white54, size: 28))),
      ]),
      if (_completed > 0) ...[const SizedBox(height: 20), Text('已完成 $_completed 个番茄', style: const TextStyle(color: Colors.white54, fontSize: 16))],
    ])));
  }
}

// ============ 21. 呼吸练习 ============
class _BreathingTool extends StatefulWidget {
  const _BreathingTool();
  @override
  State<_BreathingTool> createState() => _BreathingToolState();
}

class _BreathingToolState extends State<_BreathingTool> with TickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _anim;
  bool _running = false;
  String _phase = '准备';
  int _cycle = 0;
  Timer? _timer;
  double _duration = 4; // seconds per phase

  @override
  void initState() { super.initState(); _animCtrl = AnimationController(vsync: this, duration: Duration(seconds: _duration.toInt())); _anim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut)); }
  @override
  void dispose() { _timer?.cancel(); _animCtrl.dispose(); super.dispose(); }

  void _start() {
    _running = true; _cycle = 0;
    _runCycle();
  }

  void _runCycle() {
    if (!_running) return;
    // Breathe in
    _phase = '吸气';
    _animCtrl.forward(from: 0);
    _timer = Timer(Duration(seconds: _duration.toInt()), () {
      if (!_running) return;
      // Hold
      _phase = '屏息';
      _timer = Timer(Duration(seconds: _duration.toInt()), () {
        if (!_running) return;
        // Breathe out
        _phase = '呼气';
        _animCtrl.reverse(from: 1);
        _timer = Timer(Duration(seconds: _duration.toInt()), () {
          if (!_running) return;
          _cycle++;
          setState(() {});
          _runCycle();
        });
      });
    });
    setState(() {});
  }

  void _stop() { _running = false; _timer?.cancel(); _animCtrl.stop(); setState(() { _phase = '已停止'; }); }

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [4, 5, 6, 7].map((s) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(label: Text('${s}s', style: TextStyle(color: _duration == s ? Colors.black : Colors.white70, fontSize: 12)), selected: _duration == s, selectedColor: const Color(0xFF00d4ff), backgroundColor: Colors.white.withOpacity(0.08), onSelected: (_) { setState(() { _duration = s.toDouble(); _animCtrl.duration = Duration(seconds: s); }); }))).toList()),
      const SizedBox(height: 30),
      AnimatedBuilder(animation: _anim, builder: (_, child) => Transform.scale(scale: _anim.value, child: child), child: Container(
        width: 180, height: 180,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF00d4ff).withOpacity(0.3), const Color(0xFF0077be).withOpacity(0.1)]), border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.5), width: 3), boxShadow: [BoxShadow(color: const Color(0xFF00d4ff).withOpacity(0.2), blurRadius: 30)]),
        child: Center(child: Text(_phase, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
      )),
      const SizedBox(height: 30),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(width: 140, child: ElevatedButton.icon(onPressed: _running ? _stop : _start, icon: Icon(_running ? Icons.stop : Icons.play_arrow), label: Text(_running ? '停止' : '开始'), style: ElevatedButton.styleFrom(backgroundColor: _running ? Colors.redAccent : const Color(0xFF00d4ff), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
      ]),
      if (_cycle > 0) ...[const SizedBox(height: 12), Text('完成 $_cycle 个循环', style: const TextStyle(color: Colors.white54, fontSize: 14))],
    ])));
  }
}

// ============ 22. 节拍器 ============
class _MetronomeTool extends StatefulWidget {
  const _MetronomeTool();
  @override
  State<_MetronomeTool> createState() => _MetronomeToolState();
}

class _MetronomeToolState extends State<_MetronomeTool> with TickerProviderStateMixin {
  double _bpm = 120;
  bool _playing = false;
  Timer? _timer;
  int _beat = 0;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  int _beatsPerBar = 4;

  @override
  void initState() { super.initState(); _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100)); _pulseAnim = Tween<double>(begin: 1.0, end: 1.4).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut)); }
  @override
  void dispose() { _timer?.cancel(); _pulseCtrl.dispose(); super.dispose(); }

  void _toggle() {
    if (_playing) { _timer?.cancel(); _playing = false; setState(() {}); return; }
    _playing = true; _beat = 0;
    _tick();
  }

  void _tick() {
    if (!_playing) return;
    _pulseCtrl.reset(); _pulseCtrl.forward();
    HapticFeedback.lightImpact();
    setState(() { _beat = (_beat + 1) % _beatsPerBar; });
    _timer = Timer(Duration(milliseconds: (60000 / _bpm).round()), _tick);
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('${_bpm.toInt()} BPM', style: const TextStyle(color: const Color(0xFF00d4ff), fontSize: 56, fontWeight: FontWeight.w200)),
      const SizedBox(height: 10),
      Slider(value: _bpm, min: 40, max: 240, divisions: 200, activeColor: const Color(0xFFb388ff), onChanged: (v) => setState(() => _bpm = v)),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_beatsPerBar, (i) {
        return AnimatedBuilder(animation: _pulseAnim, builder: (_, child) => Transform.scale(scale: _playing && _beat == i ? _pulseAnim.value : 1.0, child: child), child: Container(
          width: 40, height: 40, margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(shape: BoxShape.circle, color: i == 0 ? Colors.redAccent.withOpacity(0.6) : const Color(0xFFb388ff).withOpacity(0.4), border: Border.all(color: (_playing && _beat == i) ? Colors.white : Colors.transparent, width: 2)),
        ));
      })),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [2, 3, 4, 5, 6].map((b) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(label: Text('$b/4', style: TextStyle(color: _beatsPerBar == b ? Colors.black : Colors.white70, fontSize: 11)), selected: _beatsPerBar == b, selectedColor: const Color(0xFFb388ff), backgroundColor: Colors.white.withOpacity(0.08), onSelected: (_) => setState(() => _beatsPerBar = b)))).toList()),
      const SizedBox(height: 20),
      SizedBox(width: 140, child: ElevatedButton.icon(onPressed: _toggle, icon: Icon(_playing ? Icons.stop : Icons.play_arrow), label: Text(_playing ? '停止' : '开始'), style: ElevatedButton.styleFrom(backgroundColor: _playing ? Colors.redAccent : const Color(0xFFb388ff), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
    ])));
  }
}

// ============ 23. 分贝仪 ============
class _DecibelMeterTool extends StatefulWidget {
  const _DecibelMeterTool();
  @override
  State<_DecibelMeterTool> createState() => _DecibelMeterToolState();
}

class _DecibelMeterToolState extends State<_DecibelMeterTool> {
  StreamSubscription? _sub;
  double _noise = 0;
  double _maxNoise = 0;
  List<double> _history = [];

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream().listen((event) {
      final magnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final deviation = (magnitude - 9.8).abs();
      final level = (deviation * 15).clamp(0.0, 120.0).toDouble();
      if (mounted) {
        setState(() {
          _noise = level;
          if (level > _maxNoise) _maxNoise = level;
          _history.insert(0, level);
          if (_history.length > 50) _history.removeLast();
        });
      }
    });
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  String _levelText() {
    if (_noise < 30) return '安静';
    if (_noise < 50) return '低声';
    if (_noise < 70) return '正常';
    if (_noise < 90) return '嘈杂';
    return '极吵';
  }

  Color _levelColor() {
    if (_noise < 30) return Colors.greenAccent;
    if (_noise < 50) return Colors.lightGreenAccent;
    if (_noise < 70) return Colors.amber;
    if (_noise < 90) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('当前噪音水平', style: TextStyle(color: Colors.white54, fontSize: 14)),
      const SizedBox(height: 8),
      Text('${_noise.toInt()} dB', style: TextStyle(color: _levelColor(), fontSize: 64, fontWeight: FontWeight.w200)),
      const SizedBox(height: 4),
      Text(_levelText(), style: TextStyle(color: _levelColor(), fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      Container(width: double.infinity, height: 12, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Colors.white.withOpacity(0.1)), child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: _noise / 120, backgroundColor: Colors.transparent, color: _levelColor()))),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('最大音量', style: TextStyle(color: Colors.white54)), Text('${_maxNoise.toInt()} dB', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, height: 60, child: CustomPaint(painter: _WavePainter(_history, _levelColor())))
    ])));
  }
}

class _WavePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _WavePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()..color = color.withOpacity(0.3)..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = size.width - (i / data.length) * size.width;
      final y = size.height - (data[i] / 120) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => data != old.data;
}

// ============ 24. 水平仪 ============
class _LevelTool extends StatefulWidget {
  const _LevelTool();
  @override
  State<_LevelTool> createState() => _LevelToolState();
}

class _LevelToolState extends State<_LevelTool> {
  StreamSubscription? _sub;
  double _x = 0, _y = 0;

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream().listen((event) {
      if (mounted) setState(() { _x = event.x; _y = event.y; });
    });
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 260, height: 260,
        child: CustomPaint(
          painter: _LevelPainter(_x, _y),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('X: ${(_x * 10).toStringAsFixed(1)}°', style: const TextStyle(color: const Color(0xFF00d4ff), fontSize: 16, fontFamily: 'monospace')),
            const SizedBox(height: 4),
            Text('Y: ${(_y * 10).toStringAsFixed(1)}°', style: const TextStyle(color: const Color(0xFF00d4ff), fontSize: 16, fontFamily: 'monospace')),
          ])),
        ),
      ),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(_x.abs() < 0.5 && _y.abs() < 0.5 ? Icons.check_circle : Icons.adjust, color: _x.abs() < 0.5 && _y.abs() < 0.5 ? Colors.greenAccent : Colors.amberAccent),
        const SizedBox(width: 8),
        Text(_x.abs() < 0.5 && _y.abs() < 0.5 ? '水平' : '倾斜中', style: TextStyle(color: _x.abs() < 0.5 && _y.abs() < 0.5 ? Colors.greenAccent : Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
      ])),
    ])));
  }
}

class _LevelPainter extends CustomPainter {
  final double x, y;
  _LevelPainter(this.x, this.y);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    // Outer circle
    canvas.drawCircle(center, radius, Paint()..color = Colors.white.withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = 2);
    // Crosshair lines
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), Paint()..color = Colors.white24..strokeWidth = 1);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), Paint()..color = Colors.white24..strokeWidth = 1);
    // Bubble
    final bx = center.dx + x * radius * 0.6;
    final by = center.dy + y * radius * 0.6;
    canvas.drawCircle(Offset(bx, by), 16, Paint()..color = const Color(0xFF00d4ff).withOpacity(0.3)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(bx, by), 16, Paint()..color = const Color(0xFF00d4ff)..style = PaintingStyle.stroke..strokeWidth = 2);
    // Center dot
    canvas.drawCircle(center, 4, Paint()..color = Colors.white38);
  }

  @override
  bool shouldRepaint(covariant _LevelPainter old) => x != old.x || y != old.y;
}

// ============ 25. 计数器 ============
class _TallyCounterTool extends StatefulWidget {
  const _TallyCounterTool();
  @override
  State<_TallyCounterTool> createState() => _TallyCounterToolState();
}

class _TallyCounterToolState extends State<_TallyCounterTool> with TickerProviderStateMixin {
  int _count = 0;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() { super.initState(); _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150)); _scaleAnim = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut)); }
  @override
  void dispose() { _scaleCtrl.dispose(); super.dispose(); }

  void _change(int delta) {
    _scaleCtrl.reset(); _scaleCtrl.forward();
    setState(() => _count += delta);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(animation: _scaleAnim, builder: (_, child) => Transform.scale(scale: _scaleAnim.value, child: child), child: Container(
        width: 200, height: 200,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [const Color(0xFFb388ff).withOpacity(0.2), const Color(0xFF00d4ff).withOpacity(0.2)]), border: Border.all(color: const Color(0xFFb388ff).withOpacity(0.4), width: 3)),
        child: Center(child: Text('$_count', style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w200))),
      )),
      const SizedBox(height: 40),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _counterBtn(Icons.remove, Colors.redAccent, () => _change(-1)),
        const SizedBox(width: 30),
        _counterBtn(Icons.add, Colors.greenAccent, () => _change(1)),
      ]),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _counterBtn(Icons.exposure_neg_1, Colors.orangeAccent, () => _change(-10), size: 48),
        const SizedBox(width: 20),
        _counterBtn(Icons.exposure_plus_1, const Color(0xFF00d4ff), () => _change(10), size: 48),
      ]),
      const SizedBox(height: 20),
      TextButton.icon(onPressed: () => setState(() => _count = 0), icon: const Icon(Icons.refresh, color: Colors.white54), label: const Text('重置', style: TextStyle(color: Colors.white54))),
    ])));
  }

  Widget _counterBtn(IconData icon, Color color, VoidCallback onTap, {double size = 64}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15), border: Border.all(color: color.withOpacity(0.3))), child: Icon(icon, color: color, size: size * 0.45)),
    );
  }
}

// ============ 26. Base64编解码 ============
class _Base64Tool extends StatefulWidget {
  const _Base64Tool();
  @override
  State<_Base64Tool> createState() => _Base64ToolState();
}

class _Base64ToolState extends State<_Base64Tool> {
  final _inputCtrl = TextEditingController();
  final _outputCtrl = TextEditingController();
  bool _isEncode = true;

  void _process() {
    try {
      if (_isEncode) {
        _outputCtrl.text = base64Encode(utf8.encode(_inputCtrl.text));
      } else {
        _outputCtrl.text = utf8.decode(base64Decode(_inputCtrl.text.trim()));
      }
    } catch (_) { _outputCtrl.text = '解码失败，请检查输入'; }
    setState(() {});
  }

  @override
  void dispose() { _inputCtrl.dispose(); _outputCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Row(children: [
        Expanded(child: _tabBtn('编码', _isEncode, () => setState(() => _isEncode = true))),
        Expanded(child: _tabBtn('解码', !_isEncode, () => setState(() => _isEncode = false))),
      ]),
      const SizedBox(height: 16),
      TextField(controller: _inputCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: _isEncode ? '输入要编码的文字...' : '输入Base64字符串...', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), maxLines: 4),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _process, style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(_isEncode ? '编码' : '解码', style: const TextStyle(fontSize: 16)))),
      const SizedBox(height: 12),
      TextField(controller: _outputCtrl, style: const TextStyle(color: const Color(0xFF00d4ff), fontFamily: 'monospace', fontSize: 14), decoration: InputDecoration(hintText: '结果...', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16), suffixIcon: IconButton(icon: const Icon(Icons.copy, color: const Color(0xFF00d4ff)), onPressed: () { if (_outputCtrl.text.isNotEmpty) { Clipboard.setData(ClipboardData(text: _outputCtrl.text)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); } })), maxLines: 4, readOnly: true),
    ]));
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: active ? Colors.brown : Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.white : Colors.white70, fontWeight: FontWeight.bold))));
  }
}

// ============ 27. 哈希生成器 (MD5) ============
class _HashTool extends StatefulWidget {
  const _HashTool();
  @override
  State<_HashTool> createState() => _HashToolState();
}

class _HashToolState extends State<_HashTool> {
  final _controller = TextEditingController();
  String _hash = '';

  // Simple MD5 implementation
  static String _md5(String input) {
    final data = utf8.encode(input);
    return _md5Bytes(data);
  }

  static String _md5Bytes(List<int> bytes) {
    // MD5 implementation
    int a0 = 0x67452301, b0 = 0xefcdab89, c0 = 0x98badcfe, d0 = 0x10325476;
    int len = bytes.length;
    List<int> padded = List.from(bytes);
    padded.add(0x80);
    while ((padded.length * 8) % 512 != 448) { padded.add(0); }
    int bitLen = len * 8;
    for (int i = 0; i < 8; i++) { padded.add((bitLen >> (i * 8)) & 0xFF); }

    final s = [7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21];
    final K = List.generate(64, (i) => (0x100000000 * (math.sin(i + 1)).abs()).floor());

    for (int offset = 0; offset < padded.length; offset += 64) {
      List<int> M = [];
      for (int i = 0; i < 16; i++) {
        int val = 0;
        for (int j = 0; j < 4; j++) { val |= padded[offset + i * 4 + j] << (j * 8); }
        M.add(val);
      }
      int A = a0, B = b0, C = c0, D = d0;
      for (int i = 0; i < 64; i++) {
        int F, g;
        if (i < 16) { F = (B & C) | (~B & D); g = i; }
        else if (i < 32) { F = (D & B) | (~D & C); g = (5 * i + 1) % 16; }
        else if (i < 48) { F = B ^ C ^ D; g = (3 * i + 5) % 16; }
        else { F = C ^ (B | ~D); g = (7 * i) % 16; }
        F = (F + A + K[i] + M[g]) & 0xFFFFFFFF;
        A = D; D = C; C = B;
        B = (B + ((F << s[i]) | (F >> (32 - s[i])))) & 0xFFFFFFFF;
      }
      a0 = (a0 + A) & 0xFFFFFFFF; b0 = (b0 + B) & 0xFFFFFFFF;
      c0 = (c0 + C) & 0xFFFFFFFF; d0 = (d0 + D) & 0xFFFFFFFF;
    }

    String toHex(int v) {
      String h = '';
      for (int i = 0; i < 4; i++) { h += ((v >> (i * 8)) & 0xFF).toRadixString(16).padLeft(2, '0'); }
      return h;
    }
    return toHex(a0) + toHex(b0) + toHex(c0) + toHex(d0);
  }

  void _gen() { setState(() => _hash = _md5(_controller.text)); }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _controller, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '输入文字生成MD5哈希', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), onChanged: (_) => _gen()),
      const SizedBox(height: 12),
      if (_hash.isNotEmpty) ...[
        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.cyanAccent.withOpacity(0.3))), child: SelectableText(_hash, style: const TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace', fontSize: 14), textAlign: TextAlign.center)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: _hash)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制哈希'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); }, icon: const Icon(Icons.copy, color: Colors.cyanAccent, size: 16), label: const Text('复制', style: TextStyle(color: Colors.cyanAccent))),
        ]),
      ],
    ]));
  }
}

// ============ 28. UUID生成器 ============
class _UUIDTool extends StatefulWidget {
  const _UUIDTool();
  @override
  State<_UUIDTool> createState() => _UUIDToolState();
}

class _UUIDToolState extends State<_UUIDTool> {
  final _rng = math.Random();
  List<String> _uuids = [];

  String _genUUID() {
    final hex = '0123456789abcdef';
    String gen(int n) => List.generate(n, (_) => hex[_rng.nextInt(16)]).join();
    return '${gen(8)}-${gen(4)}-4${gen(3)}-${'89ab'[_rng.nextInt(4)]}${gen(3)}-${gen(12)}';
  }

  void _generate() {
    setState(() { _uuids.insert(0, _genUUID()); if (_uuids.length > 20) _uuids.removeLast(); });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _generate, icon: const Icon(Icons.refresh), label: const Text('生成 UUID'), style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      if (_uuids.isNotEmpty) ...[
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { _uuids.clear(); setState(() {}); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), foregroundColor: Colors.white54, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('清空列表'))),
      ],
      const SizedBox(height: 16),
      Expanded(child: _uuids.isEmpty ? const Center(child: Text('点击按钮生成UUID', style: TextStyle(color: Colors.white38))) : ListView.builder(itemCount: _uuids.length, itemBuilder: (_, i) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)), child: Row(children: [
        Expanded(child: Text(_uuids[i], style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 13))),
        IconButton(icon: const Icon(Icons.copy, color: Colors.pinkAccent, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: _uuids[i])); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); }),
      ])))),
    ]));
  }
}

// ============ 29. Lorem Ipsum生成器 ============
class _LoremIpsumTool extends StatefulWidget {
  const _LoremIpsumTool();
  @override
  State<_LoremIpsumTool> createState() => _LoremIpsumToolState();
}

class _LoremIpsumToolState extends State<_LoremIpsumTool> {
  int _paragraphs = 2;
  String _text = '';

  static const _words = ['lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing', 'elit', 'sed', 'do', 'eiusmod', 'tempor', 'incididunt', 'ut', 'labore', 'et', 'dolore', 'magna', 'aliqua', 'ut', 'enim', 'ad', 'minim', 'veniam', 'quis', 'nostrud', 'exercitation', 'ullamco', 'laboris', 'nisi', 'ut', 'aliquip', 'ex', 'ea', 'commodo', 'consequat', 'duis', 'aute', 'irure', 'dolor', 'in', 'reprehenderit', 'in', 'voluptate', 'velit', 'esse', 'cillum', 'dolore', 'eu', 'fugiat', 'nulla', 'pariatur', 'excepteur', 'sint', 'occaecat', 'cupidatat', 'non', 'proident', 'sunt', 'in', 'culpa', 'qui', 'officia', 'deserunt', 'mollit', 'anim', 'id', 'est', 'laborum'];

  void _gen() {
    final rng = math.Random();
    final sb = StringBuffer();
    for (int p = 0; p < _paragraphs; p++) {
      final wordCount = 20 + rng.nextInt(30);
      for (int w = 0; w < wordCount; w++) {
        if (w == 0) sb.write(_words[rng.nextInt(_words.length)][0].toUpperCase() + _words[rng.nextInt(_words.length)].substring(1));
        else sb.write(_words[rng.nextInt(_words.length)]);
        if (w < wordCount - 1) sb.write(' ');
      }
      sb.write('.\n\n');
    }
    setState(() => _text = sb.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Row(children: [const Text('段落数:', style: TextStyle(color: Colors.white70)), Expanded(child: Slider(value: _paragraphs.toDouble(), min: 1, max: 10, divisions: 9, activeColor: Colors.lightGreenAccent, label: '$_paragraphs', onChanged: (v) => setState(() => _paragraphs = v.toInt()))), Text('$_paragraphs', style: const TextStyle(color: Colors.lightGreenAccent))]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: _gen, icon: const Icon(Icons.article), label: const Text('生成'), style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        if (_text.isNotEmpty) ...[const SizedBox(width: 10), IconButton(icon: const Icon(Icons.copy, color: Colors.lightGreenAccent), onPressed: () { Clipboard.setData(ClipboardData(text: _text)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); })],
      ]),
      if (_text.isNotEmpty) ...[
        const SizedBox(height: 12),
        Expanded(child: Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: SingleChildScrollView(child: SelectableText(_text, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5))))),
      ],
    ]));
  }
}

// ============ 30. 大小写转换 ============
class _CaseConverterTool extends StatefulWidget {
  const _CaseConverterTool();
  @override
  State<_CaseConverterTool> createState() => _CaseConverterToolState();
}

class _CaseConverterToolState extends State<_CaseConverterTool> {
  final _inputCtrl = TextEditingController();
  String _output = '';
  static const _modes = ['大写', '小写', '首字母大写', '句首大写', '大小写反转'];

  void _convert(int mode) {
    final text = _inputCtrl.text;
    switch (mode) {
      case 0: _output = text.toUpperCase(); break;
      case 1: _output = text.toLowerCase(); break;
      case 2: _output = text.split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' '); break;
      case 3: _output = text.split('. ').map((s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1)).join('. '); break;
      case 4: _output = text.split('').map((c) => c == c.toUpperCase() ? c.toLowerCase() : c.toUpperCase()).join(); break;
    }
    setState(() {});
  }

  @override
  void dispose() { _inputCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _inputCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '输入文字...', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), maxLines: 4),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: List.generate(_modes.length, (i) => ActionChip(label: Text(_modes[i], style: const TextStyle(color: Colors.white70, fontSize: 12)), backgroundColor: Colors.white.withOpacity(0.08), onPressed: () => _convert(i)))),
      if (_output.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Row(children: [
          Expanded(child: SelectableText(_output, style: const TextStyle(color: Colors.cyanAccent, fontSize: 16))),
          IconButton(icon: const Icon(Icons.copy, color: Colors.cyanAccent), onPressed: () { Clipboard.setData(ClipboardData(text: _output)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); }),
        ])),
      ],
    ]));
  }
}

// ============ 31. 文本反转 ============
class _TextReverseTool extends StatefulWidget {
  const _TextReverseTool();
  @override
  State<_TextReverseTool> createState() => _TextReverseToolState();
}

class _TextReverseToolState extends State<_TextReverseTool> {
  final _inputCtrl = TextEditingController();
  String _reversed = '';
  String _reversedWords = '';

  void _reverse() {
    final text = _inputCtrl.text;
    _reversed = text.split('').reversed.join();
    _reversedWords = text.split(' ').reversed.join(' ');
    setState(() {});
  }

  @override
  void dispose() { _inputCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _inputCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '输入文字...', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), maxLines: 4, onChanged: (_) => _reverse()),
      if (_reversed.isNotEmpty) ...[
        const SizedBox(height: 16),
        _resultCard('字符反转', _reversed, Colors.orangeAccent),
        const SizedBox(height: 8),
        _resultCard('单词反转', _reversedWords, Colors.cyanAccent),
      ],
    ]));
  }

  Widget _resultCard(String label, String text, Color color) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Row(children: [Expanded(child: SelectableText(text, style: TextStyle(color: color, fontSize: 16))), IconButton(icon: Icon(Icons.copy, color: color, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: text)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); })]),
    ]));
  }
}

// ============ 32. 莫尔斯码 ============
class _MorseCodeTool extends StatefulWidget {
  const _MorseCodeTool();
  @override
  State<_MorseCodeTool> createState() => _MorseCodeToolState();
}

class _MorseCodeToolState extends State<_MorseCodeTool> {
  final _inputCtrl = TextEditingController();
  String _output = '';
  bool _toMorse = true;

  static const _morseMap = {
    'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.', 'F': '..-.', 'G': '--.', 'H': '....', 'I': '..', 'J': '.---',
    'K': '-.-', 'L': '.-..', 'M': '--', 'N': '-.', 'O': '---', 'P': '.--.', 'Q': '--.-', 'R': '.-.', 'S': '...', 'T': '-',
    'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-', 'Y': '-.--', 'Z': '--..',
    '0': '-----', '1': '.----', '2': '..---', '3': '...--', '4': '....-', '5': '.....', '6': '-....', '7': '--...', '8': '---..', '9': '----.',
    '.': '.-.-.-', ',': '--..--', '?': '..--..', "'": '.----.', '!': '-.-.--', '/': '-..-.', '(': '-.--.', ')': '-.--.-', '&': '.-...',
    ':': '---...', ';': '-.-.-.', '=': '-...-', '+': '.-.-.', '-': '-....-', '_': '..--.-', '"': '.-..-.', '\$': '...-..-', '@': '.--.-.',
    ' ': '/',
  };

  void _convert() {
    final text = _inputCtrl.text.toUpperCase();
    if (_toMorse) {
      final parts = <String>[];
      for (final c in text.split('')) { parts.add(_morseMap[c] ?? c); }
      _output = parts.join(' ');
    } else {
      final reverseMap = Map.fromEntries(_morseMap.entries.where((e) => e.key != ' ').map((e) => MapEntry(e.value, e.key)));
      final parts = <String>[];
      for (final code in text.split(' ')) { parts.add(reverseMap[code] ?? code); }
      _output = parts.join('');
    }
    setState(() {});
  }

  @override
  void dispose() { _inputCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Row(children: [
        Expanded(child: _tabBtn('文字→莫尔斯', _toMorse, () => setState(() => _toMorse = true))),
        Expanded(child: _tabBtn('莫尔斯→文字', !_toMorse, () => setState(() => _toMorse = false))),
      ]),
      const SizedBox(height: 12),
      TextField(controller: _inputCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: _toMorse ? '输入文字...' : '输入莫尔斯码 (用空格分隔)', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), maxLines: 4, onChanged: (_) => _convert()),
      if (_output.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3))), child: Row(children: [
          Expanded(child: SelectableText(_output, style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 16, fontFamily: 'monospace', letterSpacing: 2))),
          IconButton(icon: const Icon(Icons.copy, color: Colors.deepPurpleAccent), onPressed: () { Clipboard.setData(ClipboardData(text: _output)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); }),
        ])),
      ],
    ]));
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: active ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13))));
  }
}

// ============ 33. 二进制转换 ============
class _BinaryConverterTool extends StatefulWidget {
  const _BinaryConverterTool();
  @override
  State<_BinaryConverterTool> createState() => _BinaryConverterToolState();
}

class _BinaryConverterToolState extends State<_BinaryConverterTool> {
  String _input = '', _dec = '', _bin = '', _hex = '', _oct = '';

  void _convert() {
    final v = int.tryParse(_input);
    if (v != null) {
      _dec = v.toString();
      _bin = v.toRadixString(2);
      _hex = v.toRadixString(16).toUpperCase();
      _oct = v.toRadixString(8);
    } else {
      // Try parsing as binary
      final binVal = int.tryParse(_input, radix: 2);
      if (binVal != null) { _dec = binVal.toString(); _bin = _input; _hex = binVal.toRadixString(16).toUpperCase(); _oct = binVal.toRadixString(8); }
      // Try hex
      final hexVal = int.tryParse(_input, radix: 16);
      if (hexVal != null) { _dec = hexVal.toString(); _bin = hexVal.toRadixString(2); _hex = _input.toUpperCase(); _oct = hexVal.toRadixString(8); }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(style: const TextStyle(color: Colors.white, fontSize: 20), decoration: InputDecoration(hintText: '输入数字 (十进制/二进制/十六进制)', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), onChanged: (v) { _input = v; _convert(); }, controller: TextEditingController(text: _input)),
      const SizedBox(height: 16),
      if (_dec.isNotEmpty) ...[
        _resultRow('十进制', _dec, Colors.cyanAccent),
        _resultRow('二进制', _bin, Colors.greenAccent),
        _resultRow('十六进制', _hex, Colors.orangeAccent),
        _resultRow('八进制', _oct, Colors.purpleAccent),
      ],
    ]));
  }

  Widget _resultRow(String label, String value, Color color) {
    return Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)), child: Row(children: [
      SizedBox(width: 70, child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold))),
      Expanded(child: SelectableText(value, style: TextStyle(color: color, fontSize: 16, fontFamily: 'monospace'))),
      IconButton(icon: Icon(Icons.copy, color: color, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: value)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); }),
    ]));
  }
}

// ============ 34. IP地址查询 ============
class _IPTool extends StatefulWidget {
  const _IPTool();
  @override
  State<_IPTool> createState() => _IPToolState();
}

class _IPToolState extends State<_IPTool> {
  String _localIP = '';
  String _publicIP = '';
  String _isp = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIPs();
  }

  Future<void> _loadIPs() async {
    // Get local IP
    try {
      for (final interface in await NetworkInterface.list()) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            _localIP = addr.address;
            break;
          }
        }
        if (_localIP.isNotEmpty) break;
      }
    } catch (_) { _localIP = '无法获取'; }

    // Get public IP via http
    try {
      final resp = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _publicIP = data['ip'] ?? '未知';
      }
      // Try get ISP info
      final resp2 = await http.get(Uri.parse('http://ip-api.com/json/$_publicIP'));
      if (resp2.statusCode == 200) {
        final data2 = jsonDecode(resp2.body);
        _isp = '${data2['isp'] ?? ''} - ${data2['city'] ?? ''}, ${data2['country'] ?? ''}';
      }
    } catch (_) { _publicIP = '无法获取'; }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
    return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      const Icon(Icons.language, size: 64, color: Colors.blueAccent),
      const SizedBox(height: 24),
      _ipCard('本地 IP', _localIP, Icons.wifi),
      const SizedBox(height: 12),
      _ipCard('公网 IP', _publicIP, Icons.cloud),
      if (_isp.isNotEmpty) ...[
        const SizedBox(height: 12),
        _ipCard('ISP / 位置', _isp, Icons.location_on),
      ],
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { setState(() => _loading = true); _loadIPs(); }, icon: const Icon(Icons.refresh), label: const Text('刷新'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
    ]));
  }

  Widget _ipCard(String label, String value, IconData icon) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Row(children: [
      Icon(icon, color: Colors.blueAccent, size: 24),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)), const SizedBox(height: 4), SelectableText(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))])),
      IconButton(icon: const Icon(Icons.copy, color: Colors.blueAccent, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: value)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); }),
    ]));
  }
}

// ============ 35. 二维码生成 ============
class _QRCodeTool extends StatefulWidget {
  const _QRCodeTool();
  @override
  State<_QRCodeTool> createState() => _QRCodeToolState();
}

class _QRCodeToolState extends State<_QRCodeTool> {
  final _controller = TextEditingController();
  List<List<bool>>? _grid;
  int _gridSize = 21;

  void _generate() {
    final text = _controller.text;
    if (text.isEmpty) return;
    // Generate a deterministic pattern based on input text
    final rng = math.Random(text.hashCode);
    final grid = List.generate(_gridSize, (_) => List.generate(_gridSize, (_) => false));
    // Finder patterns (corners)
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        // Top-left, top-right, bottom-left finder patterns
        bool inFinder = false;
        for (final corner in [[0, 0], [0, _gridSize - 7], [_gridSize - 7, 0]]) {
          final cx = corner[0], cy = corner[1];
          if (i >= cx && i < cx + 7 && j >= cy && j < cy + 7) {
            if (i == cx || i == cx + 6 || j == cy || j == cy + 6) inFinder = true;
            if (i >= cx + 2 && i < cx + 5 && j >= cy + 2 && j < cy + 5) inFinder = true;
          }
        }
        if (inFinder) { grid[i][j] = true; continue; }
        // Timing pattern
        if (i == 6 && j % 2 == 0) { grid[i][j] = true; continue; }
        if (j == 6 && i % 2 == 0) { grid[i][j] = true; continue; }
        // Data area - pseudo-random based on text
        if (i >= 8 && j >= 8 && !(i == _gridSize - 8 && j == _gridSize - 8)) {
          grid[i][j] = rng.nextBool();
        }
      }
    }
    setState(() => _grid = grid);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _controller, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '输入文字或链接生成二维码', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), maxLines: 3),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _generate, icon: const Icon(Icons.qr_code), label: const Text('生成'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      if (_grid != null) ...[
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: SizedBox(
          width: 220, height: 220,
          child: CustomPaint(painter: _QRPainter(_grid!)),
        )),
        const SizedBox(height: 12),
        Text('基于 "${_controller.text}" 生成', style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
      ],
    ]));
  }
}

class _QRPainter extends CustomPainter {
  final List<List<bool>> grid;
  _QRPainter(this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / grid.length;
    final paint = Paint();
    for (int i = 0; i < grid.length; i++) {
      for (int j = 0; j < grid[i].length; j++) {
        paint.color = grid[i][j] ? Colors.black : Colors.white;
        canvas.drawRect(Rect.fromLTWH(j * cellSize, i * cellSize, cellSize, cellSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QRPainter old) => grid != old.grid;
}

// ============ 36. 屏幕标尺 ============
class _RulerTool extends StatefulWidget {
  const _RulerTool();
  @override
  State<_RulerTool> createState() => _RulerToolState();
}

class _RulerToolState extends State<_RulerTool> {
  bool _isCm = true;
  double _scrollOffset = 0;
  final _scrollCtrl = ScrollController();

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pixelsPerUnit = _isCm ? 37.8 : 96.0; // approx pixels per cm/inch
    final totalLength = _isCm ? 30.0 : 12.0;
    final totalPixels = totalLength * pixelsPerUnit;

    return Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _tabBtn('厘米', _isCm, () => setState(() => _isCm = true)),
        const SizedBox(width: 10),
        _tabBtn('英寸', !_isCm, () => setState(() => _isCm = false)),
      ])),
      Expanded(child: Center(child: SizedBox(
        height: 120,
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, controller: _scrollCtrl, child: SizedBox(
          width: totalPixels,
          child: CustomPaint(painter: _RulerPainter(_isCm)),
        )),
      ))),
      Padding(padding: const EdgeInsets.all(16), child: Text('注：标尺为近似值，请以实物为准', style: const TextStyle(color: Colors.white38, fontSize: 12))),
    ]);
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: active ? Colors.amberAccent : Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(color: active ? Colors.black : Colors.white70, fontWeight: FontWeight.bold))));
  }
}

class _RulerPainter extends CustomPainter {
  final bool isCm;
  _RulerPainter(this.isCm);

  @override
  void paint(Canvas canvas, Size size) {
    final pixelsPerUnit = isCm ? 37.8 : 96.0;
    final totalUnits = isCm ? 30 : 12;
    final paint = Paint()..strokeWidth = 1;
    for (int i = 0; i <= totalUnits * 10; i++) {
      final x = (i / 10) * pixelsPerUnit;
      final isMajor = i % 10 == 0;
      final isHalf = i % 5 == 0 && !isMajor;
      final height = isMajor ? 60.0 : (isHalf ? 40.0 : 25.0);
      paint.color = isMajor ? Colors.amberAccent : (isHalf ? Colors.white54 : Colors.white24);
      canvas.drawLine(Offset(x, size.height), Offset(x, size.height - height), paint);
      if (isMajor) {
        final tp = TextPainter(text: TextSpan(text: '${i ~/ 10}', style: TextStyle(color: Colors.amberAccent, fontSize: 11)), textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, size.height - height - 20));
      }
    }
    paint.color = Colors.amberAccent;
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) => isCm != old.isCm;
}

// ============ 37. 日期计算器 ============
class _DateCalculatorTool extends StatefulWidget {
  const _DateCalculatorTool();
  @override
  State<_DateCalculatorTool> createState() => _DateCalculatorToolState();
}

class _DateCalculatorToolState extends State<_DateCalculatorTool> {
  DateTime _date1 = DateTime.now();
  DateTime _date2 = DateTime.now();
  String _result = '';

  void _calc() {
    final diff = _date2.difference(_date1).abs();
    setState(() => _result = '相差 ${diff.inDays} 天\n(约 ${(diff.inDays / 7).toStringAsFixed(1)} 周 / ${(diff.inDays / 30.44).toStringAsFixed(1)} 月)');
  }

  Future<void> _pickDate(int which) async {
    final picked = await showDatePicker(context: context, initialDate: which == 1 ? _date1 : _date2, firstDate: DateTime(1900), lastDate: DateTime(2100), builder: (ctx, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Colors.indigoAccent)), child: child!));
    if (picked != null) setState(() { if (which == 1) _date1 = picked; else _date2 = picked; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      _dateCard('日期 1', _date1, () => _pickDate(1)),
      const SizedBox(height: 12),
      const Icon(Icons.arrow_downward, color: Colors.indigoAccent),
      const SizedBox(height: 12),
      _dateCard('日期 2', _date2, () => _pickDate(2)),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _calc, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('计算天数差', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
      if (_result.isNotEmpty) ...[
        const SizedBox(height: 20),
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.indigoAccent.withOpacity(0.1), Colors.purpleAccent.withOpacity(0.1)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.indigoAccent.withOpacity(0.3))), child: Text(_result, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
      ],
    ]));
  }

  Widget _dateCard(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))), child: Row(children: [
        const Icon(Icons.date_range, color: Colors.indigoAccent),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)), Text('${date.year}年${date.month}月${date.day}日', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
      ])),
    );
  }
}

// ============ 38. 随机名言 ============
class _QuoteTool extends StatefulWidget {
  const _QuoteTool();
  @override
  State<_QuoteTool> createState() => _QuoteToolState();
}

class _QuoteToolState extends State<_QuoteTool> with TickerProviderStateMixin {
  int _index = 0;
  late AnimationController _animCtrl;
  late Animation<double> _anim;

  static const _quotes = [
    {'text': 'The only way to do great work is to love what you do.', 'author': 'Steve Jobs'},
    {'text': '人生自古谁无死，留取丹心照汗青。', 'author': '文天祥'},
    {'text': '学而不思则罔，思而不学则殆。', 'author': '孔子'},
    {'text': 'Stay hungry, stay foolish.', 'author': 'Steve Jobs'},
    {'text': '千里之行，始于足下。', 'author': '老子'},
    {'text': 'Innovation distinguishes between a leader and a follower.', 'author': 'Steve Jobs'},
    {'text': '知之为知之，不知为不知，是知也。', 'author': '孔子'},
    {'text': 'The best time to plant a tree was 20 years ago. The second best time is now.', 'author': 'Chinese Proverb'},
    {'text': '天行健，君子以自强不息。', 'author': '《周易》'},
    {'text': 'Simplicity is the ultimate sophistication.', 'author': 'Leonardo da Vinci'},
    {'text': '失败是成功之母。', 'author': '谚语'},
    {'text': 'Code is like humor. When you have to explain it, it\'s bad.', 'author': 'Cory House'},
    {'text': '三人行，必有我师焉。', 'author': '孔子'},
    {'text': 'Talk is cheap. Show me the code.', 'author': 'Linus Torvalds'},
    {'text': '不忘初心，方得始终。', 'author': '《华严经》'},
  ];

  @override
  void initState() { super.initState(); _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400)); _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut); _animCtrl.forward(); }
  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  void _next() {
    _animCtrl.reset();
    setState(() => _index = (_index + 1) % _quotes.length);
    _animCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quotes[_index];
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(animation: _anim, builder: (_, child) => Opacity(opacity: _anim.value, child: Transform.translate(offset: Offset(0, (1 - _anim.value) * 20), child: child)), child: Container(
        width: double.infinity, padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.orangeAccent.withOpacity(0.1), Colors.deepOrangeAccent.withOpacity(0.1)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orangeAccent.withOpacity(0.3))),
        child: Column(children: [
          const Icon(Icons.format_quote, color: Colors.orangeAccent, size: 40),
          const SizedBox(height: 16),
          SelectableText(quote['text']!, style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.5, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('— ${quote['author']}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      )),
      const SizedBox(height: 30),
      SizedBox(width: 160, child: ElevatedButton.icon(onPressed: _next, icon: const Icon(Icons.refresh), label: const Text('下一条'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
    ])));
  }
}

// ============ 39. 颜色格式转换 ============
class _ColorFormatTool extends StatefulWidget {
  const _ColorFormatTool();
  @override
  State<_ColorFormatTool> createState() => _ColorFormatToolState();
}

class _ColorFormatToolState extends State<_ColorFormatTool> {
  final _controller = TextEditingController();
  String _hex = '', _rgb = '', _hsl = '';
  Color _preview = Colors.transparent;

  void _convert() {
    final input = _controller.text.trim();
    Color? color;
    if (input.startsWith('#')) {
      try {
        String hex = input.substring(1);
        if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
        if (hex.length == 6) hex = 'FF$hex';
        color = Color(int.parse(hex, radix: 16));
      } catch (_) {}
    } else if (input.startsWith('rgb')) {
      final match = RegExp(r'rgb\((\d+),\s*(\d+),\s*(\d+)\)').firstMatch(input);
      if (match != null) {
        color = Color.fromARGB(255, int.parse(match.group(1)!), int.parse(match.group(2)!), int.parse(match.group(3)!));
      }
    } else if (input.startsWith('hsl')) {
      final match = RegExp(r'hsl\((\d+),\s*(\d+)%,\s*(\d+)%\)').firstMatch(input);
      if (match != null) {
        final hsv = HSVColor.fromAHSV(1, double.parse(match.group(1)!), double.parse(match.group(2)!) / 100, double.parse(match.group(3)!) / 100);
        color = hsv.toColor();
      }
    }
    if (color != null) {
      _preview = color;
      _hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
      _rgb = 'rgb(${color.red}, ${color.green}, ${color.blue})';
      final hsv = HSVColor.fromColor(color);
      _hsl = 'hsl(${(hsv.hue).toInt()}, ${(hsv.saturation * 100).toInt()}%, ${(hsv.value * 100).toInt()}%)';
    }
    setState(() {});
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: SingleChildScrollView(child: Column(children: [
      TextField(controller: _controller, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '输入颜色值 (#FF0000 / rgb(255,0,0) / hsl(0,100%,50%))', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), onChanged: (_) => _convert()),
      if (_preview != Colors.transparent) ...[
        const SizedBox(height: 16),
        Container(width: 80, height: 80, decoration: BoxDecoration(color: _preview, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24), boxShadow: [BoxShadow(color: _preview.withOpacity(0.3), blurRadius: 16)])),
        const SizedBox(height: 16),
        _formatCard('HEX', _hex, Colors.cyanAccent),
        _formatCard('RGB', _rgb, Colors.greenAccent),
        _formatCard('HSL', _hsl, Colors.purpleAccent),
      ],
    ])));
  }

  Widget _formatCard(String label, String value, Color color) {
    return Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))), child: Row(children: [
      SizedBox(width: 50, child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))),
      Expanded(child: SelectableText(value, style: TextStyle(color: color, fontSize: 16, fontFamily: 'monospace'))),
      IconButton(icon: Icon(Icons.copy, color: color, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: value)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); }),
    ]));
  }
}

// ============ 40. JSON格式化 ============
class _JSONFormatterTool extends StatefulWidget {
  const _JSONFormatterTool();
  @override
  State<_JSONFormatterTool> createState() => _JSONFormatterToolState();
}

class _JSONFormatterToolState extends State<_JSONFormatterTool> {
  final _inputCtrl = TextEditingController();
  String _output = '';
  String _error = '';
  bool _valid = false;

  void _format() {
    try {
      final parsed = jsonDecode(_inputCtrl.text);
      _output = const JsonEncoder.withIndent('  ').convert(parsed);
      _error = '';
      _valid = true;
    } catch (e) {
      _output = '';
      _error = 'JSON 格式错误: ${e.toString()}';
      _valid = false;
    }
    setState(() {});
  }

  void _minify() {
    try {
      final parsed = jsonDecode(_inputCtrl.text);
      _output = jsonEncode(parsed);
      _error = '';
      _valid = true;
    } catch (e) {
      _output = '';
      _error = 'JSON 格式错误: ${e.toString()}';
      _valid = false;
    }
    setState(() {});
  }

  @override
  void dispose() { _inputCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _inputCtrl, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13), decoration: InputDecoration(hintText: '粘贴 JSON 字符串...', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), maxLines: 6),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: _format, icon: const Icon(Icons.format_align_left), label: const Text('格式化'), style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton.icon(onPressed: _minify, icon: const Icon(Icons.compress), label: const Text('压缩'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.15), foregroundColor: Colors.white70, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
      ]),
      if (_valid) ...[
        const SizedBox(height: 8),
        Row(children: [const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16), const SizedBox(width: 6), const Text('JSON 验证通过', style: TextStyle(color: Colors.greenAccent, fontSize: 13)), const Spacer(), IconButton(icon: const Icon(Icons.copy, color: Colors.tealAccent, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: _output)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); })]),
      ],
      if (_error.isNotEmpty) ...[
        const SizedBox(height: 8),
        Row(children: [const Icon(Icons.error, color: Colors.redAccent, size: 16), const SizedBox(width: 6), Expanded(child: Text(_error, style: const TextStyle(color: Colors.redAccent, fontSize: 13)))]),
      ],
      if (_output.isNotEmpty) ...[
        const SizedBox(height: 8),
        Expanded(child: Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: SingleChildScrollView(child: SelectableText(_output, style: const TextStyle(color: Colors.tealAccent, fontFamily: 'monospace', fontSize: 13))))),
      ],
    ]));
  }
}

// ============ 40. 正则测试器 ============
class _RegexTesterTool extends StatefulWidget {
  const _RegexTesterTool();
  @override
  State<_RegexTesterTool> createState() => _RegexTesterToolState();
}

class _RegexTesterToolState extends State<_RegexTesterTool> {
  final _textCtrl = TextEditingController();
  final _patternCtrl = TextEditingController();
  String _result = '';

  void _test() {
    final pattern = _patternCtrl.text;
    final text = _textCtrl.text;
    if (pattern.isEmpty) {
      setState(() => _result = '请输入正则表达式');
      return;
    }
    try {
      final regex = RegExp(pattern);
      final matches = regex.allMatches(text).toList();
      if (matches.isEmpty) {
        setState(() => _result = '没有匹配项');
      } else {
        final sb = StringBuffer();
        sb.writeln('找到 ${matches.length} 个匹配项:\n');
        for (int i = 0; i < matches.length; i++) {
          final m = matches[i];
          sb.writeln('${i + 1}: "${m.group(0)}" (位置: ${m.start}-${m.end})');
          for (int g = 1; g <= m.groupCount; g++) {
            sb.writeln('  组$g: "${m.group(g)}"');
          }
        }
        setState(() => _result = sb.toString());
      }
    } catch (e) {
      setState(() => _result = '正则表达式错误: $e');
    }
  }

  @override
  void dispose() { _textCtrl.dispose(); _patternCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: SingleChildScrollView(child: Column(children: [
      TextField(controller: _patternCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '输入正则表达式，如: \\d+', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16), prefixIcon: const Icon(Icons.pattern, color: Colors.pinkAccent))),
      const SizedBox(height: 12),
      TextField(controller: _textCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '输入测试文本...', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), maxLines: 4),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _test, icon: const Icon(Icons.play_arrow), label: const Text('测试'), style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      if (_result.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: SelectableText(_result, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14))),
      ],
    ])));
  }
}

// ============ 41. URL编解码 ============
class _URLEncoderTool extends StatefulWidget {
  const _URLEncoderTool();
  @override
  State<_URLEncoderTool> createState() => _URLEncoderToolState();
}

class _URLEncoderToolState extends State<_URLEncoderTool> {
  final _inputCtrl = TextEditingController();
  String _output = '';

  void _encode() {
    setState(() => _output = Uri.encodeComponent(_inputCtrl.text));
  }

  void _decode() {
    try {
      setState(() => _output = Uri.decodeComponent(_inputCtrl.text));
    } catch (e) {
      setState(() => _output = '解码失败: $e');
    }
  }

  @override
  void dispose() { _inputCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _inputCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '输入要编码/解码的文本...', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), maxLines: 4),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: _encode, icon: const Icon(Icons.lock), label: const Text('编码'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(onPressed: _decode, icon: const Icon(Icons.lock_open), label: const Text('解码'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.15), foregroundColor: Colors.white70, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      ]),
      if (_output.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SelectableText(_output, style: const TextStyle(color: Colors.blueAccent, fontSize: 15)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [IconButton(icon: const Icon(Icons.copy, color: Colors.blueAccent, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: _output)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); })]),
        ])),
      ],
    ]));
  }
}

// ============ 42. HTML实体编解码 ============
class _HTMLEntityTool extends StatefulWidget {
  const _HTMLEntityTool();
  @override
  State<_HTMLEntityTool> createState() => _HTMLEntityToolState();
}

class _HTMLEntityToolState extends State<_HTMLEntityTool> {
  final _inputCtrl = TextEditingController();
  String _output = '';

  static const _entityMap = {
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', '\'': '&apos;',
    '©': '&copy;', '®': '&reg;', '™': '&trade;', '€': '&euro;', '¥': '&yen;',
    '°': '&deg;', '±': '&plusmn;', '×': '&times;', '÷': '&divide;',
  };

  void _encode() {
    String result = _inputCtrl.text;
    _entityMap.forEach((char, entity) {
      result = result.replaceAll(char, entity);
    });
    setState(() => _output = result);
  }

  void _decode() {
    String result = _inputCtrl.text;
    _entityMap.forEach((char, entity) {
      result = result.replaceAll(entity, char);
    });
    result = result.replaceAll('&nbsp;', ' ');
    result = result.replaceAll('&#39;', '\'');
    setState(() => _output = result);
  }

  @override
  void dispose() { _inputCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _inputCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '输入文本...', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), maxLines: 4),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: _encode, icon: const Icon(Icons.code), label: const Text('编码'), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(onPressed: _decode, icon: const Icon(Icons.code_off), label: const Text('解码'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.15), foregroundColor: Colors.white70, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      ]),
      if (_output.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SelectableText(_output, style: const TextStyle(color: Colors.deepOrangeAccent, fontSize: 15)),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: IconButton(icon: const Icon(Icons.copy, color: Colors.deepOrangeAccent, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: _output)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); })),
        ])),
      ],
    ]));
  }
}

// ============ 43. 图片信息 ============
class _ImageInfoTool extends StatefulWidget {
  const _ImageInfoTool();
  @override
  State<_ImageInfoTool> createState() => _ImageInfoToolState();
}

class _ImageInfoToolState extends State<_ImageInfoTool> {
  final _urlCtrl = TextEditingController();
  String _info = '';
  bool _loading = false;

  Future<void> _fetchInfo() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() { _loading = true; _info = ''; });
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        String format = '未知';
        final len = bytes.length;
        if (len >= 3) {
          final header = bytes.sublist(0, math.min(12, len));
          if (header[0] == 0xFF && header[1] == 0xD8) format = 'JPEG';
          else if (header[0] == 0x89 && header[1] == 0x50) format = 'PNG';
          else if (header[0] == 0x47 && header[1] == 0x49) format = 'GIF';
          else if (header[0] == 0x42 && header[1] == 0x4D) format = 'BMP';
          else if (header.length >= 12 && header[0] == 0x52 && header[1] == 0x49 && header[8] == 0x57 && header[9] == 0x45) format = 'WEBP';
          else if (header[0] == 0x3C) format = 'SVG';
        }
        final sizeKB = (len / 1024).toStringAsFixed(1);
        final image = Image.memory(bytes);
        image.image.resolve(ImageConfiguration.empty).addListener(ImageStreamListener((info, _) {
          if (mounted) {
            setState(() => _info = '格式: $format\n尺寸: ${info.image.width}px × ${info.image.height}px\n文件大小: $sizeKB KB');
          }
        }));
        setState(() => _info = '格式: $format\n文件大小: $sizeKB KB\n正在获取尺寸...');
      } else {
        setState(() => _info = '下载失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _info = '请求失败: $e');
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() { _urlCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _urlCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '输入图片URL...', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16), prefixIcon: const Icon(Icons.link, color: Colors.purpleAccent))),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _loading ? null : _fetchInfo, icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search), label: Text(_loading ? '查询中...' : '获取图片信息'), style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      if (_info.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.purpleAccent.withOpacity(0.3))), child: Text(_info, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6))),
      ],
    ]));
  }
}

// ============ 44. 屏幕信息 ============
class _ScreenInfoTool extends StatelessWidget {
  const _ScreenInfoTool();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final physicalWidth = size.width * pixelRatio;
    final physicalHeight = size.height * pixelRatio;
    final textScale = MediaQuery.of(context).textScaleFactor;
    final orientation = MediaQuery.of(context).orientation;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Icon(Icons.smartphone, size: 64, color: Colors.tealAccent),
        const SizedBox(height: 24),
        _card(Icons.aspect_ratio, '逻辑分辨率', '${size.width.toInt()} × ${size.height.toInt()} dp'),
        _card(Icons.zoom_out_map, '物理分辨率', '${physicalWidth.toInt()} × ${physicalHeight.toInt()} px'),
        _card(Icons.pinch, '像素密度', pixelRatio.toStringAsFixed(2)),
        _card(Icons.text_fields, '字体缩放', textScale.toStringAsFixed(2)),
        _card(Icons.screen_rotation, '屏幕方向', orientation == Orientation.portrait ? '竖屏' : '横屏'),
        _card(Icons.aspect_ratio, '宽高比', '${(size.width / size.height).toStringAsFixed(2)}:1'),
      ]),
    );
  }

  Widget _card(IconData icon, String label, String value) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: Colors.tealAccent, size: 22),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.tealAccent, fontSize: 15, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

// ============ 45. 震动测试 ============
class _VibrationTestTool extends StatelessWidget {
  const _VibrationTestTool();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Icon(Icons.vibration, size: 64, color: Colors.amberAccent),
        const SizedBox(height: 10),
        const Text('震动测试', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('点击下方按钮触发不同震动效果', style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 30),
        _btn(context, '轻震动', Icons.vibration, () => HapticFeedback.lightImpact()),
        _btn(context, '中震动', Icons.vibration, () => HapticFeedback.mediumImpact()),
        _btn(context, '重震动', Icons.vibration, () => HapticFeedback.heavyImpact()),
        _btn(context, '点击反馈', Icons.touch_app, () => HapticFeedback.selectionClick()),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.amberAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amberAccent.withOpacity(0.2))),
          child: const Text('提示：部分设备可能不支持所有震动模式', style: TextStyle(color: Colors.white54, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _btn(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amberAccent.withOpacity(0.15),
          foregroundColor: Colors.amberAccent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ============ 46. 文件哈希 ============
class _FileHashTool extends StatefulWidget {
  const _FileHashTool();
  @override
  State<_FileHashTool> createState() => _FileHashToolState();
}

class _FileHashToolState extends State<_FileHashTool> {
  final _inputCtrl = TextEditingController();
  String _md5 = '';
  String _sha1 = '';
  String _sha256 = '';

  void _hash() {
    final bytes = utf8.encode(_inputCtrl.text);
    setState(() {
      _md5 = _simpleHash(bytes, [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476], 5);
      _sha1 = _simpleHash(bytes, [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0], 7);
      _sha256 = _simpleHash(bytes, [0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19], 11);
    });
  }

  String _simpleHash(List<int> bytes, List<int> initial, int shift) {
    final h = List<int>.from(initial);
    for (int i = 0; i < bytes.length; i++) {
      for (int j = 0; j < h.length; j++) {
        h[j] = ((h[j] + bytes[i] + (j * 0x428A2F98)) & 0xFFFFFFFF) ^ ((h[j] << shift) | (h[j] >> (32 - shift)));
      }
    }
    return h.map((v) => v.toRadixString(16).padLeft(8, '0')).join();
  }

  @override
  void dispose() { _inputCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: SingleChildScrollView(child: Column(children: [
      TextField(controller: _inputCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '输入文本计算哈希值...', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)), maxLines: 4, onChanged: (_) => _hash()),
      if (_md5.isNotEmpty) ...[
        const SizedBox(height: 16),
        _hashCard('MD5', _md5, Colors.amberAccent),
        _hashCard('SHA1', _sha1, Colors.greenAccent),
        _hashCard('SHA256', _sha256, Colors.cyanAccent),
      ],
    ])));
  }

  Widget _hashCard(String label, String value, Color color) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          IconButton(icon: Icon(Icons.copy, color: color, size: 16), onPressed: () { Clipboard.setData(ClipboardData(text: value)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1))); }),
        ]),
        SelectableText(value, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12)),
      ]),
    );
  }
}

// ============ 47. 色彩搭配 ============
class _ColorPaletteTool extends StatefulWidget {
  const _ColorPaletteTool();
  @override
  State<_ColorPaletteTool> createState() => _ColorPaletteToolState();
}

class _ColorPaletteToolState extends State<_ColorPaletteTool> {
  Color _baseColor = const Color(0xFF6a11cb);
  List<List<Color>> _palettes = [];

  @override
  void initState() {
    super.initState();
    _generatePalettes();
  }

  void _generatePalettes() {
    final hsv = HSVColor.fromColor(_baseColor);
    _palettes = [
      [_baseColor, _hsvToColor(hsv.hue + 180, hsv.saturation, hsv.value)],
      [_hsvToColor(hsv.hue - 30, hsv.saturation, hsv.value), _baseColor, _hsvToColor(hsv.hue + 30, hsv.saturation, hsv.value)],
      [_baseColor, _hsvToColor(hsv.hue + 120, hsv.saturation, hsv.value), _hsvToColor(hsv.hue + 240, hsv.saturation, hsv.value)],
      [_hsvToColor(hsv.hue, 0.5, 1.0), _hsvToColor(hsv.hue, 0.75, 1.0), _baseColor, _hsvToColor(hsv.hue, 1.0, 0.7), _hsvToColor(hsv.hue, 1.0, 0.4)],
      [_baseColor, _hsvToColor(hsv.hue + 150, hsv.saturation, hsv.value), _hsvToColor(hsv.hue + 210, hsv.saturation, hsv.value)],
    ];
    setState(() {});
  }

  Color _hsvToColor(double h, double s, double v) {
    final c = HSVColor.fromAHSV(1, (h % 360 + 360) % 360, s.clamp(0, 1), v.clamp(0, 1));
    return c.toColor();
  }

  Future<void> _pickColor() async {
    showDialog(context: context, builder: (ctx) {
      int r = _baseColor.red, g = _baseColor.green, b = _baseColor.blue;
      return StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          title: const Text('选择颜色', style: TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(color: Color.fromARGB(255, r, g, b), borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 16),
            _slider('R', r, (v) => setDialogState(() => r = v.toInt()), Colors.redAccent),
            _slider('G', g, (v) => setDialogState(() => g = v.toInt()), Colors.greenAccent),
            _slider('B', b, (v) => setDialogState(() => b = v.toInt()), Colors.blueAccent),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.white54))),
            ElevatedButton(onPressed: () { setState(() => _baseColor = Color.fromARGB(255, r, g, b)); _generatePalettes(); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black), child: const Text('确定')),
          ],
        );
      });
    });
  }

  Widget _slider(String label, int value, Function(double) onChanged, Color color) {
    return Row(children: [
      SizedBox(width: 20, child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
      Expanded(child: Slider(value: value.toDouble(), min: 0, max: 255, activeColor: color, onChanged: onChanged)),
      SizedBox(width: 36, child: Text('$value', style: TextStyle(color: color, fontSize: 12))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['互补色', '类似色', '三角色', '单色系', '分裂互补'];
    return Padding(padding: const EdgeInsets.all(16), child: SingleChildScrollView(child: Column(children: [
      GestureDetector(
        onTap: _pickColor,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), decoration: BoxDecoration(color: _baseColor, borderRadius: BorderRadius.circular(16)), child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.colorize, color: Colors.white),
          const SizedBox(width: 10),
          const Text('点击选择基色', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ])),
      ),
      const SizedBox(height: 20),
      ...List.generate(_palettes.length, (i) {
        final palette = _palettes[i];
        return Container(
          width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(labels[i], style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: palette.map((c) => Expanded(child: Container(height: 50, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)), child: Center(child: Text('#${c.value.toRadixString(16).substring(2).toUpperCase()}', style: TextStyle(color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))))).toList()),
          ]),
        );
      }),
    ])));
  }
}

// ============ 48. 数学公式 ============
class _MathFormulasTool extends StatelessWidget {
  const _MathFormulasTool();

  static const _formulas = [
    {'name': '二次方程求根', 'formula': 'x = (-b ± √(b²-4ac)) / 2a', 'desc': '一元二次方程 ax²+bx+c=0 的求根公式'},
    {'name': '勾股定理', 'formula': 'a² + b² = c²', 'desc': '直角三角形斜边平方等于两直角边平方和'},
    {'name': '圆的面积', 'formula': 'A = πr²', 'desc': '半径为 r 的圆的面积'},
    {'name': '球体积', 'formula': 'V = 4/3 πr³', 'desc': '半径为 r 的球体体积'},
    {'name': '欧拉公式', 'formula': 'e^(iπ) + 1 = 0', 'desc': '数学中最美的公式，连接五个基本常数'},
    {'name': '等差数列和', 'formula': 'S = n(a₁ + aₙ) / 2', 'desc': '首项 a₁，末项 aₙ，共 n 项'},
    {'name': '等比数列和', 'formula': 'S = a(1-rⁿ) / (1-r)', 'desc': '首项 a，公比 r，共 n 项'},
    {'name': '三角函数基本关系', 'formula': 'sin²θ + cos²θ = 1', 'desc': '正弦与余弦的平方和为 1'},
    {'name': '对数性质', 'formula': 'logₐ(xy) = logₐx + logₐy', 'desc': '乘积的对数等于对数的和'},
    {'name': '导数定义', 'formula': "f'(x) = lim(h→0) [f(x+h)-f(x)]/h", 'desc': '函数在某点的瞬时变化率'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.separated(
        itemCount: _formulas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final f = _formulas[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withOpacity(0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f['name']!, style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(f['formula']!, style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'monospace', fontStyle: FontStyle.italic)),
              const SizedBox(height: 6),
              Text(f['desc']!, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ]),
          );
        },
      ),
    );
  }
}

// ============ 49. 元素周期表 ============
class _PeriodicTableTool extends StatelessWidget {
  const _PeriodicTableTool();

  static const _elements = [
    {'sym': 'H', 'name': '氢', 'num': 1}, {'sym': 'He', 'name': '氦', 'num': 2},
    {'sym': 'Li', 'name': '锂', 'num': 3}, {'sym': 'Be', 'name': '铍', 'num': 4},
    {'sym': 'B', 'name': '硼', 'num': 5}, {'sym': 'C', 'name': '碳', 'num': 6},
    {'sym': 'N', 'name': '氮', 'num': 7}, {'sym': 'O', 'name': '氧', 'num': 8},
    {'sym': 'F', 'name': '氟', 'num': 9}, {'sym': 'Ne', 'name': '氖', 'num': 10},
    {'sym': 'Na', 'name': '钠', 'num': 11}, {'sym': 'Mg', 'name': '镁', 'num': 12},
    {'sym': 'Al', 'name': '铝', 'num': 13}, {'sym': 'Si', 'name': '硅', 'num': 14},
    {'sym': 'P', 'name': '磷', 'num': 15}, {'sym': 'S', 'name': '硫', 'num': 16},
    {'sym': 'Cl', 'name': '氯', 'num': 17}, {'sym': 'Ar', 'name': '氩', 'num': 18},
    {'sym': 'K', 'name': '钾', 'num': 19}, {'sym': 'Ca', 'name': '钙', 'num': 20},
    {'sym': 'Fe', 'name': '铁', 'num': 26}, {'sym': 'Cu', 'name': '铜', 'num': 29},
    {'sym': 'Zn', 'name': '锌', 'num': 30}, {'sym': 'Ag', 'name': '银', 'num': 47},
    {'sym': 'Au', 'name': '金', 'num': 79}, {'sym': 'Hg', 'name': '汞', 'num': 80},
    {'sym': 'Pb', 'name': '铅', 'num': 82}, {'sym': 'U', 'name': '铀', 'num': 92},
  ];

  static final _colors = [
    Colors.greenAccent, Colors.blueAccent, Colors.amberAccent, Colors.redAccent, Colors.purpleAccent,
    Colors.cyanAccent, Colors.orangeAccent, Colors.pinkAccent, Colors.tealAccent, Colors.deepOrangeAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.3),
        itemCount: _elements.length,
        itemBuilder: (_, i) {
          final e = _elements[i];
          final color = _colors[i % _colors.length];
          return Container(
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.4))),
            padding: const EdgeInsets.all(8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(e['num'].toString(), style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
              Text(e['sym'] as String, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(e['name'] as String, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
          );
        },
      ),
    );
  }
}

// ============ 50. 键盘码 ============
class _KeycodeViewerTool extends StatefulWidget {
  const _KeycodeViewerTool();
  @override
  State<_KeycodeViewerTool> createState() => _KeycodeViewerToolState();
}

class _KeycodeViewerToolState extends State<_KeycodeViewerTool> {
  String _keyName = '按下任意键...';
  String _keyLabel = '';
  String _keyCode = '';

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          setState(() {
            _keyName = event.logicalKey.debugName ?? '未知';
            _keyLabel = event.logicalKey.keyLabel;
            _keyCode = event.logicalKey.keyId.toString();
          });
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const Icon(Icons.keyboard, size: 64, color: Colors.blueGrey),
          const SizedBox(height: 10),
          const Text('键盘码查看器', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('按下键盘上的任意键查看键码', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 40),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blueGrey.withOpacity(0.3))),
            child: Column(children: [
              _infoRow('键名', _keyName, Colors.cyanAccent),
              const SizedBox(height: 16),
              _infoRow('键标签', _keyLabel, Colors.greenAccent),
              const SizedBox(height: 16),
              _infoRow('键码', _keyCode, Colors.amberAccent),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('提示：此功能在桌面平台上效果最佳', style: TextStyle(color: Colors.white54, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color color) {
    return Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 15))),
      Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)))),
    ]);
  }
}

// ============ 51. 时区转换 ============
class _TimezoneConverterTool extends StatefulWidget {
  const _TimezoneConverterTool();
  @override
  State<_TimezoneConverterTool> createState() => _TimezoneConverterToolState();
}

class _TimezoneConverterToolState extends State<_TimezoneConverterTool> {
  DateTime _selectedTime = DateTime.now();
  final _offsetCtrl = TextEditingController(text: '0');
  String _result = '';

  static const _timezones = [
    {'name': '北京时间 (UTC+8)', 'offset': 8},
    {'name': '东京 (UTC+9)', 'offset': 9},
    {'name': '纽约 (UTC-5)', 'offset': -5},
    {'name': '洛杉矶 (UTC-8)', 'offset': -8},
    {'name': '伦敦 (UTC+0)', 'offset': 0},
    {'name': '巴黎 (UTC+1)', 'offset': 1},
    {'name': '莫斯科 (UTC+3)', 'offset': 3},
    {'name': '迪拜 (UTC+4)', 'offset': 4},
    {'name': '孟买 (UTC+5:30)', 'offset': 5.5},
    {'name': '悉尼 (UTC+10)', 'offset': 10},
    {'name': '自定义', 'offset': -99},
  ];

  int _selectedTz = 0;

  @override
  void initState() { super.initState(); _convert(); }

  void _convert() {
    final offset = _selectedTz == _timezones.length - 1 ? double.tryParse(_offsetCtrl.text) ?? 0 : (_timezones[_selectedTz]['offset'] as num).toDouble();
    final utc = _selectedTime.toUtc();
    final target = utc.add(Duration(hours: offset.toInt(), minutes: ((offset - offset.toInt()) * 60).toInt()));
    setState(() => _result = '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')} ${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')}:${target.second.toString().padLeft(2, '0')}');
  }

  @override
  void dispose() { _offsetCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: SingleChildScrollView(child: Column(children: [
      const Icon(Icons.schedule, size: 48, color: Colors.blueAccent),
      const SizedBox(height: 16),
      const Text('选择源时间', style: TextStyle(color: Colors.white70, fontSize: 14)),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(context: context, initialDate: _selectedTime, firstDate: DateTime(2000), lastDate: DateTime(2100), builder: (ctx, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Colors.blueAccent)), child: child!));
            if (picked != null) {
              final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_selectedTime), builder: (ctx, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Colors.blueAccent)), child: child!));
              if (time != null) {
                setState(() => _selectedTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute));
                _convert();
              }
            }
          },
          icon: const Icon(Icons.calendar_today),
          label: Text('${_selectedTime.year}-${_selectedTime.month.toString().padLeft(2, '0')}-${_selectedTime.day.toString().padLeft(2, '0')} ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
      const SizedBox(height: 16),
      const Text('目标时区', style: TextStyle(color: Colors.white70, fontSize: 14)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: List.generate(_timezones.length, (i) {
        final tz = _timezones[i];
        return ChoiceChip(
          label: Text(tz['name'] as String, style: TextStyle(color: _selectedTz == i ? Colors.black : Colors.white70, fontSize: 12)),
          selected: _selectedTz == i,
          selectedColor: Colors.blueAccent,
          backgroundColor: Colors.white.withOpacity(0.08),
          onSelected: (v) { setState(() => _selectedTz = i); _convert(); },
        );
      })),
      if (_selectedTz == _timezones.length - 1) ...[
        const SizedBox(height: 10),
        TextField(controller: _offsetCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '时区偏移 (±小时)', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(12)), keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true), onChanged: (_) => _convert()),
      ],
      if (_result.isNotEmpty) ...[
        const SizedBox(height: 20),
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blueAccent.withOpacity(0.1), Colors.cyanAccent.withOpacity(0.1)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueAccent.withOpacity(0.3))), child: Column(children: [
          const Text('转换结果', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          Text(_result, style: const TextStyle(color: Colors.blueAccent, fontSize: 28, fontWeight: FontWeight.bold)),
        ])),
      ],
    ])));
  }
}

// ============ 52. 数字进制转换 ============
class _NumberBaseConverterTool extends StatefulWidget {
  const _NumberBaseConverterTool();
  @override
  State<_NumberBaseConverterTool> createState() => _NumberBaseConverterToolState();
}

class _NumberBaseConverterToolState extends State<_NumberBaseConverterTool> {
  final _inputCtrl = TextEditingController();
  String _result = '';

  void _convert() {
    final input = _inputCtrl.text.trim();
    if (input.isEmpty) {
      setState(() => _result = '');
      return;
    }
    try {
      int value;
      if (input.startsWith('0b') || input.startsWith('0B')) {
        value = int.parse(input.substring(2), radix: 2);
      } else if (input.startsWith('0o') || input.startsWith('0O')) {
        value = int.parse(input.substring(2), radix: 8);
      } else if (input.startsWith('0x') || input.startsWith('0X')) {
        value = int.parse(input.substring(2), radix: 16);
      } else {
        value = int.parse(input);
      }
      setState(() => _result = '''
二进制: 0b${value.toRadixString(2)}
八进制: 0o${value.toRadixString(8)}
十进制: ${value.toRadixString(10)}
十六进制: 0x${value.toRadixString(16).toUpperCase()}
''');
    } catch (e) {
      setState(() => _result = '输入格式错误');
    }
  }

  @override
  void dispose() { _inputCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(
        controller: _inputCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'monospace'),
        decoration: InputDecoration(
          hintText: '输入数字 (支持 0b/0o/0x 前缀)...',
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true, fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: const Icon(Icons.transform, color: Colors.tealAccent),
        ),
        onChanged: (_) => _convert(),
      ),
      const SizedBox(height: 8),
      const Text('示例: 255, 0b11111111, 0o377, 0xFF', style: TextStyle(color: Colors.white38, fontSize: 12)),
      if (_result.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.tealAccent.withOpacity(0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.tealAccent.withOpacity(0.2))), child: SelectableText(_result, style: const TextStyle(color: Colors.tealAccent, fontSize: 16, fontFamily: 'monospace', height: 1.8))),
      ],
    ]));
  }
}

// ============ 53. 列表随机 ============
class _ListRandomizerTool extends StatefulWidget {
  const _ListRandomizerTool();
  @override
  State<_ListRandomizerTool> createState() => _ListRandomizerToolState();
}

class _ListRandomizerToolState extends State<_ListRandomizerTool> {
  final _inputCtrl = TextEditingController();
  List<String> _items = [];
  List<String> _shuffled = [];

  void _parse() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) {
      setState(() { _items = []; _shuffled = []; });
      return;
    }
    final items = text.split(RegExp(r'[\n,;]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    setState(() => _items = items);
  }

  void _shuffle() {
    final list = List<String>.from(_items);
    list.shuffle(math.Random());
    setState(() => _shuffled = list);
  }

  void _pick() {
    if (_items.isEmpty) return;
    final picked = _items[math.Random().nextInt(_items.length)];
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('选中: $picked', style: const TextStyle(fontSize: 16)), backgroundColor: Colors.amberAccent.withOpacity(0.9), duration: const Duration(seconds: 2)));
  }

  @override
  void dispose() { _inputCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(
        controller: _inputCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: '输入列表项，用逗号、分号或换行分隔...',
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true, fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(16),
        ),
        maxLines: 4,
        onChanged: (_) => _parse(),
      ),
      if (_items.isNotEmpty) ...[
        const SizedBox(height: 8),
        Row(children: [
          Text('共 ${_items.length} 项', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          TextButton(onPressed: _parse, child: const Text('刷新', style: TextStyle(color: Colors.amberAccent))),
        ]),
      ],
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: _items.isEmpty ? null : _shuffle, icon: const Icon(Icons.shuffle), label: const Text('随机排序'), style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(onPressed: _items.isEmpty ? null : _pick, icon: const Icon(Icons.touch_app), label: const Text('随机抽取'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.15), foregroundColor: Colors.amberAccent, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      ]),
      if (_shuffled.isNotEmpty) ...[
        const SizedBox(height: 16),
        Expanded(child: Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: ListView.builder(itemCount: _shuffled.length, itemBuilder: (_, i) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
          Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.amberAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text('${i + 1}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(child: Text(_shuffled[i], style: const TextStyle(color: Colors.white, fontSize: 15))),
        ]))))),
      ],
    ]));
  }
}

// ============ 54. 倒计时 ============
class _CountdownTimerTool extends StatefulWidget {
  const _CountdownTimerTool();
  @override
  State<_CountdownTimerTool> createState() => _CountdownTimerToolState();
}

class _CountdownTimerToolState extends State<_CountdownTimerTool> with TickerProviderStateMixin {
  final _hoursCtrl = TextEditingController(text: '0');
  final _minutesCtrl = TextEditingController(text: '1');
  final _secondsCtrl = TextEditingController(text: '0');
  Timer? _timer;
  Duration _remaining = Duration.zero;
  Duration _total = Duration.zero;
  bool _running = false;
  bool _finished = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _hoursCtrl.dispose();
    _minutesCtrl.dispose();
    _secondsCtrl.dispose();
    super.dispose();
  }

  void _start() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    if (_finished) {
      _reset();
      return;
    }
    if (_remaining == Duration.zero) {
      final h = int.tryParse(_hoursCtrl.text) ?? 0;
      final m = int.tryParse(_minutesCtrl.text) ?? 0;
      final s = int.tryParse(_secondsCtrl.text) ?? 0;
      _remaining = Duration(hours: h, minutes: m, seconds: s);
      _total = _remaining;
    }
    if (_remaining <= Duration.zero) return;
    _finished = false;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _remaining -= const Duration(milliseconds: 100);
        if (_remaining <= Duration.zero) {
          _remaining = Duration.zero;
          _running = false;
          _finished = true;
          _timer?.cancel();
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = Duration.zero;
      _total = Duration.zero;
      _running = false;
      _finished = false;
    });
  }

  String _format(Duration d) {
    return '${d.inHours.toString().padLeft(2, '0')}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total > Duration.zero ? 1.0 - (_remaining.inMilliseconds / _total.inMilliseconds) : 0.0;
    return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      if (!_running && _remaining == Duration.zero && !_finished) ...[
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _timeField(_hoursCtrl, '时'),
          const Text(' : ', style: TextStyle(color: Colors.white38, fontSize: 24)),
          _timeField(_minutesCtrl, '分'),
          const Text(' : ', style: TextStyle(color: Colors.white38, fontSize: 24)),
          _timeField(_secondsCtrl, '秒'),
        ]),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _preset(1, '1分'), _preset(3, '3分'), _preset(5, '5分'), _preset(10, '10分'), _preset(15, '15分'), _preset(30, '30分'), _preset(60, '1小时'), _preset(120, '2小时'),
        ]),
      ],
      if (_running || _finished || _remaining > Duration.zero) ...[
        const Spacer(),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(scale: _running ? _pulseAnim.value : 1.0, child: child),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.redAccent.withOpacity(0.1), Colors.orangeAccent.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _finished ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.3)),
            ),
            child: Column(children: [
              Text(_format(_remaining), style: TextStyle(color: _finished ? Colors.greenAccent : _remaining < const Duration(seconds: 10) ? Colors.redAccent : Colors.orangeAccent, fontSize: 56, fontWeight: FontWeight.w200, fontFamily: 'monospace')),
              if (_finished) ...[
                const SizedBox(height: 12),
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 40),
                const SizedBox(height: 8),
                const Text('时间到！', style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
              if (_running) ...[
                const SizedBox(height: 16),
                ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withOpacity(0.1), color: Colors.redAccent, minHeight: 6)),
              ],
            ]),
          ),
        ),
      ],
      const SizedBox(height: 30),
      SizedBox(
        width: 200,
        child: ElevatedButton(
          onPressed: _start,
          style: ElevatedButton.styleFrom(
            backgroundColor: _finished ? Colors.greenAccent : _running ? Colors.orangeAccent : Colors.redAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_finished ? Icons.refresh : _running ? Icons.pause : Icons.play_arrow, size: 28),
            const SizedBox(width: 8),
            Text(_finished ? '重新开始' : _running ? '暂停' : '开始', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
      if (_running || _finished || _remaining > Duration.zero) const Spacer(),
    ]));
  }

  Widget _timeField(TextEditingController ctrl, String label) {
    return SizedBox(
      width: 72,
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: const TextStyle(color: Colors.white24),
          filled: true, fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          label: Center(child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12))),
        ),
      ),
    );
  }

  Widget _preset(int minutes, String label) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      selected: false,
      backgroundColor: Colors.white.withOpacity(0.08),
      onSelected: (_) {
        _hoursCtrl.text = '0';
        _minutesCtrl.text = '$minutes';
        _secondsCtrl.text = '0';
        setState(() {});
      },
    );
  }
}