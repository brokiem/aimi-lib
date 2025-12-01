/// Represents a lightweight anime search result.
class AnimeSearchResult {
  final String id;
  final String title;
  final String? image;
  final String? type;
  final String? time;

  AnimeSearchResult({
    required this.id,
    required this.title,
    this.image,
    this.type,
    this.time,
  });

  @override
  String toString() => '$title ($type)';
}
