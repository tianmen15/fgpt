import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局错误捕获 - 防止闪退
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // 不让应用崩溃，记录错误即可
    debugPrint('Flutter Error: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    return true; // 防止崩溃
  };

  await StorageService.init();

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const VideoApp());
}

class VideoApp extends StatelessWidget {
  const VideoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '万能视频播放器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00d4ff),
        scaffoldBackgroundColor: const Color(0xFF0a0a1a),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00d4ff),
          onPrimary: Color(0xFF003545),
          primaryContainer: Color(0xFF004d64),
          secondary: Color(0xFFb388ff),
          onSecondary: Color(0xFF1a0033),
          secondaryContainer: Color(0xFF311b92),
          tertiary: Color(0xFF00e676),
          onTertiary: Color(0xFF003d00),
          surface: Color(0xFF1a1a2e),
          onSurface: Color(0xFFe0e0e0),
          outline: Color(0xFF3a3a5c),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1a1a2e).withOpacity(0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00d4ff),
          foregroundColor: Color(0xFF003545),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withOpacity(0.06),
          thickness: 0.5,
        ),
      ),
      home: const HomeScreen(),
      builder: (context, child) {
        // 最外层错误保护
        return ErrorGuard(child: child ??= const SizedBox.shrink());
      },
    );
  }
}

// 全局错误保护组件 - 任何地方出错都不闪退
class ErrorGuard extends StatefulWidget {
  final Widget child;
  const ErrorGuard({super.key, required this.child});

  @override
  State<ErrorGuard> createState() => _ErrorGuardState();
}

class _ErrorGuardState extends State<ErrorGuard> {
  bool _hasError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      debugPrint('Widget Error: ${details.exception}');
      return Container(
        color: const Color(0xFF1a1a2e),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, size: 48, color: Colors.white38),
              SizedBox(height: 8),
              Text('组件加载异常', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF1a1a2e),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('应用遇到问题', style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(_errorMsg, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() { _hasError = false; _errorMsg = ''; }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00d4ff),
                      foregroundColor: const Color(0xFF003545),
                    ),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      return widget.child;
    } catch (e) {
      _hasError = true;
      _errorMsg = e.toString();
      return const SizedBox.shrink();
    }
  }
}