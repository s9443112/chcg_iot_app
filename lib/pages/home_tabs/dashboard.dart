import 'package:flutter/material.dart';
import 'package:agritalk_iot_app/core/observation_icons.dart';
import 'package:agritalk_iot_app/core/hlscamera.dart';
import 'package:agritalk_iot_app/pages/home_tabs/observationhistory.dart';
import 'package:agritalk_iot_app/pages/home_tabs/autocontrol.dart';
import 'package:agritalk_iot_app/core/api_service.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
// 放在檔案最上面其它 import 旁邊
import 'dart:ui' show ImageFilter;
import 'package:flutter/services.dart';
import 'dart:async';

final apiService = ApiService();

class DashboardPage extends StatefulWidget {
  final List<dynamic> devices;
  final String areaName;

  const DashboardPage({
    super.key,
    required this.devices,
    required this.areaName,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
  }

  // 記錄目前暫停顯示的串流（用 URL 辨識）
  final Set<String> _pausedCameras = {};
  // 新增：是否為條列式
  bool _listMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            centerTitle: true,
            backgroundColor: const Color(0xFF065B4C),
            foregroundColor: Colors.white,
            elevation: 1,
            title: Text(
              '目標即時資料 - ${widget.areaName}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
            ),
            actions: [
              IconButton(
                tooltip: _listMode ? '切換成卡片網格' : '切換成條列式',
                icon: Icon(
                  _listMode ? Icons.grid_view_rounded : Icons.view_list_rounded,
                ),
                onPressed: () {
                  setState(() {
                    _listMode = !_listMode;
                  });
                },
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            sliver:
                _listMode
                    ? _buildNonCameraListByDeviceSliver() // ➌ 條列式（略過攝影機）
                    : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final device = widget.devices[index];
                        final deviceObservations =
                            device["observationlatest"].toList();
                        return _buildDeviceCard(device, deviceObservations);
                      }, childCount: widget.devices.length),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(dynamic device, List<dynamic> deviceObservations) {
    final cameras =
        deviceObservations
            .where(
              (o) =>
                  (o['featureEnglishName'] ?? '').toString().toLowerCase() ==
                  'camera',
            )
            .toList();

    final others =
        deviceObservations
            .where(
              (o) =>
                  (o['featureEnglishName'] ?? '').toString().toLowerCase() !=
                  'camera',
            )
            .toList()
          ..sort((a, b) {
            // 先判斷 Actuator 排前面
            final aIsActuator = (a['style'] ?? '').toString() == 'Actuator';
            final bIsActuator = (b['style'] ?? '').toString() == 'Actuator';

            if (aIsActuator && !bIsActuator) return -1;
            if (!aIsActuator && bIsActuator) return 1;

            // 轉成數字比較
            final aSerial =
                int.tryParse((a['serialId'] ?? '0').toString()) ?? 0;
            final bSerial =
                int.tryParse((b['serialId'] ?? '0').toString()) ?? 0;

            return aSerial.compareTo(bSerial);
          });

    return Card(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
        side: BorderSide(color: Colors.blue.shade100, width: 0.5.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors, size: 6.w, color: const Color(0xFF065B4C)),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    device['name'] ?? '未命名裝置',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF065B4C),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.3.h),
            // 先畫攝影機
            ...cameras.map((obs) => _buildCameraCard(obs)).toList(),
            // 再畫一般感測器（用Grid）
            if (others.isNotEmpty)
              GridView.builder(
                padding: EdgeInsets.only(top: 0.75.h),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: others.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 3.w,
                  mainAxisSpacing: 3.w,
                  mainAxisExtent: 28.h,
                ),
                itemBuilder:
                    (context, index) => _buildObservationCard(others[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraCard(dynamic obs) {
    final alias = (obs['alias'] ?? '').toString();
    final featureName =
        alias.isNotEmpty ? alias : (obs['deviceFeatureName'] ?? '').toString();
    final serialId = (obs['serialId'] ?? '').toString();
    final time = (obs['time'] ?? '').toString();
    final value = (obs['value'] ?? '').toString();

    return GestureDetector(
      onTap: () => _openFullscreenCamera(context, value),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 1.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
          border: Border.all(color: Colors.blue.shade100, width: 0.5.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3.w),
              child: AspectRatio(
                aspectRatio: 16 / 12,
                child:
                    _pausedCameras.contains(value)
                        ? const ColoredBox(color: Colors.black12)
                        : CameraViewer(url: value),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              featureName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: const Color(0xFF065B4C),
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              '編號：$serialId',
              style: TextStyle(fontSize: 14.sp, color: Colors.black54),
            ),
            Text(time, style: TextStyle(fontSize: 13.sp, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationCard(dynamic obs) {
    final isCamera =
        (obs['featureEnglishName'] ?? '').toString().toLowerCase() == 'camera';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final card = _buildObservationContent(obs, width);

        if (isCamera) {
          return SizedBox(
            width: width * 2 + 3.w, // 寬度拉大2倍＋間隔
            child: card,
          );
        } else {
          return card;
        }
      },
    );
  }

  Widget _buildObservationContent(dynamic obs, double width) {
    final alias = (obs['alias'] ?? '').toString();
    final featureName =
        alias.isNotEmpty ? alias : (obs['deviceFeatureName'] ?? '').toString();
    final value = (obs['value'] ?? '').toString();
    final serialId = (obs['serialId'] ?? '').toString();
    final time = (obs['time'] ?? '').toString();
    final isCamera =
        (obs['featureEnglishName'] ?? '').toString().toLowerCase() == 'camera';
    final isActuator =
        (obs['style'] ?? '').toString().toLowerCase() == 'actuator';
    final iconData = ObservationIcons.getIcon(obs['deviceFeatureName']);
    bool isSwitchOn = (value.toLowerCase() == 'true');
    bool _isSwitchLoading = false;

    return StatefulBuilder(
      builder: (context, setInnerState) {
        final bool enableLongPressToAuto = isActuator;

        return GestureDetector(
          onLongPress:
              enableLongPressToAuto
                  ? () => _viewAutoControl(context, obs)
                  : null,
          child: Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 上：編號 + 更多
                Row(
                  children: [
                    Text(
                      '編號: $serialId',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (isActuator)
                      PopupMenuButton<String>(
                        tooltip: '更多',
                        onSelected: (key) {
                          if (key == 'auto') _viewAutoControl(context, obs);
                        },
                        itemBuilder:
                            (context) => const [
                              PopupMenuItem(
                                value: 'auto',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.settings_suggest_rounded,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text('自動控制設定'),
                                  ],
                                ),
                              ),
                            ],
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 0.5.h),

                // 中：主體 (Expanded 撐開)
                Expanded(
                  child: Center(
                    child:
                        isActuator
                            ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isSwitchOn ? 'ON' : 'OFF',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    color:
                                        isSwitchOn ? Colors.green : Colors.red,
                                  ),
                                ),
                                SizedBox(height: 0.8.h),
                                Switch(
                                  value: isSwitchOn,
                                  onChanged:
                                      _isSwitchLoading
                                          ? null
                                          : (bool newValue) async {
                                            // 原本的 switchSetting 邏輯
                                          },
                                ),
                              ],
                            )
                            : Align(
                              alignment: Alignment.bottomCenter,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(2.w),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      iconData,
                                      size: 9.w,
                                      color: const Color(0xFF065B4C),
                                    ),
                                  ),
                                  SizedBox(height: 0.2.h),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  ),
                ),

                SizedBox(height: 0.2.h),

                // 下：名稱 + 時間 + 查看歷史
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    featureName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                  ),
                ),
                Text(
                  time,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
                if (!isCamera)
                  TextButton(
                    onPressed: () => _viewHistory(context, obs),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF065B4C),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('查看歷史資料'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNonCameraListByDeviceSliver() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, deviceIndex) {
        final device = widget.devices[deviceIndex];
        return _buildDeviceSectionForListMode(device);
      }, childCount: widget.devices.length),
    );
  }

  Widget _buildDeviceSectionForListMode(dynamic device) {
    final deviceName = (device['name'] ?? '未命名裝置').toString();

    // 該裝置的非攝影機觀測值
    final List<dynamic> items =
        (device['observationlatest'] as List)
            .where(
              (o) =>
                  ((o['featureEnglishName'] ?? '').toString().toLowerCase() !=
                      'camera'),
            )
            .toList()
          ..sort((a, b) {
            final aIsActuator = (a['style'] ?? '').toString() == 'Actuator';
            final bIsActuator = (b['style'] ?? '').toString() == 'Actuator';
            if (aIsActuator && !bIsActuator) return -1;
            if (!aIsActuator && bIsActuator) return 1;
            final aSerial =
                int.tryParse((a['serialId'] ?? '0').toString()) ?? 0;
            final bSerial =
                int.tryParse((b['serialId'] ?? '0').toString()) ?? 0;
            return aSerial.compareTo(bSerial);
          });

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 裝置小標題
          Padding(
            padding: EdgeInsets.symmetric(vertical: 0.5.h, horizontal: 1.w),
            child: Text(
              deviceName,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF065B4C),
              ),
            ),
          ),
          // 該裝置的條列卡片
          ...items
              .map((obs) => _buildNonCameraListItemOnlyFeature(obs))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildNonCameraListItemOnlyFeature(dynamic obs) {
    final alias = (obs['alias'] ?? '').toString();
    final featureName =
        alias.isNotEmpty ? alias : (obs['deviceFeatureName'] ?? '').toString();
    final serialId = (obs['serialId'] ?? '').toString();
    final time = (obs['time'] ?? '').toString();
    final valueRaw = (obs['value'] ?? '').toString();
    final isActuator =
        (obs['style'] ?? '').toString().toLowerCase() == 'actuator';
    final iconData = ObservationIcons.getIcon(obs['deviceFeatureName']);

    bool isSwitchOn = valueRaw.toLowerCase() == 'true';
    bool _isSwitchLoading = false;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.h),
      child: GestureDetector(
        onLongPress: isActuator ? () => _viewAutoControl(context, obs) : null,
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
            border: Border.all(color: Colors.blue.shade100, width: 0.5.w),
          ),
          child: StatefulBuilder(
            builder: (context, setInner) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(2.6.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      size: 7.w,
                      color: const Color(0xFF065B4C),
                    ),
                  ),
                  SizedBox(width: 3.w),

