import '../stream/stream_provider.dart';
import 'episode.dart';

/// Represents an anime found on a stream source.
class StreamableAnime {
  /// The unique identifier for this anime on the streaming site.
  final String id;

  /// The title of the anime.
  final String title;

  /// The number of available episodes, if known.
  final int? availableEpisodes;

  /// The stream provider instance that created this object.
  final StreamProvider stream;

  StreamableAnime({
    required this.id,
    required this.title,
    required this.stream,
    this.availableEpisodes,
  });

  /// Fetches episodes for this anime using its attached stream source.
  Future<List<Episode>> getEpisodes() async {
    return stream.getEpisodes(this);
  }

  @override
  String toString() => '$title ($availableEpisodes episodes)';
}
