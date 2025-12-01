import '../stream/stream_provider.dart';
import 'stream_source.dart';

/// Represents an episode's details.
class Episode {
  /// The ID of the anime this episode belongs to.
  final String animeId;

  /// The episode number (e.g., "1", "12").
  final String number;

  /// A unique identifier for this episode on the streaming site, if available.
  final String? sourceId;

  /// The stream provider instance that created this object.
  final StreamProvider? stream;

  Episode({
    required this.animeId,
    required this.number,
    this.sourceId,
    this.stream,
  });

  /// Fetches video sources for this episode using its attached stream source.
  /// Throws an exception if no stream is attached.
  Future<List<StreamSource>> getSources({Map<String, dynamic>? options}) async {
    if (stream == null) {
      throw Exception('No stream attached to this Episode instance.');
    }
    return stream!.getSources(this, options: options);
  }

  Episode copyWith({
    String? animeId,
    String? number,
    String? sourceId,
    StreamProvider? stream,
  }) {
    return Episode(
      animeId: animeId ?? this.animeId,
      number: number ?? this.number,
      sourceId: sourceId ?? this.sourceId,
      stream: stream ?? this.stream,
    );
  }
}
