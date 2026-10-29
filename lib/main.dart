import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ==========================================
// 1. نماذج البيانات (Models)
// ==========================================
class Channel {
  final String id;
  final String name;
  final String url;
  final String? logo;
  final String group;
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

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String,
        logo: json['logo'] as String?,
        group: json['group'] as String? ?? 'General',
        isFavorite: json['isFavorite'] as bool? ?? false,
      );
}

// ==========================================
// 2. معالج قوائم M3U (M3U Parser Service)
// ==========================================
class M3uService {
  static const _uuid = Uuid();

  static Future<List<Channel>> fetchAndParse(String url) async {
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('انتهت مهلة تحميل الرابط'),
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      return parse(decodedBody);
    } else {
      throw Exception('خطأ في الاتصال: كود ${response.statusCode}');
    }
  }

  static List<Channel> parse(String content) {
    final List<Channel> channels = [];
    final lines = const LineSplitter().convert(content);

    String? currentName;
    String? currentLogo;
    String currentGroup = 'عام';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line);
        currentLogo = logoMatch?.group(1);

        final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(line);
        currentGroup = groupMatch?.group(1) ?? 'عام';
        if (currentGroup.isEmpty) currentGroup = 'عام';

        final commaIndex = line.lastIndexOf(',');
        if (commaIndex != -1 && commaIndex < line.length - 1) {
          currentName = line.substring(commaIndex + 1).trim();
        } else {
          currentName = 'قناة';
        }
      } else if (!line.startsWith('#') &&
          (line.startsWith('http://') ||
              line.startsWith('https://') ||
              line.startsWith('rtmp://'))) {
        if (currentName != null) {
          channels.add(
            Channel(
              id: _uuid.v4(),
              name: currentName,
              url: line,
              logo: (currentLogo != null && currentLogo.isNotEmpty)
                  ? currentLogo
                  : null,
              group: currentGroup,
            ),
          );
        }
        currentName = null;
        currentLogo = null;
        currentGroup = 'عام';
      }
    }
    return channels;
  }
}

// ==========================================
// 3. نظام الترجمة المدمج (Localizations)
// ==========================================
class AppStrings {
  static final Map<String, Map<String, String>> _values = {
    'ar': {
      'app_title': 'Heedar TV',
      'home': 'الرئيسية',
      'live_tv': 'بث مباشر',
      'favorites': 'المفضلة',
      'sources': 'المصادر',
      'settings': 'الإعدادات',
      'all': 'الكل',
      'search': 'ابحث عن اسم القناة...',
      'channels_count': 'إجمالي القنوات',
      'sources_count': 'المصادر المضافة',
      'favs_count': 'المفضلة',
      'welcome_msg': 'بوابتك الفاخرة للبث التلفزيوني بجودة عالية',
      'add_source': 'إضافة قائمة M3U جديدة',
      'source_name': 'اسم القائمة (مثال: قنواتي)',
      'source_url': 'رابط M3U أو M3U8 مباشر',
      'save': 'حفظ وإضافة',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'no_channels': 'لا توجد قنوات. أضف مصدراً من قسم المصادر.',
      'no_favs': 'قائمتك المفضلة فارغة حالياً.',
      'loading': 'جاري استيراد القنوات...',
      'success': 'تم استيراد القنوات بنجاح',
      'error': 'تعذر جلب المصدر، يرجى فحص الرابط',
      'lang': 'اللغة / Language',
      'clear_cache': 'مسح جميع القنوات المحفوظة',
    },
    'en': {
      'app_title': 'Heedar TV',
      'home': 'Home',
      'live_tv': 'Live TV',
      'favorites': 'Favorites',
      'sources': 'Sources',
      'settings': 'Settings',
      'all': 'All',
      'search': 'Search channel name...',
      'channels_count': 'Total Channels',
      'sources_count': 'Total Sources',
      'favs_count': 'Favorites',
      'welcome_msg': 'Your premium live streaming gateway',
      'add_source': 'Add New M3U Playlist',
      'source_name': 'Playlist Name',
      'source_url': 'Direct M3U / M3U8 URL',
      'save': 'Save & Import',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'no_channels': 'No channels found. Add a source first.',
      'no_favs': 'Your favorites list is empty.',
      'loading': 'Importing channels...',
      'success': 'Channels imported successfully',
      'error': 'Failed to import source. Check URL.',
      'lang': 'Language / اللغة',
      'clear_cache': 'Clear all cached channels',
    }
  };

