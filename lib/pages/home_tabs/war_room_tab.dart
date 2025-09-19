import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agritalk_iot_app/core/api_service.dart';
import 'package:agritalk_iot_app/pages/home_tabs/dashboard.dart';

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
    final systems =
        _allSystems.where((s) {
          final name = (s['name'] ?? '').toString().toLowerCase();
          return name.contains(_search.toLowerCase());
        }).toList();

    // 建立 systemUUID -> targets 映射
    Map<String, List<dynamic>> targetsBySystem = {};
    for (final t in _allTargets) {
      final sys = t['systemUUID'];
      targetsBySystem.putIfAbsent(sys, () => []).add(t);
    }

    return SafeArea(
      child: Column(
        children: [
          // 搜尋框
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: '搜尋系統名稱…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child:
                systems.isEmpty
                    ? const Center(child: Text('查無系統'))
                    : ListView.builder(
                      itemCount: systems.length,
                      itemBuilder: (ctx, i) {
                        final s = systems[i];
                        final sysName = s['name'] ?? '未命名系統';
                        final sysUUID = s['systemUUID'];
                        final list =
                            (targetsBySystem[sysUUID] ?? []).cast<Map>();

                        // 目標清單項目
                        final tiles =
                            list.map((t) {
                              final area = t['area'] ?? '無區域名稱';
                              return ListTile(
                                leading: const Icon(Icons.place),
                                title: Text(area),
                                subtitle: Text(
                                  'Lat: ${t['lat_WGS84']}, Lng: ${t['lon_WGS84']}',
                                ),
                                trailing: TextButton(
  child: const Text('即時看板'),
  onPressed: () => _onTargetMarkerTapped(t['targetUUID'], area),
),
                                onTap:
                                    () => _onTargetMarkerTapped(
                                      t['targetUUID'],
                                      area,
                                    ),
                              );
                            }).toList();

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            leading: const Icon(
                              Icons.hub,
                              color: const Color(0xFF065B4C),
                            ),
                            title: Text(
                              sysName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text('目標數：${list.length}'),
                            children:
                                tiles.isNotEmpty
                                    ? tiles
                                    : [
                                      const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text('此系統尚無目標'),
                                      ),
                                    ],
                            onExpansionChanged: (expanded) async {
                              if (expanded) {
                                // 展開時順便把地圖鏡頭移到系統位置（若你想要）
                                final lat = s['lat_WGS84'];
                                final lng = s['lon_WGS84'];
                                if (lat != null &&
                                    lng != null &&
                                    !_isListMode) {
                                  await mapController.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                      LatLng(lat, lng),
                                      12,
                                    ),
                                  );
                                }
                              }
                            },
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
        backgroundColor: const Color(0xFF065B4C),
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
                              backgroundColor: const Color(0xFF065B4C),
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
                              backgroundColor: const Color(0xFF065B4C),
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
                        bottom: 70, // 剛好在「切換一般圖」上方
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          width: 250,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(blurRadius: 6, color: Colors.black26),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "檢視地理位置",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text('選擇系統'),
                                value: _selectedSystemUUID,
                                items:
                                    _allSystems.map<DropdownMenuItem<String>>((
                                      item,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: item['systemUUID'],
                                        child: Text(item['name']),
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
                              DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text('選擇目標'),
                                value: _selectedTargetUUID,
                                items:
                                    _allTargets
                                        .where(
                                          (item) =>
                                              item['systemUUID'] ==
                                              _selectedSystemUUID,
                                        )
                                        .map<DropdownMenuItem<String>>((item) {
                                          return DropdownMenuItem<String>(
                                            value: item['targetUUID'],
                                            child: Text(
                                              item['area'] ?? '無區域名稱',
                                            ),
                                          );
                                        })
                                        .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    final target = _allTargets.firstWhere(
                                      (item) =>
                                          item['systemUUID'] ==
                                              _selectedSystemUUID &&
                                          item['targetUUID'] == value,
                                      orElse: () => null,
                                    );

                                    if (target != null) {
                                      mapController.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                          LatLng(
                                            target['lat_WGS84'],
                                            target['lon_WGS84'],
                                          ),
                                          18,
                                        ),
                                      );
                                    }
                                    setState(() {
                                      _selectedTargetUUID = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xFF065B4C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                onPressed: () {
                                  final matched = _allTargets.firstWhere(
                                    (t) =>
                                        t['targetUUID'] == _selectedTargetUUID,
                                    orElse: () => null,
                                  );

                                  if (matched != null) {
                                    _onTargetMarkerTapped(
                                      matched["targetUUID"],
                                      matched["area"],
                                    );
                                  }
                                },
                                child: const Text("即時看板"),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
