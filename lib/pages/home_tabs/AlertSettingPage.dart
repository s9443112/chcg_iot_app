import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chcg_iot_app/core/api_service.dart';

class AlertSettingPage extends StatefulWidget {
  final Object obs;
  final String deviceUUID;
  final String featureEnglishName;
  final String serialId;

  const AlertSettingPage({
    super.key,
    required this.obs,
    required this.deviceUUID,
    required this.featureEnglishName,
    required this.serialId,
  });

  @override
  State<AlertSettingPage> createState() => _AlertSettingPageState();
}

class _AlertSettingPageState extends State<AlertSettingPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      _HighLowAlertTab(
        deviceUUID: widget.deviceUUID,
        featureEnglishName: widget.featureEnglishName,
        serialId: widget.serialId,
      ),
      _HistoryAlertTab(
        deviceUUID: widget.deviceUUID,
        featureEnglishName: widget.featureEnglishName,
        serialId: widget.serialId,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '警戒值設定',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF7B4DBB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.warning_amber_rounded),
            label: "警戒值",
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_rounded),
            label: "歷史紀錄",
          ),
        ],
      ),
    );
  }
}

/// ======================
/// 高低警戒值 Tab
/// ======================

class _HighLowAlertTab extends StatefulWidget {
  final String deviceUUID;
  final String featureEnglishName;
  final String serialId;

  const _HighLowAlertTab({
    required this.deviceUUID,
    required this.featureEnglishName,
    required this.serialId,
  });

  @override
  State<_HighLowAlertTab> createState() => _HighLowAlertTabState();
}

class _HighLowAlertTabState extends State<_HighLowAlertTab> {
  final ApiService _api = ApiService();

  final TextEditingController _highCtrl = TextEditingController();
  final TextEditingController _lowCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadThreshold();
  }

  @override
  void dispose() {
    _highCtrl.dispose();
    _lowCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadThreshold() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() {
          _error = '尚未登入，無法讀取警戒值';
          _loading = false;
        });
        return;
      }

      final data = await _api.fetchAlertThreshold(
        token: token,
        deviceUUID: widget.deviceUUID,
        featureEnglishName: widget.featureEnglishName,
        serialId: widget.serialId,
      );

      if (data != null) {
        final high = data['highValue'];
        final low = data['lowValue'];

        _highCtrl.text =
            (high == null || '$high' == 'null') ? '' : high.toString();
        _lowCtrl.text =
            (low == null || '$low' == 'null') ? '' : low.toString();
      } else {
        _highCtrl.text = '';
        _lowCtrl.text = '';
      }
    } catch (e) {
      _error = '載入失敗：$e';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveThreshold() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('尚未登入，無法儲存警戒值')),
        );
        setState(() {
          _saving = false;
        });
        return;
      }

      double? highValue;
      double? lowValue;

      if (_highCtrl.text.trim().isNotEmpty) {
        highValue = double.tryParse(_highCtrl.text.trim());
        if (highValue == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('高於警戒值請輸入數字')),
          );
          setState(() {
            _saving = false;
          });
          return;
        }
      }

      if (_lowCtrl.text.trim().isNotEmpty) {
        lowValue = double.tryParse(_lowCtrl.text.trim());
        if (lowValue == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('低於警戒值請輸入數字')),
          );
          setState(() {
            _saving = false;
          });
          return;
        }
      }

      await _api.alertThresholdAdd(
        token: token,
        deviceUUID: widget.deviceUUID,
        featureEnglishName: widget.featureEnglishName,
        serialId: widget.serialId,
        highValue: highValue,
        lowValue: lowValue,
        // alias 可視需求帶入，這裡先不處理
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('警戒值已儲存')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('儲存失敗：$e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _clearThreshold() async {
    setState(() {
      _saving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('尚未登入，無法清除警戒值')),
        );
        setState(() {
          _saving = false;
        });
        return;
      }

      await _api.alertThresholdDel(
        token: token,
        deviceUUID: widget.deviceUUID,
        featureEnglishName: widget.featureEnglishName,
        serialId: widget.serialId,
      );

      _highCtrl.clear();
      _lowCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('警戒值已清除')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清除失敗：$e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "設定警戒範圍",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            "裝置 UUID：${widget.deviceUUID}\n項目：${widget.featureEnglishName}（serialId: ${widget.serialId}）",
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _highCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "高於此值觸發警戒",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lowCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "低於此值觸發警戒",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B4DBB),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _saving ? null : _saveThreshold,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "儲存設定",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _saving ? null : _clearThreshold,
                icon: const Icon(Icons.delete_outline),
                label: const Text("清除"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ======================
/// 歷史紀錄 Tab
/// ======================

class _HistoryAlertTab extends StatefulWidget {
  final String deviceUUID;
  final String featureEnglishName;
  final String serialId;

  const _HistoryAlertTab({
    required this.deviceUUID,
    required this.featureEnglishName,
    required this.serialId,
  });

  @override
  State<_HistoryAlertTab> createState() => _HistoryAlertTabState();
}

class _HistoryAlertTabState extends State<_HistoryAlertTab> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() {
          _error = '尚未登入，無法讀取歷史紀錄';
          _loading = false;
        });
        return;
      }

      final list = await _api.fetchAlertHistory(
        token: token,
        deviceUUID: widget.deviceUUID,
        featureEnglishName: widget.featureEnglishName,
        serialId: widget.serialId,
        limit: 100,
      );

      setState(() {
        _items = list ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '載入失敗：$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text(
          "尚未有警戒紀錄",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemBuilder: (context, index) {
          final item = _items[index] as Map<String, dynamic>;
          final type = (item['triggeredType'] ?? '').toString(); // HIGH / LOW
          final value = item['currentValue'];
          final createdAt = (item['createdAt'] ?? '').toString();
          final alias = (item['alias'] ?? '').toString();
          final featureName =
              (item['deviceFeatureName'] ?? '').toString();

          final isHigh = type.toUpperCase() == 'HIGH';

          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第一行：時間 + 方向 badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        createdAt,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isHigh ? Colors.red[100] : Colors.blue[100],
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isHigh ? '高於警戒' : '低於警戒',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isHigh ? Colors.red[800] : Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alias.isNotEmpty ? '$featureName ($alias)' : featureName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '當時數值：$value',
                    style: TextStyle(
                      fontSize: 14,
                      color: isHigh ? Colors.red[700] : Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: _items.length,
      ),
    );
  }
}
