import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:agritalk_iot_app/core/api_service.dart';

class ObservationHistoryPage extends StatefulWidget {
  final String deviceUUID;
  final String featureEnglishName;
  final String serialId;

  const ObservationHistoryPage({
    super.key,
    required this.deviceUUID,
    required this.featureEnglishName,
    required this.serialId,
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
  final apiService = ApiService();
  late TooltipBehavior _tooltipBehavior;

  static const deepBlue = Color(0xFF065B4C);

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

    if (data != null) {
      final List<_ChartData> loaded =
          data.map<_ChartData>((item) {
            return _ChartData(
              DateTime.parse(item['time']),
              double.tryParse(item['value'].toString()) ?? 0.0,
            );
          }).toList();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '歷史資料',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF065B4C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          DropdownMenuItem(value: 'raw', child: Text('原始資料')),
                          DropdownMenuItem(value: 'hours', child: Text('小時平均')),
                          DropdownMenuItem(value: 'days', child: Text('天平均')),
                          DropdownMenuItem(value: 'months', child: Text('月平均')),
                        ],
                        decoration: const InputDecoration(
                          labelText: '統計區間',
                          border: OutlineInputBorder(),
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
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('查詢'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : chartData.isEmpty
                    ? const Center(child: Text('查無資料'))
                    : SfCartesianChart(
                      primaryXAxis: DateTimeAxis(
                        intervalType: DateTimeIntervalType.auto,
                        dateFormat: DateFormat('yyyy-MM-dd HH:mm:ss'),
                        majorGridLines: const MajorGridLines(width: 0.5),
                      ),
                      primaryYAxis: NumericAxis(
                        majorGridLines: const MajorGridLines(width: 0.5),
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
                          xValueMapper: (_ChartData data, _) => data.time,
                          yValueMapper: (_ChartData data, _) => data.value,
                          markerSettings: const MarkerSettings(
                            isVisible: false,
                          ),
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: false,
                          ),
                        ),
                      ],
                    ),
          ),
          chartData.length != 0 ?
          Text('共 ${chartData.length} 筆資料，時間範圍：${DateFormat('MM/dd HH:mm').format(chartData.first.time)} - ${DateFormat('MM/dd HH:mm').format(chartData.last.time)}'):Text("無資料")

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
