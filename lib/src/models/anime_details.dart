/// Represents detailed anime information from a database.
class AnimeDetails {
  final String id;
  final String title;
  final String? titleEn;
  final String? titleJp;
  final List<String>? titleSynonyms;
  final String? image;
  final String? description;
  final String? type;
  final String? aired;
  final int? airedInt;
  final String? rating;
  final double? score;
  final int? member;
  final int? rank;
  final List<String>? genres;
  final String? tags;
  final String? duration;
  final List<String>? studios;
  final String? source;
  final String? season;
  final int? episodes;
  final int? lastEpisode;
  final int? schedule;
  final String? status;

  AnimeDetails({
    required this.id,
    required this.title,
    this.titleEn,
    this.titleJp,
    this.titleSynonyms,
    this.image,
    this.description,
    this.type,
    this.aired,
    this.airedInt,
    this.rating,
    this.score,
    this.member,
    this.rank,
    this.genres,
    this.tags,
    this.duration,
    this.studios,
    this.source,
    this.season,
    this.episodes,
    this.lastEpisode,
    this.schedule,
    this.status,
  });

  @override
  String toString() => '$title ($status)';
}
