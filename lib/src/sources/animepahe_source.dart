import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import '../models.dart';
import '../utils.dart';
import 'anime_source.dart';

class AnimePaheSource implements AnimeSource {
  @override
  String get name => 'AnimePahe';

  static const String _authority = 'animepahe.si';
  static const String _userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36';

  final http.Client _client;
  late final String _cookie;

  AnimePaheSource({http.Client? client}) : _client = client ?? http.Client() {
    _cookie = '__ddg2_=${StringUtils.generateRandomString(16)}';
  }

  Future<http.Response> _get(Uri uri, {Map<String, String>? headers}) async {
    final response = await _client.get(
      uri,
      headers: {
        'User-Agent': _userAgent,
        'Cookie': _cookie,
        ...?headers,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Request to $uri failed with status: ${response.statusCode}');
    }
    return response;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _get(uri);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<List<Anime>> searchAnime(String query) async {
    final uri = Uri.https(_authority, '/api', {
      'm': 'search',
      'q': query,
    });

    try {
      final data = await _getJson(uri);
      if (data['total'] == 0) return [];

      final results = data['data'] as List;
      return results.map((e) {
        return Anime(
          id: e['session'],
          name: e['title'],
          availableEpisodes: e['episodes'],
          typename: e['type'],
          source: this,
        );
      }).toList();
    } catch (e) {
      throw Exception('Error searching anime: $e');
    }
  }

  @override
  Future<List<Episode>> getEpisodes(String animeId) async {
    final episodes = <Episode>[];
    int page = 1;
    int lastPage = 1;

    try {
      do {
        final uri = Uri.https(_authority, '/api', {
          'm': 'release',
          'id': animeId,
          'sort': 'episode_asc',
          'page': page.toString(),
        });

        final data = await _getJson(uri);
        lastPage = data['last_page'];
        final results = data['data'] as List;

        episodes.addAll(
          results.map((e) {
            return Episode(
              animeId: animeId,
              number: e['episode'].toString(),
              id: e['session'],
              source: this,
            );
          }),
        );
        page++;
      } while (page <= lastPage);

      return episodes;
    } catch (e) {
      throw Exception('Error getting episodes: $e');
    }
  }

  @override
  Future<List<VideoSource>> getEpisodeSources(
    Episode episode, {
    String mode = 'sub',
  }) async {
    if (episode.id == null) {
      throw Exception('Episode ID (session) is required for AnimePahe');
    }

    final uri = Uri.https(_authority, '/play/${episode.animeId}/${episode.id}');

    try {
      final response = await _get(uri, headers: {'Referer': 'https://$_authority'});
      final document = html_parser.parse(response.body);
      final buttons = document.querySelectorAll('#resolutionMenu > button');

      final targetAudio = mode == 'dub' ? 'eng' : 'jpn';

      final tasks = buttons.where((button) {
        final audio = button.attributes['data-audio'];
        return audio == null || audio == targetAudio;
      }).map((button) {
        final src = button.attributes['data-src'];
        final kwik = button.attributes['data-kwik'];
        final resolution = button.attributes['data-resolution'] ?? 'unknown';
        final url = src ?? kwik;

        if (url != null) {
          return _processEmbed(url, resolution);
        }
        return null;
      }).whereType<Future<VideoSource?>>();

      final results = await Future.wait(tasks);
      return results.whereType<VideoSource>().toList();
    } catch (e) {
      throw Exception('Error getting episode sources: $e');
    }
  }

  Future<VideoSource?> _processEmbed(String url, String quality) async {
    try {
      final uri = Uri.parse(url);
      final response = await _get(uri, headers: {'Referer': 'https://$_authority'});

      // Regex to capture the arguments of the packed function
      // eval(function(p,a,c,k,e,d){...}(args))
      final scriptRegex = RegExp(
        r"eval\(function\(p,a,c,k,e,d\).*?\}\((.*?\.split\(['\x22]\|['\x22]\),\d+,.*?)\)\)",
        dotAll: true,
      );

      final matches = scriptRegex.allMatches(response.body);
      for (final match in matches) {
        final args = match.group(1);
        if (args == null) continue;

        final unpacked = DeanEdwardsPacker.unpack(args);

        // Extract m3u8 link from unpacked code
        final sourceRegex = RegExp(r"source\s*=\s*['\x22](.*?)['\x22]");
        final sourceMatch = sourceRegex.firstMatch(unpacked);

        if (sourceMatch != null) {
          return VideoSource(
            url: sourceMatch.group(1)!,
            quality: quality,
            type: 'hls',
            headers: {'Referer': 'https://kwik.cx/'},
          );
        }
      }
    } catch (e) {
      // Ignore errors for individual sources to allow others to succeed
    }
    return null;
  }

  @override
  void close() {
    _client.close();
  }
}
