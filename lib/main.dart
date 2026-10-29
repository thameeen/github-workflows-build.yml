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
    final prefs = await SharedPreferences.getIns
