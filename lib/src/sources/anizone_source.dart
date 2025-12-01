import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import '../models.dart';
import 'anime_source.dart';

class AnizoneSource implements AnimeSource {
  @override
  String get name => 'Anizone';

  static const String _baseUrl = 'https://anizone.to';
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
  };

  final http.Client _client;

  AnizoneSource({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<List<Anime>> searchAnime(String query) async {
    final uri = Uri.parse('$_baseUrl/anime?search=$query');

    try {
      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load search results: ${response.statusCode}',
        );
      }

      var document = parser.parse(response.body);
      List<Anime> results = [];

      var items = document.querySelectorAll(
        'div.grid > div.relative.overflow-hidden',
      );

      for (var item in items) {
        var titleElement = item.querySelector('a[title]');
        var infoElement = item.querySelector('.text-xs');

        if (titleElement != null) {
          String href = titleElement.attributes['href'] ?? '';
          String title = titleElement.attributes['title'] ?? '';
          String info =
              infoElement?.text.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';

          int? episodeCount;
          // Try to extract episode count from info string like "TV • 2016 • 1 Eps"
          final epsMatch = RegExp(r'(\d+)\s*Eps').firstMatch(info);
          if (epsMatch != null) {
            episodeCount = int.tryParse(epsMatch.group(1) ?? '');
          }

          results.add(Anime(
            id: href,
            name: title,
            availableEpisodes: episodeCount,
            source: this,
          ));
        }
      }
      return results;
    } catch (e) {
      throw Exception('Error searching anime: $e');
    }
  }

  @override
  Future<List<Episode>> getEpisodes(String animeId) async {
    try {
      final response = await _client.get(Uri.parse(animeId), headers: _headers);
      if (response.statusCode != 200) {
        throw Exception('Failed to load anime details: ${response.statusCode}');
      }

      var document = parser.parse(response.body);
      List<Episode> episodes = [];

      var episodeList = document.querySelectorAll('ul.grid li a');

      for (var element in episodeList) {
        String href = element.attributes['href'] ?? '';
        var titleEl = element.querySelector('h3');
        String title = titleEl?.text.trim() ?? 'Unknown';

        String number = title;
        // Extract number from "Episode 1"
        final numMatch = RegExp(r'Episode\s+(\d+(\.\d+)?)').firstMatch(title);
        if (numMatch != null) {
          number = numMatch.group(1)!;
        }

        episodes.add(Episode(
          animeId: animeId,
          number: number,
          id: href,
          source: this,
        ));
      }

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
    if (episode.id == null) return [];

    try {
      final response = await _client.get(
        Uri.parse(episode.id!),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load episode: ${response.statusCode}');
      }

      var document = parser.parse(response.body);
      List<VideoSource> sources = [];

      var player = document.querySelector('media-player');

      if (player != null) {
        String streamUrl = player.attributes['src'] ?? '';
        if (streamUrl.isNotEmpty) {
          String type = 'hls';
          if (streamUrl.endsWith('.mp4')) {
            type = 'mp4';
          }

          sources.add(VideoSource(
            url: streamUrl,
            quality: 'default',
            type: type,
            headers: _headers,
          ));
        }
      }

      return sources;
    } catch (e) {
      throw Exception('Error getting episode sources: $e');
    }
  }

  @override
  void close() {
    _client.close();
  }
}
