import 'sources/anime_source.dart';

/// Represents a search result for an anime.
class Anime {
  final String id;
  final String name;
  final int? availableEpisodes;
  final String? typename;
  final AnimeSource? source;

  Anime({
    required this.id,
    required this.name,
    this.availableEpisodes,
    this.typename,
    this.source,
  });

  factory Anime.fromJson(Map<String, dynamic> json, {AnimeSource? source}) {
    return Anime(
      id: (json['_id'] ?? '') as String,
      name: (json['name'] ?? 'Unknown') as String,
      availableEpisodes: json['availableEpisodes'] is int
          ? json['availableEpisodes']
          : (json['availableEpisodes'] is Map
              ? (json['availableEpisodes']['sub'] ??
                  json['availableEpisodes']['dub'])
              : null),
      typename: json['__typename'],
      source: source,
    );
  }

  Future<List<Episode>> getEpisodes() async {
    if (source == null) {
      throw Exception('No source attached to this Anime instance.');
    }
    return source!.getEpisodes(id);
  }

  Anime copyWith({
    String? id,
    String? name,
    int? availableEpisodes,
    String? typename,
    AnimeSource? source,
  }) {
    return Anime(
      id: id ?? this.id,
      name: name ?? this.name,
      availableEpisodes: availableEpisodes ?? this.availableEpisodes,
      typename: typename ?? this.typename,
      source: source ?? this.source,
    );
  }

  @override
  String toString() => '$name ($availableEpisodes episodes)';
}

/// Represents a video source link.
class VideoSource {
  final String url;
  final String quality; // e.g., "1080p", "720p", "default"
  final String type; // "mp4" or "hls"
  final Map<String, String>? headers;

  VideoSource({
    required this.url,
    required this.quality,
    required this.type,
    this.headers,
  });

  @override
  String toString() => '$quality ($type): $url';
}

/// Represents an episode's details.
class Episode {
  final String animeId;
  final String number;
  final String? id; // Unique ID if available
  final List<String> sourceUrls;
  final AnimeSource? source;

  Episode({
    required this.animeId,
    required this.number,
    this.id,
    this.sourceUrls = const [],
    this.source,
  });

  Future<List<VideoSource>> getSources({String mode = 'sub'}) async {
    if (source == null) {
      throw Exception('No source attached to this Episode instance.');
    }
    return source!.getEpisodeSources(this, mode: mode);
  }

  Episode copyWith({
    String? animeId,
    String? number,
    String? id,
    List<String>? sourceUrls,
    AnimeSource? source,
  }) {
    return Episode(
      animeId: animeId ?? this.animeId,
      number: number ?? this.number,
      id: id ?? this.id,
      sourceUrls: sourceUrls ?? this.sourceUrls,
      source: source ?? this.source,
    );
  }
}
