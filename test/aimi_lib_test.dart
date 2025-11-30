import 'package:aimi_lib/aimi_lib.dart';
import 'package:aimi_lib/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('Decryptor', () {
    test('decrypts simple string correctly', () {
      // 79 -> A, 08 -> 0, 15 -> -
      expect(Decryptor.decrypt('790815'), equals('A0-'));
    });

    test('decrypts clock url correctly', () {
      // /clock -> /clock.json
      // We need to construct a string that decrypts to something containing /clock
      // / -> 17
      // c -> 5b
      // l -> 54
      // o -> 57
      // c -> 5b
      // k -> 53
      // So "175b54575b53" -> "/clock" -> "/clock.json"
      expect(Decryptor.decrypt('175b54575b53'), equals('/clock.json'));
    });

    test('handles odd length strings', () {
      // 79 -> A, 0 -> 0 (left as is because loop checks i+1 < length)
      expect(Decryptor.decrypt('790'), equals('A0'));
    });
  });

  group('Models', () {
    test('Anime.fromJson handles valid json', () {
      final json = {
        '_id': '123',
        'name': 'Test Anime',
        'availableEpisodes': 12,
        '__typename': 'Show'
      };
      final anime = Anime.fromJson(json);
      expect(anime.id, equals('123'));
      expect(anime.name, equals('Test Anime'));
      expect(anime.availableEpisodes, equals(12));
    });

    test('Anime.fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final anime = Anime.fromJson(json);
      expect(anime.id, equals(''));
      expect(anime.name, equals('Unknown'));
      expect(anime.availableEpisodes, isNull);
    });

    test('Anime.fromJson handles nested availableEpisodes', () {
      final json = {
        '_id': '123',
        'name': 'Test Anime',
        'availableEpisodes': {'sub': 24, 'dub': 12},
        '__typename': 'Show'
      };
      final anime = Anime.fromJson(json);
      expect(anime.availableEpisodes, equals(24));
    });
  });
}
