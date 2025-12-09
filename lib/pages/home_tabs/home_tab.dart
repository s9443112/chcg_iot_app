import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chcg_iot_app/pages/home_tabs/guava_page/guava_page.dart';
import 'package:chcg_iot_app/pages/home_tabs/grape_page/grape_page.dart';
import 'package:chcg_iot_app/pages/home_tabs/disease_ai/main.dart';
import 'package:chcg_iot_app/pages/home_tabs/NewsDetailPage.dart';
import 'package:chcg_iot_app/core/api_service.dart';
import 'package:chcg_iot_app/pages/home_tabs/disease_query/crop_disease_query_page.dart';
import 'package:chcg_iot_app/pages/home_tabs/disease_query/disease_search_page.dart';


class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final apiService = ApiService();

  final Color _primaryColor = const Color(0xFF7B4DBB);

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
        backgroundColor: _primaryColor,
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
              _buildSectionTitle("熱門資源入口"),
              const SizedBox(height: 8),
              _buildEntrySlider(),

              const SizedBox(height: 24),
              _buildSectionTitle("近期焦點消息"),
              const SizedBox(height: 8),
              _buildNewsSlider(),

              const SizedBox(height: 24),
              _buildSectionTitle("訊息中心"),
              const SizedBox(height: 8),
              _buildRankList(),
            ],
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    ],
  );
}


  Widget _buildEntrySlider() {
    final entries = [
      {
        'title': '彰化縣政府',
        'subtitle': '地方政府平台',
        'image': 'assets/homepage/changhua.png',
        'url': 'https://www.chcg.gov.tw/ch2/index.aspx',
      },
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
      {
        'title': '用藥查詢',
        'subtitle': '用藥查詢',
        'image': 'assets/homepage/filer.png', // 你可以換成自己有的圖片
        'url': null,
      },
      {
        'title': '病害查詢',
        'subtitle': '病害查詢',
        'image': 'assets/homepage/detection.png', // 你可以換成自己有的圖片
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
                }else if (e['title'] == '用藥查詢') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CropDiseaseQueryPage(),
                    ),
                  );
                }else if (e['title'] == '病害查詢') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DiseaseSearchPage(),
                    ),
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
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Text(
        '目前沒有新聞資料',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  return SizedBox(
    height: 250,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: newsCarouselList.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final item = newsCarouselList[index];

        final String imageUrl = item['image'] ?? '';
        final String rawTitle = item['title'] ?? '';
        final String title = rawTitle.replaceFirst('標題：', '');
        final String rawDate = item['date'] ?? '';
        final String date = rawDate.replaceFirst('發佈日期：', '');
        final String link = item['link'] ?? '';

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            if (link.isNotEmpty &&
                await canLaunchUrl(Uri.parse(link))) {
              await launchUrl(
                Uri.parse(link),
                mode: LaunchMode.externalApplication,
              );
            }
          },
          child: SizedBox(
            width: 280,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 圖片 + 左上角「焦點」貼紙
                  Stack(
                    children: [
                      imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              height: 130,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      Container(
                                        height: 130,
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
                              height: 130,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image_not_supported),
                              ),
                            ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '焦點',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.event,
                                size: 14, color: Colors.black45),
                            const SizedBox(width: 4),
                            Text(
                              date,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
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
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Text(
        '目前沒有訊息中心資料',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  return Column(
    children: newsCenterList.map((item) {
      final String title =
          (item['title'] ?? '').replaceFirst('標題：', '');
      final String date =
          (item['date'] ?? '').replaceFirst('發佈日期：', '');
      final String link = item['link'] ?? '';
      final String tag =
          (item['tag'] ?? '').replaceFirst('分顃：', '');

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (link.isNotEmpty &&
                await canLaunchUrl(Uri.parse(link))) {
              await launchUrl(
                Uri.parse(link),
                mode: LaunchMode.externalApplication,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左側 icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.article,
                    color: _primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                // 中間文字
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.event,
                              size: 13, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (tag.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.open_in_new,
                  color: Colors.grey,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
}

}