                  // 中：只顯示 featureName
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 功能名稱
                        Text(
                          featureName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.3.h),
                        Text(
                          '編號：$serialId   |   $time',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isActuator) ...[
                          SizedBox(height: 0.3.h),
                          Text(
                            valueRaw,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 右：Actuator（Switch + ⋮）或 非 Actuator（查看歷史）
                  if (isActuator)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isSwitchOn,
                              activeColor: Colors.blue,
                              inactiveThumbColor: Colors.grey,
                              onChanged:
                                  _isSwitchLoading
                                      ? null
                                      : (bool newValue) async {
                                        setInner(() => _isSwitchLoading = true);
                                        final success = await apiService
                                            .switchSetting(
                                              deviceUUID: obs['deviceUUID'],
                                              featureEnglishName:
                                                  obs['featureEnglishName'],
                                              serialId: serialId,
                                              newValue: newValue,
                                            );
                                        if (success && context.mounted) {
                                          setInner(() {
                                            obs['value'] = newValue.toString();
                                            isSwitchOn = newValue;
                                          });
                                        }
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                success ? '開關成功' : '送出失敗',
                                              ),
                                            ),
                                          );
                                        }
                                        setInner(
                                          () => _isSwitchLoading = false,
                                        );
                                      },
                            ),
                            PopupMenuButton<String>(
                              tooltip: '更多',
                              onSelected: (key) {
                                if (key == 'auto') {
                                  _viewAutoControl(context, obs);
                                }
                              },
                              itemBuilder:
                                  (context) => const [
                                    PopupMenuItem(
                                      value: 'auto',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.settings_suggest_rounded,
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Text('自動控制設定'),
                                        ],
                                      ),
                                    ),
                                  ],
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => _viewHistory(context, obs),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF065B4C),
                            textStyle: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('查看歷史'),
                        ),
                      ],
                    )
                  else
                    TextButton(
                      onPressed: () => _viewHistory(context, obs),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF065B4C),
                        textStyle: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('查看歷史'),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openFullscreenCamera(BuildContext context, String url) {
    // 先把列表上的相同 URL 暫停
    setState(() {
      _pausedCameras.add(url);
    });

    Uri u = Uri.parse(url);

    // 取得帳密（若 url 有 user:pass@）
    final userInfo = u.userInfo;
    String? username;
    String? password;
    if (userInfo.isNotEmpty && userInfo.contains(':')) {
      final parts = userInfo.split(':');
      username = parts[0];
      password = parts[1];
    }

    // 推得控制端點 base
    // 規則：
    // - http/https 串流：沿用原本 scheme/port
    // - rtsp 串流：ctrlScheme = http，控制埠 = (串流埠 - 1)（若原本沒帶 port 就不附加）
    String ctrlScheme;
    int? ctrlPort;

    if (u.scheme == 'http' || u.scheme == 'https') {
      ctrlScheme = u.scheme;
      ctrlPort = u.hasPort ? u.port : null;
    } else {
      // rtsp => http，且 port - 1
      ctrlScheme = 'http';
      if (u.hasPort) {
        final p = u.port - 1;
        ctrlPort = p > 0 ? p : null; // 避免無效或負數埠
      } else {
        ctrlPort = null; // 沒有帶埠就不附加（會用 http 預設 80）
      }
    }

    final authority = (ctrlPort != null) ? '${u.host}:$ctrlPort' : u.host;

    // 若你想把 user:pass 放在 URL 上（有些設備要），可加在這裡：
    final userInfoInUrl =
        (username != null && password != null) ? '$username:$password@' : '';

    final controlBase =
        '$ctrlScheme://$userInfoInUrl$authority/cgi-bin/camctrl/camctrl.cgi';
    // final controlBase =
    //     '$ctrlScheme://$userInfoInUrl$authority/cgi-bin/camctrl/eCamCtrl.cgi';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                centerTitle: true,
                backgroundColor: const Color(0xFF065B4C),
                foregroundColor: Colors.white,
                title: const Text('攝影機直播'),
              ),
              body: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 12,
                      child: CameraViewer(url: url), // 全螢幕這裡照常播放
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PtzPad(
                        controlBase: controlBase,
                        username: username,
                        password: password,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    ).then((_) {
      // 返回時恢復列表上的播放
      if (mounted) {
        setState(() {
          _pausedCameras.remove(url);
        });
      }
    });
  }

  void _viewHistory(BuildContext context, dynamic obs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ObservationHistoryPage(
              deviceUUID: obs['deviceUUID'],
              featureEnglishName: obs['featureEnglishName'],
              serialId: obs['serialId'],
            ),
      ),
    );
  }

  void _viewAutoControl(BuildContext context, dynamic obs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AutoControlPage(
              obs: obs,
              deviceUUID: obs['deviceUUID'],
              featureEnglishName: obs['featureEnglishName'],
              serialId: obs['serialId'],
            ),
      ),
    );
  }
}

