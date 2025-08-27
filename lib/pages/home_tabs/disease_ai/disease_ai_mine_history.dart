import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:agritalk_iot_app/core/api_service.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class DiseaseAIMinePage extends StatefulWidget {
  const DiseaseAIMinePage({super.key});

  @override
  State<DiseaseAIMinePage> createState() => _DiseaseAIPageState();
}

class _DiseaseAIPageState extends State<DiseaseAIMinePage> {
  final apiService = ApiService();
  List<dynamic> results = [];
  bool loading = true;

  DateTime selectedDate = DateTime.now();

  final Map<String, Uint8List?> _imageCache = {}; // ✅ 圖片快取

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    setState(() => loading = true);

    final startTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      0,
      0,
      0,
    );
    final endTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      23,
      59,
      59,
    );

    final res = await apiService.fetchImageDetectHistory(
      startTime: startTime,
      endTime: endTime,
      cameraIp: 'person',
    );

    if (mounted) {
      setState(() {
        results = res?['data']?['results'] ?? [];
        _imageCache.clear();
        loading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
      fetchHistory();
    }
  }

  Future<void> _showFullImage(Uint8List imageData, String fileName) async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InteractiveViewer(
              child: Image.memory(imageData),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _saveImage(imageData, fileName),
              icon: const Icon(Icons.download),
              label: const Text("儲存圖片"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveImage(Uint8List data, String fileName) async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      final dir = await getExternalStorageDirectory();
      final path = '${dir?.path}/$fileName';
      final file = File(path);
      await file.writeAsBytes(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('圖片已儲存'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('儲存圖片需要權限'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("白粉病 AI 檢測紀錄"),
        backgroundColor: const Color(0xFF065B4C),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _selectDate,
                  child: Text(
                    '查詢日期：${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                    ? const Center(child: Text("目前沒有資料"))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = results[index];
                          final filePath = item['file_path'] ?? '';
                          final uploadTime = item['upload_time'] ?? '';
                          final lesionArea = item['lesion_area'] ?? 0;
                          final leafArea = item['leaf_area'] ?? 0;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: FutureBuilder<Uint8List?>(
                                    future: _loadImage(filePath),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Container(
                                          height: 180,
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      } else if (snapshot.hasData) {
                                        return GestureDetector(
                                          onTap: () => _showFullImage(
                                            snapshot.data!,
                                            filePath.split('/').last,
                                          ),
                                          child: Image.memory(
                                            snapshot.data!,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      } else {
                                        return Container(
                                          height: 180,
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(Icons.broken_image),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("上傳時間：${_formatDateTime(uploadTime)}"),
                                      const SizedBox(height: 6),
                                      Text("葉面積：${leafArea.toStringAsFixed(2)}"),
                                      Text(
                                        "病斑面積：${lesionArea.toStringAsFixed(2)}",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _loadImage(String path) async {
    if (_imageCache.containsKey(path)) {
      return _imageCache[path];
    } else {
      final data = await apiService.fetchImageDetectPath(path: path, tag: 'test');
      if (data != null) _imageCache[path] = data;
      return data;
    }
  }

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('yyyy/MM/dd HH:mm:ss').format(dt);
    } catch (_) {
      return raw;
    }
  }
}
