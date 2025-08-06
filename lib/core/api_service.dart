import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

class ApiService {
  final baseUrl = dotenv.env['API_BASE_URL'];

  Future<Map<String, dynamic>?> login(
    String username,
    String password,
    String? fcm_token,
  ) async {
    final url = Uri.parse('$baseUrl/odata/api/v1-Odata/account/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'fcm_token': fcm_token,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      print('登入失敗: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> account(String token) async {
    final url = Uri.parse('$baseUrl/odata/api/v1-Odata/account');
    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': token},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data["user"];
    } else {
      print('查看帳號失敗: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse(
      '$baseUrl/odata/api/v1-Odata/account/change-password',
    );
    final res = await http.post(
      url,
      headers: {'Authorization': '$token', 'Content-Type': 'application/json'},
      body: json.encode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } else {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final errorMessage = body['error'] ?? '變更密碼失敗';
      throw Exception(errorMessage);
    }
  }

  Future<List<dynamic>?> fetchSystems(String token) async {
    final url = Uri.parse('$baseUrl/odata/api/v1-Odata/Systems');
    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['value'];
    } else {
      print('取得 Systems 失敗: ${response.statusCode}');
      return null;
    }
  }

  Future<List<dynamic>?> fetchTargets(String token) async {
    final url = Uri.parse('$baseUrl/odata/api/v1-Odata/Targets');
    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['value'];
    } else {
      print('取得 Targets 失敗: ${response.statusCode}');
      return null;
    }
  }

