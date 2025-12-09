import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:chcg_iot_app/core/api_service.dart';

class ObservationHistoryPage extends StatefulWidget {
  final String deviceUUID;
  final String featureEnglishName;
  final String serialId;
  final String alias;
  final String deviceFeatureName;

  const ObservationHistoryPage({
    super.key,
    required this.deviceUUID,
    required this.featureEnglishName,
    required this.serialId,
    required this.alias,
    required this.deviceFeatureName,
  });

  @override
  State<ObservationHistoryPage> createState() => _ObservationHistoryPageState();
}

class _ObservationHistoryPageState extends State<ObservationHistoryPage> {
  late DateTime startTime;
  late DateTime endTime;
  String aggregate = 'raw';
  List<_ChartData> chartData = [];
  bool isLoading = false;
  bool _ascending = true; // ✅ 表格排序：true = 正序、false = 倒序

  final apiService = ApiService();
  late TooltipBehavior _tooltipBehavior;

  static const deepBlue = Color(0xFF7B4DBB);

  // 數值格式（最多 6 小數位，去掉尾巴多餘 0）
  final NumberFormat _numFmt = NumberFormat('0.######');
  String _fmtValue(double v) => _numFmt.format(v);

  @override
  void initState() {
    super.initState();
    _setDefaultTimeRange();
    _fetchData();
    _tooltipBehavior = TooltipBehavior(enable: true, header: '');
  }

  void _setDefaultTimeRange() {
    final now = DateTime.now();
    if (aggregate == 'raw') {
      startTime = DateTime(now.year, now.month, now.day, 0, 0, 0);
      endTime = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (aggregate == 'hours') {
      startTime = now.subtract(const Duration(days: 7));
      endTime = now;
    } else if (aggregate == 'days') {
      startTime = DateTime(now.year, now.month - 3, now.day);
      endTime = now;
    } else if (aggregate == 'months') {
      startTime = DateTime(now.year - 1, now.month, now.day);
      endTime = now;
    }
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);

    final data = await apiService.fetchObservationRawData(
      deviceUUID: widget.deviceUUID,
      featureEnglishName: widget.featureEnglishName,
      serialId: widget.serialId,
      startTime: startTime,
      endTime: endTime,
      aggregate: aggregate,
    );

    if (!mounted) return;

    if (data != null) {
      final List<_ChartData> loaded = data.map<_ChartData>((item) {
        final rawValue = item['value'];
        double parsedValue;

        if (rawValue.toString().toLowerCase() == 'true') {
          parsedValue = 1.0;
        } else if (rawValue.toString().toLowerCase() == 'false') {
          parsedValue = 0.0;
        } else {
          parsedValue = double.tryParse(rawValue.toString()) ?? 0.0;
        }

        return _ChartData(DateTime.parse(item['time']), parsedValue);
      }).toList();

      // 圖表用「時間正序」
      loaded.sort((a, b) => a.time.compareTo(b.time));

      setState(() {
        chartData = loaded;
        isLoading = false;
      });
    } else {
      setState(() {
        chartData = [];
        isLoading = false;
      });
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? startTime : endTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          startTime = DateTime(date.year, date.month, date.day, 0, 0, 0);
        } else {
          endTime = DateTime(date.year, date.month, date.day, 23, 59, 59);
        }
      });
    }
  }

  /// ✅ 表格：固定高度，內部可捲動，支援正序 / 倒序
  Widget _buildDataTable() {
    if (chartData.isEmpty) return const SizedBox.shrink();

    // 欄位比例（你可微調 6/4 → 7/3 或 5/5）
    const int timeFlex = 6;
    const int valueFlex = 4;

    // 根據排序選擇要顯示的資料順序
    final List<_ChartData> dataToShow =
        _ascending ? chartData : chartData.reversed.toList();

    return SizedBox(
      height: 260, // 固定高度，內部垂直捲動
      child: Column(
        children: [
          // 表頭 + 排序控制
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  flex: timeFlex,
                  child: Text(
                    '時間',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  flex: valueFlex,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        '數值',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _ascending = !_ascending;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: deepBlue.withOpacity(0.05),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _ascending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 16,
                                color: deepBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _ascending ? '時間正序' : '時間倒序',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
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
          ),
          const Divider(height: 1),

          // 內容（可捲動）
          Expanded(
            child: ListView.separated(
              itemCount: dataToShow.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = dataToShow[i];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: timeFlex,
                        child: Text(
                          DateFormat('MM/dd HH:mm:ss').format(e.time),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                      Expanded(
                        flex: valueFlex,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(_fmtValue(e.value)),
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

  @override
  Widget build(BuildContext context) {
    final alias = widget.alias;
    final deviceFeatureName = widget.deviceFeatureName;
    final featureName =
        alias.isNotEmpty ? alias : (deviceFeatureName ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$featureName · 歷史資料',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF6F6F8),
      body: Column(
        children: [
          // 🔧 條件區塊
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickDate(true),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: deepBlue),
                              foregroundColor: deepBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              '開始\n${DateFormat('yyyy-MM-dd').format(startTime)}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickDate(false),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: deepBlue),
                              foregroundColor: deepBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              '結束\n${DateFormat('yyyy-MM-dd').format(endTime)}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: aggregate,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  aggregate = value;
                                  _setDefaultTimeRange();
                                });
                                _fetchData();
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                  value: 'raw', child: Text('原始資料')),
                              DropdownMenuItem(
                                  value: 'hours', child: Text('小時平均')),
                              DropdownMenuItem(
                                  value: 'days', child: Text('天平均')),
                              DropdownMenuItem(
                                  value: 'months', child: Text('月平均')),
                            ],
                            decoration: const InputDecoration(
                              labelText: '統計區間',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _fetchData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: deepBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          child: const Text('查詢'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 📈 圖表 + 📊 表格區塊（可捲動）
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : chartData.isEmpty
                    ? const Center(child: Text('查無資料'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 圖表 Card（高度較大）
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  height: 320, // ✅ 圖表高度放大
                                  child: SfCartesianChart(
                                    primaryXAxis: DateTimeAxis(
                                      intervalType: DateTimeIntervalType.auto,
                                      dateFormat: DateFormat('MM/dd HH:mm'),
                                      majorGridLines:
                                          const MajorGridLines(width: 0.5),
                                    ),
                                    primaryYAxis: const NumericAxis(
                                      majorGridLines: MajorGridLines(width: 0.5),
                                    ),
                                    zoomPanBehavior: ZoomPanBehavior(
                                      enablePinching: true,
                                      enablePanning: true,
                                      enableDoubleTapZooming: true,
                                    ),
                                    tooltipBehavior: _tooltipBehavior,
                                    series: <CartesianSeries<_ChartData, DateTime>>[
                                      LineSeries<_ChartData, DateTime>(
                                        name: '數值',
                                        color: deepBlue,
                                        dataSource: chartData,
                                        xValueMapper: (_ChartData d, _) => d.time,
                                        yValueMapper: (_ChartData d, _) => d.value,
                                        markerSettings: const MarkerSettings(
                                          isVisible: false,
                                        ),
                                        dataLabelSettings:
                                            const DataLabelSettings(
                                          isVisible: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 摘要 + 表格
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    12, 10, 12, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '共 ${chartData.length} 筆資料',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '時間範圍：'
                                      '${DateFormat('MM/dd HH:mm').format(chartData.first.time)} - '
                                      '${DateFormat('MM/dd HH:mm').format(chartData.last.time)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDataTable(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final DateTime time;
  final double value;
  _ChartData(this.time, this.value);
}
