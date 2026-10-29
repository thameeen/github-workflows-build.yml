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
        group: json['group'] as String? ?? 'عام',
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
      'lang': 'لغة التطبيق',
      'clear_cache': 'مسح القنوات والذاكرة المؤقتة',
      'player_settings': 'إعدادات المشغل',
      'aspect_ratio': 'أبعاد الشاشة الافتراضية',
      'keep_awake': 'إبقاء الشاشة مضاءة أثناء البث',
      'tv_mode': 'وضع شاشات Android TV وتحديد الريموت',
      'about': 'حول التطبيق',
      'version_info': 'النسخة الفاخرة 1.2 — للهواتف وشاشات التلفزيون',
      'confirm_clear': 'هل أنت متأكد من مسح جميع القنوات؟',
      'cleared_msg': 'تم مسح جميع البيانات والقنوات بنجاح',
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
      'lang': 'App Language',
      'clear_cache': 'Clear Cached Channels',
      'player_settings': 'Player Settings',
      'aspect_ratio': 'Default Screen Aspect Ratio',
      'keep_awake': 'Keep Screen Awake during stream',
      'tv_mode': 'Android TV Remote Highlight Mode',
      'about': 'About Heedar TV',
      'version_info': 'Luxury Edition 1.2 — Phones & TV Screens',
      'confirm_clear': 'Are you sure you want to clear all channels?',
      'cleared_msg': 'All channels cleared successfully',
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
        fontFamily: 'sans-serif',
        colorScheme: const ColorScheme.dark(
          primary: goldPrimary,
          secondary: Color(0xFFFFD700),
          surface: cardDark,
        ),
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
// 5. الشاشة الرئيسية والهيكل العام
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

  // إعدادات المستخدم المحفوظة
  String _aspectRatioMode = '16:9';
  bool _keepAwake = true;
  bool _tvFocusHighlight = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aspectRatioMode = prefs.getString('pref_aspect_ratio') ?? '16:9';
      _keepAwake = prefs.getBool('pref_keep_awake') ?? true;
      _tvFocusHighlight = prefs.getBool('pref_tv_highlight') ?? true;
    });
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

  void _clearAllChannels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tv_channels');
    await prefs.remove('tv_sources');
    await prefs.remove('tv_favorites');
    setState(() {
      _channels.clear();
      _sources.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('cleared_msg', widget.currentLang)),
          backgroundColor: const Color(0xFFD4AF37),
        ),
      );
    }
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
          // شريط تنقل جانبي متطور مع إمكانية التمرير لشاشات التلفزيون
          Container(
            color: const Color(0xFF111218),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    backgroundColor: Colors.transparent,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (val) =>
                        setState(() => _selectedIndex = val),
                    labelType: NavigationRailLabelType.all,
                    selectedIconTheme: const IconThemeData(
                        color: Color(0xFFD4AF37), size: 28),
                    unselectedIconTheme:
                        const IconThemeData(color: Colors.white54, size: 24),
                    selectedLabelTextStyle: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                    unselectedLabelTextStyle:
                        const TextStyle(color: Colors.white54, fontSize: 10),
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFD4AF37), width: 1.5),
                        ),
                        child: const Icon(Icons.tv,
                            color: Color(0xFFD4AF37), size: 26),
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
                ),
              ),
            ),
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
              border:
                  Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
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
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 14),
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

  // --- شاشة القنوات والمفضلة ---
  Widget _buildChannelsView(String lang, bool onlyFavs) {
    return _ChannelExplorer(
      channels:
          onlyFavs ? _channels.where((c) => c.isFavorite).toList() : _channels,
      isFavMode: onlyFavs,
      lang: lang,
      aspectRatio: _aspectRatioMode,
      keepAwake: _keepAwake,
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
                      leading:
                          const Icon(Icons.link, color: Color(0xFFD4AF37)),
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

  // ==========================================
  // شاشة الإعدادات الشاملة والفاخرة
  // ==========================================
  Widget _buildSettingsView(String lang) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Text(
            AppStrings.get('settings', lang),
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37)),
          ),
          const SizedBox(height: 20),

          // 1. قسم اللغات
          _buildSettingsHeader(AppStrings.get('lang', lang), Icons.language),
          ListTile(
            tileColor: const Color(0xFF161821),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('اللغة / Language'),
            trailing: DropdownButton<String>(
              dropdownColor: const Color(0xFF1E212D),
              value: lang,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية 🇸🇦')),
                DropdownMenuItem(value: 'en', child: Text('English 🇺🇸')),
              ],
              onChanged: (val) {
                if (val != null) {
                  HeedarTvApp.setLocale(context, val);
                }
              },
            ),
          ),
          const SizedBox(height: 20),

          // 2. قسم إعدادات المشغل (Player)
          _buildSettingsHeader(
              AppStrings.get('player_settings', lang), Icons.play_circle_fill),
          ListTile(
            tileColor: const Color(0xFF161821),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(AppStrings.get('aspect_ratio', lang)),
            trailing: DropdownButton<String>(
              dropdownColor: const Color(0xFF1E212D),
              value: _aspectRatioMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: '16:9', child: Text('16:9 (عريض)')),
                DropdownMenuItem(value: '4:3', child: Text('4:3 (كلاسيكي)')),
                DropdownMenuItem(value: 'auto', child: Text('تلقائي (Auto)')),
              ],
              onChanged: (val) async {
                if (val != null) {
                  setState(() => _aspectRatioMode = val);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('pref_aspect_ratio', val);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            tileColor: const Color(0xFF161821),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            activeColor: const Color(0xFFD4AF37),
            title: Text(AppStrings.get('keep_awake', lang)),
            subtitle: const Text('منع إطفاء الشاشة عند المشاهدة',
                style: TextStyle(fontSize: 12, color: Colors.white54)),
            value: _keepAwake,
            onChanged: (val) async {
              setState(() => _keepAwake = val);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('pref_keep_awake', val);
            },
          ),
          const SizedBox(height: 20),

          // 3. قسم دعم أجهزة التلفزيون
          _buildSettingsHeader('أجهزة التلفزيون والريموت', Icons.tv),
          SwitchListTile(
            tileColor: const Color(0xFF161821),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            activeColor: const Color(0xFFD4AF37),
            title: Text(AppStrings.get('tv_mode', lang)),
            subtitle: const Text('إظهار إطار ذهبي مضيء على القناة المحددة',
                style: TextStyle(fontSize: 12, color: Colors.white54)),
            value: _tvFocusHighlight,
            onChanged: (val) async {
              setState(() => _tvFocusHighlight = val);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('pref_tv_highlight', val);
            },
          ),
          const SizedBox(height: 20),

          // 4. قسم مسح الذاكرة
          _buildSettingsHeader('إدارة البيانات', Icons.storage),
          ListTile(
            tileColor: const Color(0xFF161821),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: Text(AppStrings.get('clear_cache', lang)),
            subtitle: Text('عدد القنوات المحفوظة: ${_channels.length}',
                style: const TextStyle(fontSize: 12, color: Colors.white54)),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1D27),
                  title: const Text('تأكيد المسح'),
                  content: Text(AppStrings.get('confirm_clear', lang)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(AppStrings.get('cancel', lang)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _clearAllChannels();
                      },
                      child: Text(AppStrings.get('delete', lang),
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // 5. بطاقة حول التطبيق الفاخرة
          _buildSettingsHeader(AppStrings.get('about', lang), Icons.info_outline),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161821),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified,
                    color: Color(0xFFD4AF37), size: 36),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HEEDAR TV — LUXURY',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFFD4AF37))),
                    const SizedBox(height: 4),
                    Text(AppStrings.get('version_info', lang),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white54)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70)),
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
  final String aspectRatio;
  final bool keepAwake;
  final Function(Channel) onToggleFav;

  const _ChannelExplorer({
    required this.channels,
    required this.isFavMode,
    required this.lang,
    required this.aspectRatio,
    required this.keepAwake,
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
          const SizedBox(h