class _PtzPad extends StatefulWidget {
  final String controlBase; // 例如 http://host:port/cgi-bin/camctrl/camctrl.cgi
  final String? username;
  final String? password;

  const _PtzPad({required this.controlBase, this.username, this.password});

  @override
  State<_PtzPad> createState() => _PtzPadState();
}

class _PtzPadState extends State<_PtzPad> {
  bool _zoomBusy = false;
  bool _moving = false; // 目前是否正在連續移動（長按）
  String? _movingDir; // 當前方向
  Timer? _nudgeTimer; // 點一下的小步移動計時器（自動 stop）

  // ====== 基礎 API 包裝 ======
  Future<void> _startMove(String dir) async {
    if (_moving && _movingDir == dir) return;
    _moving = true;
    _movingDir = dir;
    HapticFeedback.selectionClick();
    await apiService.cameraMove(
      controlBase: widget.controlBase,
      direction: dir,
      username: widget.username,
      password: widget.password,
    );
  }

  Future<void> _stopMove() async {
    if (!_moving) return;
    _moving = false;
    final ok = await apiService.cameraMove(
      controlBase: widget.controlBase,
      direction: 'stop',
      username: widget.username,
      password: widget.password,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PTZ 停止失敗')));
    }
    _movingDir = null;
  }

