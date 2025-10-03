import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:agritalk_iot_app/pages/home_tabs/guava_page/guava_page.dart';
import 'package:agritalk_iot_app/pages/home_tabs/grape_page/grape_page.dart';
import 'package:agritalk_iot_app/pages/home_tabs/disease_ai/main.dart';
import 'package:agritalk_iot_app/pages/home_tabs/NewsDetailPage.dart';
import 'package:agritalk_iot_app/core/api_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final apiService = ApiService();

  List<dynamic> newsCarouselList = [];
  List<dynamic> newsCenterList = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchNewsData();
  }

  Future<void> fetchNewsData() async {
    try {
      final data = await apiService.fetchNews();

      if (mounted && data != null) {
        setState(() {
          newsCarouselList = data['latest_news_carousel'] ?? [];
          newsCenterList = data['latest_news_center'] ?? [];
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          newsCarouselList = [];
          newsCenterList = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF065B4C),
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          '智慧農業資源平台',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _buildSectionTitle("熱門資源入口", onShowAll: () {}),
          const SizedBox(height: 8),
          _buildEntrySlider(),

          const SizedBox(height: 24),
          _buildSectionTitle("近期焦點消息", onShowAll: () {}),
          const SizedBox(height: 8),

          _buildNewsSlider(),

          const SizedBox(height: 24),
          _buildSectionTitle("訊息中心", onShowAll: () {}),
          const SizedBox(height: 8),
          _buildRankList(),
          
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onShowAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        // GestureDetector(
        //   onTap: onShowAll,
        //   child: const Text('顯示全部', style: TextStyle(color: Colors.indigo)),
        // ),
      ],
    );
  }

  Widget _buildEntrySlider() {
    final entries = [
      {
        'title': '芭樂雲',
        'subtitle': '進入芭樂雲平台',
        'image': 'assets/homepage/guava.jpg',
        'url': null,
      },
      {
        'title': '葡萄雲',
        'subtitle': '進入葡萄雲平台',
        'image': 'assets/homepage/grape.jpg',
        'url': null,
      },
      // {
      //   'title': '白粉病檢測',
      //   'subtitle': '進入白粉病檢測平台',
      //   'image': 'assets/homepage/detection.png',
      //   'url': null,
      // },
      // {
      //   'title': '防檢署藥劑',
      //   'subtitle': '查看藥劑資料',
      //   'image': 'assets/homepage/drug.png',
      //   'url': 'https://www.aphia.gov.tw/',
      // },
      // {
      //   'title': '農糧署',
      //   'subtitle': '農糧署服務',
      //   'image': 'assets/homepage/agriculture.jpg',
      //   'url': 'https://www.afa.gov.tw/cht/index.php?code=list&ids=556',
      // },
      // {
      //   'title': '彰化縣政府',
      //   'subtitle': '地方政府平台',
      //   'image': 'assets/homepage/changhua.png',
      //   'url': 'https://www.chcg.gov.tw/ch2/index.aspx',
      // },
      // {
      //   'title': '農譯科技',
      //   'subtitle': '進入農譯科技',
      //   'image': 'assets/homepage/agritalk.png',
      //   'url': 'https://www.agritalk.com.tw/',
      // },
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final e = entries[index];
          return GestureDetector(
            onTap: () async {
              if (e['url'] != null) {
                await launchUrl(
                  Uri.parse(e['url'].toString()),
                  mode: LaunchMode.externalApplication,
                );
              } else {
                if (e['title'] == '芭樂雲') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GuavaPage()),
                  );
                } else if (e['title'] == '葡萄雲') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GrapePage()),
                  );
                } else if (e['title'] == '白粉病檢測') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DiseaseAIMainPage()),
                  );
                }
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    e['image'].toString(),
                    width: 80,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  e['title'].toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsSlider() {
    if (newsCarouselList.isEmpty) {
      return const Center(
        child: Text('目前沒有新聞資料', style: TextStyle(color: Colors.grey)),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: newsCarouselList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = newsCarouselList[index];

          final String imageUrl = item['image'] ?? '';
          final String title = (item['title'] ?? '').replaceFirst('標題：', '');
          final String date = (item['date'] ?? '').replaceFirst('發佈日期：', '');
          final String link = item['link'] ?? '';

          return GestureDetector(
            onTap: () async {
              if (link.isNotEmpty && await canLaunchUrl(Uri.parse(link))) {
                await launchUrl(
                  Uri.parse(link),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            child: SizedBox(
              width: 280,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 圖片
                    imageUrl.isNotEmpty
                        ? Image.network(
                          imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                height: 120,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                        )
                        : Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image_not_supported),
                          ),
                        ),
                    // 文字內容
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            date,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsCard({
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              image,
              height: 120, // ✅ 控制圖片不要過高
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankList() {
  if (newsCenterList.isEmpty) {
    return const Center(
      child: Text('目前沒有訊息中心資料', style: TextStyle(color: Colors.grey)),
    );
  }

  return Column(
    children: newsCenterList.map((item) {
      final String title = (item['title'] ?? '').replaceFirst('標題：', '');
      final String date = (item['date'] ?? '').replaceFirst('發佈日期：', '');
      final String link = item['link'] ?? '';
      final String tag = (item['tag'] ?? '').replaceFirst('分顃：', '');

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: GestureDetector(
          onTap: () async {
            if (link.isNotEmpty && await canLaunchUrl(Uri.parse(link))) {
              await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.indigo,
                child: const Icon(Icons.article, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    Text('$date  ｜  $tag',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, color: Colors.grey, size: 18),
            ],
          ),
        ),
      );
    }).toList(),
  );
}

}
