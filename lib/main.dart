import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ── 1. نموذج القناة ──
class Channel {
  final String id, name, url, group;
  final String? logo;
  bool isFavorite;

  Channel({
    required this.id,
    required this.name,
    required this.url,
    this.logo,
    required this.group,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'logo': logo,
        'group': group,
        'isFavorite': isFavorite,
      };

  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        url: j['url'] ?? '',
        logo: j['logo'],
        group: j['group'] ?? 'عام',
        isFavorite: j['isFavorite'] ?? false,
      );
}

// ── 2. محلل روابط M3U ──
class M3uService {
  static const _uuid = Uuid();
  static Future<List<Channel>> fetchAndParse(String url) async {
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    final lines = const LineSplitter().convert(utf8.decode(res.bodyBytes, allowMalformed: true));
    final List<Channel> list = [];
    String? name, logo;
    String group = 'عام';

    for (var l in lines) {
      l = l.trim();
      if (l.startsWith('#EXTINF:')) {
        logo = RegExp(r'tvg-logo="([^"]*)"').firstMatch(l)?.group(1);
        group = RegExp(r'group-title="([^"]*)"').firstMatch(l)?.group(1) ?? 'عام';
        final c = l.lastIndexOf(',');
        name = c != -1 ? l.substring(c + 1).trim() : 'قناة';
      } else if (!l.startsWith('#') && (l.startsWith('http://') || l.startsWith('https://'))) {
        if (name != null) list.add(Channel(id: _uuid.v4(), name: name, url: l, logo: logo, group: group));
        name = null; logo = null; group = 'عام';
      }
    }
    return list;
  }
}

// ── 3. التطبيق والثيم الملكي الأسود والذهبي ──
void main() => runApp(const HeedarTvApp());

class HeedarTvApp extends StatelessWidget {
  const HeedarTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heedar TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07080A),
        primaryColor: const Color(0xFFD4AF37),
        fontFamily: 'sans-serif',
      ),
      home: const LuxuryPortalScreen(),
    );
  }
}

// ── 4. الواجهة الرئيسية (القائمة على اليسار + 3 كروت سينمائية) ──
class LuxuryPortalScreen extends StatefulWidget {
  const LuxuryPortalScreen({super.key});
  @override
  State<LuxuryPortalScreen> createState() => _LuxuryPortalScreenState();
}

class _LuxuryPortalScreenState extends State<LuxuryPortalScreen> {
  List<Channel> _channels = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    try { WakelockPlus.enable(); } catch (_) {}
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final data = p.getString('ch_list');
    final favs = p.getStringList('fav_list') ?? [];
    if (data != null) {
      final List dec = jsonDecode(data);
      setState(() {
        _channels = dec.map((e) {
          final c = Channel.fromJson(e);
          c.isFavorite = favs.contains(c.url);
          return c;
        }).toList();
      });
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ch_list', jsonEncode(_channels.map((e) => e.toJson()).toList()));
    await p.setStringList('fav_list', _channels.where((e) => e.isFavorite).map((e) => e.url).toList());
  }

