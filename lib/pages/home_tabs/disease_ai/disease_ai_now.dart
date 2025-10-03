import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agritalk_iot_app/core/api_service.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';


class DiseaseAINowPage extends StatefulWidget {
  const DiseaseAINowPage({super.key});

  @override
  State<DiseaseAINowPage> createState() => _DiseaseAINowPageState();
}

class _DiseaseAINowPageState extends State<DiseaseAINowPage> {
  final apiService = ApiService();
  final picker = ImagePicker();

  XFile? selectedImage;
  Map<String, dynamic>? analysisResult;
  bool loading = false;
  Uint8List? latestImage;

  Future<void> pickImages() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = pickedFile);
    }
  }

  Future<void> uploadImages() async {
    if (selectedImage == null) return;

    setState(() {
      loading = true;
      analysisResult = null;
    });

    final bytes = await selectedImage!.readAsBytes();
    final fileName = 'upload_${DateTime.now().millisecondsSinceEpoch}.png';

    final result = await apiService.uploadImageDetectNow(
      uploaderName: 'pinhao',
      cameraId: 'person',
      images: [bytes],
      filenames: [fileName],
      analysisPhoto: true,
    );

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('分析失敗，請稍後再試'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        analysisResult = result;
        loading = false;
      });
    }

    final now = DateTime.now();
    final startTime = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endTime = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final res = await apiService.fetchImageDetectHistory(
      startTime: startTime,
      endTime: endTime,
      cameraIp: 'person',
    );

    final results = res?['data']?['results'] ?? [];
    if (results.isNotEmpty) {
      final latest = results.reversed.first;
      final path = latest['file_path'];
      final imageData = await apiService.fetchImageDetectPath(
        path: path,
        tag: 'test',
      );
      if (mounted) {
        setState(() {
          latestImage = imageData;
        });
      }
    }
  }

  void _showFullImage(Uint8List imageData) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Image.memory(imageData),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final status = await Permission.storage.request();
              if (!status.isGranted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('請開啟儲存權限')),
                );
                return;
              }

              final dir = await getExternalStorageDirectory();
              final filePath = '${dir!.path}/detect_${DateTime.now().millisecondsSinceEpoch}.png';
              final file = File(filePath);
              await file.writeAsBytes(imageData);

              if (context.mounted) {
                Navigator.pop(context); // 關閉 dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已儲存至：$filePath')),
                );
              }
            },
            icon: const Icon(Icons.save_alt, color: Colors.white),
            label: const Text('儲存圖片', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('即時影像辨識'),
        backgroundColor: const Color(0xFF7B4DBB),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('選擇圖片'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: uploadImages,
                  icon: const Icon(Icons.upload),
                  label: const Text('開始分析'),
                ),
              ],
            ),
          ),
          if (loading) const LinearProgressIndicator(),
          if (selectedImage != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Image.file(
                File(selectedImage!.path),
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          const Divider(),
          if (latestImage != null)
            GestureDetector(
              onTap: () => _showFullImage(latestImage!),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Image.memory(
                  latestImage!,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          Expanded(
            child: analysisResult == null
                ? const Center(child: Text('尚未分析'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Text('結果：${analysisResult!['message']}'),
                      // Text('分析數量：${analysisResult!['total_images']}'),
                      // const SizedBox(height: 12),
                      ...List.generate(
                        (analysisResult!['results'] as List).length,
                        (index) {
                          final item = analysisResult!['results'][index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('相機：${item['camera_id']}'),
                                  Text('分析訊息：${item['message']}'),
                                  Text('儲存筆數：${item['records_saved']}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}