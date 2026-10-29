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

// ── 2. محلل قوائم M3U ──
class M3uService {
  static const _uuid = Uuid();
  static Future<List<Channel>> fetchAndParse(String url) async {
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw Exception('فشل جلب الرابط');
    final lines = const LineSplitter().convert(utf8.decode(res.bodyBytes, allowMalformed: true));
    final List<Channel> list = [];
    String? name, logo;
    String group = 'عام';

    for (var l in lines) {
      l = l.trim();
      if (l.startsWith('#EXTINF:')) {
        final lm = RegExp(r'tvg-logo="([^"]*)"').firstMatch(l);
        logo = lm?.group(1);
        final gm = RegExp(r'group-title="([^"]*)"').firstMatch(l);
        group = gm?.group(1) ?? 'عام';
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

// ── 3. مشغل التطبيق والثيم الفاخر ──
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
        scaffoldBackgroundColor: const Color(0xFF0A0C10),
        primaryColor: const Color(0xFFD4AF37),
        fontFamily: 'sans-serif',
      ),
      home: const HeedarTvDirectScreen(),
    );
  }
}

// ── 4. الواجهة الموحدة والمباشرة (Heedar TV System) ──
class HeedarTvDirectScreen extends StatefulWidget {
  const HeedarTvDirectScreen({super.key});
  @override
  State<HeedarTvDirectScreen> createState() => _HeedarTvDirectScreenState();
}

class _HeedarTvDirectScreenState extends State<HeedarTvDirectScreen> {
  List<Channel> _channels = [];
  Channel? _activeChannel;
  VideoPlayerController? _player;
  String _selectedCategory = 'الكل';
  String _search = '';
  bool _isFullscreen = false;
  bool _showControls = true;
  bool _loading = false;
  String _ratio = '16:9';

  @override
  void initState() {
    super.initState();
    try { WakelockPlus.enable(); } catch (_) {}
    _loadChannels();
  }

  @override
  void dispose() {
    _player?.dispose();
    try { WakelockPlus.disable(); } catch (_) {}
    super.dispose();
  }

  Future<void> _loadChannels() async {
    final p = await SharedPreferences.getInstance();
    final data = p.getString('cached_channels');
    final favs = p.getStringList('fav_urls') ?? [];
    if (data != null) {
      final List dec = jsonDecode(data);
      setState(() {
        _channels = dec.map((e) {
          final c = Channel.fromJson(e);
          c.isFavorite = favs.contains(c.url);
          return c;
        }).toList();
        if (_channels.isNotEmpty && _activeChannel == null) {
          _playChannel(_channels.first);
        }
      });
    }
  }

