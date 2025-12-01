import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anime_details.dart';
import '../models/streamable_anime.dart';
import '../models/episode.dart';
import '../models/stream_source.dart';
import '../utils/decryptor.dart';
import 'stream_provider.dart';

/// A [StreamProvider] implementation for AllAnime.
class AllAnime implements StreamProvider {
  @override
  String get name => 'AllAnime';

  static const String _baseUrl = 'https://api.allanime.day/api';
  static const String _referer = 'https://allmanga.to';
  static const String _agent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:145.0) Gecko/20100101 Firefox/145.0';

  final http.Client _client;

  AllAnime({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<List<StreamableAnime>> search(dynamic query) async {
    String searchQuery;
    if (query is AnimeDetails) {
      searchQuery = query.title;
    } else if (query is String) {
      searchQuery = query;
    } else {
      throw ArgumentError('Query must be a String or AnimeDetails object');
    }

    const String searchGql =
        'query( \$search: SearchInput \$limit: Int \$page: Int \$translationType: VaildTranslationTypeEnumType \$countryOrigin: VaildCountryOriginEnumType ) { shows( search: \$search limit: \$limit page: \$page translationType: \$translationType countryOrigin: \$countryOrigin ) { edges { _id name availableEpisodes __typename } }}';

    final variables = {
      "search": {
        "allowAdult": false,
        "allowUnknown": false,
        "query": searchQuery,
      },
      "limit": 40,
      "page": 1,
      "translationType": "sub",
      "countryOrigin": "ALL",
    };

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {'variables': jsonEncode(variables), 'query': searchGql},
    );

    try {
      final response = await _client
          .get(uri, headers: {'Referer': _referer, 'User-Agent': _agent})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final edges = data['data']['shows']['edges'] as List?;
        if (edges == null) return [];
        return edges.map((e) {
          final availableEpisodes = e['availableEpisodes'];
          int? eps;
          if (availableEpisodes is int) {
            eps = availableEpisodes;
          } else if (availableEpisodes is Map) {
            eps = availableEpisodes['sub'] ?? availableEpisodes['dub'];
          }

          return StreamableAnime(
            id: (e['_id'] ?? '') as String,
            title: (e['name'] ?? 'Unknown') as String,
            availableEpisodes: eps,
            stream: this,
          );
        }).toList();
      } else {
        throw Exception('Failed to search anime: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching anime: $e');
    }
  }

  @override
  Future<List<Episode>> getEpisodes(StreamableAnime anime) async {
    final animeId = anime.id;
    const String episodesListGql =
        'query (\$showId: String!) { show( _id: \$showId ) { _id availableEpisodesDetail }}';

    final variables = {"showId": animeId};

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'variables': jsonEncode(variables),
        'query': episodesListGql,
      },
    );

    try {
      final response = await _client
          .get(uri, headers: {'Referer': _referer, 'User-Agent': _agent})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final show = data['data']['show'];
        if (show == null) return [];

        final availableEpisodesDetail = show['availableEpisodesDetail'];
        if (availableEpisodesDetail == null) return [];

        final sub = availableEpisodesDetail['sub'] as List?;
        final dub = availableEpisodesDetail['dub'] as List?;
        final raw = availableEpisodesDetail['raw'] as List?;

        final Set<String> episodes = {};
        if (sub != null) episodes.addAll(sub.cast<String>());
        if (dub != null) episodes.addAll(dub.cast<String>());
        if (raw != null) episodes.addAll(raw.cast<String>());

        final sortedEps = episodes.toList()
          ..sort((a, b) {
            final numA = double.tryParse(a) ?? 0;
            final numB = double.tryParse(b) ?? 0;
            return numA.compareTo(numB);
          });

        return sortedEps
            .map((e) => Episode(animeId: animeId, number: e, stream: this))
            .toList();
      } else {
        throw Exception('Failed to get episodes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting episodes: $e');
    }
  }

  @override
  Future<List<StreamSource>> getSources(
    Episode episode, {
    Map<String, dynamic>? options,
  }) async {
    final animeId = episode.animeId;
    final episodeNumber = episode.number;

    final String mode = options?['mode'] ?? 'sub';

    const String episodeEmbedGql =
        'query (\$showId: String!, \$translationType: VaildTranslationTypeEnumType!, \$episodeString: String!) { episode( showId: \$showId translationType: \$translationType episodeString: \$episodeString ) { episodeString sourceUrls }}';

    final variables = {
      "showId": animeId,
      "translationType": mode,
      "episodeString": episodeNumber,
    };

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'variables': jsonEncode(variables),
        'query': episodeEmbedGql,
      },
    );

    try {
      final response = await _client
          .get(uri, headers: {'Referer': _referer, 'User-Agent': _agent})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to get episode sources: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);
      final episodeData = data['data']['episode'];
      if (episodeData == null) return [];

      final sourceUrls = episodeData['sourceUrls'] as List?;
      if (sourceUrls == null) return [];

      final results = await Future.wait(
        sourceUrls.map((source) => _processSource(source)),
      );

      return results.expand((i) => i).toList();
    } catch (e) {
      throw Exception('Error getting episode sources: $e');
    }
  }

  Future<List<StreamSource>> _processSource(dynamic source) async {
    List<StreamSource> sources = [];
    try {
      final sourceUrl = source['sourceUrl'];
      final sourceName = source['sourceName'];
      if (sourceUrl == null) return [];

      String decryptedId = sourceUrl;
      if (sourceUrl.startsWith('--')) {
        decryptedId = Decryptor.decrypt(sourceUrl.substring(2));
      }

      final uri = Uri.parse('https://allanime.day$decryptedId');

      final response = await _client
          .get(uri, headers: {'Referer': _referer, 'User-Agent': _agent})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        sources.addAll(await _parseLinks(response.body, sourceName));
      }
    } catch (e) {
      // Ignore errors for individual sources
    }
    return sources;
  }

  Future<List<StreamSource>> _parseLinks(
    String responseBody,
    String? sourceName,
  ) async {
    List<StreamSource> sources = [];

    String? m3u8Referer;
    final refererMatch = RegExp(
      r'"Referer":"([^"]*)"',
    ).firstMatch(responseBody);
    if (refererMatch != null) {
      m3u8Referer = refererMatch.group(1);
    }

    // Extract direct links (mp4)
    final linkRegex = RegExp(r'"link":"([^"]*)".*?"resolutionStr":"([^"]*)"');
    for (final match in linkRegex.allMatches(responseBody)) {
      String url = match.group(1)!.replaceAll(r'\/', '/');
      String quality = match.group(2)!;

      if (url.contains('.m3u8')) {
        await _parseM3u8(url, m3u8Referer, sources);
      } else {
        sources.add(StreamSource(url: url, quality: quality, type: 'mp4'));
      }
    }

    // Extract HLS links
    final hlsRegex = RegExp(r'"hls","url":"([^"]*)".*?"hardsub_lang":"en-US"');
    for (final match in hlsRegex.allMatches(responseBody)) {
      String url = match.group(1)!.replaceAll(r'\/', '/');

      if (url.contains('master.m3u8')) {
        await _parseM3u8(url, m3u8Referer, sources);
      } else {
        sources.add(StreamSource(url: url, quality: 'auto', type: 'hls'));
      }
    }

    return sources;
  }

  Future<void> _parseM3u8(
    String url,
    String? referer,
    List<StreamSource> sources,
  ) async {
    try {
      final m3u8Response = await _client
          .get(
            Uri.parse(url),
            headers: {'Referer': referer ?? _referer, 'User-Agent': _agent},
          )
          .timeout(const Duration(seconds: 30));

      if (m3u8Response.statusCode == 200) {
        final lines = LineSplitter.split(m3u8Response.body).toList();
        bool foundStream = false;
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].startsWith('#EXT-X-STREAM-INF')) {
            String quality = 'auto';
            final resMatch = RegExp(
              r'RESOLUTION=(\d+x\d+)',
            ).firstMatch(lines[i]);
            if (resMatch != null) {
              quality = resMatch.group(1)!;
            }

            if (i + 1 < lines.length) {
              String streamUrl = lines[i + 1].trim();
              if (streamUrl.isNotEmpty && !streamUrl.startsWith('#')) {
                if (!streamUrl.startsWith('http')) {
                  final base = url.substring(0, url.lastIndexOf('/') + 1);
                  streamUrl = base + streamUrl;
                }
                sources.add(
                  StreamSource(url: streamUrl, quality: quality, type: 'hls'),
                );
                foundStream = true;
              }
            }
          }
        }
        if (!foundStream) {
          sources.add(StreamSource(url: url, quality: 'auto', type: 'hls'));
        }
      }
    } catch (e) {
      sources.add(StreamSource(url: url, quality: 'auto', type: 'hls'));
    }
  }

  void close() {
    _client.close();
  }
}
