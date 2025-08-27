import 'package:flutter/material.dart';
import 'package:agritalk_iot_app/core/api_service.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GrapeObservationPage extends StatefulWidget {
  const GrapeObservationPage({super.key});

  @override
  State<GrapeObservationPage> createState() => _GrapeObservationPageState();
}

class _GrapeObservationPageState extends State<GrapeObservationPage> {
  final apiService = ApiService();
  final groupUUID = '3f72eb66-32e2-4241-8a72-58c235ac6164';

  DateTime startTime = DateTime.now().subtract(const Duration(days: 1));
  DateTime endTime = DateTime.now().add(const Duration(days: 1));
  bool loading = false;

  final Map<String, String> featureNameMap = {
    'Precipitation': '降雨量',
    'Atmospheric Pressure': '大氣壓力',
    'Soil Temperature': '土壤溫度',
    'Soil Moisture': '土壤水分張力感測器',
    'Soil Electrical Conductivity': '土壤電導度',
    'Potential of Hydrogen': '酸鹼度',
    'Temperature': '環境溫度',
    'Humidity': '環境相對濕度',
    'Illuminance': '光照度',
    'Photosynthetically Active Radiation': '光合作用有效輻射',
    'Solar Radiation': '太陽輻射度',
    'Carbon Dioxide': '二氧化碳',
    'Wind Direction': '風向',
    'Wind Speed': '風速',
  };

  final List<String> features = [
    'Temperature',
    'Humidity',
    'Illuminance',
    'Photosynthetically Active Radiation',
    'Solar Radiation',
    'Carbon Dioxide',
    'Atmospheric Pressure',
    'Soil Temperature',
    'Soil Moisture',
    'Soil Electrical Conductivity',
    'Potential of Hydrogen',
  ];

  Map<String, List<ChartData>> chartDataMap = {};
  Map<String, List<ChartData>> myChartDataMap = {};
  final tooltipBehavior = TooltipBehavior(enable: true);

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => loading = true);
    Map<String, List<ChartData>> groupDataMap = {};
    Map<String, List<ChartData>> mineDataMap = {};

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    for (String feature in features) {
      // ✅ 取群組資料
      final data = await apiService.fetchGroupObservation(
        groupUUID: groupUUID,
        featureEnglishName: feature,
        startTime: startTime,
        endTime: endTime,
        aggregate: "hours",
      );

      groupDataMap[feature] =
          data
              ?.map<ChartData>(
                (item) => ChartData(
                  DateTime.parse(item['time']),
                  double.tryParse(item['value'].toString()) ?? 0,
                ),
              )
              .toList() ??
          [];

      // ✅ 取自己的資料（已登入）
      if (token != null && token.isNotEmpty && token != 'GUEST_MODE') {
        final mydata = await apiService.fetchMineRawData(
          featureEnglishName: feature,
          startTime: startTime,
          endTime: endTime,
          aggregate: "hours",
        );

        mineDataMap[feature] =
            mydata
                ?.map<ChartData>(
                  (item) => ChartData(
                    DateTime.parse(item['time']),
                    double.tryParse(item['value'].toString()) ?? 0,
                  ),
                )
                .toList() ??
            [];
      }
    }

    setState(() {
      chartDataMap = groupDataMap;
      myChartDataMap = mineDataMap;
      loading = false;
    });
  }

  Future<void> _selectDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startTime : endTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        } else {
          endTime = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
      _fetchAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF065B4C),
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          '葡萄雲 - 環境數據圖表',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _selectDate(isStart: true),
                          child: Text(
                            '開始：${DateFormat('yyyy-MM-dd').format(startTime)}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _selectDate(isStart: false),
                          child: Text(
                            '結束：${DateFormat('yyyy-MM-dd').format(endTime)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: features.length,
                      itemBuilder: (context, index) {
                        final feature = features[index];

                        return FeatureChart(
                          feature: feature,
                          title: featureNameMap[feature] ?? feature,
                          data: chartDataMap[feature] ?? [],
                          myData: myChartDataMap[feature] ?? [],
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

class FeatureChart extends StatefulWidget {
  final String feature;
  final String title;
  final List<ChartData> data;
  final List<ChartData> myData;
  const FeatureChart({
    super.key,
    required this.feature,
    required this.title,
    required this.data,
    required this.myData,
  });

  @override
  State<FeatureChart> createState() => _FeatureChartState();
}

class _FeatureChartState extends State<FeatureChart>
    with AutomaticKeepAliveClientMixin {
  late TooltipBehavior tooltipBehavior;

  @override
  void initState() {
    super.initState();
    tooltipBehavior = TooltipBehavior(enable: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for AutomaticKeepAliveClientMixin

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              widget.data.isEmpty
                  ? const Text('查無資料', style: TextStyle(color: Colors.grey))
                  : SizedBox(
                    height: 240,
                    child: SfCartesianChart(
                      tooltipBehavior: tooltipBehavior,
                      primaryXAxis: DateTimeAxis(
                        dateFormat: DateFormat('MM/dd HH:mm'),
                        intervalType: DateTimeIntervalType.auto,
                      ),
                      primaryYAxis: NumericAxis(
                        majorGridLines: const MajorGridLines(width: 0.3),
                      ),
                      zoomPanBehavior: ZoomPanBehavior(
                        enablePinching: true,
                        enablePanning: true,
                        enableDoubleTapZooming: true,
                      ),
                      series: <CartesianSeries>[
                        // 群組資料線
                        LineSeries<ChartData, DateTime>(
                          dataSource: widget.data,
                          xValueMapper: (ChartData d, _) => d.time,
                          yValueMapper: (ChartData d, _) => d.value,
                          color: Colors.indigo,
                          width: 2,
                          name: '群組平均',
                          markerSettings: const MarkerSettings(
                            isVisible: false,
                          ),
                        ),
                        // 我的資料線
                        if (widget.myData.isNotEmpty)
                          LineSeries<ChartData, DateTime>(
                            dataSource: widget.myData,
                            xValueMapper: (ChartData d, _) => d.time,
                            yValueMapper: (ChartData d, _) => d.value,
                            color: Colors.orange,
                            width: 2,
                            name: '我的數據',
                            markerSettings: const MarkerSettings(
                              isVisible: false,
                            ),
                          ),
                      ],
                      legend: Legend(isVisible: true),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ChartData {
  final DateTime time;
  final double value;

  ChartData(this.time, this.value);
}
