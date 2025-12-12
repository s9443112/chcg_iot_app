import 'package:flutter/material.dart';
import 'package:chcg_iot_app/core/api_service.dart';

// 引入獨立的詳細頁檔案
import 'package:chcg_iot_app/pages/home_tabs/amis_product_detail_page.dart';

const Color _primaryColor = Color(0xFF7B4DBB);

// 排序欄位：市場 or 產品
enum _SortField { market, product }

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
  final String plantType; // Veg / Fruit / Flower
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

  // 排序欄位＆方向
  _SortField _sortField = _SortField.market;
  bool _sortAsc = true;

  // 篩選區是否展開
  bool _filterExpanded = false; // 預設收合，想要一進來就展開就改成 true

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

  void _sortList(List<Map<String, dynamic>> list) {
    int cmp(String a, String b) => a.compareTo(b);

    list.sort((a, b) {
      final mA = (a['市場'] ?? '').toString();
      final mB = (b['市場'] ?? '').toString();
      final pA = (a['產品'] ?? '').toString();
      final pB = (b['產品'] ?? '').toString();

      int result;
      if (_sortField == _SortField.market) {
        result = cmp(mA, mB);
        if (result == 0) result = cmp(pA, pB);
      } else {
        result = cmp(pA, pB);
        if (result == 0) result = cmp(mA, mB);
      }
      return _sortAsc ? result : -result;
    });
  }

  void _applyFilter() {
    final search = _searchCtrl.text.trim();

    List<Map<String, dynamic>> list = List.from(_allItems);

    if (_selectedMarket != null && _selectedMarket!.isNotEmpty) {
      list =
          list.where((e) => e['市場']?.toString() == _selectedMarket).toList();
    }

    if (_selectedProduct != null && _selectedProduct!.isNotEmpty) {
      list =
          list.where((e) => e['產品']?.toString() == _selectedProduct).toList();
    }

    if (search.isNotEmpty) {
      final lower = search.toLowerCase();
      list = list.where((e) {
        final m = (e['市場'] ?? '').toString().toLowerCase();
        final p = (e['產品'] ?? '').toString().toLowerCase();
        return m.contains(lower) || p.contains(lower);
      }).toList();
    }

    _sortList(list);

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

  /// 上方篩選卡片：市場 / 產品 / 搜尋（可收合）
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
            // 標題 + 展開/收合按鈕
            Row(
              children: [
                const Icon(Icons.filter_list_rounded,
                    size: 22, color: _primaryColor),
                const SizedBox(width: 6),
                const Text(
                  '篩選條件',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _filterExpanded = !_filterExpanded;
                    });
                  },
                  icon: Icon(
                    _filterExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: _primaryColor,
                  ),
                  label: Text(
                    _filterExpanded ? '收合條件' : '展開條件',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _primaryColor,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),

            // ↓ 這塊用 AnimatedCrossFade 收起/展開 ↓
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _filterExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _selectedMarket,
                          isDense: true,
                          isExpanded: true,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                          isExpanded: true,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 10),
                  // 排序控制列
                  Row(
                    children: [
                      const Text(
                        '排序：',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('市場'),
                        selected: _sortField == _SortField.market,
                        onSelected: (_) {
                          setState(() {
                            _sortField = _SortField.market;
                          });
                          _applyFilter();
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('產品'),
                        selected: _sortField == _SortField.product,
                        onSelected: (_) {
                          setState(() {
                            _sortField = _SortField.product;
                          });
                          _applyFilter();
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: _sortAsc ? '升冪排序' : '降冪排序',
                        onPressed: () {
                          setState(() {
                            _sortAsc = !_sortAsc;
                          });
                          _applyFilter();
                        },
                        icon: Icon(
                          _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

              // 中間：平均價 + 上/中/下（避免 overflow）
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左側：平均價
                  Expanded(
                    child: Column(
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
                  ),
                  const SizedBox(width: 8),
                  // 右側：上中下 + 價較前一日
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '上：$high   中：$mid   下：$low',
                          textAlign: TextAlign.right,
                          softWrap: true,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
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
                        ),
                      ],
                    ),
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

/// 如果其他地方會用得到就保留
String formatToRoc(DateTime dt) {
  final rocYear = dt.year - 1911;
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$rocYear/$m/$d';
}
