import 'package:flutter/material.dart';
import 'package:agritalk_iot_app/core/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConditionControlTab extends StatefulWidget {
  final String deviceUUID;
  final String featureEnglishName;
  final String serialId;

  const ConditionControlTab({
    super.key,
    required this.deviceUUID,
    required this.featureEnglishName,
    required this.serialId,
  });

  @override
  State<ConditionControlTab> createState() => _ConditionControlTabState();
}

class _ConditionControlTabState extends State<ConditionControlTab> {
  final apiService = ApiService();
  List<dynamic>? conditionList;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchConditions();
  }

  Future<void> fetchConditions() async {
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

      final data = await apiService.fetchCondition(
        token,
        widget.deviceUUID,
        widget.serialId,
      );

      setState(() {
        conditionList = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = '載入條件排程失敗：$e';
        isLoading = false;
      });
    }
  }

  Future<void> addConditionDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('找不到 token')));
      return;
    }

    List<dynamic> targets = await apiService.fetchTargets(token) ?? [];
    List<Map<String, dynamic>> conditions = [];

    // ⭐ 新增：動作與秒數（以秒）欄位
    String action = 'ON'; // 預設 ON
    final durationCtrl = TextEditingController(); // 可空白

    void addEmptyCondition() {
      conditions.add({
        'target': null,
        'device': null,
        'devices': <dynamic>[],
        'features': <dynamic>[],
        'feature': null,
        'operator': '>',
        'value': '',
      });
    }

    addEmptyCondition();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> updateDevicesAndFeatures(
              int index,
              String targetUUID,
            ) async {
              final devices =
                  await apiService.fetchDevices(token, targetUUID) ?? [];
              setState(() {
                conditions[index]['device'] = null;
                conditions[index]['feature'] = null;
                conditions[index]['devices'] = devices;
                conditions[index]['features'] = [];
              });
            }

            Future<void> updateFeatures(
              int index,
              Map<String, dynamic> device,
            ) async {
              final obs = device['deviceFeature'] ?? [];
              setState(() {
                conditions[index]['features'] = obs;
                conditions[index]['feature'] = null;
              });
            }

            return AlertDialog(
              title: const Text('新增條件規則'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ⭐ 動作 & durationSeconds（秒，可空）
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: action,
                              decoration: const InputDecoration(
                                labelText: '執行動作',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'ON',
                                  child: Text('ON'),
                                ),
                                DropdownMenuItem(
                                  value: 'OFF',
                                  child: Text('OFF'),
                                ),
                              ],
                              onChanged:
                                  (v) => setState(() => action = v ?? 'ON'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: durationCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '回復時間',
                                helperText: 'ON→N秒後OFF；OFF→N秒後ON',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 條件組
                      ...conditions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final cond = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              // Target
                              SizedBox(
                                width: 220,
                                child: DropdownButtonFormField<String>(
                                  value: cond['target'] as String?,
                                  hint: const Text("選擇目標"),
                                  items:
                                      targets.map<DropdownMenuItem<String>>((
                                        t,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: t['targetUUID'],
                                          child: Text(t['area'] ?? '未命名'),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      cond['target'] = value;
                                    });
                                    if (value != null) {
                                      updateDevicesAndFeatures(index, value);
                                    }
                                  },
                                ),
                              ),

                              // Device
                              SizedBox(
                                width: 220,
                                child: DropdownButtonFormField<
                                  Map<String, dynamic>
                                >(
                                  value:
                                      cond['device'] as Map<String, dynamic>?,
                                  hint: const Text("選擇裝置"),
                                  items:
                                      (cond['devices'] ?? []).map<
                                        DropdownMenuItem<Map<String, dynamic>>
                                      >((d) {
                                        return DropdownMenuItem<
                                          Map<String, dynamic>
                                        >(
                                          value: d,
                                          child: Text(d['name'] ?? '未知裝置'),
                                        );
                                      }).toList(),
                                  onChanged: (device) {
                                    setState(() {
                                      cond['device'] = device;
                                    });
                                    if (device != null) {
                                      updateFeatures(index, device);
                                    }
                                  },
                                ),
                              ),

                              // Feature
                              SizedBox(
                                width: 220,
                                child: DropdownButtonFormField<
                                  Map<String, dynamic>
                                >(
                                  value:
                                      cond['feature'] as Map<String, dynamic>?,
                                  hint: const Text("選擇感測項目"),
                                  items:
                                      (cond['features'] ?? []).map<
                                        DropdownMenuItem<Map<String, dynamic>>
                                      >((f) {
                                        final name =
                                            (f['deviceFeatureName']
                                                        ?.toString()
                                                        .isNotEmpty ==
                                                    true)
                                                ? f['deviceFeatureName']
                                                : f['alias'] ?? '未知項目';
                                        final text =
                                            '$name（編號: ${f['serialId'] ?? '無'}）';
                                        return DropdownMenuItem<
                                          Map<String, dynamic>
                                        >(value: f, child: Text(text));
                                      }).toList(),
                                  onChanged: (f) {
                                    setState(() {
                                      cond['feature'] = f;
                                    });
                                  },
                                ),
                              ),

                              // Operator
                              SizedBox(
                                width: 220,
                                child: DropdownButtonFormField<String>(
                                  value: cond['operator'],
                                  items: const [
                                    DropdownMenuItem(
                                      value: ">",
                                      child: Text(">"),
                                    ),
                                    DropdownMenuItem(
                                      value: "<",
                                      child: Text("<"),
                                    ),
                                    DropdownMenuItem(
                                      value: ">=",
                                      child: Text(">="),
                                    ),
                                    DropdownMenuItem(
                                      value: "<=",
                                      child: Text("<="),
                                    ),
                                    DropdownMenuItem(
                                      value: "==",
                                      child: Text("=="),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      cond['operator'] = val;
                                    });
                                  },
                                ),
                              ),

                              // Value
                              SizedBox(
                                width: 220,
                                child: TextFormField(
                                  initialValue: cond['value'],
                                  decoration: const InputDecoration(
                                    hintText: "數值",
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    cond['value'] = val;
                                  },
                                ),
                              ),

                              // 刪除條件
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    conditions.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("+ AND 條件"),
                          onPressed: () {
                            setState(() => addEmptyCondition());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("取消"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final prepared =
                          conditions
                              .where(
                                (c) =>
                                    c['device'] != null &&
                                    c['feature'] != null &&
                                    c['value'].toString().isNotEmpty,
                              )
                              .map((c) {
                                return {
                                  "deviceUUID": c['device']['deviceUUID'],
                                  "sensor": c['feature']['name'] ?? '',
                                  "serialId": c['feature']['serialId'],
                                  "operator": c['operator'],
                                  "value": num.tryParse(c['value']) ?? 0,
                                };
                              })
                              .toList();

                      if (prepared.isEmpty) {
                        throw '請至少新增一個完整的條件';
                      }

                      // ⭐ 解析秒數（可空）
                      final int? durationSeconds =
                          durationCtrl.text.trim().isEmpty
                              ? null
                              : int.tryParse(durationCtrl.text.trim());

                      final result = await apiService.conditionAdd(
                        token: token,
                        deviceUUID: widget.deviceUUID,
                        serialId: int.parse(widget.serialId),
                        action: action, // 使用者選擇
                        conditions: prepared,
                        durationSeconds: durationSeconds, // ⭐ 新增
                      );

                      if (!mounted) return;
                      Navigator.pop(context);
                      await fetchConditions();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result["message"] ?? "新增成功")),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("新增失敗：$e")));
                    }
                  },
                  child: const Text("送出"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _onConfirmDismissCondition(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('確認刪除'),
            content: const Text('你確定要刪除此條件規則嗎？'),
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
    if (ok != true) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw '找不到 token';

      final res = await apiService.conditionDel(token: token, id: id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res['message'] ?? '刪除成功')));
        await fetchConditions(); // 與後端同步
      }
      return true; // 允許滑掉
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除失敗：$e'), backgroundColor: Colors.red),
        );
      }
      return false; // 取消滑掉
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      body = Center(
        child: Text(error!, style: const TextStyle(color: Colors.red)),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: fetchConditions,
        child:
            conditionList == null || conditionList!.isEmpty
                ? ListView(
                  children: [
                    SizedBox(
                      height: 400,
                      child: Center(child: Text('尚未設定任何條件排程')),
                    ),
                  ],
                )
                : ListView.builder(
                  itemCount: conditionList!.length,
                  itemBuilder: (context, index) {
                    final rule = conditionList![index];

                    // ⭐ 顯示 duration_seconds（後端請於 list API 回傳此欄位）
                    final ds = rule['duration_seconds'];

                    return Dismissible(
                      key: ValueKey('condition_${rule["id"]}'), // 確保唯一
                      direction: DismissDirection.endToStart, // 右→左（左滑刪除）
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss:
                          (_) => _onConfirmDismissCondition(rule['id'] as int),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(
                            "執行動作: ${rule["action"] ?? "未指定"}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (rule['duration_seconds'] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'duration: ${rule['duration_seconds']}s（觸發後自動切換相反狀態）',
                                  style: const TextStyle(
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              ...(rule["conditions"] as List<dynamic>? ??
                                      const [])
                                  .map((cond) {
                                    final device = cond["deviceName"] ?? "未知裝置";
                                    final feature =
                                        cond["featureName"] ?? "未知項目";
                                    final operator = cond["operator"] ?? "?";
                                    final value =
                                        cond["value"]?.toString() ?? "?";
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2.0,
                                      ),
                                      child: Text(
                                        "‧ [$device] $feature $operator $value",
                                      ),
                                    );
                                  })
                                  .toList(),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.rule),
                          onTap: () {
                            // TODO: 點擊查看或編輯
                          },
                          // onLongPress: ...  // ← 不再需要長按刪除
                        ),
                      ),
                    );
                  },
                ),
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addConditionDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('新增規則', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF065B4C),
      ),
    );
  }
}
