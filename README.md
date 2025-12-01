# aimi_lib

A Dart library for interacting with anime APIs and playing videos.

## Features
 - **Search Anime**: Search for anime titles from supported sources (AllAnime, AnimePahe, and Anizone).
 - **Fetch Episodes**: Retrieve available episodes for a selected anime.
 - **Get Video Sources**: Extract video stream URLs (HLS/MP4) for episodes.
 - **Play Video**: Launch external video players (MPV, VLC, IINA) or open in browser.
 - **Cross-Platform**: Works on Windows, macOS, Linux, and Android.

## Getting started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  aimi_lib: ^1.0.0
```

If you plan to use the built-in `Player` class to play videos, ensure you have a supported video player installed:
- **MPV** (Recommended)
- **VLC**
- **IINA** (macOS)

Note: This is optional. You can implement your own player logic or use other packages to handle video playback using the URLs provided by `VideoSource`.

## Usage

You can run the example script to see the library in action. The CLI lets you choose between AllAnime, AnimePahe, and Anizone sources:

```bash
dart run example/aimi_lib_example.dart
```

Here is a simple example of how to use the library:

```dart
import 'package:aimi_lib/aimi_lib.dart';

void main() async {
  // Initialize source
  final source = AllAnimeSource(); // or AnimePaheSource(), AnizoneSource()

  // Search for anime
  final results = await source.searchAnime('Naruto');
  if (results.isNotEmpty) {
    final anime = results.first;
    print('Found: ${anime.name}');

    // Get episodes
    final episodes = await anime.getEpisodes();
    if (episodes.isNotEmpty) {
      final firstEp = episodes.first;
      
      // Get video sources
      final sources = await firstEp.getSources();
      
      if (sources.isNotEmpty) {
        // Play the first source
        await Player.play(sources.first, title: '${anime.name} - Episode ${firstEp.number}');
      }
    }
  }
  
  // Free memory
  source.close();
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

- Special thanks to [ani-cli](https://github.com/pystardust/ani-cli) for providing the base logic and inspiration.
- Special thanks to [animepahe-dl](https://github.com/KevCui/animepahe-dl) for the AnimePahe source logic.
