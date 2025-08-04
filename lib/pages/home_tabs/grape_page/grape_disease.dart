import 'package:flutter/material.dart';
import 'package:agritalk_iot_app/core/api_service.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GrapeDiseasePage extends StatefulWidget {
  const GrapeDiseasePage({super.key});

  @override
  State<GrapeDiseasePage> createState() => _GrapeDiseasePageState();
}

class _GrapeDiseasePageState extends State<GrapeDiseasePage> {
  final apiService = ApiService();
  final String groupUUID = '3f72eb66-32e2-4241-8a72-58c235ac6164';

  Map<String, dynamic>? thripsData;     // 小黃薊馬
  Map<String, dynamic>? rotData;        // 晚腐病
  Map<String, dynamic>? powderyData;    // 白粉病

  List<ChartData> thripsHistory = [];
  List<ChartData> rotHistory = [];
  List<ChartData> powderyHistory = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchScores();
  }

  Future<void> fetchScores() async {
    try {
      // ✅ 即時資料
      final data1 = await apiService.fetchGroupScore(
        groupUUID: groupUUID,
        fruit: '葡萄',
        disease: '小黃薊馬',
      );

      final data2 = await apiService.fetchGroupScore(
        groupUUID: groupUUID,
        fruit: '葡萄',
        disease: '晚腐病',
      );

      final data3 = await apiService.fetchGroupScore(
        groupUUID: groupUUID,
        fruit: '葡萄',
        disease: '白粉病',
      );

      // ✅ 歷史資料
      final hist1 = await apiService.fetchGroupScoreHistory(
        groupUUID: groupUUID,
        fruit: '葡萄',
        disease: '小黃薊馬',
      );

      final hist2 = await apiService.fetchGroupScoreHistory(
        groupUUID: groupUUID,
        fruit: '葡萄',
        disease: '晚腐病',
      );

      final hist3 = await apiService.fetchGroupScoreHistory(
        groupUUID: groupUUID,
        fruit: '葡萄',
        disease: '白粉病',
      );

      setState(() {
        thripsData = data1;
        rotData = data2;
        powderyData = data3;

        thripsHistory = (hist1 ?? [])
            .map<ChartData>((item) => ChartData(
                  DateTime.parse(item['time'].toString()),
                  double.tryParse(item['score']?.toString() ?? '0') ?? 0,
                ))
            .toList();

        rotHistory = (hist2 ?? [])
            .map<ChartData>((item) => ChartData(
                  DateTime.parse(item['time'].toString()),
                  double.tryParse(item['score']?.toString() ?? '0') ?? 0,
                ))
            .toList();

        powderyHistory = (hist3 ?? [])
            .map<ChartData>((item) => ChartData(
                  DateTime.parse(item['time'].toString()),
                  double.tryParse(item['score']?.toString() ?? '0') ?? 0,
                ))
            .toList();

        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('資料載入失敗：$e')),
      );
    }
  }

  Color getRiskColor(double score) {
    if (score >= 75) return Colors.red;
    if (score >= 40) return Colors.orange;
    return Colors.green;
  }

  /// ✅ 卡片 + 圖表整合
  Widget buildDiseaseCard(Map<String, dynamic>? data, List<ChartData> history) {
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
            Text(
              data['feedback'] ?? '-',
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 16),

            // ✅ 圖表
            history.isEmpty
                ? const Text('無歷史資料', style: TextStyle(color: Colors.grey))
                : SizedBox(
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
                        format: 'point.x : 分數 {point.y}%',
                      ),
                      series: <CartesianSeries>[
                        LineSeries<ChartData, DateTime>(
                          dataSource: history,
                          xValueMapper: (ChartData d, _) => d.time,
                          yValueMapper: (ChartData d, _) => d.value,
                          color: riskColor,
                          markerSettings: const MarkerSettings(isVisible: true),
                          name: '分數',
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
        backgroundColor: const Color(0xFF7B4DBB),
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          '葡萄雲 - 病蟲害預測',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                buildDiseaseCard(thripsData, thripsHistory),
                buildDiseaseCard(rotData, rotHistory),
                buildDiseaseCard(powderyData, powderyHistory),
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