  Future<void> _nudge(String dir, {int ms = 200}) async {
    // 點一下：短促移動
    await _startMove(dir);
    _nudgeTimer?.cancel();
    _nudgeTimer = Timer(Duration(milliseconds: ms), _stopMove);
  }

  Future<void> _zoom(String action) async {
    if (_zoomBusy) return;
    setState(() => _zoomBusy = true);
    HapticFeedback.lightImpact();
    final ok = await apiService.cameraZoom(
      controlBase: widget.controlBase,
      action: action, // tele / wide
      username: widget.username,
      password: widget.password,
    );
    if (!mounted) return;
    setState(() => _zoomBusy = false);
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('變焦失敗')));
    }
  }

  // ====== UI 元件 ======
  Widget _softCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(10),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.28),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _roundBtn(
    IconData icon, {
    VoidCallback? onPressed,
    bool active = false,
    double size = 56,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            active
                ? const Color(0xFF065B4C).withOpacity(0.95)
                : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: active ? Colors.white : const Color(0xFF065B4C),
        ),
        onPressed: onPressed,
      ),
    );
  }

  // 方向鍵（點一下 = 發送一次 API）
  Widget _dirBtn(IconData icon, String dir, {double size = 56}) {
    final isActive = _moving && _movingDir == dir;
    return _roundBtn(
      icon,
      active: isActive,
      size: size,
      onPressed: () {
        // 點一下直接呼叫一次移動 API
        _nudge(dir);
      },
    );
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double btnSize = 56; // 單一按鈕大小
    const double gap = 10; // 按鈕間距
    const double sideGap = 12; // Zoom 與 DPad 的左右間距

    return _softCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左側：放大
          _zoomColumn(icon: Icons.zoom_in, action: 'tele', size: 50),

          const SizedBox(width: sideGap),

          // 中間：方向盤（置中）
          _dpad(btnSize: btnSize, gap: gap),

          const SizedBox(width: sideGap),

          // 右側：縮小
          _zoomColumn(icon: Icons.zoom_out, action: 'wide', size: 50),
        ],
      ),
    );
  }

  // === 方向盤（置中）===
  Widget _dpad({required double btnSize, required double gap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 上
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: btnSize + gap), // 讓上鍵置中
            _dirBtn(Icons.keyboard_arrow_up_rounded, 'up', size: btnSize),
            SizedBox(width: btnSize + gap),
          ],
        ),
        SizedBox(height: gap),

        // 中（左/停/右）
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dirBtn(Icons.keyboard_arrow_left_rounded, 'left', size: btnSize),
            SizedBox(width: gap),
            _dirBtn(Icons.stop_rounded, 'home', size: btnSize),
            SizedBox(width: gap),
            _dirBtn(Icons.keyboard_arrow_right_rounded, 'right', size: btnSize),
          ],
        ),
        SizedBox(height: gap),

        // 下
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: btnSize + gap),
            _dirBtn(Icons.keyboard_arrow_down_rounded, 'down', size: btnSize),
            SizedBox(width: btnSize + gap),
          ],
        ),
      ],
    );
  }

  // === 左/右側 Zoom 柱狀按鈕 ===
  Widget _zoomColumn({
    required IconData icon,
    required String action, // 'tele' or 'wide'
    double size = 50,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _roundBtn(
          icon,
          onPressed: _zoomBusy ? null : () => _zoom(action),
          size: size,
        ),
      ],
    );
  }
}
