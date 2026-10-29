
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const HeedarTVApp());
}

// ───────────────────── Localization ─────────────────────
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocDelegate();

  static final Map<String, Map<String, String>> _v = {
    'ar': {
      'appName': 'Heedar TV',
      'home': 'الرئيسية',
      'live': 'بث مباشر',
      'movies': 'أفلام',
      'series': 'مسلسلات',
      'sources': 'المصادر',
      'settings': 'الإعدادات',
      'searchChannel': 'ابحث عن قناة...',
      'all': 'الكل',
      'favorites': 'المفضلة',
      'noChannels': 'لا توجد قنوات',
      'noResults': 'لا توجد نتائج',
      'importM3U': 'استيراد M3U',
      'liveTV': 'البث المباشر',
      'chooseChannel': 'اختر قناة للبدء',
      'connecting': 'جاري الاتصال بالبث...',
      'playbackError': 'تعذر تشغيل هذا البث',
      'retry': 'إعادة المحاولة',
      'importPlaylist': 'استيراد قائمة M3U / M3U8',
      'importNote':
          'أضف قوائم M3U من مصادر تملك حق استخدامها.\nالتطبيق لا يأتي بقنوات جاهزة.',
      'startImport': 'بدء الاستيراد',
      'downloading': 'جاري التنزيل...',
      'parsing': 'جاري التحليل...',
      'importSuccess': 'تم استيراد',
      'channels': 'قناة',
      'newChannels': 'قناة جديدة',
      'importFailed': 'فشل: تأكد من الرابط',
      'currentChannels': 'القنوات الحالية',
      'savedLocally': 'يتم حفظ المصادر محليًا.',
      'noMovies': 'لا توجد أفلام بعد.\nأضف مصدر VOD لاحقًا.',
      'noSeries': 'لا توجد مسلسلات بعد.\nأضف مصدر VOD لاحقًا.',
      'language': 'اللغة',
      'arabic': 'العربية',
      'english': 'English',
      'manageSources': 'إدارة المصادر',
      'clearChannels': 'مسح كل القنوات',
      'version': 'نسخة فاخرة 1.1 — هواتف وشاشات TV',
      'close': 'إغلاق',
      'cancel': 'إلغاء',
    },
    'en': {
      'appName': 'Heedar TV',
      'home': 'Home',
      'live': 'Live TV',
      'movies': 'Movies',
      'series': 'Series',
      'sources': 'Sources',
      'settings': 'Settings',
      'searchChannel': 'Search channels...',
      'all': 'All',
      'favorites': 'Favorites',
      'noChannels': 'No channels',
      'noResults': 'No results',
      'importM3U': 'Import M3U',
      'liveTV': 'Live TV',
      'chooseChannel': 'Select a channel to start',
      'connecting': 'Connecting to stream...',
      'playbackError': 'Unable to play this stream',
      'retry': 'Retry',
      'importPlaylist': 'Import M3U / M3U8 Playlist',
      'importNote':
          'Add M3U playlists from sources you have rights to use.\nNo preloaded channels.',
      'startImport': 'Start Import',
      'downloading': 'Downloading...',
      'parsing': 'Parsing channels...',
      'importSuccess': 'Imported',
      'channels': 'channels',
      'newChannels': 'new channels',
      'importFailed': 'Failed: check the URL',
      'currentChannels': 'Current channels',
      'savedLocally': 'Sources are saved locally.',
      'noMovies': 'No movies yet.\nAdd a VOD source later.',
      'noSeries': 'No series yet.\nAdd a VOD source later.',
      'language': 'Language',
      'arabic': 'العربية',
      'english': 'English',
      'manageSources': 'Manage Sources',
      'clearChannels': 'Clear all channels',
      'version': 'Premium 1.1 — Phones & Android TV',
      'close': 'Close',
      'cancel': 'Cancel',
    },
  };

  String get(String k) =>
      _v[locale.languageCode]?[k] ?? _v['en']?[k] ?? k;

  String get live => get('live');
  String get movies => get('movies');
  String get series => get('series');
  String get sources => get('sources');
  String get settings => get('settings');
  String get searchChannel => get('searchChannel');
  String get all => get('all');
  String get favorites => get('favorites');
  String get noChannels => get('noChannels');
  String get noResults => get('noResults');
  String get importM3U => get('importM3U');
  String get liveTV => get('liveTV');
  String get chooseChannel => get('chooseChannel');
  String get connecting => get('connecting');
  String get playbackError => get('playbackError');
  String get retry => get('retry');
  String get importPlaylist => get('importPlaylist');
  String get importNote => get('importNote');
  String get startImport => get('startImport');
  String get downloading => get('downloading');
  String get parsing => get('parsing');
  String get importSuccess => get('importSuccess');
  String get channels => get('channels');
  String get newChannels => get('newChannels');
  String get importFailed => get('importFailed');
  String get currentChannels => get('currentChannels');
  String get savedLocally => get('savedLocally');
  String get noMovies => get('noMovies');
  String get noSeries => get('noSeries');
  String get language => get('language');
  String get arabic => get('arabic');
  String get english => get('english');
  String get manageSources => get('manageSources');
  String get clearChannels => get('clearChannels');
  String get version => get('version');
  String get close => get('close');
  String get cancel => get('cancel');
}

