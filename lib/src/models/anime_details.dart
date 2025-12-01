/// Represents detailed anime information from a database.
class AnimeDetails {
  final String id;
  final String title;
  final String? image;
  final String? description;
  final String? rating;
  final double? score;
  final List<String>? genres;
  final List<String>? studios;
  final String? status;

  AnimeDetails({
    required this.id,
    required this.title,
    this.image,
    this.description,
    this.rating,
    this.score,
    this.genres,
    this.studios,
    this.status,
  });

  @override
  String toString() => '$title ($status)';
}