  Future<List<dynamic>?> fetchDevices(String token, String targetUUID) async {
    final url = Uri.parse(
      '${baseUrl}/odata/api/v1-Odata/Devices?targetUUID=${targetUUID}',
    );
    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['value'];
    } else {
      print('取得 Devices 失敗: ${response.statusCode}');
      return null;
    }
  }

  Future<List<dynamic>?> fetchObservationsLatest(String token) async {
    final url = Uri.parse('$baseUrl/odata/api/v1-Odata/ObservationsLatest');
    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['value'];
    } else {
      print('取得 ObservationsLatest 失敗: ${response.statusCode}');
      return null;
    }
  }

  Future<List<dynamic>?> fetchObservationRawData({
    required String deviceUUID,
    required String featureEnglishName,
    required String serialId,
    required DateTime startTime,
    required DateTime endTime,
    required String aggregate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final url = Uri.parse(
      '$baseUrl/odata/api/v1-Odata/Observations/RawData'
      '?deviceUUID=$deviceUUID'
      '&featureEnglishName=$featureEnglishName'
      '&serialId=$serialId'
      '&start_time=${DateFormat('yyyy-MM-dd HH:mm:ss').format(startTime)}'
      '&end_time=${DateFormat('yyyy-MM-dd HH:mm:ss').format(endTime)}'
      '&aggregate=$aggregate',
    );

    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['value'] ?? [];
    } else {
      print('fetchObservationRawData失敗 ${response.statusCode}');
      return null;
    }
  }

  Future<List<dynamic>?> fetchMineRawData({
    required String featureEnglishName,
    required DateTime startTime,
    required DateTime endTime,
    required String aggregate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final url = Uri.parse(
      '$baseUrl/odata/api/v1-Odata/Observations/account/RawData'
      '?featureEnglishName=$featureEnglishName'
      '&start_time=${DateFormat('yyyy-MM-dd HH:mm:ss').format(startTime)}'
      '&end_time=${DateFormat('yyyy-MM-dd HH:mm:ss').format(endTime)}'
      '&aggregate=$aggregate',
    );

    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['value'] ?? [];
    } else {
      print('fetchMineObservationRawData失敗 ${response.statusCode}');
      return null;
    }
  }

  Future<bool> switchSetting({
    required String deviceUUID,
    required String featureEnglishName,
    required String serialId,
    required bool newValue,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No token found');
    }

    final url = Uri.parse('$baseUrl/odata/api/v1-Odata/Settings');

    final body = {
      'deviceUUID': deviceUUID,
      'featureEnglishName': featureEnglishName,
      'value': newValue ? 'ON' : 'OFF',
      'serialId': serialId,
    };

    final response = await http.post(
      url,
      headers: {
        'accept': 'application/json',
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print('Switch Setting 失敗: ${response.statusCode} ${response.body}');
      return false;
    }
  }

  /// 查詢所有 GroupDevices（包含底下 Devices 資訊）
  Future<List<dynamic>?> fetchGroupDevices(String token) async {
    final url = Uri.parse('$baseUrl/odata/api/v1-Odata/GroupDevices');
    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['value'];
    } else {
      print('取得 GroupDevices 失敗: ${response.statusCode}');
      return null;
    }
  }

  /// 查詢 GroupDevice 中所有裝置的平均觀測資料（raw/hours/days/months）
  Future<List<dynamic>?> fetchGroupObservation({
    required String groupUUID,
    required String featureEnglishName,
    required DateTime startTime,
    required DateTime endTime,
    String aggregate = 'raw',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final url = Uri.parse(
      '$baseUrl/odata/api/v1-Odata/GroupDevices(\'$groupUUID\')/Observations'
      '?featureEnglishName=$featureEnglishName'
      '&start_time=${DateFormat('yyyy-MM-dd HH:mm:ss').format(startTime)}'
      '&end_time=${DateFormat('yyyy-MM-dd HH:mm:ss').format(endTime)}'
      '&aggregate=$aggregate',
    );

    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['value'];
    } else {
      print('取得 GroupDevice 観測資料失敗: ${response.statusCode}');
      return null;
    }
  }

  /// 查詢時間排程
  Future<List<dynamic>?> fetchschedule(
    String token,
    String deviceUUID,
    String serial_id,
  ) async {
    final url = Uri.parse(
      '$baseUrl/odata/api/v1-Odata/schedule/$deviceUUID/$serial_id/',
    );
    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['schedules'];
    } else {
      print('取得 schedule 失敗: ${response.statusCode}');
      return null;
    }
  }

  Future<Map<String, dynamic>> scheduleAdd({
    required String token,
    required String deviceUUID,
    required String featureEnglishName,
    required int serialId,
    required String action,
    required String time,
    required List<String> weekdays,
  }) async {
    final url = Uri.parse('$baseUrl/odata/api/v1-Odata/schedule/add/');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },

      body: jsonEncode({
        'action': action, // "ON" 或 "OFF"
        'deviceUUID': deviceUUID,
        'enabled': true,
        'featureEnglishName': featureEnglishName,
        'serial_id': serialId,
        'time': time, // "05:00"
        'weekdays': weekdays, // List<String> like ["monday", "tuesday"]
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('新增排程失敗：${response.body}');
    }
  }

  Future<Map<String, dynamic>> scheduleDel({
    required String token,
    required int id,
  }) async {
    final url = Uri.parse('$baseUrl/odata/api/v1-Odata/schedule/delete/');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },

      body: jsonEncode({'id': id}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('刪除排程失敗：${response.body}');
    }
  }

  /// 查詢時間排程
  Future<List<dynamic>?> fetchCondition(
    String token,
    String deviceUUID,
    String serial_id,
  ) async {
    final url = Uri.parse(
      '$baseUrl/odata/api/v1-Odata/condition/$deviceUUID/$serial_id/',
    );
    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['rules'];
    } else {
      print('取得 condition 失敗: ${response.statusCode}');
      return null;
    }
  }

  Future<Map<String, dynamic>> conditionAdd({
    required String token,
    required String deviceUUID,
    required int serialId,
    required String action,
    required List<Map<String, dynamic>> conditions,
  }) async {
    final url = Uri.parse('$baseUrl/odata/api/v1-Odata/condition/add/');
    print({
      'deviceUUID': deviceUUID,
      'serial_id': serialId,
      'action': action,
      'enabled': true,
      'rule_id': null,
      'conditions': conditions,
    });
    final response = await http.post(
      url,
      headers: {'Authorization': token, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'deviceUUID': deviceUUID,
        'serial_id': serialId,
        'action': action,
        'enabled': true,
        'rule_id': null,
        'conditions': conditions,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('新增條件排程失敗：${response.body}');
    }
  }

  Future<Map<String, dynamic>> conditionDel({
    required String token,
    required int id,
  }) async {
    final url = Uri.parse('$baseUrl/odata/api/v1-Odata/condition/delete/');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },

      body: jsonEncode({'id': id}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('刪除排程失敗：${response.body}');
    }
  }

  Future<Map<String, dynamic>?> fetchGroupScore({
    required String groupUUID,
    required String fruit,
    required String disease,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final encodedFruit = Uri.encodeComponent(fruit);
    final encodedDisease = Uri.encodeComponent(disease);

    final url = Uri.parse(
      '$baseUrl/odata/api/v1-Odata/GroupDevices/score/'
      '?groupUUID=$groupUUID'
      '&fruit=$encodedFruit'
      '&disease=$encodedDisease',
    );

    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['data']; // ✅ 只回傳 data 欄位
    } else {
      print('取得病蟲害預測失敗: ${response.statusCode}');
      return null;
    }
  }

  Future<List<dynamic>?> fetchGroupScoreHistory({
    required String groupUUID,
    required String fruit,
    required String disease,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    final encodedFruit = Uri.encodeComponent(fruit);
    final encodedDisease = Uri.encodeComponent(disease);

    final url = Uri.parse(
      '$baseUrl/odata/api/v1-Odata/GroupDevices/score_history/'
      '?groupUUID=$groupUUID'
      '&fruit=$encodedFruit'
      '&disease=$encodedDisease',
    );

    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map && data.containsKey('data') && data['data'] is List) {
        return data['data'] as List;
      }
      return [];
    } else {
      print('取得病蟲害預測失敗: ${response.statusCode}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchNews() async {
    final url = Uri.parse('$baseUrl/odata/api/v1-Odata/news');

    final response = await http.get(
      url,
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data; // ✅ 直接回傳整個 Map
    } else {
      print('取得新聞資料失敗: ${response.statusCode}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchChatgpt({
    required String groupUUID,
    required String fruit,
    required String disease,
    required String score,
  }) async {
    final url = Uri.parse(
      '$baseUrl/odata/api/v1-Odata/chatgpt?groupUUID=$groupUUID&fruit=$fruit&disease=$disease&score=$score',
    );

    final response = await http.get(
      url,
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data; // ✅ 直接回傳整個 Map
    } else {
      print('取得新聞資料失敗: ${response.statusCode}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchImageDetectHistory({
    required DateTime startTime,
    required DateTime endTime,
    required String cameraIp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final url = Uri.parse(
      '$baseUrl/odata/api/v1-Odata/image_detect_history'
      '?start_time=${startTime.toIso8601String()}'
      '&end_time=${endTime.toIso8601String()}'
      '&camera_ip=$cameraIp',
    );

    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 200) {
      try {
        final body = response.body;
        print("原始回應：$body");
        return jsonDecode(response.body);
      } catch (e) {
        print('解析 JSON 失敗: $e');
        print('伺服器回應: ${response.body}');
        return null;
      }
    } else {
      print("取得 image_detect_history 失敗: ${response.statusCode}");
      print("伺服器回應: ${response.body}");
      return null;
    }
  }

  Future<Uint8List?> fetchImageDetectPath({required String path}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    print({"path": path});

    final url = Uri.parse('$baseUrl/odata/api/v1-Odata/image_detect_image');
    final response = await http.post(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
        'Accept': 'image/*', // ✅ 接受圖片格式
      },
      body: jsonEncode({"path": path}),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes; // ✅ 圖片 binary
    } else {
      print("取得圖片失敗 ${response.statusCode}");
      return null;
    }
  }
}
