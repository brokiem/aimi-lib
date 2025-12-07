import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anime_details.dart';
import '../models/anime_search_result.dart';
import 'metadata_provider.dart';

/// A [MetadataProvider] implementation that fetches data from Kuroiru.
class Kuroiru implements MetadataProvider {
  static const String _searchUrl = 'https://kuroiru.co/backend/search';
  static const String _detailsUrl = 'https://kuroiru.co/backend/api';

  static const Map<String, String> _headers = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:145.0) Gecko/20100101 Firefox/145.0",
    "Content-Type": "application/x-www-form-urlencoded",
  };

  final http.Client _client;

  Kuroiru({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<List<AnimeSearchResult>> search(String query) async {
    try {
      final response = await _client.post(
        Uri.parse(_searchUrl),
        headers: {..._headers, "Referer": "https://kuroiru.co/"},
        body: "q=${Uri.encodeComponent(query)}",
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to search Kuroiru: ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map(
            (e) => AnimeSearchResult(
              id: e['id'].toString(),
              title: e['title'],
              image: _processImageUrl(e['image']),
              type: e['type'],
              time: e['time'],
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Error searching Kuroiru: $e');
    }
  }

  @override
  Future<AnimeDetails> getDetails(String id) async {
    try {
      final response = await _client.post(
        Uri.parse(_detailsUrl),
        headers: {..._headers, "Referer": "https://kuroiru.co/"},
        body: "prompt=$id",
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to get Kuroiru details: ${response.statusCode}, id: $id',
        );
      }

      final data = jsonDecode(response.body);
      final info = data['info'] ?? {};

      return AnimeDetails(
        id: id,
        title: data['title'] ?? 'Unknown',
        titleEn: data['title_en'],
        titleJp: data['title_jp'],
        titleSynonyms: (data['title_synonyms'] as List?)
            ?.map((e) => e.toString())
            .toList(),
        image: _processImageUrl(data['picture']),
        description: info['synopsis'],
        type: info['type'],
        aired: info['aired'],
        airedInt: info['airedint'],
        rating: info['rating'],
        score: info['score'] is num ? (info['score'] as num).toDouble() : null,
        member: info['member'],
        rank: info['rank'],
        genres: (info['genres'] as List?)?.map((e) => e.toString()).toList(),
        tags: info['tags'],
        duration: info['duration'],
        studios: (info['studios'] as List?)?.map((e) => e.toString()).toList(),
        source: info['source'],
        season: info['season'],
        episodes: data['episodes'],
        lastEpisode: data['lastep'],
        schedule: data['schedule'],
        status: data['status'],
      );
    } catch (e) {
      throw Exception('Error getting Kuroiru details: $e');
    }
  }

  String? _processImageUrl(dynamic path) {
    if (path == null) return null;
    final pathStr = path.toString();

    if (pathStr.startsWith('/img/')) {
      final regex = RegExp(r'^/img/(\d+)/(\d+)\.jpg$');
      final match = regex.firstMatch(pathStr);
      if (match != null) {
        return 'https://cdn.myanimelist.net/images/anime/${match.group(1)}/${match.group(2)}l.jpg';
      }
    }

    if (pathStr.startsWith('/')) {
      return 'https://kuroiru.co$pathStr';
    }

    return pathStr;
  }
}
