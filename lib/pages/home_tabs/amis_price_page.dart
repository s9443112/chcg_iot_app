import 'package:flutter/material.dart';
import 'package:chcg_iot_app/core/api_service.dart';

import 'package:syncfusion_flutter_charts/charts.dart';
const Color _primaryColor = Color(0xFF7B4DBB);


class HistoryPoint {
  final DateTime date;
  final double avgPrice;
  final String market;

  HistoryPoint(this.date, this.avgPrice, this.market);
}

/// 最外層頁面：只在這裡打一次 API，
/// 把三種行情資料丟給下方三個 Tab 使用
class AgriMarketPage extends StatefulWidget {
  const AgriMarketPage({super.key});

  @override
  State<AgriMarketPage> createState() => _AgriMarketPageState();
}

class _AgriMarketPageState extends State<AgriMarketPage> {
  final api = ApiService();

  bool loading = true;
  String? error;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  Future<void> fetchAll() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await api.fetchAmis();
      setState(() {
        data = res ?? {};
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = '取得農產品行情失敗：$e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          title: const Text(
            '農產品行情',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: '蔬菜行情'),
              Tab(text: '水果行情'),
              Tab(text: '花卉行情'),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFF4F3FA),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 44, color: Colors.red.shade400),
                          const SizedBox(height: 10),
                          Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _primaryColor,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            onPressed: fetchAll,
                            icon: const Icon(Icons.refresh),
                            label: const Text(
                              '重新整理',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    children: [
                      AmisCategoryTab(
                        plantType: 'Veg',
                        items: (data?['amis_veg_today'] as List?) ?? const [],
                      ),
                      AmisCategoryTab(
                        plantType: 'Fruit',
                        items:
                            (data?['amis_fruit_today'] as List?) ?? const [],
                      ),
                      AmisCategoryTab(
                        plantType: 'Flower',
                        items:
                            (data?['amis_flower_today'] as List?) ?? const [],
                      ),
                    ],
                  ),
      ),
    );
  }
}

/// 單一類別行情 Tab（蔬菜 / 水果 / 花卉共用）
/// 不再打 API，只吃父層傳進來的 items
class AmisCategoryTab extends StatefulWidget {
  final String plantType;          // Veg / Fruit / Flower
  final List<dynamic> items;

  const AmisCategoryTab({
    super.key,
    required this.plantType,
    required this.items,
  });

  @override
  State<AmisCategoryTab> createState() => _AmisCategoryTabState();
}

