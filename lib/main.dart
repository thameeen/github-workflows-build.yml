import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ── 1. نموذج البيانات ──
class Channel {
  final String id, name, url, group;
  final String? logo;
  bool isFavorite;

  Channel({required this.id, required this.name, required this.url, this.logo, required this.group, this.isFavorite = false});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'url': url, 'logo': logo, 'group': group, 'isFavorite': isFavorite};

  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
        id: j['id'] ?? '', name: j['name'] ?? '', url: j['url'] ?? '', logo: j['logo'], group: j['group'] ?? 'عام', isFavorite: j['isFavorite'] ?? false);
}

// ── 2. معالج قوائم M3U ──
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
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF08090C), // أسود فاحم سينمائي
        primaryColor: const Color(0xFFD4AF37), // ذهبي ملكي
        fontFamily: 'sans-serif',
      ),
      home: const LuxuryHomeScreen(),
    );
  }
}

// ── 4. الشاشة الرئيسية الفاخرة بالبطاقات الثلاث ──
class LuxuryHomeScreen extends StatefulWidget {
  const LuxuryHomeScreen({super.key});
  @override
  State<LuxuryHomeScreen> createState() => _LuxuryHomeScreenState();
}

class _LuxuryHomeScreenState extends State<LuxuryHomeScreen> {
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
    final data = p.getString('ch_data');
    final favs = p.getStringList('ch_favs') ?? [];
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
    await p.setString('ch_data', jsonEncode(_channels.map((e) => e.toJson()).toList()));
    await p.setStringList('ch_favs', _channels.where((e) => e.isFavorite).map((e) => e.url).toList());
  }

  void _addPlaylistDialog() {
    final u = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141722),
        title: const Text('إضافة رابط M3U / M3U8', style: TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(controller: u, decoration: const InputDecoration(labelText: 'ضع الرابط المباشر هنا')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () async {
              if (u.text.isNotEmpty) {
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
            child: const Text('تحميل القنوات'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // الهيدر والشعار الذهبي
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD4AF37), width: 1.5)),
                          child: const Icon(Icons.tv, color: Color(0xFFD4AF37), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text('HEEDAR TV', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                          icon: const Icon(Icons.add_link),
                          label: const Text('إضافة مصدر'),
                          onPressed: _addPlaylistDialog,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'مسح القنوات',
                          onPressed: () async {
                            final p = await SharedPreferences.getInstance();
                            await p.remove('ch_data');
                            setState(() => _channels.clear());
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── البطاقات الثلاث الرئيسية (الصور المصغرة الفاخرة) ──
                Expanded(
                  child: Row(
                    children: [
                      // 1. بطاقة البث المباشر
                      _buildPortalCard(
                        title: 'بث مباشر',
                        subtitle: '${_channels.length} قناة متاحة',
                        imageUrl: 'https://images.unsplash.com/photo-1593784991095-a205069470b6?w=600',
                        icon: Icons.live_tv_rounded,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => LivePlayerScreen(channels: _channels, onSave: _save)));
                        },
                      ),
                      const SizedBox(width: 16),

                      // 2. بطاقة الأفلام
                      _buildPortalCard(
                        title: 'الأفلام',
                        subtitle: 'مكتبة VOD السينمائية',
                        imageUrl: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600',
                        icon: Icons.movie_creation_rounded,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قسم الأفلام جاهز')));
                        },
                      ),
                      const SizedBox(width: 16),

                      // 3. بطاقة المسلسلات
                      _buildPortalCard(
                        title: 'المسلسلات',
                        subtitle: 'المواسم والحلقات الكاملة',
                        imageUrl: 'https://images.unsplash.com/photo-1522869635100-9f4c5e86aa37?w=600',
                        icon: Icons.tv_rounded,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قسم المسلسلات جاهز')));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))),
        ],
      ),
    );
  }

  Widget _buildPortalCard({required String title, required String subtitle, required String imageUrl, required IconData icon, required VoidCallback onTap}) {
    return Expanded(
      child: Focus(
        child: Builder(builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isFocused ? const Color(0xFFD4AF37) : Colors.white12, width: isFocused ? 3 : 1),
                boxShadow: [if (isFocused) BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.35), blurRadius: 15)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: const Color(0xFF141722))),
                    // تدرج أسود فاحم مع لمسة ذهبية
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.85)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(backgroundColor: const Color(0xFFD4AF37), radius: 22, child: Icon(icon, color: Colors.black, size: 24)),
                          const SizedBox(height: 10),
                          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── 5. شاشة المشغل المباشر (قنوات + بث فوري) ──
class LivePlayerScreen extends StatefulWidget {
  final List<Channel> channels;
  final VoidCallback onSave;
  const LivePlayerScreen({super.key, required this.channels, required this.onSave});
  @override
  State<LivePlayerScreen> createState() => _LivePlayerScreenState();
}

class _LivePlayerScreenState extends State<LivePlayerScreen> {
  Channel? _current;
  VideoPlayerController? _c;
  String _cat = 'الكل', _q = '';
  bool _loading = false;

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
    setState(() { _current = ch; _loading = true; });
    _c?.dispose();
    _c = VideoPlayerController.networkUrl(Uri.parse(ch.url))
      ..initialize().then((_) {
        if (mounted) { setState(() => _loading = false); _c?.play(); }
      }).catchError((_) { if (mounted) setState(() => _loading = false); });
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
          // شريط القنوات الجانبي
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFF0F1117),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)), onPressed: () => Navigator.pop(context)),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _q = v),
                          decoration: const InputDecoration(hintText: 'بحث عن قناة...', isDense: true, border: InputBorder.none),
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
                          backgroundColor: const Color(0xFF161821),
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
                        final isSel = ch.url == _current?.url;
                        return ListTile(
                          dense: true,
                          tileColor: isSel ? const Color(0xFFD4AF37).withOpacity(0.2) : null,
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

          // شاشة البث المباشر
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.black,
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator(color: Color(0xFFD4AF37))
                    : _c != null && _c!.value.isInitialized
                        ? AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!))
                        : const Text('اختر قناة للبدء', style: TextStyle(color: Colors.white54)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
