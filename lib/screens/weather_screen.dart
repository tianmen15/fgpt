import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/wallpaper_scaffold.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with TickerProviderStateMixin {
  final _cityController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _weather;
  List<Map<String, dynamic>> _forecast = [];
  String? _error;
  String _currentCity = 'Beijing';
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _cloudCtrl;
  late Animation<double> _cloudAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _cloudCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _cloudAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _cloudCtrl, curve: Curves.linear));
    _cloudCtrl.repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.repeat(reverse: true);
    _fetchWeather(_currentCity);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _animCtrl.dispose();
    _cloudCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather(String city) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _animCtrl.reset();
    _animCtrl.forward();

    try {
      final response = await http.get(
        Uri.parse('https://wttr.in/$city?format=j1'),
        headers: {'User-Agent': 'curl/7.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _weather = data;
            _currentCity = city;
            _forecast = _parseForecast(data);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '获取天气失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _parseForecast(Map<String, dynamic> data) {
    try {
      final weather = data['weather'] as List;
      final forecast = <Map<String, dynamic>>[];
      for (final day in weather.take(3)) {
        final hourly = (day['hourly'] as List?)?.firstOrNull;
        String condition = 'Unknown';
        if (hourly != null) {
          final desc = hourly['weatherDesc'];
          if (desc is List && desc.isNotEmpty) {
            final firstDesc = desc.first;
            if (firstDesc is Map) {
              condition = firstDesc['value']?.toString() ?? 'Unknown';
            }
          }
        }
        forecast.add({
          'date': day['date'] ?? '',
          'maxTemp': day['maxtempC'] ?? '--',
          'minTemp': day['mintempC'] ?? '--',
          'condition': condition,
          'icon': hourly?['weatherCode']?.toString() ?? '113',
        });
      }
      return forecast;
    } catch (_) {
      return [];
    }
  }

  String _getWeatherIcon(String? code) {
    switch (code) {
      case '113': return '☀️';
      case '116': return '⛅';
      case '119': return '☁️';
      case '122': return '☁️';
      case '143': return '🌫️';
      case '176': return '🌦️';
      case '179': return '🌨️';
      case '182': return '🌨️';
      case '185': return '🌨️';
      case '200': return '⛈️';
      case '227': return '🌨️';
      case '230': return '🌨️';
      case '248': return '🌫️';
      case '260': return '🌫️';
      case '263': return '🌧️';
      case '266': return '🌧️';
      case '281': return '🌧️';
      case '284': return '🌧️';
      case '293': return '🌧️';
      case '296': return '🌧️';
      case '299': return '🌧️';
      case '302': return '🌧️';
      case '305': return '🌧️';
      case '308': return '🌧️';
      case '311': return '🌧️';
      case '314': return '🌧️';
      case '317': return '🌧️';
      case '320': return '🌨️';
      case '323': return '🌨️';
      case '326': return '🌨️';
      case '329': return '🌨️';
      case '332': return '🌨️';
      case '335': return '🌨️';
      case '338': return '🌨️';
      case '350': return '🌨️';
      case '353': return '🌧️';
      case '356': return '🌧️';
      case '359': return '🌧️';
      case '362': return '🌨️';
      case '365': return '🌨️';
      case '368': return '🌨️';
      case '371': return '🌨️';
      case '374': return '🌨️';
      case '377': return '🌨️';
      case '386': return '⛈️';
      case '389': return '⛈️';
      case '392': return '⛈️';
      case '395': return '🌨️';
      default: return '🌤️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperScaffold(
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: const Text('天气', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                  : _error != null
                      ? _buildError()
                      : _weather != null
                          ? _buildWeatherContent()
                          : _buildEmpty(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _cityController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '输入城市名 (如 Beijing, Tokyo, London)',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  prefixIcon: const Icon(Icons.location_city, color: Colors.cyanAccent),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (v) => v.trim().isNotEmpty ? _fetchWeather(v.trim()) : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
            child: Material(
              color: Colors.cyanAccent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  final city = _cityController.text.trim();
                  if (city.isNotEmpty) _fetchWeather(city);
                },
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.search, color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _fetchWeather(_currentCity),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(seconds: 1),
            curve: Curves.elasticOut,
            builder: (_, v, __) => Transform.scale(scale: v, child: const Icon(Icons.cloud, size: 64, color: Colors.white24)),
          ),
          const SizedBox(height: 16),
          const Text('搜索城市查看天气', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    final current = _weather!['current_condition']?[0];
    final temp = current?['temp_C'] ?? '--';
    final humidity = current?['humidity'] ?? '--';
    final windSpeed = current?['windspeedKmph'] ?? '--';
    final windDir = current?['winddir16Point'] ?? '--';
    final feelsLike = current?['FeelsLikeC'] ?? '--';
    final visibility = current?['visibility'] ?? '--';
    final pressure = current?['pressure'] ?? '--';
    final uvIndex = current?['uvIndex'] ?? '--';
    final weatherCode = current?['weatherCode']?.toString();
    String weatherDesc = '--';
    final wd = current?['weatherDesc'];
    if (wd is List && wd.isNotEmpty) {
      final first = wd.first;
      if (first is Map) {
        weatherDesc = first['value']?.toString() ?? '--';
      }
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // 当前天气卡片
            AnimatedBuilder(
              animation: _cloudAnim,
              builder: (_, child) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6a11cb).withOpacity(0.3),
                        const Color(0xFF2575fc).withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(seconds: 1),
                            curve: Curves.elasticOut,
                            builder: (_, v, __) => Transform.scale(
                              scale: v,
                              child: Text(_getWeatherIcon(weatherCode), style: const TextStyle(fontSize: 64)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentCity,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(weatherDesc, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 12),
                      Text(
                        '$temp°C',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 64,
                          fontWeight: FontWeight.w200,
                          shadows: [Shadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 20)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('体感 $feelsLike°C', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _infoChip(Icons.water_drop, '$humidity%', '湿度'),
                          _infoChip(Icons.air, '$windSpeed km/h', '$windDir'),
                          _infoChip(Icons.visibility, '$visibility', '能见度'),
                          _infoChip(Icons.speed, '$pressure', '气压'),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // 3天预报
            const Text('未来3天预报', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_forecast.isNotEmpty)
              ..._forecast.map((day) => _buildForecastCard(day)),
            const SizedBox(height: 20),
            // 额外信息
            Row(
              children: [
                Expanded(child: _extraCard('UV指数', '$uvIndex', Icons.wb_sunny, Colors.amber)),
                const SizedBox(width: 10),
                Expanded(child: _extraCard('风速', '$windSpeed km/h', Icons.air, Colors.cyanAccent)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.cyanAccent.withOpacity(0.7), size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> day) {
    final dateStr = day['date'] as String? ?? '';
    String displayDate = dateStr;
    try {
      final date = DateTime.parse(dateStr);
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      displayDate = '${weekdays[date.weekday - 1]} ${date.month}/${date.day}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(displayDate, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Text(
            _getWeatherIcon(day['icon']?.toString()),
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              day['condition'] ?? '--',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const Icon(Icons.arrow_downward, color: Colors.blueAccent, size: 14),
          Text(' ${day['minTemp']}°', style: const TextStyle(color: Colors.blueAccent, fontSize: 14)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 14),
          Text(' ${day['maxTemp']}°', style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _extraCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}