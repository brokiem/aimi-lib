import 'dart:io';
import 'package:aimi_lib/aimi_lib.dart';

void main() async {
  // Default to AllAnimeSource for now
  AnimeSource source = AllAnimeSource();

  print('Using source: ${source.name}');

  print('Enter anime name to search:');
  final query = stdin.readLineSync();
  if (query == null || query.isEmpty) return;

  try {
    print('Searching...');
    final results = await source.searchAnime(query);

    if (results.isEmpty) {
      print('No results found.');
      return;
    }

    for (var i = 0; i < results.length; i++) {
      print('$i: ${results[i].name} (${results[i].availableEpisodes} eps)');
    }

    print('Select anime (index):');
    final indexStr = stdin.readLineSync();
    if (indexStr == null) return;
    final index = int.tryParse(indexStr);
    if (index == null || index < 0 || index >= results.length) {
      print('Invalid selection.');
      return;
    }

    final anime = results[index];
    print('Fetching episodes for ${anime.name}...');
    final episodes = await anime.getEpisodes();

    if (episodes.isEmpty) {
      print('No episodes found.');
      return;
    }

    // Sort episodes by number if possible
    episodes.sort((a, b) {
      final numA = double.tryParse(a.number);
      final numB = double.tryParse(b.number);
      if (numA != null && numB != null) return numA.compareTo(numB);
      return a.number.compareTo(b.number);
    });

    print('Available episodes: ${episodes.map((e) => e.number).join(', ')}');

    print('Enter episode number:');
    final epNum = stdin.readLineSync();
    if (epNum == null) return;

    // Find the episode object
    final episode = episodes.firstWhere(
      (e) => e.number == epNum,
      orElse: () => throw Exception('Episode not found'),
    );

    print('Fetching sources...');
    final sources = await episode.getSources();

    if (sources.isEmpty) {
      print('No sources found.');
      return;
    }

    for (var i = 0; i < sources.length; i++) {
      print(
        '$i: ${sources[i].quality} (${sources[i].type}) - ${sources[i].url}',
      );
    }

    print('Select source to play (index) or q to quit:');
    final sourceIndexStr = stdin.readLineSync();
    if (sourceIndexStr == 'q') return;

    final sourceIndex = int.tryParse(sourceIndexStr ?? '');
    if (sourceIndex != null &&
        sourceIndex >= 0 &&
        sourceIndex < sources.length) {
      print('Launching player...');
      await Player.play(
        sources[sourceIndex],
        title: '${anime.name} - Episode $epNum',
        player: PlayerType.mpv,
      );
    }
  } catch (e) {
    print('Error: $e');
  }
}
