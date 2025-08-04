import 'package:flutter/material.dart';

class ObservationIcons {
  static const Map<String, IconData> icons = {
    '風扇致動器': Icons.air,
    '噴霧致動器': Icons.opacity,
    '遮陰致動器': Icons.wb_cloudy,
    '捲揚致動器': Icons.sync,
    '滴灌致動器': Icons.invert_colors,
    '灌溉致動器': Icons.water_drop,
    '窗戶致動器': Icons.door_front_door,
    '加熱致動器': Icons.thermostat,
    '給藥致動器': Icons.bug_report,
    '照明致動器': Icons.lightbulb,
    '水濂致動器': Icons.window,
    '沖洗致動器': Icons.water,
    '繼電器致動器': Icons.toggle_on,
    '複合式致動器': Icons.settings_input_composite,

    '低電量告警': Icons.battery_alert,
    '裝置電壓': Icons.flash_on,
    '裝置電流': Icons.flash_on,
    '裝置電量': Icons.battery_full,
    '數據回傳週期': Icons.timer,

    '環境溫度': Icons.thermostat,
    '環境相對濕度': Icons.water_drop,
    '光照度': Icons.wb_sunny,
    '光合有效輻射': Icons.local_florist,
    '太陽輻射度': Icons.brightness_high,

    '一氧化碳': Icons.cloud,
    '二氧化碳': Icons.cloud_queue,
    '氧氣': Icons.air,
    '乙烯': Icons.cloud,
    '氨氣': Icons.cloud,

    '風向': Icons.navigation,
    '風速': Icons.air,
    '降雨量': Icons.grain,
    '大氣壓力': Icons.compress,

    '土壤溫度': Icons.thermostat,
    '土壤水分張力感測器': Icons.water,
    '土壤濕度感測器': Icons.water_drop,
    '土壤電導度': Icons.flash_on,
    '土壤酸鹼值': Icons.science,

    '液位': Icons.bar_chart,
    '酸鹼度': Icons.science,
    '電導度': Icons.flash_on,
    '水溫': Icons.thermostat,
    '葉面溫度': Icons.thermostat,
    '葉面濕度': Icons.water_drop,
    '紫外線輻射': Icons.wb_sunny,

    '懸浮微粒': Icons.blur_on,
    '細懸浮微粒': Icons.blur_on,
    '露點溫度': Icons.grain,

    '流量': Icons.water,
    '流速': Icons.speed,
    '二氧化硫': Icons.cloud,
    '土壤氧氣': Icons.air,
    '溶氧': Icons.water_drop,
    '濁度': Icons.cloud,
    '氧化還原電位': Icons.bolt,
    '總溶解固體量': Icons.scatter_plot,
    '硫化氫': Icons.cloud,
    '甲烷': Icons.cloud,

    '複合式感測': Icons.sensors,
    '紅外線計數': Icons.visibility,
    '重量': Icons.scale,
    '攝影機': Icons.camera_alt,
  };

  static IconData getIcon(String chineseName) {
    return icons[chineseName] ?? Icons.device_unknown;
  }
}
