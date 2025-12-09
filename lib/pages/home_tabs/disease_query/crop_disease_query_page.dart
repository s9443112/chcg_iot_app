import 'package:flutter/material.dart';
import 'package:chcg_iot_app/core/api_service.dart';
import 'package:chcg_iot_app/pages/home_tabs/disease_query/bug_usage_detail_page.dart';

class CropDiseaseQueryPage extends StatefulWidget {
  const CropDiseaseQueryPage({super.key});

  @override
  State<CropDiseaseQueryPage> createState() => _CropDiseaseQueryPageState();
}

class _CropDiseaseQueryPageState extends State<CropDiseaseQueryPage> {
  final _cropController = TextEditingController(text: '火龍果');
  final _diseaseApi = DiseaseApiService();

  bool _loadingFarms = false;
  bool _loadingBugs = false;
  bool _loadingDetail = false;

  List<dynamic> _farmList = []; // GetFarm 回來的 items
  Set<String> _selectedFarmIds = {}; // 使用者勾選的 farmid
  Map<String, dynamic>? _bugListResult; // fetchBugFarmList 的整個 Map
  Map<String, dynamic>? _bugDetail; // fetchBugFarmUserange 的整個 Map

  @override
  void dispose() {
    _cropController.dispose();
    super.dispose();
  }

  Future<void> _searchFarms() async {
    final keyword = _cropController.text.trim();
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入作物名稱關鍵字')),
      );
      return;
    }

    setState(() {
      _loadingFarms = true;
      _farmList = [];
      _selectedFarmIds.clear();
      _bugListResult = null;
      _bugDetail = null;
    });

    try {
      final res = await _diseaseApi.fetchFarms(farm: keyword);
      if (!mounted) return;

      setState(() {
        _farmList = res?['items'] ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('查詢作物代碼失敗：$e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingFarms = false;
        });
      }
    }
  }

  Future<void> _searchBugList() async {
    if (_selectedFarmIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先選擇至少一個作物代碼')),
      );
      return;
    }

    final farmParam = _selectedFarmIds.join(',');

    setState(() {
      _loadingBugs = true;
      _bugListResult = null;
      _bugDetail = null;
    });

    try {
      final res = await _diseaseApi.fetchBugFarmList(farm: farmParam);
      if (!mounted) return;

      setState(() {
        _bugListResult = res;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('查詢病蟲清單失敗：$e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingBugs = false;
        });
      }
    }
  }

    Future<void> _loadBugDetail(Map<String, dynamic> item) async {
    final farmCode = item['farm_code']?.toString();
    final bugCode = item['bug_code']?.toString();
    final cropName = item['crop_name']?.toString() ?? '';
    final bugName = item['bug_name']?.toString() ?? '';

    if (farmCode == null || bugCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('此筆資料缺少 farm_code 或 bug_code')),
      );
      return;
    }

    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => BugUsageDetailPage(
      farmCode: farmCode,
      bugCode: bugCode,
      cropName: item['crop_name'] ?? '',
      bugName: item['bug_name'] ?? '',
    ),
  ),
);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用藥查詢'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCropSearchSection(),
          const SizedBox(height: 16),
          _buildFarmListSection(),
          const Divider(height: 32),
          _buildBugListSection(),
          // const Divider(height: 32),
          // _buildBugDetailSection(),
        ],
      ),
    );
  }

  Widget _buildCropSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. 查詢作物代碼 (GetFarm)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cropController,
                decoration: const InputDecoration(
                  labelText: '作物名稱關鍵字，例如：火龍果、芭樂',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _loadingFarms ? null : _searchFarms,
              child: _loadingFarms
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('查詢'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFarmListSection() {
    if (_loadingFarms) {
      return const SizedBox.shrink();
    }
    if (_farmList.isEmpty) {
      return const Text(
        '尚未查詢或查無作物代碼。',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. 選擇作物代碼（可複選）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._farmList.map((f) {
          final String farmid = (f['farmid'] ?? '').toString().trim();
          final String farmna = (f['farmna'] ?? '').toString();
          final String farmga = (f['farmga'] ?? '').toString();

          final bool selected = _selectedFarmIds.contains(farmid);

          return CheckboxListTile(
            value: selected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedFarmIds.add(farmid);
                } else {
                  _selectedFarmIds.remove(farmid);
                }
              });
            },
            title: Text('$farmna ($farmid)'),
            subtitle: Text(farmga),
            dense: true,
          );
        }).toList(),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _loadingBugs ? null : _searchBugList,
            icon: _loadingBugs
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: const Text('查詢病蟲清單'),
          ),
        ),
      ],
    );
  }

  Widget _buildBugListSection() {
    if (_bugListResult == null) {
      return const Text(
        '尚未查詢病蟲清單。',
        style: TextStyle(color: Colors.grey),
      );
    }

    final items = (_bugListResult?['items'] ?? []) as List<dynamic>;
    if (items.isEmpty) {
      return const Text(
        '查無病蟲清單資料。',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3. 病蟲清單（點擊某一筆查看用藥建議）',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          final String cropName = (item['crop_name'] ?? '').toString();
          final String bugName = (item['bug_name'] ?? '').toString();
          final String bugCode = (item['bug_code'] ?? '').toString();
          final String farmCode = (item['farm_code'] ?? '').toString();

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(bugName),
              subtitle: Text('作物：$cropName\nfarm: $farmCode  / bug: $bugCode'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _loadingDetail ? null : () => _loadBugDetail(item),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBugDetailSection() {
    if (_loadingDetail) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_bugDetail == null) {
      return const Text(
        '尚未選擇病蟲查看用藥建議。',
        style: TextStyle(color: Colors.grey),
      );
    }

    final title = _bugDetail?['title']?.toString() ?? '';
    final summary = _bugDetail?['summary'] as Map<String, dynamic>?;
    final total = summary?['total'];
    final columns = (_bugDetail?['columns'] ?? []) as List<dynamic>;
    final items = (_bugDetail?['items'] ?? []) as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '4. 用藥建議（BugFarmUserange）',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (title.isNotEmpty) Text(title, style: const TextStyle(fontSize: 15)),
        if (total != null)
          Text(
            '符合條件筆數：$total',
            style: const TextStyle(color: Colors.black54),
          ),
        const SizedBox(height: 8),
        // 資料表（橫向可捲動）
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: columns
                .map((c) => DataColumn(
                      label: Text(
                        (c['label'] ?? '').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ))
                .toList(),
            rows: items.map<DataRow>((row) {
              final r = row as Map<String, dynamic>;
              return DataRow(
                cells: columns.map<DataCell>((c) {
                  final key = c['key']?.toString() ?? '';
                  final value = (r[key] ?? '').toString();
                  return DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        value,
                        softWrap: true,
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
