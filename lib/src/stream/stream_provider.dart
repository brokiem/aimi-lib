import '../models/streamable_anime.dart';
import '../models/episode.dart';
import '../models/stream_source.dart';

/// Interface for providers that fetch streaming links and episodes.
abstract class StreamProvider {
  /// The name of the stream provider (e.g., "AllAnime", "AnimePahe").
  String get name;

  /// Searches for anime on the streaming site.
  ///
  /// [query] can be a String (title) or [AnimeDetails] object.
  /// Returns a list of [StreamableAnime] found on the provider.
  Future<List<StreamableAnime>> search(dynamic query);

  /// Fetches the list of episodes for a given [anime].
  Future<List<Episode>> getEpisodes(StreamableAnime anime);

  /// Fetches the video sources (stream URLs) for a given [episode].
  ///
  /// [options] can be used to specify preferences like mode (sub/dub).
  Future<List<StreamSource>> getSources(
    Episode episode, {
    Map<String, dynamic>? options,
  });
}
