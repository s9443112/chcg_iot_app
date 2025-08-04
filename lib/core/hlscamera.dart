import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HlsCameraViewer extends StatefulWidget {
  final String url;

  const HlsCameraViewer({super.key, required this.url});

  @override
  State<HlsCameraViewer> createState() => _MjpegCameraViewerState();
}

class _MjpegCameraViewerState extends State<HlsCameraViewer> {
  late http.Client _client;
  final ValueNotifier<Uint8List?> _frameNotifier = ValueNotifier(null);
  bool _isRunning = true;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _client = http.Client();
    _startStream();
  }

  Future<void> _startStream() async {
    while (_isRunning) {
      try {
        final uri = Uri.parse(widget.url);
        String username = '';
        String password = '';
        String baseUrl = widget.url;

        // 解析帳號密碼
        if (uri.userInfo.isNotEmpty) {
          final parts = uri.userInfo.split(':');
          if (parts.length == 2) {
            username = parts[0];
            password = parts[1];
          }
          baseUrl = '${uri.scheme}://${uri.host}:${uri.port}${uri.path}';
        }

        final request = http.Request('GET', Uri.parse(baseUrl));
        if (username.isNotEmpty && password.isNotEmpty) {
          final auth = base64Encode(utf8.encode('$username:$password'));
          request.headers['Authorization'] = 'Basic $auth';
        }

        final response = await _client.send(request);

        if (response.statusCode == 200) {
          final stream = response.stream;
          final List<int> buffer = [];

          await for (var chunk in stream) {
            if (!_isRunning) break;

            buffer.addAll(chunk);

            // 限制 buffer 最大長度 (2MB)
            if (buffer.length > 2 * 1024 * 1024) {
              buffer.removeRange(0, buffer.length - 1024 * 1024);
            }

            final start = _indexOf(buffer, [0xFF, 0xD8]);
            final end = _indexOf(buffer, [0xFF, 0xD9], start);

            if (start != -1 && end != -1) {
              final imageBytes = buffer.sublist(start, end + 2);
              _frameNotifier.value = Uint8List.fromList(imageBytes);

              // 移除已處理部分
              buffer.removeRange(0, end + 2);
            }
          }
        } else {
          debugPrint('HTTP Error: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Stream error: $e');
      }

      // 🔄 重連間隔 3 秒
      if (_isRunning) {
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }

  int _indexOf(List<int> data, List<int> pattern, [int start = 0]) {
    for (var i = start; i <= data.length - pattern.length; i++) {
      var match = true;
      for (var j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  @override
  void dispose() {
    _isRunning = false;
    _client.close();
    _frameNotifier.dispose();
    _reconnectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: _frameNotifier,
      builder: (context, frame, _) {
        if (frame != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              frame,
              gaplessPlayback: true,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
