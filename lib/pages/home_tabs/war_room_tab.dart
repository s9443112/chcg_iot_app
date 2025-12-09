import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chcg_iot_app/core/api_service.dart';
import 'package:chcg_iot_app/pages/home_tabs/dashboard.dart';
import 'dart:ui';

class WarRoomTab extends StatefulWidget {
  const WarRoomTab({super.key});

  @override
  State<WarRoomTab> createState() => _WarRoomTabState();
}

class _WarRoomTabState extends State<WarRoomTab> {
  late GoogleMapController mapController;
  Set<Marker> _systemMarkers = {};
  Set<Marker> _targetMarkers = {};
  MapType _currentMapType = MapType.hybrid;
  bool _loading = true;
  final apiService = ApiService();
  final LatLng _center = const LatLng(23.6978, 120.9605);

  bool _showSelectorPanel = true;
  String? _selectedSystemUUID;
  String? _selectedTargetUUID;
  List<dynamic> _allTargets = [];
  List<dynamic> _allSystems = [];

  bool _isListMode = false; // ← 新增：是否為列表模式
  String _search = ''; // ← 新增：列表模式搜尋字
  final _searchCtrl = TextEditingController();

  Map<String, dynamic>? _selectedTargetMeta;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _showLoginRequiredDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('請先登入'),
            content: const Text('您需要登入才能使用戰情室功能。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 關閉對話框
                },
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 關閉對話框
                  Navigator.pushReplacementNamed(context, '/'); // 返回登入頁
                },
                child: const Text('前往登入'),
              ),
            ],
          ),
    );
  }

  Future<void> _loadMapData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty || token == 'GUEST_MODE') {
      if (mounted) {
        await _showLoginRequiredDialog();
      }
      return;
    }

    final systems = await apiService.fetchSystems(token);
    if (systems != null) {
      Set<Marker> loadedMarkers =
          systems.map<Marker>((item) {
            final lat = item['lat_WGS84'];
            final lng = item['lon_WGS84'];
            final name = item['name'] ?? '未命名系統';
            final city = item['city'] ?? '';
            final town = item['town'] ?? '';

            return Marker(
              markerId: MarkerId('system-${item['systemID']}'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: name,
                snippet: '$city $town (查看所有目標)',
                onTap: () => _onSystemMarkerTapped(item['systemUUID']),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            );
          }).toSet();

      setState(() {
        _systemMarkers = loadedMarkers;
        _loading = false;
        _allSystems = systems;
      });
      final targets = await apiService.fetchTargets(token);
      if (targets != null) {
        _allTargets = targets;
      }
    }
  }

  Future<void> _onSystemMarkerTapped(String systemUUID) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    final targets = await apiService.fetchTargets(token);
    if (targets != null) {
      final matchedTargets =
          targets.where((t) => t['systemUUID'] == systemUUID).toList();

      if (matchedTargets.isNotEmpty) {
        Set<Marker> loadedTargetMarkers =
            matchedTargets.map<Marker>((item) {
              final lat = item['lat_WGS84'];
              final lng = item['lon_WGS84'];
              final area = item['area'] ?? '未命名區域';

              return Marker(
                markerId: MarkerId('target-${item['targetID']}'),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: '$area',
                  snippet: '(詳細資訊)',
                  onTap: () => _onTargetMarkerTapped(item['targetUUID'], area),
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
              );
            }).toSet();

        setState(() {
          _targetMarkers = loadedTargetMarkers;
        });

        final firstTarget = matchedTargets.first;
        await mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                firstTarget['lat_WGS84'],
                firstTarget['lon_WGS84'],
              ),
              zoom: 18.0,
            ),
          ),
        );
      }
    }
  }

  Future<void> _onTargetMarkerTapped(String targetUUID, String areaName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    // 顯示 loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // 禁止點擊背景關閉
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final devices = await apiService.fetchDevices(token, targetUUID);
      // print(devices);
      devices?.sort((a, b) {
        // 轉小寫避免大小寫影響
        final aName = (a['name'] ?? '').toString().toLowerCase();
        final bName = (b['name'] ?? '').toString().toLowerCase();

        // 設定權重：攝影(1) < 控制(2) < 其他(3)
        int getPriority(String name) {
          if (name.contains('攝影')) return 1;
          if (name.contains('控制')) return 2;
          return 3;
        }

        final aPriority = getPriority(aName);
        final bPriority = getPriority(bName);

        // 先依權重排，再保持原本字典序
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }
        return aName.compareTo(bName);
      });

      if (devices != null) {
        // 關閉 loading dialog
        if (mounted) Navigator.pop(context);

        // 跳轉畫面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    DashboardPage(devices: devices, areaName: areaName),
          ),
        );
      } else {
        if (mounted) Navigator.pop(context); // 關掉 loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('資料載入失敗')));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // 關掉 loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('發生錯誤: $e')));
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType =
          _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

 Widget _buildListBody() {
  // 依搜尋字過濾 systems / targets
  final systems = _allSystems.where((s) {
    final name = (s['name'] ?? '').toString().toLowerCase();
    return name.contains(_search.toLowerCase());
  }).toList();

  // 建立 systemUUID -> targets 映射
  final Map<String, List<dynamic>> targetsBySystem = {};
  for (final t in _allTargets) {
    final sys = t['systemUUID'];
    targetsBySystem.putIfAbsent(sys, () => []).add(t);
  }

  return SafeArea(
    child: Column(
      children: [
        // 🔍 搜尋框
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: '搜尋系統名稱…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    ),
              isDense: true,
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // 📄 清單
        Expanded(
          child: systems.isEmpty
              ? const Center(child: Text('查無系統'))
              : ListView.builder(
                  itemCount: systems.length,
                  itemBuilder: (ctx, i) {
                    final s = systems[i];
                    final sysName = s['name'] ?? '未命名系統';
                    final sysUUID = s['systemUUID'];
                    final city = s['city'] ?? '';
                    final town = s['town'] ?? '';
                    final list = (targetsBySystem[sysUUID] ?? []).cast<Map>();

                    // 目標 ListTile
                    final tiles = list.map((t) {
                      final area = t['area'] ?? '無區域名稱';
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.place,
                          color: Color(0xFF7B4DBB),
                        ),
                        title: Text(
                          area,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Lat: ${t['lat_WGS84']}, Lng: ${t['lon_WGS84']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7B4DBB),
                            side: const BorderSide(color: Color(0xFF7B4DBB)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('即時看板'),
                          onPressed: () =>
                              _onTargetMarkerTapped(t['targetUUID'], area),
                        ),
                        onTap: () =>
                            _onTargetMarkerTapped(t['targetUUID'], area),
                      );
                    }).toList();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Column(
                        children: [
                          // 上面加一條紫色色條
                          Container(
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7B4DBB),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                          ),
                          ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            childrenPadding:
                                const EdgeInsets.only(bottom: 8, right: 8),
                            leading: const Icon(
                              Icons.hub,
                              color: Color(0xFF7B4DBB),
                            ),
                            title: Text(
                              sysName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${city}${town.isNotEmpty ? " $town" : ""} · 目標數：${list.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            children: tiles.isNotEmpty
                                ? tiles
                                : const [
                                    Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text('此系統尚無目標'),
                                    ),
                                  ],
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '戰情室',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),

        centerTitle: true,
        backgroundColor: const Color(0xFF7B4DBB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _isListMode ? '切換到地圖' : '切換到列表',
            icon: Icon(_isListMode ? Icons.map : Icons.list),
            onPressed: () => setState(() => _isListMode = !_isListMode),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _isListMode
              ? _buildListBody()
              : SafeArea(
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controller) => mapController = controller,
                      initialCameraPosition: CameraPosition(
                        target: _center,
                        zoom: 7.5,
                      ),
                      markers: _systemMarkers.union(_targetMarkers),
                      mapType: _currentMapType,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),

                    // ⭐ 懸浮資訊欄（選到目標才會顯示）
      if (_selectedTargetMeta != null)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.95),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.place, color: Color(0xFF7B4DBB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedTargetMeta!['area'] ?? '無區域名稱',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '座標：${_selectedTargetMeta!['lat_WGS84']}, '
                          '${_selectedTargetMeta!['lon_WGS84']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      final t = _selectedTargetMeta!;
                      _onTargetMarkerTapped(
                        t['targetUUID'],
                        t['area'] ?? '無區域名稱',
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7B4DBB),
                    ),
                    child: const Text('即時看板'),
                  ),
                ],
              ),
            ),
          ),
        ),

                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showSelectorPanel = !_showSelectorPanel;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B4DBB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Icon(
                              _showSelectorPanel ? Icons.tune : Icons.tune,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _toggleMapType,
                            icon: Icon(
                              _currentMapType == MapType.normal
                                  ? Icons.satellite_alt
                                  : Icons.map,
                              color: Colors.white,
                            ),
                            label: Text(
                              _currentMapType == MapType.normal
                                  ? '切換衛星圖'
                                  : '切換一般圖',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B4DBB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_showSelectorPanel)
  Positioned(
    bottom: 72,
    left: 16,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: const [
                  Icon(Icons.location_searching,
                      size: 18, color: Color(0xFF7B4DBB)),
                  SizedBox(width: 6),
                  Text(
                    '檢視地理位置',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '選擇系統',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                value: _selectedSystemUUID,
                items: _allSystems
                    .map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item['systemUUID'],
                    child: Text(item['name'] ?? '未命名系統'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _onSystemMarkerTapped(value);
                    setState(() {
                      _selectedSystemUUID = value;
                      _selectedTargetUUID = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '選擇目標',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                value: _selectedTargetUUID,
                items: _allTargets
                    .where((item) =>
                        item['systemUUID'] == _selectedSystemUUID)
                    .map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item['targetUUID'],
                    child: Text(item['area'] ?? '無區域名稱'),
                  );
                }).toList(),
                onChanged: (value) async {
  if (value == null) return;

  // 找到選中的 target
  final target = _allTargets.firstWhere(
    (item) =>
        item['systemUUID'] == _selectedSystemUUID &&
        item['targetUUID'] == value,
    orElse: () => null,
  );

  if (target != null) {
    // 1️⃣ 地圖鏡頭移過去
    await mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(
          target['lat_WGS84'],
          target['lon_WGS84'],
        ),
        18,
      ),
    );

    // 2️⃣ 重新建立 marker，讓選中的那顆高亮（黃色）
    final relatedTargets = _allTargets
        .where((item) => item['systemUUID'] == _selectedSystemUUID)
        .toList();

    final Set<Marker> newTargetMarkers = relatedTargets.map<Marker>((item) {
      final area = item['area'] ?? '未命名區域';
      final isSelected = item['targetUUID'] == value;

      return Marker(
        markerId: MarkerId('target-${item['targetID']}'),
        position: LatLng(item['lat_WGS84'], item['lon_WGS84']),
        infoWindow: InfoWindow(
          title: area,
          snippet: '(詳細資訊)',
          onTap: () => _onTargetMarkerTapped(item['targetUUID'], area),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected
              ? BitmapDescriptor.hueYellow    // ⭐ 高亮色
              : BitmapDescriptor.hueAzure,    // 原本顏色
        ),
      );
    }).toSet();

    // 3️⃣ 更新 state：目前選中哪個目標 & marker 高亮
    setState(() {
      _selectedTargetUUID = value;
      _selectedTargetMeta = target;   // ⭐ 給懸浮欄用
      _targetMarkers = newTargetMarkers;
    });
  }
},
),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF7B4DBB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () {
                    final matched = _allTargets.firstWhere(
                      (t) => t['targetUUID'] == _selectedTargetUUID,
                      orElse: () => null,
                    );
                    if (matched != null) {
                      _onTargetMarkerTapped(
                        matched['targetUUID'],
                        matched['area'],
                      );
                    }
                  },
                  icon: const Icon(Icons.monitor_heart),
                  label: const Text('即時看板'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  )
],
                ),
              ),
    );
  }
}
