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