class _AppLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocDelegate();
  @override
  bool isSupported(Locale l) => ['ar', 'en'].contains(l.languageCode);
  @override
  Future<AppLocalizations> load(Locale l) async => AppLocalizations(l);
  @override
  bool shouldReload(_) => false;
}

// ───────────────────── Models ─────────────────────
class Channel {
  final String id;
  final String name;
  final String url;
  final String logo;
  final String group;
  bool isFavorite;
  bool isWorking;

  Channel({
    required this.id,
    required this.name,
    required this.url,
    this.logo = '',
    this.group = 'عام',
    this.isFavorite = false,
    this.isWorking = true,
  });

  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        url: j['url'] ?? '',
        logo: j['logo'] ?? '',
        group: j['group'] ?? 'عام',
        isFavorite: j['isFavorite'] ?? false,
        isWorking: j['isWorking'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'logo': logo,
        'group': group,
        'isFavorite': isFavorite,
        'isWorking': isWorking,
      };
}

class MediaItem {
  final String id;
  final String title;
  final String overview;
  final String posterUrl;
  final String backdropUrl;
  final String year;
  final double rating;
  final List<String> genres;
  final String type;
  final String? streamUrl;
  bool isFavorite;

  MediaItem({
    required this.id,
    required this.title,
    this.overview = '',
    this.posterUrl = '',
    this.backdropUrl = '',
    this.year = '',
    this.rating = 0,
    this.genres = const [],
    required this.type,
    this.streamUrl,
    this.isFavorite = false,
  });

  bool get isPlayable => streamUrl != null && streamUrl!.isNotEmpty;

  factory MediaItem.fromJson(Map<String, dynamic> j) => MediaItem(
        id: j['id']?.toString() ?? '',
        title: j['title'] ?? j['name'] ?? '',
        overview: j['overview'] ?? '',
        posterUrl: j['posterUrl'] ?? '',
        backdropUrl: j['backdropUrl'] ?? '',
        year: j['year']?.toString() ?? '',
        rating: (j['rating'] ?? 0).toDouble(),
        genres: (j['genres'] as List?)?.map((e) => e.toString()).toList() ?? [],
        type: j['type'] ?? 'movie',
        streamUrl: j['streamUrl'],
        isFavorite: j['isFavorite'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'overview': overview,
        'posterUrl': posterUrl,
        'backdropUrl': backdropUrl,
        'year': year,
        'rating': rating,
        'genres': genres,
        'type': type,
        'streamUrl': streamUrl,
        'isFavorite': isFavorite,
      };
}

// ───────────────────── M3U Parser ─────────────────────
class M3uService {
  static const _uuid = Uuid();

