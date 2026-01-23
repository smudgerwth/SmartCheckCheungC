import 'package:dio/dio.dart';
import '../models/court_session.dart';
import '../models/district.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://www.smartplay.lcsd.gov.hk/rest/facility-catalog/api/v1/',
    headers: {
      'Accept': 'application/json',
      'channel': 'INTERNET',
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
    },
  ))..interceptors.add(LogInterceptor(
      request: true,
      requestHeader: false,
      requestBody: true,
      responseHeader: false,
      responseBody: false,
      error: true,
    ));

  void setLocale(String locale) {
    if (['en', 'zh-hk', 'zh-cn'].contains(locale.toLowerCase())) {
      _dio.options.headers['Accept-Language'] = locale;
    }
  }

  Future<List<CourtSession>> fetchSessions(String facilityCode, String date) async {
    try {
      final response = await _dio.get(
        'publ/facilities',
        queryParameters: {
          'faCode': facilityCode,
          'playDate': date,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> sessionsJson = [];
        final data = response.data['data'];
        
        // Match the logic in main.py: parse morning, afternoon, evening
        final timesOfDay = ['morning', 'afternoon', 'evening'];
        for (var time in timesOfDay) {
          final distList = data[time]['distList'] as List;
          for (var dist in distList) {
            final venueList = dist['venueList'] as List;
            for (var venue in venueList) {
              final fatList = venue['fatList'] as List;
              for (var fat in fatList) {
                final sessionList = fat['sessionList'] as List;
                for (var session in sessionList) {
                  // Flatten the nested structure as done in main.py
                  sessionsJson.add({
                    'distName': dist['distName'],
                    'distCode': dist['distCode'],
                    'venueName': venue['venueName'],
                    'venueId': venue['venueId'],
                    'fatName': fat['fatName'],
                    'fatId': fat['fatId'],
                    'ssnStartTime': session['ssnStartTime'],
                    'ssnStartDate': session['ssnStartDate'],
                    'available': session['available'],
                    'sessionCount': session['sessionCount'],
                  });
                }
              }
            }
          }
        }
        return sessionsJson.map((s) => CourtSession.fromJson(s)).toList();
      } else {
        throw Exception('Failed to load sessions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sessions: $e');
    }
  }

  Future<List<Region>> fetchDistricts() async {
    try {
      final response = await _dio.get(
        'https://www.smartplay.lcsd.gov.hk/rest/param/api/v1/publ/districts/searching-criteria?',
      );

      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((r) => Region.fromJson(r))
            .toList();
      } else {
        throw Exception('Failed to load districts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching districts: $e');
    }
  }
}
