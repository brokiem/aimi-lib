## 3.0.0

- **New Feature**: Refactored `AnimeDetails` to include additional metadata fields: `titleEn`, `titleJp`, `titleSynonyms`, `type`, `aired`, `airedInt`, `member`, `rank`, `tags`, `duration`, `source`, `season`, `episodes`, `lastEpisode`, and `schedule`.
- **Update**: Updated `Kuroiru` provider to populate the new `AnimeDetails` fields.

## 2.0.0

- **New Feature**: Added `MetadataProvider` interface for fetching anime details (synopsis, rating, genres, etc.).
- **New Feature**: Added `Kuroiru` as the default implementation of `MetadataProvider`.
- **Breaking Change**: Renamed `Anime` class to `StreamableAnime` to better reflect its purpose.
- **Breaking Change**: Renamed `AnimeSource` class to `StreamProvider`.
- **Breaking Change**: Refactored project structure, moving core logic to `src/` folder.
- Added `options` parameter to `getSources` method in `StreamProvider` to support additional configurations (e.g., sub/dub selection).
- Added comprehensive unit tests for all providers (`Kuroiru`, `Anizone`, `AllAnime`, `AnimePahe`) and utilities.
- Added DartDocs to public API classes and methods.
- Updated README with detailed usage examples and credits.

## 1.1.0

- Added Anizone source.

## 1.0.0

- Initial version.
