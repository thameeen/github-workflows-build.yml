import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const HeedarTvApp());

const gold = Color(0xFFD4AF37);
const bg = Color(0xFF07080A);

class MediaLink {
  final String title;
  final String subtitle;
  final String category;
  final String url;
  final IconData icon;
  const MediaLink(this.title, this.subtitle, this.category, this.url, this.icon);

  Uri get uri => Uri.parse(url);
}

// روابط صفحات رسمية فقط. التوفر والمحتوى قد يختلفان حسب البلد.
const catalog = <MediaLink>[
  MediaLink('التلفزيون الأردني — بث مباشر', 'الموقع الرسمي • الأردن', 'قنوات', 'https://www.jrtv.gov.jo/ar/live-tv', Icons.live_tv),
  MediaLink('رؤيا — بث مباشر', 'الموقع الرسمي • الأردن', 'قنوات', 'https://roya.tv/live-stream/1', Icons.live_tv),
  MediaLink('قنوات رؤيا', 'Roya TV وRoya News وقنوات أخرى', 'قنوات', 'https://roya.tv/', Icons.tv),
  MediaLink('شاهد — بث ومحتوى عربي', 'قد يتطلب بعض المحتوى اشتراكاً', 'قنوات', 'https://shahid.mbc.net/ar', Icons.live_tv),
  MediaLink('التلفزيون الأردني — مسلسلات', 'المسلسلات والأرشيف الرسمي', 'مسلسلات', 'https://www.jrtv.gov.jo/ar/series', Icons.movie),
  MediaLink('رؤيا — مسلسلات', 'المسلسلات على الموقع الرسمي', 'مسلسلات', 'https://roya.tv/series', Icons.tv),
  MediaLink('شاهد — مسلسلات', 'حلقات مجانية ومدفوعة حسب العنوان', 'مسلسلات', 'https://shahid.mbc.net/ar/series', Icons.tv),
  MediaLink('قناة شاهد الرسمية على يوتيوب', 'حلقات ومقاطع يتيحها الناشر مجاناً', 'مسلسلات', 'https://www.youtube.com/@MBCShahid', Icons.smart_display),
  MediaLink('tabii عربي — دراما تركية', 'قناة الناشر الرسمية؛ حلقات عربية متاحة حسب العنوان', 'مسلسلات تركية', 'https://www.youtube.com/@tabii.arabic', Icons.subtitles),
  MediaLink('قيامة أرطغرل — الحلقات الرسمية', 'قائمة حلقات من قناة tabii عربي الرسمية', 'مسلسلات تركية', 'https://www.youtube.com/playlist?list=PLZhY-MJA-pw-hzp40xUApZd8LLgJEZD53', Icons.movie),
  MediaLink('Deep in Love — ترجمة عربية', 'قائمة رسمية على tabii؛ الترجمة متاحة من إعدادات يوتيوب', 'مسلسلات تركية', 'https://www.youtube.com/playlist?list=PLDoK5CcjJZA5zEFnpeYwsTjsMHfrQlpa_', Icons.subtitles),
  MediaLink('رؤيا — أفلام مختارة', 'اختيارات متاحة عبر الموقع الرسمي', 'أفلام', 'https://roya.tv/', Icons.local_movies),
  MediaLink('شاهد — أفلام', 'تختلف الإتاحة؛ قد يتطلب بعضها VIP', 'أفلام', 'https://shahid.mbc.net/ar/movies', Icons.movie_creation),
  MediaLink('الجزيرة — بث مباشر', 'قنوات الجزيرة الرسمية', 'أخبار', 'https://www.aljazeera.net/live', Icons.newspaper),
  MediaLink('العربية — بث مباشر', 'البث الرسمي لقناة العربية', 'أخبار', 'https://www.alarabiya.net/live-stream', Icons.newspaper),
  MediaLink('الحدث — بث مباشر', 'البث الرسمي لقناة الحدث', 'أخبار', 'https://www.alarabiya.net/live-stream-hadath', Icons.newspaper),
  MediaLink('قناة المملكة الأردنية', 'موقع القناة الرسمي والبث المباشر', 'أخبار', 'https://almamlakatv.com/', Icons.newspaper),
  MediaLink('المملكة — بث مباشر على يوتيوب', 'البث الرسمي؛ إذا كان متاحاً', 'أخبار', 'https://www.youtube.com/watch?v=YAQQ1RLfQtY', Icons.smart_display),
  MediaLink('التلفزيون الأردني — القناة الرياضية', 'اختَر الرياضية من البث الرسمي لقنوات JRTV', 'رياضة', 'https://www.jrtv.gov.jo/ar/live-tv', Icons.sports_soccer),
  MediaLink('Jordan TV Sport — يوتيوب', 'حلقات وملخصات ومحتوى رياضي رسمي', 'رياضة', 'https://www.youtube.com/@jordantvsport', Icons.sports_soccer),
  MediaLink('Roya Sports — يوتيوب', 'أخبار وملخصات رياضية رسمية؛ البث حسب الحقوق', 'رياضة', 'https://www.youtube.com/royasports', Icons.sports_soccer),
];

class HeedarTvApp extends StatelessWidget {
  const HeedarTvApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Heedar TV',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: bg,
          colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        home: const CatalogScreen(),
      );
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String selected = 'الكل';
  String query = '';
  bool opening = false;

  Future<void> openOfficial(MediaLink item) async {
    setState(() => opening = true);
    try {
      final ok = await launchUrl(item.uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح الرابط. تحقق من اتصال الإنترنت.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح الرابط.')),
        );
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const categories = ['الكل', 'قنوات', 'أفلام', 'مسلسلات', 'مسلسلات تركية', 'أخبار', 'رياضة'];
    final filtered = catalog.where((item) {
      final categoryMatch = selected == 'الكل' || item.category == selected;
      final queryMatch = '${item.title} ${item.subtitle}'.toLowerCase().contains(query.toLowerCase());
      return categoryMatch && queryMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0E14),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('HEEDAR TV', style: TextStyle(color: gold, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          Text('دليل المصادر الرسمية — الأردن', style: TextStyle(fontSize: 11, color: Colors.white60)),
        ]),
        actions: [if (opening) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: gold)))],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: InputDecoration(
              hintText: 'ابحث عن قناة أو فيلم أو مسلسل',
              prefixIcon: const Icon(Icons.search, color: gold),
              filled: true,
              fillColor: const Color(0xFF12151D),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            for (final category in categories)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(category),
                  selected: selected == category,
                  selectedColor: gold,
                  onSelected: (_) => setState(() => selected = category),
                ),
              ),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('تفتح العناصر مواقعها أو تطبيقاتها الرسمية. توفر المحتوى وشروط المشاهدة يحددهما كل مزوّد.', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('لا توجد نتائج', style: TextStyle(color: Colors.white60)))
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Card(
                      color: const Color(0xFF12151D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: gold.withOpacity(.22))),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: gold.withOpacity(.16), child: Icon(item.icon, color: gold)),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${item.category} • ${item.subtitle}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: const Icon(Icons.open_in_new, color: gold, size: 20),
                        onTap: () => openOfficial(item),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