  static String get(String key, String lang) {
    return _values[lang]?[key] ?? _values['ar']![key] ?? key;
  }
}

// ==========================================
// 4. التطبيق الرئيسي والثيم الفاخر
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HeedarTvApp());
}

class HeedarTvApp extends StatefulWidget {
  const HeedarTvApp({super.key});

  static void setLocale(BuildContext context, String lang) {
    final state = context.findAncestorStateOfType<_HeedarTvAppState>();
    state?.changeLanguage(lang);
  }

  @override
  State<HeedarTvApp> createState() => _HeedarTvAppState();
}

class _HeedarTvAppState extends State<HeedarTvApp> {
  String _currentLocale = 'ar';

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  void _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLocale = prefs.getString('app_lang') ?? 'ar';
    });
  }

  void changeLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
    setState(() {
      _currentLocale = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    const goldPrimary = Color(0xFFD4AF37);
    const bgDark = Color(0xFF0D0E12);
    const cardDark = Color(0xFF161821);

    return MaterialApp(
      title: 'Heedar TV',
      debugShowCheckedModeBanner: false,
      locale: Locale(_currentLocale),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        primaryColor: goldPrimary,
        colorScheme: const ColorScheme.dark(
          primary: goldPrimary,
          secondary: Color(0xFFFFD700),
          surface: cardDark,
        ),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark,
          elevation: 0,
        ),
      ),
      home: MainShellScreen(currentLang: _currentLocale),
    );
  }
}

// ==========================================
// 5. الشاشة الرئيسية والهيكل العام مع دعم TV
// ==========================================
class MainShellScreen extends StatefulWidget {
  final String currentLang;
  const MainShellScreen({super.key, required this.currentLang});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;
  List<Channel> _channels = [];
  final List<Map<String, String>> _sources = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSources = prefs.getStringList('tv_sources') ?? [];
    final savedFavs = prefs.getStringList('tv_favorites') ?? [];

    setState(() {
      _sources.clear();
      for (var s in savedSources) {
        _sources.add(Map<String, String>.from(jsonDecode(s)));
      }
    });

