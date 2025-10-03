import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart'; // 引入 PDF 套件

class NewsDetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String content;
  final String? pdfPath;

  const NewsDetailPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
    this.pdfPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新聞詳情'),
        backgroundColor: const Color(0xFF7B4DBB),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),

          if (pdfPath != null) ...[
            const SizedBox(height: 24),
            const Text(
              '相關附件',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 400,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PDFViewerPage(assetPath: pdfPath!),
                    ),
                  );
                },
                child: AbsorbPointer(
                  // 不讓使用者在預覽頁互動
                  child: PDF().fromAsset(pdfPath!),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PDFViewerPage extends StatelessWidget {
  final String assetPath;

  const PDFViewerPage({super.key, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF 檢視'),
        backgroundColor: const Color(0xFF7B4DBB),
        foregroundColor: Colors.white,
      ),
      body: const PDF().fromAsset(assetPath),
    );
  }
}
