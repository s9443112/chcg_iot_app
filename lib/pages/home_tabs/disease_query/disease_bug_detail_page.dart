import 'package:flutter/material.dart';
import 'package:chcg_iot_app/core/api_service.dart';

/// 單一病害詳細頁：同時使用
/// - fetchAzaiBugDetail (文字說明)
/// - fetchAzaiBugPics (圖片列表)
class AzaiBugDetailPage extends StatefulWidget {
  const AzaiBugDetailPage({
    super.key,
    required this.bugId,
    required this.title, // 中文名稱，從列表帶進來
  });

  final String bugId;
  final String title;

  @override
  State<AzaiBugDetailPage> createState() => _AzaiBugDetailPageState();
}

class _AzaiBugDetailPageState extends State<AzaiBugDetailPage> {
  final DiseaseApiService _api = DiseaseApiService();

  late Future<_BugDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BugDetailData> _load() async {
    final detailRes = await _api.fetchAzaiBugDetail(bugId: widget.bugId);
    final picsRes = await _api.fetchAzaiBugPics(bugId: widget.bugId);

    final detailList = (detailRes?['data'] as List?) ?? const [];
    final picsList = (picsRes?['data'] as List?) ?? const [];

    return _BugDetailData(details: detailList, pics: picsList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // 直接用列表帶進來的中文名
      ),
      body: FutureBuilder<_BugDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('載入失敗：${snapshot.error}'),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('沒有資料'));
          }

          final details = data.details;
          final pics = data.pics;

          // detail 只取第一筆（大部分情況就是 1 筆）
          final detail = details.isNotEmpty
              ? (details.first as Map<String, dynamic>? ?? {})
              : <String, dynamic>{};

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 圖片輪播
                _buildPicsCarousel(pics),

                // 2. 文字區塊
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildDetailSection(detail),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 圖片輪播 (利用 fetchAzaiBugPics 回來的 data)
  Widget _buildPicsCarousel(List<dynamic> pics) {
    if (pics.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('尚無圖片')),
      );
    }

    return SizedBox(
      height: 260,
      child: PageView.builder(
        itemCount: pics.length,
        itemBuilder: (context, index) {
          final item = pics[index] as Map<String, dynamic>? ?? {};
          // 後端回來的 key 你可以依實際調整，例如 'pic', 'image_url'...
          final url = item['pic']?.toString() ??
              item['image_url']?.toString() ??
              '';

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: url.isEmpty
                  ? Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 48,
                        ),
                      ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }

  /// 文字詳細資訊區塊（使用 fetchAzaiBugDetail 的第一筆資料）
  Widget _buildDetailSection(Map<String, dynamic> detail) {
    // 依你 .NET 資料實際欄位來排順序
    const fieldOrder = <String>[
      'CName',     // 中文名稱
      'SName',     // 學名
      'Type',      // 類別：真菌 / 卵菌 / 線蟲...
      'Host',      // 寄主 / 危害作物
      'Harm',      // 危害作物 / 防治對象（簡短）
      'HarmDetail',// 危害詳細描述
      'HarmPart',  // 危害部位
      'Peculiarity', // 特性
      'Property',  // 病原 / 特徵說明
      'Symptom',   // 症狀
      'Biology',   // 生態 / 生活史
      'Measure',   // 防治建議
    ];

    const fieldLabel = <String, String>{
      'CName': '中文名稱',
      'SName': '學名',
      'Type': '類別',
      'Host': '寄主 / 危害作物',
      'Harm': '危害作物 / 防治對象',
      'HarmDetail': '危害情形',
      'HarmPart': '危害部位',
      'Peculiarity': '特性',
      'Property': '病原特性',
      'Symptom': '症狀特徵',
      'Biology': '生活史 / 生態',
      'Measure': '防治建議',
    };

    final widgets = <Widget>[];

    // 上面有一排儲存 chip 的資訊（例如 Type）
    final type = (detail['Type'] ?? '').toString().trim();
    if (type.isNotEmpty) {
      widgets.add(
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Chip(
              label: Text(type),
              backgroundColor: Colors.green.shade50,
              labelStyle: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    for (final key in fieldOrder) {
      final raw = detail[key];
      if (raw == null) continue;
      final text = raw.toString().trim();
      if (text.isEmpty) continue;

      // CName 已經放在 AppBar 了，可以略過或當作第一行標題
      if (key == 'CName') continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fieldLabel[key] ?? key,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(const Text('尚無詳細文字說明'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

/// 用來同時存放 detail / pics 兩個 API 的資料
class _BugDetailData {
  final List<dynamic> details;
  final List<dynamic> pics;

  _BugDetailData({
    required this.details,
    required this.pics,
  });
}
