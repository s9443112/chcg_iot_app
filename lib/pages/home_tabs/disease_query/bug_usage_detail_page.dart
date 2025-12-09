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
    appBar: AppBar(
      backgroundColor: const Color(0xFF7B4DBB),
      foregroundColor: Colors.white,
      title: Text(
        titleText,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _fetchDetail,
                icon: const Icon(Icons.refresh),
                label: const Text('重新整理'),
              ),
            ],
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
                color: const Color(0xFF7B4DBB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_florist, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isNotEmpty ? title : '${widget.cropName} ${widget.bugName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                  Text(
                    'farm: ${widget.farmCode} ・ bug: ${widget.bugCode}',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
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
                headingRowColor: MaterialStateProperty.all(const Color(0xFF7B4DBB)),
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

                        // 把比較重要的欄位稍微強調
                        final isImportant = key == 'dose_per_hectare' ||
                            key == 'dilution_factor' ||
                            key == 'usage_timing' ||
                            key == 'pre_harvest_interval';

                        return DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 80, maxWidth: 160),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                value.isEmpty ? '-' : value,
                                softWrap: true,
                                style: TextStyle(
                                  fontWeight: isImportant ? FontWeight.w600 : FontWeight.normal,
                                  color: isImportant ? const Color(0xFF4A148C) : Colors.black87,
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