  void _addSourceDialog() {
    final u = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF11141C),
        title: const Text('إضافة رابط M3U / M3U8', style: TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(controller: u, decoration: const InputDecoration(labelText: 'رابط البث المباشر')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () async {
              if (u.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => _loading = true);
                try {
                  final list = await M3uService.fetchAndParse(u.text.trim());
                  _channels.addAll(list);
                  await _save();
                } catch (_) {}
                if (mounted) setState(() => _loading = false);
              }
            },
            child: const Text('تحميل'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        // الشريط الجانبي على اليسار حصرياً
        children: [
          // 1. القائمة الجانبية (Left Sidebar)
          Container(
            width: 62,
            color: const Color(0xFF0C0E14),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD4AF37), width: 1.5)),
                  child: const Icon(Icons.tv, color: Color(0xFFD4AF37), size: 24),
                ),
                const Divider(color: Colors.white12, height: 30),
                IconButton(
                  tooltip: 'إضافة مصدر',
                  icon: const Icon(Icons.add_circle, color: Color(0xFFD4AF37), size: 28),
                  onPressed: _addSourceDialog,
                ),
                IconButton(
                  tooltip: 'المفضلة',
                  icon: const Icon(Icons.star, color: Colors.amber, size: 26),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => LiveViewScreen(channels: _channels.where((c) => c.isFavorite).toList(), onSave: _save)));
                  },
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'مسح القنوات',
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                  onPressed: () async {
                    final p = await SharedPreferences.getInstance();
                    await p.remove('ch_list');
                    setState(() => _channels.clear());
                  },
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.white12),

          // 2. الواجهة الرئيسية بالبطاقات الثلاث
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الهيدر والاسم الذهبي
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HEEDAR TV', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          SizedBox(height: 2),
                          Text('البوابة الملكية الترفيهية الفاخرة', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141722),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                        ),
                        child: Text('${_channels.length} قناة متاحة', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── البطاقات الثلاث بالصور المناسبة ──
                  Expanded(
                    child: Row(
                      children: [
                        // كرت البث المباشر (صورة بث واستوديو)
                        _card(
                          title: 'بث مباشر',
                          sub: 'قنوات فضائية ورياضية',
                          img: 'https://images.unsplash.com/photo-1593784991095-a205069470b6?w=700',
                          icon: Icons.live_tv_rounded,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => LiveViewScreen(channels: _channels, onSave: _save)));
                          },
                        ),
                        const SizedBox(width: 14),

                        // كرت الأفلام (صورة سينما ومسرح)
                        _card(
                          title: 'الأفلام',
                          sub: 'مكتبة VOD السينمائية',
                          img: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=700',
                          icon: Icons.movie_creation_rounded,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قسم الأفلام جاهز للمشاهدة')));
                          },
                        ),
                        const SizedBox(width: 14),

                        // كرت المسلسلات (صورة إنتاج وتلفزيون)
                        _card(
                          title: 'المسلسلات',
                          sub: 'المواسم والحلقات الكاملة',
                          img: 'https://images.unsplash.com/photo-1522869635100-9f4c5e86aa37?w=700',
                          icon: Icons.tv_rounded,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قسم المسلسلات جاهز للمشاهدة')));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required String sub, required String img, required IconData icon, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.35), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: const Color(0xFF141722))),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.88)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(backgroundColor: const Color(0xFFD4AF37), radius: 20, child: Icon(icon, color: Colors.black, size: 22)),
                      const SizedBox(height: 10),
                      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 3),
                      Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 5. شاشة البث المباشر (قنوات + مشغل بجانبها فوري) ──
class LiveViewScreen extends StatefulWidget {
  final List<Channel> channels;
  final VoidCallback onSave;
  const LiveViewScreen({super.key, required this.channels, required this.onSave});
  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  Channel? _cur;
  VideoPlayerController? _c;
  String _cat = 'الكل', _q = '';
  bool _load = false;

  @override
  void initState() {
    super.initState();
    if (widget.channels.isNotEmpty) _play(widget.channels.first);
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  void _play(Channel ch) {
    setState(() { _cur = ch; _load = true; });
    _c?.dispose();
    _c = VideoPlayerController.networkUrl(Uri.parse(ch.url))
      ..initialize().then((_) {
        if (mounted) { setState(() => _load = false); _c?.play(); }
      }).catchError((_) { if (mounted) setState(() => _load = false); });
  }

  @override
  Widget build(BuildContext context) {
    final cats = ['الكل', 'المفضلة', ...widget.channels.map((e) => e.group).toSet()];
    final list = widget.channels.where((c) {
      final mC = _cat == 'الكل' ? true : (_cat == 'المفضلة' ? c.isFavorite : c.group == _cat);
      final mQ = c.name.toLowerCase().contains(_q.toLowerCase());
      return mC && mQ;
    }).toList();

    return Scaffold(
      body: Row(
        children: [
          // قائمة القنوات
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFF0C0E14),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)), onPressed: () => Navigator.pop(context)),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _q = v),
                          decoration: const InputDecoration(hintText: 'ابحث عن قناة...', isDense: true, border: InputBorder.none),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(cats[i], style: const TextStyle(fontSize: 11)),
                          selected: _cat == cats[i],
                          selectedColor: const Color(0xFFD4AF37),
                          backgroundColor: const Color(0xFF141722),
                          onSelected: (_) => setState(() => _cat = cats[i]),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final ch = list[i];
                        final isSel = ch.url == _cur?.url;
                        return ListTile(
                          dense: true,
                          tileColor: isSel ? const Color(0xFFD4AF37).withOpacity(0.18) : null,
                          title: Text(ch.name, maxLines: 1, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? const Color(0xFFD4AF37) : Colors.white)),
                          trailing: IconButton(
                            icon: Icon(ch.isFavorite ? Icons.star : Icons.star_border, color: ch.isFavorite ? Colors.amber : Colors.white24, size: 18),
                            onPressed: () { setState(() => ch.isFavorite = !ch.isFavorite); widget.onSave(); },
                          ),
                          onTap: () => _play(ch),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.white12),

          // نافذة المشغل الفوري
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.black,
              child: Center(
                child: _load
                    ? const CircularProgressIndicator(color: Color(0xFFD4AF37))
                    : _c != null && _c!.value.isInitialized
                        ? AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!))
                        : const Text('اختر قناة للبدء بالبث', style: TextStyle(color: Colors.white54)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