  static Stream<Channel> parseM3uContent(String content) async* {
    final lines = content.split(RegExp(r'\r?\n'));
    String? name;
    String logo = '';
    String group = 'عام';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#EXTINF:')) {
        logo = '';
        group = 'عام';
        final lm = RegExp(r'tvg-logo="([^"]*)"', caseSensitive: false).firstMatch(line);
        if (lm != null) logo = lm.group(1) ?? '';
        final gm = RegExp(r'group-title="([^"]*)"', caseSensitive: false).firstMatch(line);
        if (gm != null && (gm.group(1)?.isNotEmpty ?? false)) group = gm.group(1)!;
        final c = line.lastIndexOf(',');
        name = c != -1 ? line.substring(c + 1).trim() : null;
      } else if (line.isNotEmpty && !line.startsWith('#') && name != null && name!.isNotEmpty) {
        final lower = line.toLowerCase();
        if (lower.startsWith('http://') || lower.startsWith('https://')) {
          yield Channel(id: _uuid.v4(), name: name!, url: line, logo: logo, group: group);
        }
        name = null;
      }
      if (i % 50 == 0) await Future.delayed(Duration.zero);
    }
  }
}

// ───────────────────── App ─────────────────────
class HeedarTVApp extends StatefulWidget {
  const HeedarTVApp({super.key});
  static _HeedarTVAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_HeedarTVAppState>();
  @override
  State<HeedarTVApp> createState() => _HeedarTVAppState();
}