    final cachedJson = prefs.getString('tv_channels');
    if (cachedJson != null) {
      final List dec = jsonDecode(cachedJson);
      setState(() {
        _channels = dec.map((c) {
          final ch = Channel.fromJson(c);
          ch.isFavorite = savedFavs.contains(ch.url);
          return ch;
        }).toList();
      });
    }
  }

  Future<void> _saveChannels(List<Channel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('tv_channels', jsonStr);
  }

  Future<void> _addSource(String name, String url) async {
    setState(() => _isLoading = true);
    try {
      final parsedChannels = await M3uService.fetchAndParse(url);
      final prefs = await SharedPreferences.getInstance();

      final sourceObj = {'name': name, 'url': url};
      _sources.add(sourceObj);

      await prefs.setStringList(
          'tv_sources', _sources.map((e) => jsonEncode(e)).toList());

      final updatedChannels = [..._channels, ...parsedChannels];
      setState(() {
        _channels = updatedChannels;
      });
      await _saveChannels(updatedChannels);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppStrings.get('success', widget.currentLang)} (+${parsedChannels.length})'),
            backgroundColor: const Color(0xFFD4AF37),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.get('error', widget.currentLang)}: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleFav(Channel ch) async {
    setState(() {
      ch.isFavorite = !ch.isFavorite;
    });
    final prefs = await SharedPreferences.getInstance();
    final favList =
        _channels.where((c) => c.isFavorite).map((c) => c.url).toList();
    await prefs.setStringList('tv_favorites', favList);
  }

  void _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tv_channels');
    await prefs.remove('tv_sources');
    await prefs.remove('tv_favorites');
    setState(() {
      _channels.clear();
      _sources.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.currentLang == 'ar';
    final lang = widget.currentLang;

    final pages = [
      _buildHomeView(lang),
      _buildChannelsView(lang, false),
      _buildChannelsView(lang, true),
      _buildSourcesView(lang),
      _buildSettingsView(lang),
    ];

    return Scaffold(
      body: Row(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          NavigationRail(
            backgroundColor: const Color(0xFF111218),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (val) => setState(() => _selectedIndex = val),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme:
                const IconThemeData(color: Color(0xFFD4AF37), size: 28),
            unselectedIconTheme:
                const IconThemeData(color: Colors.white54, size: 24),
            selectedLabelTextStyle: const TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
                fontSize: 12),
            unselectedLabelTextStyle:
                const TextStyle(color: Colors.white54, fontSize: 11),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                ),
                child: const Icon(Icons.tv, color: Color(0xFFD4AF37), size: 28),
              ),
            ),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: Text(AppStrings.get('home', lang)),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.live_tv_outlined),
                selectedIcon: const Icon(Icons.live_tv),
                label: Text(AppStrings.get('live_tv', lang)),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.star_border),
                selectedIcon: const Icon(Icons.star),
                label: Text(AppStrings.get('favorites', lang)),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.cloud_download_outlined),
                selectedIcon: const Icon(Icons.cloud_download),
                label: Text(AppStrings.get('sources', lang)),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(AppStrings.get('settings', lang)),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1, color: Colors.white12),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );
  }

  // --- شاشة الرئيسية ---
  Widget _buildHomeView(String lang) {
    final favCount = _channels.where((c) => c.isFavorite).length;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF222634), Color(0xFF13151D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HEEDAR TV — LUXURY',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.get('welcome_msg', lang),
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  onPressed: () => setState(() => _selectedIndex = 1),
                  icon: const Icon(Icons.play_circle_fill),
                  label: Text(AppStrings.get('live_tv', lang),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard(AppStrings.get('channels_count', lang),
                  '${_channels.length}', Icons.tv, Colors.blueAccent),
              const SizedBox(width: 16),
              _buildStatCard(AppStrings.get('sources_count', lang),
                  '${_sources.length}', Icons.source, Colors.amber),
              const SizedBox(width: 16),
              _buildStatCard(AppStrings.get('favs_count', lang), '$favCount',
                  Icons.star, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161821),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 24,
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(title,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- شاشة القنوات والمفضلة مع تصنيفات وبحث ---
  Widget _buildChannelsView(String lang, bool onlyFavs) {
    return _ChannelExplorer(
      channels:
          onlyFavs ? _channels.where((c) => c.isFavorite).toList() : _channels,
      isFavMode: onlyFavs,
      lang: lang,
      onToggleFav: _toggleFav,
    );
  }

  // --- شاشة المصادر ---
  Widget _buildSourcesView(String lang) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get('sources', lang),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1D27),
                      title: Text(AppStrings.get('add_source', lang)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameCtrl,
                            decoration: InputDecoration(
                              labelText: AppStrings.get('source_name', lang),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: urlCtrl,
                            decoration: InputDecoration(
                              labelText: AppStrings.get('source_url', lang),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(AppStrings.get('cancel', lang)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37)),
                          onPressed: () {
                            if (urlCtrl.text.trim().isNotEmpty) {
                              Navigator.pop(ctx);
                              _addSource(
                                nameCtrl.text.trim().isEmpty
                                    ? 'قائمة'
                                    : nameCtrl.text.trim(),
                                urlCtrl.text.trim(),
                              );
                            }
                          },
                          child: Text(AppStrings.get('save', lang),
                              style: const TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: Text(AppStrings.get('add_source', lang)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
              ),
            )
          else if (_sources.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60.0),
                child: Text(AppStrings.get('no_channels', lang),
                    style: const TextStyle(color: Colors.white54)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _sources.length,
                itemBuilder: (ctx, idx) {
                  final s = _sources[idx];
                  return Card(
                    color: const Color(0xFF161821),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.link, color: Color(0xFFD4AF37)),
                      title: Text(s['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(s['url'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white38)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          setState(() {
                            _sources.removeAt(idx);
                          });
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setStringList('tv_sources',
                              _sources.map((e) => jsonEncode(e)).toList());
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // --- شاشة الإعدادات ---
  Widget _buildSettingsView(String lang) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.get('settings', lang),
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37)),
          ),
          const SizedBox(height: 24),
          ListTile(
            tileColor: const Color(0xFF161821),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.language, color: Color(0xFFD4AF37)),
            title: Text(AppStrings.get('lang', lang)),
            trailing: DropdownButton<String>(
              dropdownColor: const Color(0xFF1E212D),
              value: lang,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (val) {
                if (val != null) {
                  HeedarTvApp.setLocale(context, val);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: const Color(0xFF161821),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            title: Text(AppStrings.get('clear_cache', lang)),
            onTap: () {
              _clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تنظيف الذاكرة والقنوات')),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. مستعرض القنوات وتصفيتها حسب الفئة والبحث
// ==========================================
class _ChannelExplorer extends StatefulWidget {
  final List<Channel> channels;
  final bool isFavMode;
  final String lang;
  final Function(Channel) onToggleFav;

  const _ChannelExplorer({
    required this.channels,
    required this.isFavMode,
    required this.lang,
    required this.onToggleFav,
  });

  @override
  State<_ChannelExplorer> createState() => _ChannelExplorerState();
}

class _ChannelExplorerState extends State<_ChannelExplorer> {
  String _selectedCategory = 'الكل';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final categories = [
      'الكل',
      ...widget.channels.map((c) => c.group).toSet()
    ];

    final filtered = widget.channels.where((c) {
      final matchesCat =
          (_selectedCategory == 'الكل' || c.group == _selectedCategory);
      final matchesSearch =
          c.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: AppStrings.get('search', widget.lang),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: const Color(0xFF161821),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (ctx, i) {
                final cat = categories[i];
                final isSel = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSel,
                    selectedColor: const Color(0xFFD4AF37),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.black : Colors.white70,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: const Color(0xFF161821),
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      widget.isFavMode
                          ? AppStrings.get('no_favs', widget.lang)
                          : AppStrings.get('no_channels', widget.lang),
                      style: const TextStyle(color: Colors.white54),
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final ch = filtered[idx];
                      return Focus(
                        child: Builder(builder: (context) {
                          final isFocused = Focus.of(context).hasFocus;
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VideoPlayerScreen(channel: ch),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161821),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isFocused
                                      ? const Color(0xFFD4AF37)
                                      : Colors.white12,
                                  width: isFocused ? 2.5 : 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (ch.logo != null &&
                                            ch.logo!.isNotEmpty)
                                          CachedNetworkImage(
                                            imageUrl: ch.logo!,
                                            height: 50,
                                            width: 50,
                                            errorWidget: (_, __, ___) =>
                                                const Icon(Icons.tv,
                                                    size: 40,
                                                    color: Color(0xFFD4AF37)),
                                          )
                                        else
                                          const Icon(Icons.tv,
                                              size: 40,
                                              color: Color(0xFFD4AF37)),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Text(
                                            ch.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: IconButton(
                                      icon: Icon(
                                        ch.isFavorite
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: ch.isFavorite
                                            ? Colors.amber
                                            : Colors.white38,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          widget.onToggleFav(ch),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 7. مشغل الفيديو فائق الفخامة والتحكم
// ==========================================
class VideoPlayerScreen extends StatefulWidget {
  final Channel channel;
  const VideoPlayerScreen({super.key, required this.channel});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _initPlayer();
  }

  void _initPlayer() {
    setState(() {
      _hasError = false;
    });
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.channel.url))
          ..initialize().then((_) {
            setState(() {});
            _controller.play();
          }).catchError((err) {
            setState(() {
              _hasError = true;
            });
          });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            Center(
              child: _hasError
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 48),
                        const SizedBox(height: 12),
                        const Text('تعذر تشغيل هذا البث المباشر',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37)),
                          onPressed: _initPlayer,
                          icon: const Icon(Icons.refresh, color: Colors.black),
                          label: const Text('إعادة المحاولة',
                              style: TextStyle(color: Colors.black)),
                        )
                      ],
                    )
                  : _controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : const CircularProgressIndicator(
                          color: Color(0xFFD4AF37)),
            ),
            if (_showControls)
              Container(
                color: Colors.black38,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.channel.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      iconSize: 56,
                      color: const Color(0xFFD4AF37),
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                      ),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
