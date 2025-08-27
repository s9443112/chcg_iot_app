import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

/// 單一入口：自動判斷是 RTSP 還是 MJPEG
class CameraViewer extends StatelessWidget {
  final String url;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const CameraViewer({
    super.key,
    required this.url,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(url);
    final isRtsp = uri.scheme.toLowerCase() == 'rtsp';
    if (isRtsp) {
      return RtspCameraPlayer(url: url, borderRadius: borderRadius, fit: fit);
    } else {
      return MjpegCameraViewer(url: url, borderRadius: borderRadius, fit: fit);
    }
  }
}

/// ========== MJPEG 播放器（你原本的邏輯，整理與修正） ==========
class MjpegCameraViewer extends StatefulWidget {
  final String url;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const MjpegCameraViewer({
    super.key,
    required this.url,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  State<MjpegCameraViewer> createState() => _MjpegCameraViewerState();
}

class _MjpegCameraViewerState extends State<MjpegCameraViewer> {
  late http.Client _client;
  final ValueNotifier<Uint8List?> _frameNotifier = ValueNotifier(null);
  bool _isRunning = true;

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

        // 解析帳密（http://user:pass@host:port/path）
        if (uri.userInfo.isNotEmpty) {
          final parts = uri.userInfo.split(':');
          if (parts.length == 2) {
            username = parts[0];
            password = parts[1];
          }
          // 若原本 URL 內含帳密，重建無帳密的 baseUrl 以避免 400
          baseUrl = '${uri.scheme}://${uri.host}'
              '${uri.hasPort ? ':${uri.port}' : ''}'
              '${uri.path}'
              '${uri.hasQuery ? '?${uri.query}' : ''}';
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

            final start = _indexOf(buffer, const [0xFF, 0xD8]); // JPEG SOI
            final end = _indexOf(buffer, const [0xFF, 0xD9], start); // JPEG EOI

            if (start != -1 && end != -1) {
              final imageBytes = buffer.sublist(start, end + 2);
              _frameNotifier.value = Uint8List.fromList(imageBytes);

              // 移除已處理部分
              buffer.removeRange(0, end + 2);
            }
          }
        } else {
          debugPrint('MJPEG HTTP Error: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('MJPEG stream error: $e');
      }

      // 重連間隔
      if (_isRunning) {
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }

  int _indexOf(List<int> data, List<int> pattern, [int start = 0]) {
    if (start < 0) return -1;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(8);
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: _frameNotifier,
      builder: (context, frame, _) {
        if (frame != null) {
          return ClipRRect(
            borderRadius: radius,
            child: Image.memory(
              frame,
              gaplessPlayback: true,
              fit: widget.fit,
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

/// ========== RTSP 播放器（用 VLC） ==========
class RtspCameraPlayer extends StatefulWidget {
  final String url;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const RtspCameraPlayer({
    super.key,
    required this.url,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  State<RtspCameraPlayer> createState() => _RtspCameraPlayerState();
}

class _RtspCameraPlayerState extends State<RtspCameraPlayer> {
  late final VlcPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    // VLC 支援 rtsp://user:pass@host:port/...
    _controller = VlcPlayerController.network(
      widget.url,
      hwAcc: HwAcc.full, // 啟用硬體加速
      autoPlay: true,
      options: VlcPlayerOptions(
        // 可依環境調整緩衝，200~1000ms
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(300),
        ]),
        // 強制 TCP（很多攝影機需要）
        extras: [':rtsp-tcp', ':network-caching=300'],
      ),
    );

    _controller.addListener(() {
      if (!_initialized && mounted && _controller.value.isInitialized) {
        setState(() => _initialized = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(8);
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VlcPlayer(
            controller: _controller,
            aspectRatio: 16 / 9, // 可改為自動偵測：_controller.value.aspectRatio
            placeholder: const Center(child: CircularProgressIndicator()),
          ),
          if (!_initialized)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
