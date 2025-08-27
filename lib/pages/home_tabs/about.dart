import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withOpacity(.1),
                    child: Image.asset('assets/logo-01.png'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('關於我們', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          'AgriTalk｜以 AI + IoT + 生物科技，打造「無毒、可追溯」的智慧農業解決方案',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(.75)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 使命與願景
              _SectionCard(
                title: '使命與願景',
                bullets: const [
                  '以「解決問題」為核心，聚焦病蟲害、土壤與水資源等農業痛點，導入 AI 與物聯網進行精準管理。',
                  '讓非專業農民也能種出專業等級作物，推動青年返鄉，促進農村永續與在地就業。',
                  '提供對消費者友善的「無農藥、無重金屬、無毒素」農產與保健商品，落實企業社會責任。',
                ],
              ),

              const SizedBox(height: 16),

              // 我們在做什麼
              _SectionCard(
                title: '我們在做什麼',
                paragraphs: const [
                  'AgriTalk 智慧農業平台整合「環境感測、雲端資料庫、AI 模型與遠端控制」，協助農戶即時掌握農地狀況並自動化執行管理決策。',
                ],
                chips: const [
                  '即時監測（溫濕度、光照、風雨等）',
                  'AI 病蟲害預測',
                  '遠端控制與自動化排程',
                  '視覺化報表與溯源',
                  '跨裝置（PC/平板/手機）',
                ],
              ),

              const SizedBox(height: 16),

              // 里程碑與榮耀（簡述）
              _SectionCard(
                title: '里程碑與榮耀',
                paragraphs: const [
                  '團隊源自國立陽明交通大學跨域研發，榮獲多項國內外肯定；相關研究成果曾發表於多個期刊與媒體，並持續於臺灣各地實證與落地應用。',
                ],
              ),

              const SizedBox(height: 16),

              // 聯絡資訊
              _SectionCard(
                title: '聯絡我們',
                customChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(icon: Icons.email_outlined, label: '信箱', value: 'wenwen@agritalk.com.tw'),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.phone_outlined, label: '客服專線', value: '03-571-1199（服務時間 09:00–18:00）'),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: '地址',
                      value: '300193 新竹市東區博愛街 75 號 10 樓 1005 室（陽明交大博愛校區 賢齊館）',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            if (await canLaunchUrl(Uri.parse("https://www.agritalk.com.tw/pages/about-us"))) {
                              await launchUrl(
                                Uri.parse("https://www.agritalk.com.tw/pages/about-us"),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(Icons.public),
                          label: const Text('官網關於我們'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async{
                            if (await canLaunchUrl(Uri.parse("https://www.agritalk.com.tw/"))) {
                              await launchUrl(
                                Uri.parse("https://www.agritalk.com.tw/"),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('聯絡頁面'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 版權/尾註
              Center(
                child: Text(
                  '© ${DateTime.now().year} AgriTalk 農譯科技｜智慧農業·安心溯源',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(.6)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<String>? paragraphs;
  final List<String>? bullets;
  final List<String>? chips;
  final Widget? customChild;

  const _SectionCard({
    required this.title,
    this.paragraphs,
    this.bullets,
    this.chips,
    this.customChild,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest?.withOpacity(0.4) ?? theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            if (paragraphs != null && paragraphs!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...paragraphs!.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(p, style: theme.textTheme.bodyMedium),
                ),
              ),
            ],
            if (bullets != null && bullets!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...bullets!.map(
                (b) => _Bullet(text: b),
              ),
            ],
            if (chips != null && chips!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips!
                    .map((c) => Chip(
                          label: Text(c),
                          backgroundColor: theme.colorScheme.primary.withOpacity(.08),
                          side: BorderSide(color: theme.colorScheme.primary.withOpacity(.25)),
                        ))
                    .toList(),
              ),
            ],
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
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
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text('$label：', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