class _AmisCategoryTabState extends State<AmisCategoryTab> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];

  List<String> _marketOptions = [];
  List<String> _productOptions = [];

  String? _selectedMarket;
  String? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initData() {
    final items = widget.items
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // 排序：先市場，再產品
    items.sort((a, b) {
      final mA = (a['市場'] ?? '').toString();
      final mB = (b['市場'] ?? '').toString();
      final pA = (a['產品'] ?? '').toString();
      final pB = (b['產品'] ?? '').toString();
      final m = mA.compareTo(mB);
      return m != 0 ? m : pA.compareTo(pB);
    });

    final markets = items
        .map((e) => (e['市場'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final products = items
        .map((e) => (e['產品'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    _allItems = items;
    _marketOptions = markets;
    _productOptions = products;

    _applyFilter(); // 初始化一次
  }

  void _applyFilter() {
    final search = _searchCtrl.text.trim();

    List<Map<String, dynamic>> list = List.from(_allItems);

    if (_selectedMarket != null && _selectedMarket!.isNotEmpty) {
      list = list
          .where((e) => e['市場']?.toString() == _selectedMarket)
          .toList();
    }

    if (_selectedProduct != null && _selectedProduct!.isNotEmpty) {
      list = list
          .where((e) => e['產品']?.toString() == _selectedProduct)
          .toList();
    }

    if (search.isNotEmpty) {
      final lower = search.toLowerCase();
      list = list.where((e) {
        final m = (e['市場'] ?? '').toString().toLowerCase();
        final p = (e['產品'] ?? '').toString().toLowerCase();
        return m.contains(lower) || p.contains(lower);
      }).toList();
    }

    setState(() {
      _filteredItems = list;
    });
  }

  void _clearFilter() {
    setState(() {
      _selectedMarket = null;
      _selectedProduct = null;
      _searchCtrl.clear();
    });
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterCard(),
        const SizedBox(height: 4),
        _buildResultHeader(),
        const SizedBox(height: 4),
        Expanded(
          child: _filteredItems.isEmpty
              ? const Center(
                  child: Text(
                    '目前查無符合條件的行情資料。',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return _buildPriceCard(item);
                  },
                ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            '資料來源：農產品批發市場交易行情站',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  /// 上方篩選卡片：市場 / 產品 / 搜尋
  Widget _buildFilterCard() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.filter_list_rounded,
                    size: 22, color: _primaryColor),
                SizedBox(width: 6),
                Text(
                  '篩選條件',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedMarket,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: '選擇市場',
                      labelStyle: const TextStyle(fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('全部市場'),
                      ),
                      ..._marketOptions.map(
                        (m) => DropdownMenuItem<String?>(
                          value: m,
                          child: Text(
                            m,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      _selectedMarket = val;
                      _applyFilter();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedProduct,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: '選擇產品',
                      labelStyle: const TextStyle(fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('全部產品'),
                      ),
                      ..._productOptions.map(
                        (p) => DropdownMenuItem<String?>(
                          value: p,
                          child: Text(
                            p,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      _selectedProduct = val;
                      _applyFilter();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      labelText: '搜尋市場 / 產品關鍵字',
                      labelStyle: const TextStyle(fontSize: 14),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 15),
                    onSubmitted: (_) => _applyFilter(),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _clearFilter,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: const BorderSide(color: _primaryColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    '清除',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 顯示「共幾筆」的提示列
  Widget _buildResultHeader() {
    final total = _filteredItems.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '共 $total 筆行情',
              style: const TextStyle(
                fontSize: 14,
                color: _primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '價格與交易量數值為昨日批發市場資料，僅供參考。',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 單張行情卡片（點擊會跳到歷史行情頁）
  Widget _buildPriceCard(Map<String, dynamic> item) {
    final market = (item['市場'] ?? '').toString();
    final product = (item['產品'] ?? '').toString();
    final high = (item['上價'] ?? '').toString();
    final mid = (item['中價'] ?? '').toString();
    final low = (item['下價'] ?? '').toString();
    final avg = (item['平均價_元每公斤'] ?? '').toString();
    final priceDelta = (item['價格較前一日_百分比'] ?? '').toString();
    final volume = (item['交易量_公斤'] ?? '').toString();
    final volumeDelta = (item['交易量較前一日_百分比'] ?? '').toString();

    // 從 "11 椰子" 拆出 "11" 當 plant_code
    String plantCode = '';
    if (product.isNotEmpty) {
      plantCode = product.split(' ').first;
    }

    // 漲跌顏色
    Color deltaColor = Colors.grey;
    Color deltaBg = Colors.grey.withOpacity(0.1);
    IconData deltaIcon = Icons.horizontal_rule;

    if (priceDelta.contains('+')) {
      deltaColor = Colors.red.shade600;
      deltaBg = Colors.red.shade50;
      deltaIcon = Icons.trending_up;
    } else if (priceDelta.contains('-')) {
      deltaColor = Colors.green.shade700;
      deltaBg = Colors.green.shade50;
      deltaIcon = Icons.trending_down;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (plantCode.isEmpty) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AmisProductDetailPage(
              plantType: widget.plantType,
              plantCode: plantCode,
              productName: product,
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 上排：產品 + 市場
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      market,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 中間：平均價 + 上/中/下
              Row(
                children: [
                  // 平均價
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '平均價（元/公斤）',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        avg,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '上：$high   中：$mid   下：$low',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: deltaBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(deltaIcon, size: 18, color: deltaColor),
                            const SizedBox(width: 4),
                            Text(
                              '價較前一日：$priceDelta%',
                              style: TextStyle(
                                fontSize: 13,
                                color: deltaColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(height: 12),

              // 下排：交易量
              Row(
                children: [
                  Icon(Icons.scale_outlined,
                      size: 20, color: Colors.grey.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '交易量：$volume 公斤',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '量較前一日：$volumeDelta%',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// 將西元日期轉成民國格式：114/12/09
String formatToRoc(DateTime dt) {
  final rocYear = dt.year - 1911;
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$rocYear/$m/$d';
}



class AmisProductDetailPage extends StatefulWidget {
  final String plantType;  // Veg / Fruit / Flower
  final String plantCode;  // 例如 "11"
  final String productName; // 顯示用，例如 "11 椰子"

  const AmisProductDetailPage({
    super.key,
    required this.plantType,
    required this.plantCode,
    required this.productName,
  });

  @override
  State<AmisProductDetailPage> createState() => _AmisProductDetailPageState();
}

class _AmisProductDetailPageState extends State<AmisProductDetailPage> {
  final api = ApiService();

  bool _loading = false;
  String? _error;

  // 歷史資料（列表 + 圖表共用）
  List<Map<String, dynamic>> _historyItems = [];

  // 日期範圍（預設近 7 天）
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 7));
    _fetchHistory();
  }

  /// 西元日期 → ROC 114/12/09 格式
  String _formatToRoc(DateTime dt) {
    final y = dt.year - 1911;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: '選擇查詢日期區間',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchHistory();
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final startStr = _formatToRoc(_startDate);
      final endStr = _formatToRoc(_endDate);

      final res = await api.fetchAmisHistory(
        widget.plantType,
        widget.plantCode,
        startStr,
        endStr,
      );

      // ⚠️ 這裡用你實際的 JSON 結構：data:[ {...}, {...} ]
      final list = (res?['data'] ?? []) as List<dynamic>;

      setState(() {
        _historyItems =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (e) {
      setState(() {
        _error = '取得歷史行情失敗：$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F3FA),
        appBar: AppBar(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          title: Text(
            widget.productName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: '每日歷史行情'),
              Tab(text: '價格趨勢圖'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildDateRangeBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : TabBarView(
                          children: [
                            _buildHistoryListTab(),
                            _buildChartTab(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// 上方日期區塊（兩個 tab 共用）
  Widget _buildDateRangeBar() {
    final style = const TextStyle(fontSize: 14);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 18, color: _primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '查詢區間：${_formatToRoc(_startDate)} ～ ${_formatToRoc(_endDate)}',
              style: style,
            ),
          ),
          TextButton(
            onPressed: _pickDateRange,
            child: const Text('變更日期'),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44, color: Colors.red.shade400),
            const SizedBox(height: 10),
            Text(
              _error ?? '發生錯誤',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _primaryColor,
              ),
              onPressed: _fetchHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('重新整理'),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ Tab1：每日歷史行情列表 ------------------

  Widget _buildHistoryListTab() {
    if (_historyItems.isEmpty) {
      return const Center(
        child: Text(
          '此區間內暫無行情資料。',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }

    final reversed = _historyItems.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: _historyItems.length,
      itemBuilder: (_, i) => _buildHistoryCard(reversed[i]),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final date = (item['日期'] ?? '').toString();
    final market = (item['市場'] ?? '').toString();
    final product = (item['產品'] ?? '').toString();

    final high = (item['上價'] ?? '').toString();
    final mid = (item['中價'] ?? '').toString();
    final low = (item['下價'] ?? '').toString();
    final avg = (item['平均價_元每公斤'] ?? '').toString();

    final priceDelta = (item['價格較前一日_百分比'] ?? '').toString();
    final volume = (item['交易量_公斤'] ?? '').toString();
    final volumeDelta = (item['交易量較前一日_百分比'] ?? '').toString();

    Color deltaColor = Colors.grey;
    Color deltaBg = Colors.grey.withOpacity(0.1);
    IconData deltaIcon = Icons.horizontal_rule;

    if (priceDelta.contains('+')) {
      deltaColor = Colors.red.shade600;
      deltaBg = Colors.red.shade50;
      deltaIcon = Icons.trending_up;
    } else if (priceDelta.contains('-')) {
      deltaColor = Colors.green.shade700;
      deltaBg = Colors.green.shade50;
      deltaIcon = Icons.trending_down;
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期 + 市場
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    market,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              product,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '平均價（元/公斤）',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      avg,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '上：$high   中：$mid   下：$low',
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: deltaBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(deltaIcon, size: 18, color: deltaColor),
                            const SizedBox(width: 4),
                            Text(
                              '價較前一日：$priceDelta%',
                              style: TextStyle(
                                fontSize: 13,
                                color: deltaColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.scale_outlined,
                    size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Text(
                  '交易量：$volume 公斤',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 12),
                Text(
                  '量較前一日：$volumeDelta%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ Tab2：圖表（依市場分線） ------------------



  /// 解析 ROC 日期字串 → DateTime
  DateTime? _parseRocDate(String s) {
    final parts = s.split('/');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y + 1911, m, d);
  }

 

  Widget _buildChartTab() {
    if (_historyItems.isEmpty) {
      return const Center(
        child: Text(
          '此區間內暫無行情資料，無法繪製圖表。',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }

    // 轉成 chart 用的資料
    final List<HistoryPoint> points = [];
    for (final item in _historyItems) {
      final dateStr = (item['日期'] ?? '').toString();
      final market = (item['市場'] ?? '').toString();
      final avgStr = (item['平均價_元每公斤'] ?? '').toString();

      final dt = _parseRocDate(dateStr);
      final avg = double.tryParse(avgStr.replaceAll(',', '').trim());
      if (dt == null || avg == null) continue;

      points.add(HistoryPoint(dt, avg, market));
    }

    if (points.isEmpty) {
      return const Center(
        child: Text(
          '目前無有效數值可繪製圖表。',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }

    // 依市場分組
    final markets = points.map((p) => p.market).toSet().toList()..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SfCartesianChart(
            title: ChartTitle(text: '價格趨勢（平均價，依市場區分線條）'),
            legend: Legend(isVisible: true),
            primaryXAxis: DateTimeAxis(
              intervalType: DateTimeIntervalType.days,
              majorGridLines: const MajorGridLines(width: 0),
            ),
            primaryYAxis: NumericAxis(
              title: AxisTitle(text: '平均價（元/公斤）'),
            ),
            series: markets.map((m) {
              final dataForMarket =
                  points.where((p) => p.market == m).toList()
                    ..sort((a, b) => a.date.compareTo(b.date));
              return LineSeries<HistoryPoint, DateTime>(
                name: m,
                dataSource: dataForMarket,
                xValueMapper: (p, _) => p.date,
                yValueMapper: (p, _) => p.avgPrice,
                dataLabelSettings:
                    const DataLabelSettings(isVisible: false),
                markerSettings: const MarkerSettings(isVisible: false),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
