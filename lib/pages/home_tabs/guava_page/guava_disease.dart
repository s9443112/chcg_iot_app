import 'package:flutter/material.dart';
import 'package:agritalk_iot_app/core/api_service.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GuavaDiseasePage extends StatefulWidget {
  const GuavaDiseasePage({super.key});

  @override
  State<GuavaDiseasePage> createState() => _GuavaDiseasePageState();
}

class _GuavaDiseasePageState extends State<GuavaDiseasePage> {
  final apiService = ApiService();
  final String groupUUID = '7e98412d-117e-4fff-86a3-d0bd506173fe';

  Map<String, dynamic>? scaleInsectData;
  Map<String, dynamic>? anthracnoseData;

  List<ChartData> scaleInsectHistory = [];
  List<ChartData> anthracnoseHistory = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchScores();
  }

  Future<void> fetchScores() async {
    try {
      // 即時風險
      final data1 = await apiService.fetchGroupScore(
        groupUUID: groupUUID,
        fruit: '番石榴',
        disease: '介殼蟲',
      );

      final data2 = await apiService.fetchGroupScore(
        groupUUID: groupUUID,
        fruit: '番石榴',
        disease: '炭疽病',
      );

      // 歷史風險
      final hist1 = await apiService.fetchGroupScoreHistory(
        groupUUID: groupUUID,
        fruit: '番石榴',
        disease: '介殼蟲',
      );

      final hist2 = await apiService.fetchGroupScoreHistory(
        groupUUID: groupUUID,
        fruit: '番石榴',
        disease: '炭疽病',
      );

      setState(() {
        scaleInsectData = data1;
        anthracnoseData = data2;

        scaleInsectHistory =
            (hist1 ?? [])
                .map<ChartData>(
                  (item) => ChartData(
                    DateTime.parse(item['time'].toString()),
                    double.tryParse(item['score']?.toString() ?? '0') ?? 0,
                  ),
                )
                .toList();

        anthracnoseHistory =
            (hist2 ?? [])
                .map<ChartData>(
                  (item) => ChartData(
                    DateTime.parse(item['time'].toString()),
                    double.tryParse(item['score']?.toString() ?? '0') ?? 0,
                  ),
                )
                .toList();

        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('資料載入失敗：$e')));
    }
  }

  Color getRiskColor(double score) {
    if (score >= 75) return Colors.red;
    if (score >= 40) return Colors.orange;
    return Colors.green;
  }

  /// ✅ 單一整合卡片 (風險資訊 + 圖表)
  Widget buildDiseaseCard(
    Map<String, dynamic>? data,
    List<ChartData> history,
    String title,
  ) {
    if (data == null) return const SizedBox.shrink();

    final double score = (data['score'] ?? 0).toDouble();
    final Color riskColor = getRiskColor(score);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Row(
              children: [
                Icon(Icons.bug_report, color: riskColor, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data['name'] ?? '-',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B4DBB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 風險與地區
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: riskColor),
                const SizedBox(width: 6),
                Text(
                  '風險指數：${score.toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: 15, color: riskColor),
                ),
                const Spacer(),
                Icon(Icons.location_on, color: Colors.indigo),
                const SizedBox(width: 4),
                Text(
                  '${data['city'] ?? ''} ${data['district'] ?? ''}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 說明
            Text(
              data['feedback'] ?? '-',
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),

            const SizedBox(height: 16),

            // 圖表
            if (history.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title 歷史風險',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: SfCartesianChart(
                      primaryXAxis: DateTimeAxis(
                        dateFormat: DateFormat('MM/dd'),
                        intervalType: DateTimeIntervalType.days,
                      ),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(text: '風險指數(%)'),
                        minimum: 0,
                        maximum: 100,
                      ),
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        format: 'point.x : 分數 point.y%',
                      ),
                      series: <CartesianSeries>[
                        LineSeries<ChartData, DateTime>(
                          dataSource: history,
                          xValueMapper: (ChartData d, _) => d.time,
                          yValueMapper: (ChartData d, _) => d.value,
                          color: riskColor,
                          markerSettings: const MarkerSettings(isVisible: true),
                          name: '分數', // 🔹圖例名稱
                        ),
                      ],
                    ),
                  ),
                ],
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
        backgroundColor: const Color(0xFF7B4DBB),
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          '芭樂雲 - 病蟲害預測',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  buildDiseaseCard(scaleInsectData, scaleInsectHistory, '介殼蟲'),
                  buildDiseaseCard(anthracnoseData, anthracnoseHistory, '炭疽病'),
                ],
              ),
    );
  }
}

class ChartData {
  final DateTime time;
  final double value;

  ChartData(this.time, this.value);
}
