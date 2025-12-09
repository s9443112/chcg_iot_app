import 'package:flutter/material.dart';
import 'package:chcg_iot_app/core/api_service.dart';

class BugUsageDetailPage extends StatefulWidget {
  final String farmCode;
  final String bugCode;
  final String cropName;
  final String bugName;

  const BugUsageDetailPage({
    super.key,
    required this.farmCode,
    required this.bugCode,
    required this.cropName,
    required this.bugName,
  });

  @override
  State<BugUsageDetailPage> createState() => _BugUsageDetailPageState();
}

class _BugUsageDetailPageState extends State<BugUsageDetailPage> {
  final _diseaseApi = DiseaseApiService();

  bool _loading = true;
  Map<String, dynamic>? _data;
  String? _error;

  static const Color _primaryColor = Color(0xFF7B4DBB);

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _diseaseApi.fetchBugFarmUserange(
        farm: widget.farmCode,
        bug: widget.bugCode,
      );

      if (!mounted) return;
      if (res == null) {
        setState(() {
          _error = '查無資料';
          _loading = false;
        });
        return;
      }

      setState(() {
        _data = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '查詢失敗：$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = "${widget.cropName} - ${widget.bugName}";

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: Text(
          titleText,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 40, color: Colors.red.shade400),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                    onPressed: _fetchDetail,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      '重新整理',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_data == null) {
      return const Center(child: Text('沒有可顯示的資料'));
    }

    final title = _data?['title']?.toString() ?? '';
    final summary = _data?['summary'] as Map<String, dynamic>?;
    final total = summary?['total'];
    final columns = (_data?['columns'] ?? []) as List<dynamic>;
    final items = (_data?['items'] ?? []) as List<dynamic>;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildSummaryCard(title: title, total: total),
          const SizedBox(height: 12),
          Expanded(
            child: _buildBeautifulTable(columns: columns, items: items),
          ),
        ],
      ),
    );
  }

  /// 上方摘要卡片（顯示作物＋病蟲名稱，不再顯示 farm / bug code）
  Widget _buildSummaryCard({required String title, required dynamic total}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_florist, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 主標題：如果 API 有 title 就用；否則用「作物 + 病蟲」
                  Text(
                    title.isNotEmpty
                        ? title
                        : '${widget.cropName} - ${widget.bugName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 額外資訊：作物名稱 / 病蟲名稱
                  Text(
                    '作物：${widget.cropName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '病蟲：${widget.bugName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  if (total != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '符合條件筆數：$total',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  const Text(
                    '以下為官方建議用藥與使用方式，實際仍請依標示與專業人員指導為準。',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 美化後的表格：有顏色表頭、斑馬線、可橫向捲動
  Widget _buildBeautifulTable({
    required List<dynamic> columns,
    required List<dynamic> items,
  }) {
    if (items.isEmpty) {
      return const Center(
        child: Text('查無用藥資料', style: TextStyle(color: Colors.grey)),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTableTheme(
              data: DataTableThemeData(
                headingRowColor:
                    MaterialStateProperty.all(_primaryColor), // 紫色表頭
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                dataRowColor: MaterialStateProperty.resolveWith(
                  (states) {
                    if (states.contains(MaterialState.selected)) {
                      return const Color(0xFFEDE7F6); // 淺紫
                    }
                    return Colors.white;
                  },
                ),
                dataTextStyle: const TextStyle(fontSize: 13),
                dividerThickness: 0.5,
              ),
              child: DataTable(
                columnSpacing: 16,
                horizontalMargin: 12,
                headingRowHeight: 40,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 80,
                columns: columns
                    .map(
                      (c) => DataColumn(
                        label: SizedBox(
                          width: 120, // 控制欄寬，避免太擠
                          child: Text(
                            (c['label'] ?? '').toString(),
                            softWrap: true,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                rows: List<DataRow>.generate(
                  items.length,
                  (index) {
                    final row = items[index] as Map<String, dynamic>;
                    final bool isEven = index % 2 == 0;

                    return DataRow.byIndex(
                      index: index,
                      color: MaterialStateProperty.all(
                        isEven ? const Color(0xFFF7F5FF) : Colors.white,
                      ),
                      cells: columns.map<DataCell>((c) {
                        final key = c['key']?.toString() ?? '';
                        final value = (row[key] ?? '').toString();

                        // 把比較重要的欄位稍微強調（依實際 key 再調整）
                        final isImportant = key == 'dose_per_hectare' ||
                            key == 'dilution_factor' ||
                            key == 'usage_timing' ||
                            key == 'pre_harvest_interval';

                        return DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 80,
                              maxWidth: 160,
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                value.isEmpty ? '-' : value,
                                softWrap: true,
                                style: TextStyle(
                                  fontWeight: isImportant
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isImportant
                                      ? const Color(0xFF4A148C)
                                      : Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
