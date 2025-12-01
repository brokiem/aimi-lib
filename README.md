# aimi_lib

A Dart library for interacting with anime APIs and playing videos.

## Features
 - **Metadata Provider**: Search for anime metadata using Kuroiru.
 - **Stream Provider**: Search and fetch episodes from AllAnime, AnimePahe, and Anizone.
 - **Fetch Episodes**: Retrieve available episodes for a selected anime.
 - **Get Stream Sources**: Extract video stream URLs (HLS/MP4) for episodes.
 - **Play Video**: Launch external video players (MPV, VLC, IINA) or open in browser.
 - **Cross-Platform**: Works on Windows, macOS, Linux, and Android.

## Getting started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  aimi_lib: ^2.0.0
```

If you plan to use the built-in `Player` class to play videos, ensure you have a supported video player installed:
- **MPV** (Recommended)
- **VLC**
- **IINA** (macOS)

Note: This is optional. You can implement your own player logic or use other packages to handle video playback using the URLs provided by [`StreamSource`](lib/src/models/stream_source.dart).

## Usage

You can run the example script to see the library in action. The CLI demonstrates the full workflow:

```bash
dart run example/aimi_lib_example.dart
```

### Full Workflow (Metadata + Stream)

Use this if you want to display anime details (image, synopsis, score) before playing.

```dart
import 'package:aimi_lib/aimi_lib.dart';

void main() async {
  // 1. Search in Metadata Provider
  final db = Kuroiru();
  final results = await db.search('Naruto');
  final searchResult = results.first;
  
  // 2. Get Details (Optional)
  final details = await db.getDetails(searchResult.id);
  print('Title: ${details.title}');

  // 3. Initialize Stream Provider
  final stream = AllAnime(); // or AnimePahe(), Anizone()

  // 4. Search in Stream Provider using the title from metadata
  final streamResults = await stream.search(details.title);
  final streamAnime = streamResults.first;

  // 5. Get Episodes
  final episodes = await streamAnime.getEpisodes();
  final episode = episodes.first;

  // 6. Get Stream Sources
  final sources = await episode.getSources();
  print('Stream URL: ${sources.first.url}');

  // free memory
  stream.close();
}
```

### Direct Stream Search

If you don't need metadata, you can search directly on the stream provider.

```dart
import 'package:aimi_lib/aimi_lib.dart';

void main() async {
  // 1. Initialize Stream Provider
  final stream = AllAnime(); // or AnimePahe(), Anizone()

  // 2. Search directly
  final streamResults = await stream.search('Naruto');
  final streamAnime = streamResults.first;

  // 3. Get Episodes
  final episodes = await streamAnime.getEpisodes();
  final episode = episodes.first;

  // 4. Get Stream Sources
  final sources = await episode.getSources();
  print('Stream URL: ${sources.first.url}');

  // free memory
  stream.close();
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

- Special thanks to [ani-cli](https://github.com/pystardust/ani-cli) for providing the base logic and inspiration.
- Special thanks to [animepahe-dl](https://github.com/KevCui/animepahe-dl) for the AnimePahe source logic.
- Special thanks to [Kuroiru](https://kuroiru.co) for providing the anime database.