class _HeedarTVAppState extends State<HeedarTVApp> {
  Locale _locale = const Locale('ar', 'AE');

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString('app_locale') ?? 'ar';
    if (mounted) {
      setState(() {
        _locale = code == 'en' ? const Locale('en', 'US') : const Locale('ar', 'AE');
      });
    }
  }

  Future<void> setLocale(Locale locale) async {
    setState(() => _locale = locale);
    final p = await SharedPreferences.getInstance();
    await p.setString('app_locale', locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _locale.languageCode == 'ar';
    return MaterialApp(
      title: 'Heedar TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0D10),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4A84B),
          surface: Color(0xFF141820),
        ),
        textTheme: isAr
            ? GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme)
            : GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      locale: _locale,
      supportedLocales: const [Locale('ar', 'AE'), Locale('en', 'US')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  List<Channel> _channels = [];
  final List<MediaItem> _movies = [];
  final List<MediaItem> _series = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    try {
      final ch = p.getString('saved_channels');
      if (ch != null) {
        _channels = (jsonDecode(ch) as List)
            .map((e) => Channel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _saveChannels() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'saved_channels', jsonEncode(_channels.map((c) => c.toJson()).toList()));
  }

  void _onChannels(List<Channel> list) {
    setState(() => _channels = list);
    _saveChannels();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = AppLocalizations.of(context);

    final pages = [
      LivePage(channels: _channels, onUpdate: _onChannels),
      VodPage(title: l10n.movies, items: _movies, emptyHint: l10n.noMovies, type: 'movie'),
      VodPage(title: l10n.series, items: _series, emptyHint: l10n.noSeries, type: 'series'),
      SourcesPage(channels: _channels, onUpdate: _onChannels),
      const SettingsPage(),
    ];

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0D10),
        body: pages[_tab],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0E1116),
            border: Border(top: BorderSide(color: Color(0xFF1A1F28))),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _nav(0, Icons.live_tv_rounded, l10n.live),
                  _nav(1, Icons.movie_creation_rounded, l10n.movies),
                  _nav(2, Icons.tv_rounded, l10n.series),
                  _nav(3, Icons.cloud_download_rounded, l10n.sources),
                  _nav(4, Icons.settings_rounded, l10n.settings),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(int i, IconData icon, String label) {
    final sel = _tab == i;
    return InkWell(
      onTap: () => setState(() => _tab = i),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: sel ? const Color(0xFFD4A84B) : Colors.white38),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: sel ? const Color(0xFFD4A84B) : Colors.white38,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ───────────────────── VOD (OwnTV style) ─────────────────────
class VodPage extends StatefulWidget {
  final String title;
  final List<MediaItem> items;
  final String emptyHint;
  final String type;
  const VodPage(
      {super.key,
      required this.title,
      required this.items,
      required this.emptyHint,
      required this.type});
  @override
  State<VodPage> createState() => _VodPageState();
}

class _VodPageState extends State<VodPage> {
  String _search = '';

  List<MediaItem> get _filtered {
    if (_search.isEmpty) return widget.items;
    final q = _search.toLowerCase();
    return widget.items.where((m) => m.title.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final hero = items.isNotEmpty ? items.first : null;

    return CustomScrollView(
      slivers: [
        if (hero != null)
          SliverToBoxAdapter(child: _HeroBanner(item: hero))
        else
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1F2E), Color(0xFF0B0D10)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Text(widget.title,
                    style: GoogleFonts.cairo(
                        color: const Color(0xFFD4A84B),
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        if (widget.items.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.title}...',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF1A1F28),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text('${widget.title}  ·  ${items.length} titles',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
        ),
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(widget.emptyHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 15, height: 1.5)),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.58,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _PosterCard(item: items[i]),
                childCount: items.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final MediaItem item;
  const _HeroBanner({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.42,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.posterUrl.isNotEmpty)
            CachedNetworkImage(imageUrl: item.posterUrl, fit: BoxFit.cover)
          else
            Container(color: const Color(0xFF141820)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.55),
                  const Color(0xFF0B0D10),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 2,
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                if (item.rating > 0) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFD4A84B), size: 16),
                    Text(' ${item.rating.toStringAsFixed(1)}',
                        style: const TextStyle(color: Color(0xFFD4A84B), fontWeight: FontWeight.bold)),
                  ]),
                ],
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A84B),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: item.isPlayable
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    PlayerScreen(title: item.title, url: item.streamUrl!)),
                          )
                      : null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  final MediaItem item;
  const _PosterCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (item.isPlayable) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PlayerScreen(title: item.title, url: item.streamUrl!)),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: item.posterUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: item.posterUrl, fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFF1A1F28),
                          child: const Icon(Icons.movie, color: Colors.white24)),
                ),
                if (item.rating > 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFD4A84B), size: 12),
                        Text(' ${item.rating.toStringAsFixed(1)}',
                            style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ───────────────────── Live ─────────────────────
class LivePage extends StatefulWidget {
  final List<Channel> channels;
  final Function(List<Channel>) onUpdate;
  const LivePage({super.key, required this.channels, required this.onUpdate});
  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  String _search = '';
  String _cat = '__all__';

  List<String> get _cats {
    final g = widget.channels.map((c) => c.group).toSet().toList()..sort();
    return ['__all__', '__fav__', ...g];
  }

  String _label(String c) {
    final l = AppLocalizations.of(context);
    if (c == '__all__') return l.all;
    if (c == '__fav__') return l.favorites;
    return c;
  }

  List<Channel> get _filtered {
    var list = widget.channels;
    if (_cat == '__fav__') list = list.where((c) => c.isFavorite).toList();
    else if (_cat != '__all__') list = list.where((c) => c.group == _cat).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((c) => c.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final list = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(l10n.liveTV,
                style: GoogleFonts.cairo(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: l10n.searchChannel,
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
              filled: true,
              fillColor: const Color(0xFF1A1F28),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _cats.length,
            itemBuilder: (_, i) {
              final c = _cats[i];
              final sel = _cat == c;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _cat = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFD4A84B) : const Color(0xFF1A1F28),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_label(c),
                        style: TextStyle(
                            color: sel ? Colors.black : Colors.white70,
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                      widget.channels.isEmpty ? l10n.noChannels : l10n.noResults,
                      style: const TextStyle(color: Colors.white38)))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final ch = list[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PlayerScreen(title: ch.name, url: ch.url)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF141820),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: ch.logo.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: ch.logo,
                                        fit: BoxFit.contain,
                                        errorWidget: (_, __, ___) =>
                                            const Icon(Icons.live_tv, color: Color(0xFFD4A84B)))
                                    : const Icon(Icons.live_tv,
                                        color: Color(0xFFD4A84B), size: 36),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                              child: Text(ch.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ───────────────────── Player ─────────────────────
class PlayerScreen extends StatefulWidget {
  final String title;
  final String url;
  const PlayerScreen({super.key, required this.title, required this.url});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _c;
  bool _loading = true;
  bool _error = false;
  bool _controls = true;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize().timeout(const Duration(seconds: 15));
      await c.play();
      if (mounted) setState(() { _c = c; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _controls = !_controls),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: _error
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
                        SizedBox(height: 12),
                        Text('تعذر تشغيل البث', style: TextStyle(color: Colors.white70)),
                      ],
                    )
                  : _loading
                      ? const CircularProgressIndicator(color: Color(0xFFD4A84B))
                      : _c != null && _c!.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: _c!.value.aspectRatio,
                              child: VideoPlayer(_c!))
                          : const SizedBox(),
            ),
            if (_controls)
              SafeArea(
                child: Column(
                  children: [
                    Row(children: [
                      IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context)),
                      Expanded(
                          child: Text(widget.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ]),
                    const Spacer(),
                    if (_c != null)
                      IconButton(
                        iconSize: 64,
                        icon: Icon(
                            _c!.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: const Color(0xFFD4A84B)),
                        onPressed: () => setState(
                            () => _c!.value.isPlaying ? _c!.pause() : _c!.play()),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────── Sources ─────────────────────
class SourcesPage extends StatefulWidget {
  final List<Channel> channels;
  final Function(List<Channel>) onUpdate;
  const SourcesPage({super.key, required this.channels, required this.onUpdate});
  @override
  State<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends State<SourcesPage> {
  final _url = TextEditingController();
  bool _busy = false;
  String _status = '';

  Future<void> _import() async {
    final url = _url.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _busy = true;
      _status = AppLocalizations.of(context).downloading;
    });
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      setState(() => _status = AppLocalizations.of(context).parsing);
      final list = <Channel>[];
      await for (final ch in M3uService.parseM3uContent(res.body)) {
        list.add(ch);
      }
      final exist = widget.channels.map((c) => c.url).toSet();
      final neu = list.where((c) => !exist.contains(c.url)).toList();
      widget.onUpdate([...widget.channels, ...neu]);
      setState(() {
        _busy = false;
        _status =
            '${AppLocalizations.of(context).importSuccess} ${neu.length} ${AppLocalizations.of(context).newChannels}';
        _url.clear();
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _status = AppLocalizations.of(context).importFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.manageSources,
              style: GoogleFonts.cairo(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(l10n.importNote, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF141820),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4A84B).withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.importPlaylist,
                    style: const TextStyle(
                        color: Color(0xFFD4A84B), fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _url,
                  enabled: !_busy,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'https://...playlist.m3u',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: const Color(0xFF1A1F28),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                if (_status.isNotEmpty)
                  Text(_status, style: const TextStyle(color: Color(0xFFD4A84B))),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A84B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _busy ? null : _import,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(l10n.startImport,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('${l10n.currentChannels}: ${widget.channels.length}',
              style: const TextStyle(color: Colors.white54)),
          Text(l10n.savedLocally, style: const TextStyle(color: Colors.white30, fontSize: 12)),
        ],
      ),
    );
  }
}

// ───────────────────── Settings ─────────────────────
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.settings,
              style: GoogleFonts.cairo(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFFD4A84B)),
            title: Text(l10n.language, style: const TextStyle(color: Colors.white)),
            subtitle: Text(isAr ? l10n.arabic : l10n.english,
                style: const TextStyle(color: Colors.white54)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _chip(context, 'AR', isAr,
                    () => HeedarTVApp.of(context)?.setLocale(const Locale('ar', 'AE'))),
                const SizedBox(width: 6),
                _chip(context, 'EN', !isAr,
                    () => HeedarTVApp.of(context)?.setLocale(const Locale('en', 'US'))),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: Text(l10n.clearChannels, style: const TextStyle(color: Colors.white)),
            onTap: () async {
              final p = await SharedPreferences.getInstance();
              await p.remove('saved_channels');
            },
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFFD4A84B)),
            title: const Text('Heedar TV', style: TextStyle(color: Colors.white)),
            subtitle: Text(l10n.version,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext ctx, String label, bool sel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFD4A84B) : const Color(0xFF1A1F28),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    );
  }
}
