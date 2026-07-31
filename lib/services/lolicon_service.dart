import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class LoliconService {
  static const _baseUrl = 'https://api.lolicon.app/setu/v2';

  // 获取随机图片
  static Future<List<LoliconImage>> getImages({
    required LoliconParams params,
    int timeoutSeconds = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'r18': params.r18.toString(),
        'num': params.num.toString(),
        'size': params.size,
      };

      if (params.uid.isNotEmpty) queryParams['uid'] = params.uid;
      if (params.keyword.isNotEmpty) queryParams['keyword'] = params.keyword;
      if (params.tag.isNotEmpty) queryParams['tag'] = params.tag.join('|');
      if (params.proxy.isNotEmpty) queryParams['proxy'] = params.proxy;
      if (params.dateAfter.isNotEmpty) queryParams['dateAfter'] = params.dateAfter;
      if (params.dateBefore.isNotEmpty) queryParams['dateBefore'] = params.dateBefore;
      if (params.dsc) queryParams['dsc'] = 'true';
      if (params.excludeAI) queryParams['excludeAI'] = 'true';

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

      final response = await http.get(uri).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          final list = data['data'] as List;
          return list.map((e) => LoliconImage.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}