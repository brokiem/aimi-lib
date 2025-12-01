import '../models/anime_details.dart';
import '../models/anime_search_result.dart';

/// Interface for providers that fetch anime metadata (info, synopsis, etc.).
abstract class MetadataProvider {
  /// Searches for anime by [query].
  ///
  /// Returns a list of [AnimeSearchResult] matching the query.
  Future<List<AnimeSearchResult>> search(String query);

  /// Fetches detailed information for an anime by its [id].
  ///
  /// Returns [AnimeDetails] containing full metadata.
  Future<AnimeDetails> getDetails(String id);
}
