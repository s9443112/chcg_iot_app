import 'package:flutter/material.dart';
import 'package:agritalk_iot_app/core/observation_icons.dart';
import 'package:agritalk_iot_app/core/hlscamera.dart';
import 'package:agritalk_iot_app/pages/home_tabs/observationhistory.dart';
import 'package:agritalk_iot_app/pages/home_tabs/autocontrol.dart';
import 'package:agritalk_iot_app/core/api_service.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            centerTitle: true,
            backgroundColor: const Color(0xFF7B4DBB),
            foregroundColor: Colors.white,
            elevation: 1,
            title: Text(
              '目標即時資料 - ${widget.areaName}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final device = widget.devices[index];
                final deviceObservations = device["observationlatest"].toList();
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
    // final others =
    //     deviceObservations
    //         .where(
    //           (o) =>
    //               (o['featureEnglishName'] ?? '').toString().toLowerCase() !=
    //               'camera',
    //         )
    //         .toList();
    // print(others);

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

    // print(others);

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
                Icon(Icons.sensors, size: 6.w, color: const Color(0xFF7B4DBB)),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    device['name'] ?? '未命名裝置',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7B4DBB),
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
                  childAspectRatio: 0.75,
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
                child: HlsCameraViewer(url: value),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              featureName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: const Color(0xFF7B4DBB),
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
        return Container(
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左上角編號
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    '編號: $serialId',
                    style: TextStyle(
                      fontSize: 14.0.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                SizedBox(height: 0.5.h),

                if (isCamera)
                  GestureDetector(
                    onTap: () => _openFullscreenCamera(context, value),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3.w),
                      child: AspectRatio(
                        aspectRatio: 16 / 12,
                        child: HlsCameraViewer(url: value),
                      ),
                    ),
                  )
                else if (isActuator)
                  Column(
                    children: [
                      Text(
                        isSwitchOn ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: isSwitchOn ? Colors.green : Colors.red,
                        ),
                      ),
                      SizedBox(height: 0.8.h),
                      Switch(
                        value: isSwitchOn,
                        activeColor: Colors.blue,
                        inactiveThumbColor: Colors.grey,
                        onChanged:
                            _isSwitchLoading
                                ? null
                                : (bool newValue) async {
                                  setInnerState(() => _isSwitchLoading = true);
                                  final success = await apiService
                                      .switchSetting(
                                        deviceUUID: obs['deviceUUID'],
                                        featureEnglishName:
                                            obs['featureEnglishName'],
                                        serialId: serialId,
                                        newValue: newValue,
                                      );
                                  if (success && context.mounted) {
                                    setInnerState(() {
                                      obs['value'] = newValue.toString();
                                      isSwitchOn = newValue;
                                    });
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success ? '開關成功' : '送出失敗',
                                        ),
                                      ),
                                    );
                                  }
                                  setInnerState(() => _isSwitchLoading = false);
                                },
                      ),
                    ],
                  )
                else
                  Column(
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
                          color: const Color(0xFF7B4DBB),
                        ),
                      ),
                      // SizedBox(height: 0.1.h),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                // SizedBox(height: 0.8.h),

                // 功能名稱，不換行，自動縮小
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    featureName,
                    style: TextStyle(
                      fontSize: 17.5.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                  ),
                ),

                // SizedBox(height: 0.5.h),
                Text(
                  time,
                  style: TextStyle(fontSize: 14.0.sp, color: Colors.grey),
                ),
                if (!isCamera && !isActuator)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: TextButton(
                      onPressed: () => _viewHistory(context, obs),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF7B4DBB),
                        // padding: EdgeInsets.zero,
                        // minimumSize: Size.zero,
                        // tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('查看歷史資料'),
                    ),
                  ),

                if (isActuator)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: TextButton(
                      onPressed: () => _viewAutoControl(context, obs),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF7B4DBB),
                        // padding: EdgeInsets.zero,
                        // minimumSize: Size.zero,
                        // tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('自動控制設定'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFullscreenCamera(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                centerTitle: true,
                backgroundColor: const Color(0xFF7B4DBB),
                foregroundColor: Colors.white,
                title: const Text('攝影機直播'),
              ),
              body: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 12,
                  child: HlsCameraViewer(url: url),
                ),
              ),
            ),
      ),
    );
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
