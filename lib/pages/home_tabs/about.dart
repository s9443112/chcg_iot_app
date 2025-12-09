import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(theme: theme),

              const SizedBox(height: 20),

              // 使命與願景
              _SectionCard(
                title: '使命與願景',
                icon: Icons.flag_outlined,
                paragraphs: const [
                  'AgriTalk 以「解決實際農業問題」為核心，聚焦病蟲害、土壤與水資源等農業痛點，導入 AI 與物聯網進行精準管理。',
                ],
                bullets: const [
                  '讓非專業農民也能種出專業等級作物，降低試錯成本與風險。',
                  '推動青年返鄉與農村創生，促進在地就業與世代傳承。',
                  '提供「無農藥、無重金屬、無毒素」的安心農產與保健商品，落實企業社會責任。',
                ],
              ),

              const SizedBox(height: 16),

              // 我們在做什麼
              _SectionCard(
                title: '我們在做什麼',
                icon: Icons.agriculture_outlined,
                paragraphs: const [
                  'AgriTalk 智慧農業平台整合「環境感測、雲端資料庫、AI 模型與遠端控制」，協助農戶即時掌握農地狀況並自動化執行管理決策。',
                ],
                chips: const [
                  '環境即時監測（溫濕度、光照、風雨…）',
                  'AI 病蟲害預測與警示',
                  '遠端控制與自動化排程',
                  '視覺化報表與溯源查詢',
                  '跨裝置支援（Web / 手機 / 平板）',
                ],
              ),

              const SizedBox(height: 16),

              // 里程碑與榮耀
              _SectionCard(
                title: '里程碑與榮耀',
                icon: Icons.emoji_events_outlined,
                paragraphs: const [
                  'AgriTalk 團隊源自國立陽明交通大學跨域研發，累積多項智慧農業實證經驗，並獲得國內外創新競賽與計畫補助肯定。相關研究成果發表於期刊與研討會，持續在臺灣各地農場落地應用。',
                ],
              ),

              const SizedBox(height: 16),

              // 聯絡資訊
              _SectionCard(
                title: '聯絡我們',
                icon: Icons.contacts_outlined,
                customChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _InfoRow(
                      icon: Icons.email_outlined,
                      label: '信箱',
                      value: 'wenwen@agritalk.com.tw',
                    ),
                    const SizedBox(height: 8),
                    const _InfoRow(
                      icon: Icons.phone_outlined,
                      label: '客服專線',
                      value: '03-571-1199（服務時間 09:00–18:00）',
                    ),
                    const SizedBox(height: 8),
                    const _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: '地址',
                      value:
                          '300193 新竹市東區博愛街 75 號 10 樓 1005 室\n（國立陽明交通大學 博愛校區 賢齊館）',
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () async {
                            final uri = Uri.parse(
                              "https://www.agritalk.com.tw/pages/about-us",
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(Icons.public, size: 18),
                          label: const Text('官網・關於我們'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () async {
                            final uri =
                                Uri.parse("https://www.agritalk.com.tw/");
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('聯絡我們'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 版權/尾註
              Center(
                child: Column(
                  children: [
                    Divider(
                      color: theme.dividerColor.withOpacity(0.4),
                      height: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© ${DateTime.now().year} AgriTalk 農譯科技',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '智慧農業 · 安心溯源 · 科技友善土地',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 頂部大卡片（Logo + slogan +簡短說明）
class _HeaderCard extends StatelessWidget {
  final ThemeData theme;
  const _HeaderCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7B4DBB),
            const Color(0xFF7B4DBB).withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: ClipOval(
              child: Image.asset(
                'assets/logo-01.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '關於 AgriTalk',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '以 AI + IoT + 生物科技，打造「無毒、可追溯」的智慧農業解決方案。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<String>? paragraphs;
  final List<String>? bullets;
  final List<String>? chips;
  final Widget? customChild;

  const _SectionCard({
    required this.title,
    this.icon,
    this.paragraphs,
    this.bullets,
    this.chips,
    this.customChild,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor =
        theme.colorScheme.surfaceVariant.withOpacity(0.3);

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題列
            Row(
              children: [
                Container(
                  width: 6,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                if (icon != null) ...[
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            // 段落
            if (paragraphs != null && paragraphs!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...paragraphs!.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    p,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],

            // 條列 bullet
            if (bullets != null && bullets!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...bullets!.map((b) => _Bullet(text: b)),
            ],

            // 小標籤 chips
            if (chips != null && chips!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips!
                    .map(
                      (c) => Chip(
                        label: Text(
                          c,
                          style: const TextStyle(fontSize: 12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(.08),
                        side: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(.2),
                        ),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],

            // 客製內容
            if (customChild != null) ...[
              const SizedBox(height: 12),
              customChild!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label：',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
