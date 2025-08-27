import 'package:flutter/material.dart';
import 'package:agritalk_iot_app/core/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CycleControlTab extends StatefulWidget {
  final String deviceUUID;
  final String featureEnglishName;
  final String serialId;

  const CycleControlTab({
    super.key,
    required this.deviceUUID,
    required this.featureEnglishName,
    required this.serialId,
  });

  @override
  State<CycleControlTab> createState() => _CycleControlTabState();
}

class _CycleControlTabState extends State<CycleControlTab> {
  final apiService = ApiService();
  List<dynamic>? rules;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchCyclic();
  }

  Future<void> _fetchCyclic() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() {
          error = '未登入或找不到 token';
          isLoading = false;
        });
        return;
      }

      final data = await apiService.fetchCyclic(
        token,
        widget.deviceUUID,
        widget.serialId,
      );

      setState(() {
        rules = data ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = '載入循環排程失敗：$e';
        isLoading = false;
      });
    }
  }

  Future<void> _addOrEditDialog({Map<String, dynamic>? rule}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('找不到 token')),
      );
      return;
    }

    TimeOfDay? start = _parseHms(rule?['start_time']);
    TimeOfDay? end = _parseHms(rule?['end_time']);
    final onCtrl = TextEditingController(
      text: rule?['on_minutes']?.toString() ?? '5',
    );
    final offCtrl = TextEditingController(
      text: rule?['off_minutes']?.toString() ?? '10',
    );
    final enabled = ValueNotifier<bool>(rule?['enabled'] ?? true);

    final Set<String> allDays = const {
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    };
    final Set<String> days = {
      ...(rule?['weekdays']?.cast<String>() ?? <String>{'monday', 'tuesday', 'wednesday', 'thursday', 'friday'})
    };

    start ??= const TimeOfDay(hour: 8, minute: 0);
    end ??= const TimeOfDay(hour: 20, minute: 0);

    Future<void> pickStart() async {
      final picked = await showTimePicker(context: context, initialTime: start!);
      if (picked != null) {
        setState(() => start = picked);
      }
    }

    Future<void> pickEnd() async {
      final picked = await showTimePicker(context: context, initialTime: end!);
      if (picked != null) {
        setState(() => end = picked);
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (_, setState) {
            String fmt(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';

            return AlertDialog(
              title: Text(rule == null ? '新增循環排程' : '編輯循環排程'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 時間窗
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.schedule),
                              label: Text('開始：${fmt(start!)}'),
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: start!,
                                );
                                if (picked != null) {
                                  setState(() => start = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.schedule_outlined),
                              label: Text('結束：${fmt(end!)}'),
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: end!,
                                );
                                if (picked != null) {
                                  setState(() => end = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ON / OFF 分鐘
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: onCtrl,
                              decoration: const InputDecoration(
                                labelText: 'ON（分鐘）',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: offCtrl,
                              decoration: const InputDecoration(
                                labelText: 'OFF（分鐘）',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 星期多選
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('重複星期', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allDays.map((d) {
                          final label = _weekdayLabel(d);
                          final selected = days.contains(d);
                          return FilterChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  days.add(d);
                                } else {
                                  days.remove(d);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // 啟用
                      ValueListenableBuilder<bool>(
                        valueListenable: enabled,
                        builder: (_, v, __) {
                          return SwitchListTile(
                            value: v,
                            title: const Text('啟用'),
                            onChanged: (nv) => enabled.value = nv,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // 驗證
                      final onM = int.tryParse(onCtrl.text.trim()) ?? 0;
                      final offM = int.tryParse(offCtrl.text.trim()) ?? 0;
                      if (onM <= 0 || offM <= 0) {
                        throw 'ON/OFF 分鐘需為正整數';
                      }
                      if (days.isEmpty) {
                        throw '至少選擇一個星期';
                      }

                      final st = fmt(start!);
                      final et = fmt(end!);

                      // 比較 start < end（同日）
                      final stMinutes = start!.hour * 60 + start!.minute;
                      final etMinutes = end!.hour * 60 + end!.minute;
                      if (!(stMinutes < etMinutes)) {
                        throw '開始時間需早於結束時間（同日視窗）';
                      }

                      final ruleId = rule?['id'] as int?;
                      final result = await apiService.cyclicAdd(
                        token: token,
                        deviceUUID: widget.deviceUUID,
                        featureEnglishName: widget.featureEnglishName,
                        serialId: int.parse(widget.serialId),
                        onMinutes: onM,
                        offMinutes: offM,
                        startTime: st,
                        endTime: et,
                        weekdays: days.toList(),
                        enabled: enabled.value,
                        ruleId: ruleId,
                      );

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        await _fetchCyclic();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? '儲存成功')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('儲存失敗：$e')),
                        );
                      }
                    }
                  },
                  child: const Text('送出'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteRule(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('找不到 token')),
        );
        return;
      }

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('確認刪除'),
          content: const Text('你確定要刪除此循環排程嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('刪除', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (ok != true) return;

      final res = await apiService.cyclicDel(token: token, id: id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? '刪除成功')),
        );
        _fetchCyclic();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除失敗：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      body = Center(child: Text(error!, style: const TextStyle(color: Colors.red)));
    } else if (rules == null || rules!.isEmpty) {
      body = const Center(child: Text('尚未設定任何循環排程'));
    } else {
      body = ListView.builder(
        itemCount: rules!.length,
        itemBuilder: (context, index) {
          final r = rules![index];
          final start = (r['start_time'] ?? '').toString();
          final end = (r['end_time'] ?? '').toString();
          final onM = r['on_minutes']?.toString() ?? '?';
          final offM = r['off_minutes']?.toString() ?? '?';
          final enabled = r['enabled'] == true;
          final weekdays = (r['weekdays'] as List<dynamic>? ?? const []).cast<String>();

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('時間窗：$start ~ $end'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('週期：ON $onM 分鐘 / OFF $offM 分鐘'),
                  const SizedBox(height: 2),
                  Text('重複：${_weekdayLabelLine(weekdays)}'),
                  const SizedBox(height: 2),
                  Text('狀態：${enabled ? "啟用" : "停用"}'),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.repeat),
              onTap: () => _addOrEditDialog(rule: r), // 點擊可編輯
              onLongPress: () => _deleteRule(r['id'] as int),
            ),
          );
        },
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchCyclic,
        child: body is ListView ? body : ListView(children: [SizedBox(height: 400, child: body)]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('新增循環', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF065B4C),
      ),
    );
  }

  // ===== helpers =====

  static String _two(int n) => n.toString().padLeft(2, '0');

  static TimeOfDay? _parseHms(dynamic s) {
    if (s == null) return null;
    final str = s.toString();
    final parts = str.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h, minute: m);
    // 秒數無需用到 TimeOfDay，顯示時保留 HH:mm 即可
  }

  static String _weekdayLabel(String key) {
    switch (key) {
      case 'monday':
        return '週一';
      case 'tuesday':
        return '週二';
      case 'wednesday':
        return '週三';
      case 'thursday':
        return '週四';
      case 'friday':
        return '週五';
      case 'saturday':
        return '週六';
      case 'sunday':
        return '週日';
      default:
        return key;
    }
  }

  static String _weekdayLabelLine(List<String> keys) {
    if (keys.isEmpty) return '—';
    final mapped = keys.map(_weekdayLabel).toList();
    return mapped.join('、');
  }
}
