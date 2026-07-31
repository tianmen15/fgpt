import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/wallpaper_scaffold.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> with TickerProviderStateMixin {
  String _display = '0';
  String _expression = '';
  bool _isResult = false;
  bool _isScientific = false;
  List<String> _history = [];
  bool _showHistory = false;
  late AnimationController _pressCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _glowCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _onButtonPress(String value) {
    _pressCtrl.reset();
    _pressCtrl.forward();
    HapticFeedback.lightImpact();

    setState(() {
      if (value == 'C') {
        _display = '0';
        _expression = '';
        _isResult = false;
      } else if (value == 'AC') {
        _display = '0';
        _expression = '';
        _isResult = false;
        _history.clear();
      } else if (value == '⌫') {
        if (_isResult) {
          _display = '0';
          _expression = '';
          _isResult = false;
        } else if (_display.length > 1) {
          _display = _display.substring(0, _display.length - 1);
        } else {
          _display = '0';
        }
      } else if (value == '=') {
        _calculate();
      } else if (value == '±') {
        if (_display.startsWith('-')) {
          _display = _display.substring(1);
        } else if (_display != '0') {
          _display = '-$_display';
        }
      } else if (value == '%') {
        final num = double.tryParse(_display) ?? 0;
        _display = _formatNumber(num / 100);
        _expression = _display;
      } else if (_isScientificOp(value)) {
        _scientificOp(value);
      } else {
        if (_isResult) {
          _display = value;
          _expression = '';
          _isResult = false;
        } else {
          if (_display == '0' && value != '.') {
            _display = value;
          } else {
            _display += value;
          }
        }
      }
    });
  }

  bool _isScientificOp(String v) {
    return ['sin', 'cos', 'tan', 'log', 'ln', '√', 'x²', 'xʸ', 'π', 'e', '(', ')', '!'].contains(v);
  }

  void _scientificOp(String value) {
    switch (value) {
      case 'π':
        if (_isResult) { _display = math.pi.toStringAsFixed(10); _isResult = false; }
        else if (_display == '0') _display = math.pi.toStringAsFixed(10);
        else _display += math.pi.toStringAsFixed(10);
        break;
      case 'e':
        if (_isResult) { _display = math.e.toStringAsFixed(10); _isResult = false; }
        else if (_display == '0') _display = math.e.toStringAsFixed(10);
        else _display += math.e.toStringAsFixed(10);
        break;
      case 'sin':
        _display = _formatNumber(math.sin(_toRadians(double.tryParse(_display) ?? 0)));
        _isResult = true;
        break;
      case 'cos':
        _display = _formatNumber(math.cos(_toRadians(double.tryParse(_display) ?? 0)));
        _isResult = true;
        break;
      case 'tan':
        _display = _formatNumber(math.tan(_toRadians(double.tryParse(_display) ?? 0)));
        _isResult = true;
        break;
      case 'log':
        _display = _formatNumber(math.log(double.tryParse(_display) ?? 1) / math.ln10);
        _isResult = true;
        break;
      case 'ln':
        _display = _formatNumber(math.log(double.tryParse(_display) ?? 1));
        _isResult = true;
        break;
      case '√':
        _display = _formatNumber(math.sqrt(double.tryParse(_display) ?? 0));
        _isResult = true;
        break;
      case 'x²':
        final n = double.tryParse(_display) ?? 0;
        _display = _formatNumber(n * n);
        _isResult = true;
        break;
      case 'xʸ':
        _expression = _display;
        _display = '';
        _expression += '^';
        break;
      case '!':
        _display = _formatNumber(_factorial((double.tryParse(_display) ?? 0).toInt()).toDouble());
        _isResult = true;
        break;
      case '(':
        if (_isResult || _display == '0') _display = '(';
        else _display += '(';
        _isResult = false;
        break;
      case ')':
        _display += ')';
        break;
    }
  }

  void _calculate() {
    try {
      String expr = _expression.isEmpty ? _display : '$_expression$_display';
      if (expr.contains('^')) {
        final parts = expr.split('^');
        if (parts.length == 2) {
          final base = double.parse(parts[0]);
          final exp = double.parse(parts[1]);
          final result = math.pow(base, exp);
          _expression = expr;
          final resultNum = result is int ? result.toDouble() : (result as double);
          _display = _formatNumber(resultNum);
          _isResult = true;
          _history.add('$expr = $_display');
          return;
        }
      }

      expr = expr.replaceAll('×', '*').replaceAll('÷', '/');
      final result = _evaluate(expr);
      _expression = expr;
      final resultStr = _formatNumber(result);
      _display = resultStr;
      _isResult = true;
      _history.add('$expr = $resultStr');
      if (_history.length > 50) _history.removeAt(0);
    } catch (_) {
      _display = 'Error';
      _isResult = true;
    }
  }

  double _evaluate(String expr) {
    // Simple expression evaluator
    final tokens = _tokenize(expr);
    return _parseExpression(tokens);
  }

  List<String> _tokenize(String expr) {
    final tokens = <String>[];
    String num = '';
    for (int i = 0; i < expr.length; i++) {
      final c = expr[i];
      if (c == '-' && (i == 0 || expr[i - 1] == '(' || expr[i - 1] == '+' || expr[i - 1] == '-' || expr[i - 1] == '*' || expr[i - 1] == '/')) {
        num += c;
      } else if ('0123456789.'.contains(c)) {
        num += c;
      } else {
        if (num.isNotEmpty) {
          tokens.add(num);
          num = '';
        }
        tokens.add(c);
      }
    }
    if (num.isNotEmpty) tokens.add(num);
    return tokens;
  }

  double _parseExpression(List<String> tokens) {
    // Handle parentheses
    final stack = <double>[];
    final ops = <String>[];

    void applyOp() {
      if (ops.isEmpty || stack.length < 2) return;
      final op = ops.removeLast();
      final b = stack.removeLast();
      final a = stack.removeLast();
      switch (op) {
        case '+': stack.add(a + b); break;
        case '-': stack.add(a - b); break;
        case '*': stack.add(a * b); break;
        case '/': stack.add(a / b); break;
      }
    }

    final precedence = {'+': 1, '-': 1, '*': 2, '/': 2};

    for (final token in tokens) {
      if (token == '(') {
        ops.add(token);
      } else if (token == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          applyOp();
        }
        ops.removeLast();
      } else if (precedence.containsKey(token)) {
        while (ops.isNotEmpty && ops.last != '(' && precedence[ops.last]! >= precedence[token]!) {
          applyOp();
        }
        ops.add(token);
      } else {
        stack.add(double.parse(token));
      }
    }
    while (ops.isNotEmpty) applyOp();
    return stack.first;
  }

  int _factorial(int n) {
    if (n <= 1) return 1;
    return n * _factorial(n - 1);
  }

  double _toRadians(double deg) => deg * math.pi / 180;

  String _formatNumber(double num) {
    if (num.isNaN) return 'Error';
    if (num.isInfinite) return '∞';
    if (num == num.toInt() && num.abs() < 1e15) {
      return num.toInt().toString();
    }
    String s = num.toStringAsFixed(10);
    s = s.replaceAll(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    if (s.length > 12) s = num.toStringAsExponential(6);
    return s;
  }

  void _opButton(String value) {
    _pressCtrl.reset();
    _pressCtrl.forward();
    HapticFeedback.lightImpact();
    setState(() {
      if (_isResult) {
        _expression = _display;
        _expression += value;
        _display = '';
        _isResult = false;
      } else {
        _expression += _display;
        _expression += value;
        _display = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(_showHistory ? '计算历史' : '计算器', key: ValueKey(_showHistory), style: const TextStyle(color: Colors.white)),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isScientific ? Icons.science : Icons.calculate, color: _isScientific ? Colors.cyanAccent : Colors.white54),
            onPressed: () => setState(() => _isScientific = !_isScientific),
            tooltip: '科学计算',
          ),
          IconButton(
            icon: Icon(_showHistory ? Icons.calculate : Icons.history, color: _showHistory ? Colors.cyanAccent : Colors.white54),
            onPressed: () => setState(() => _showHistory = !_showHistory),
            tooltip: '历史',
          ),
        ],
      ),
      body: _showHistory ? _buildHistory() : _buildCalculator(),
    );
  }

  Widget _buildCalculator() {
    return SafeArea(
      child: Column(
        children: [
          _buildDisplay(),
          Expanded(child: _buildKeypad()),
        ],
      ),
    );
  }

  Widget _buildDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.cyanAccent.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, child) => ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Colors.cyanAccent.withOpacity(_glowAnim.value),
                  Colors.purpleAccent.withOpacity(_glowAnim.value),
                ],
              ).createShader(bounds),
              child: child,
            ),
            child: Text(
              _expression.isNotEmpty ? _expression : '',
              style: const TextStyle(color: Colors.white38, fontSize: 18),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
            child: Text(
              _display,
              key: ValueKey(_display),
              style: TextStyle(
                color: _display == 'Error' ? Colors.redAccent : Colors.white,
                fontSize: _display.length > 10 ? 32 : 48,
                fontWeight: FontWeight.w300,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    final basicKeys = [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['±', '0', '.', '='],
    ];

    final scientificKeys = [
      ['sin', 'cos', 'tan', 'log'],
      ['ln', '√', 'x²', 'xʸ'],
      ['π', 'e', '(', ')'],
      ['!', 'AC', '', ''],
    ];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          if (_isScientific)
            Expanded(
              flex: 3,
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.8,
                children: scientificKeys.expand((row) => row).map((k) {
                  if (k.isEmpty) return const SizedBox.shrink();
                  return _buildKey(k, isScientific: true);
                }).toList(),
              ),
            ),
          Expanded(
            flex: _isScientific ? 5 : 7,
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.4,
              children: basicKeys.expand((row) => row).map((k) => _buildKey(k)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String label, {bool isScientific = false}) {
    final isOp = ['÷', '×', '-', '+', '='].contains(label);
    final isFunc = ['C', 'AC', '⌫', '%', '±'].contains(label) || isScientific;

    Color bgColor;
    if (label == '=') {
      bgColor = Colors.cyanAccent;
    } else if (isOp) {
      bgColor = Colors.cyanAccent.withOpacity(0.2);
    } else if (isFunc) {
      bgColor = Colors.white.withOpacity(0.12);
    } else {
      bgColor = Colors.white.withOpacity(0.08);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 150),
      builder: (_, v, __) => Transform.scale(
        scale: v,
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(isScientific ? 12 : 14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (isOp && label != '=' && label != 'C' && label != 'AC' && label != '⌫' && label != '%' && label != '±') {
                _opButton(label);
              } else {
                _onButtonPress(label);
              }
            },
            onLongPress: label == 'C' ? () => _onButtonPress('AC') : null,
            splashColor: Colors.cyanAccent.withOpacity(0.3),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: label == '=' ? Colors.black : (isOp || isFunc ? Colors.cyanAccent : Colors.white),
                  fontSize: isScientific ? 14 : 20,
                  fontWeight: label == '=' ? FontWeight.bold : FontWeight.w400,
                ),
              ),
            ),
          ),
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
            const Text('暂无计算记录', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _history.clear()),
                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 18),
                label: const Text('清空', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _history.length,
            itemBuilder: (ctx, i) {
              final item = _history[_history.length - 1 - i];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 200 + i * 50),
                curve: Curves.easeOut,
                builder: (_, v, __) {
                  return Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - v)),
                      child: Card(
                        color: Colors.white.withOpacity(0.06),
                        margin: const EdgeInsets.only(bottom: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          dense: true,
                          title: Text(item, style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'monospace')),
                          trailing: IconButton(
                            icon: const Icon(Icons.content_copy, color: Colors.cyanAccent, size: 18),
                            onPressed: () {
                              final parts = item.split(' = ');
                              if (parts.length == 2) {
                                Clipboard.setData(ClipboardData(text: parts[1]));
                              } else {
                                Clipboard.setData(ClipboardData(text: item));
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已复制'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}