  Future<void> _saveChannels() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('cached_channels', jsonEncode(_channels.map((e) => e.toJson()).toList()));
    await p.setStringList('fav_urls', _channels.where((e) => e.isFavorite).map((e) => e.url).toList());
  }

  void _playChannel(Channel ch) {
    setState(() {
      _activeChannel = ch;
      _loading = true;
    });
    _player?.dispose();
    _player = VideoPlayerController.networkUrl(Uri.parse(ch.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _loading = false);
          _player?.play();
        }
      }).catchError((_) {
        if (mounted) setState(() => _loading = false);
      });
  }

  void _addM3uDialog() {
    final n = TextEditingController(), u = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161821),
        title: const Text('إضافة رابط M3U — Heedar TV', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: n, decoration: const InputDecoration(labelText: 'اسم الباقة')),
            TextField(controller: u, decoration: const InputDecoration(labelText: 'رابط M3U أو M3U8')),
          ],
        ),
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
                  await _saveChannels();
                  if (_channels.isNotEmpty && _activeChannel == null) _playChannel(_channels.first);
                } catch (_) {}
                if (mounted) setState(() => _loading = false);
              }
            },
            child: const Text('استيراد'),
          ),
        ],
      ),
    );
  }

  void _settingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: const Color(0xFF161821),
          title: const Text('الإعدادات — Heedar TV', style: TextStyle(color: Color(0xFFD4AF37))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('أبعاد المشغل'),
                trailing: DropdownButton<String>(
                  dropdownColor: const Color(0xFF161821),
                  value: _ratio,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: '16:9', child: Text('16:9')),
                    DropdownMenuItem(value: '4:3', child: Text('4:3')),
                    DropdownMenuItem(value: 'auto', child: Text('تلقائي')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _ratio = v);
                      setD(() => _ratio = v);
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('مسح القنوات والبدء من جديد'),
                onTap: () async {
                  final p = await SharedPreferences.getInstance();
                  await p.remove('cached_channels');
                  await p.remove('fav_urls');
                  _player?.pause();
                  _player?.dispose();
                  setState(() {
                    _channels.clear();
                    _activeChannel = null;
                    _player = null;
                  });
                  if (mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  double _getRatio() {
    if (_ratio == '16:9') return 16 / 9;
    if (_ratio == '4:3') return 4 / 3;
    return (_player != null && _player!.value.isInitialized) ? _player!.value.aspectRatio : 16 / 9;
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: _player != null && _player!.value.isInitialized
                    ? AspectRatio(aspectRatio: _getRatio(), child: VideoPlayer(_player!))
                    : const CircularProgressIndicator(color: Color(0xFFD4AF37)),
              ),
              if (_showControls)
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black45,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.fullscreen_exit, size: 30, color: Color(0xFFD4AF37)),
                              onPressed: () => setState(() => _isFullscreen = false),
                            ),
                            const SizedBox(width: 8),
                            Text(_activeChanne?.name ?? 'Heedar TV', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.tune, color: Colors.white),
                              onPressed: _settingsDialog,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Center(
                          child: IconButton(
                            iconSize: 64,
                            color: const Color(0xFFD4AF37),
                            icon: Icon(_player != null && _player!.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
                            onPressed: () => setState(() => _player!.value.isPlaying ? _player!.pause() : _player!.play()),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // ── الواجهة المباشرة (قنوات + بث فوري بجانبها) ──
    final categories = ['الكل', 'المفضلة', ..._channels.map((e) => e.group).toSet()];
    final filtered = _channels.where((c) {
      final mCat = _selectedCategory == 'الكل'
          ? true
          : (_selectedCategory == 'المفضلة' ? c.isFavorite : c.group == _selectedCategory);
      final mQ = c.name.toLowerCase().contains(_search.toLowerCase());
      return mCat && mQ;
    }).toList();

    return Scaffold(
      body: Row(
        children: [
          // 1. شريط الأيقونات السريع
          Container(
            width: 58,
            color: const Color(0xFF0F1117),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.tv, color: Color(0xFFD4AF37), size: 28),
                const Divider(color: Colors.white12, height: 28),
                IconButton(
                  tooltip: 'إضافة M3U',
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD4AF37)),
                  onPressed: _addM3uDialog,
                ),
                IconButton(
                  tooltip: 'المفضلة',
                  icon: Icon(Icons.star, color: _selectedCategory == 'المفضلة' ? Colors.amber : Colors.white54),
                  onPressed: () => setState(() => _selectedCategory = 'المفضلة'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'الإعدادات',
                  icon: const Icon(Icons.settings, color: Colors.white54),
                  onPressed: _settingsDialog,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // 2. قائمة القنوات والتصنيفات (Heedar TV List)
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFF12151D),
              child: Column(
                children: [
                  // شريط البحث
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'بحث في Heedar TV...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFFD4AF37)),
                        filled: true,
                        fillColor: const Color(0xFF1B1E29),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),

                  // شريط الفئات
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (_, i) {
                        final cat = categories[i];
                        final isSel = cat == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                          child: ChoiceChip(
                            label: Text(cat, style: TextStyle(fontSize: 11, color: isSel ? Colors.black : Colors.white)),
