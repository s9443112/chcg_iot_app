import 'package:flutter/material.dart';
import 'package:agritalk_iot_app/core/api_service.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';

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
  Widget buildDiseaseCard(Map<String, dynamic>? data, List<ChartData> history,String title,) {
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
                      color: Color(0xFF065B4C),
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
            TextButton.icon(
              onPressed: () {
                // 顯示 AlertDialog（初始為 loading）
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return _ChatgptAdviceDialog(
                      groupUUID: groupUUID,
                      fruit: data['fruit'] ?? '番石榴',
                      disease: data['disease'] ?? title,
                      score: (data['score'] ?? 0).toString(),
                      apiService: apiService,
                    );
                  },
                );
              },
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF065B4C),
              ),
              label: const Text(
                '如何防治？',
                style: TextStyle(
                  color: Color(0xFF065B4C),
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                      zoomPanBehavior: ZoomPanBehavior(
                        enablePinching: true,
                        enablePanning: true,
                        enableDoubleTapZooming: true,
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
        backgroundColor: const Color(0xFF065B4C),
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
                buildDiseaseCard(thripsData, thripsHistory, '小黃薊馬'),
                buildDiseaseCard(rotData, rotHistory, "晚腐病"),
                buildDiseaseCard(powderyData, powderyHistory, "白粉病"),
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

class _ChatgptAdviceDialog extends StatefulWidget {
  final String groupUUID;
  final String fruit;
  final String disease;
  final String score;
  final ApiService apiService;

  const _ChatgptAdviceDialog({
    required this.groupUUID,
    required this.fruit,
    required this.disease,
    required this.score,
    required this.apiService,
  });

  @override
  State<_ChatgptAdviceDialog> createState() => _ChatgptAdviceDialogState();
}

class _ChatgptAdviceDialogState extends State<_ChatgptAdviceDialog> {
  bool isLoading = true;
  List<String> suggestions = [];
  late Timer _dotTimer;

  String _thinkingText = 'AI 思考中 .';
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _startDotAnimation();
    _loadAdvice();
  }

  @override
  void dispose() {
    _dotTimer.cancel();
    super.dispose();
  }

  void _startDotAnimation() {
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        _dotCount = (_dotCount % 5) + 1;
        _thinkingText = 'AI 思考中 ${'.' * _dotCount}';
      });
    });
  }

  Future<void> _loadAdvice() async {
    final result = await widget.apiService.fetchChatgpt(
      groupUUID: widget.groupUUID,
      fruit: widget.fruit,
      disease: widget.disease,
      score: widget.score,
    );

    if (!mounted) return;

    if (result != null && result['data'] != null) {
      final raw = result['data'] as String;

      setState(() {
        suggestions =
            raw
                .split(RegExp(r'\\n|\n'))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
        isLoading = false;
      });
    } else {
      setState(() {
        suggestions = ['❌ 無法取得防治建議，請稍後再試。'];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '建議防治方式',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065B4C)),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content:
          isLoading
              ? SizedBox(
                height: 120,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _thinkingText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ),
              )
              : SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder:
                      (_, index) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(fontSize: 16, height: 1.5),
                          ),
                          Expanded(
                            child: Text(
                              suggestions[index],
                              style: const TextStyle(fontSize: 15, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                ),
              ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('關閉'),
        ),
      ],
    );
  }
}
