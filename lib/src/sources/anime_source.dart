import '../models.dart';

/// Abstract base class for anime sources.
abstract class AnimeSource {
  /// The name of the source.
  String get name;

  /// Searches for anime matching the [query].
  Future<List<Anime>> searchAnime(String query);

  /// Retrieves the list of available episodes for the given [animeId].
  /// Returns a list of episode IDs or numbers.
  Future<List<Episode>> getEpisodes(String animeId);

  /// Retrieves the video sources for a specific [episode].
  Future<List<VideoSource>> getEpisodeSources(Episode episode, {String mode = 'sub'});

  /// Closes the client and frees resources.
  void close();
}
