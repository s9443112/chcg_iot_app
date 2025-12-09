import 'package:flutter/material.dart';
import 'package:chcg_iot_app/core/api_service.dart';

class DiseaseSearchPage extends StatefulWidget {
  const DiseaseSearchPage({super.key});

  @override
  State<DiseaseSearchPage> createState() => _DiseaseSearchPageState();
}

class _DiseaseSearchPageState extends State<DiseaseSearchPage> {
  final DiseaseApiService _api = DiseaseApiService();
  final TextEditingController _searchController =
      TextEditingController(text: '芭樂');

  bool _loading = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final term = _searchController.text.trim();
    if (term.isEmpty) return;

    setState(() {
      _loading = true;
      _results = [];
    });

    try {
      final res = await _api.searchAzaiBugs(term: term);
      final data = res?['data'];

      if (data is List) {
        setState(() {
          _results = data.whereType<Map<String, dynamic>>().toList();
        });
      } else {
        setState(() {
          _results = [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('搜尋失敗：$e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// 單一病害卡片樣式（類似你截圖那種：左圖右文）
  Widget _buildDiseaseCard(Map<String, dynamic> item) {
    final cName = item['CName']?.toString() ?? '未命名病害';
    final sName = item['SName']?.toString() ?? '';

    // 類別標籤（粉類、真菌、細菌…）
    final typeLabel = item['Type']?.toString() ??
        item['Category']?.toString() ??
        item['Pathogen']?.toString() ??
        '';

    // 危害作物 / 防治對象
    final host = item['Host']?.toString() ??
        item['HostCrop']?.toString() ??
        item['Target']?.toString() ??
        '－';

    // 危害徵狀
    final harm = item['Harm']?.toString() ??
        item['Symptom']?.toString() ??
        '－';

    // 圖片網址
    final picUrl = item['pic']?.toString() ??
        item['image_url']?.toString() ??
        '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 左側圖片
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: picUrl.isNotEmpty
                  ? Image.network(
                      picUrl,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 110,
                          height: 110,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 36,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 110,
                      height: 110,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.bug_report,
                        size: 36,
                        color: Colors.grey,
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            // ✅ 右側文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 標題 + 類別標籤
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          cName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (typeLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            typeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (sName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      sName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // 危害作物/防治對象
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: '危害作物/防治對象：',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: host,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 危害徵狀（最多 2~3 行）
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: '危害徵狀：',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: harm,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
        title: const Text('病害查詢'),
      ),
      body: Column(
        children: [
          // 🔍 搜尋區塊
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: '作物 / 關鍵字',
                      hintText: '例如：火龍果、葡萄、番石榴…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _doSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _doSearch,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('搜尋'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 📋 結果列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(child: Text('尚未搜尋或查無資料'))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];

                          // 之後要做詳細頁可以包一層 InkWell / GestureDetector
                          return _buildDiseaseCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
