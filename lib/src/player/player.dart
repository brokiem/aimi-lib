import 'dart:io';
import '../models/stream_source.dart';

enum PlayerType { mpv, vlc, iina, androidMpv, androidVlc, browser }

/// Handles launching external video players with support for headers and platform-specific configurations.
class Player {
  /// Plays the given [source] using the specified [player] or an auto-detected one.
  ///
  /// [title] is optional and sets the window title for the player.
  /// Throws an exception if no player is found or if playback fails.
  static Future<void> play(
    StreamSource source, {
    PlayerType? player,
    String? title,
  }) async {
    final playerToUse = player ?? await _detectPlayer();
    if (playerToUse == null) {
      throw Exception(
        'No supported player found. Please install MPV, VLC, or IINA.',
      );
    }

    try {
      switch (playerToUse) {
        case PlayerType.mpv:
          await _playMpv(source, title);
          break;
        case PlayerType.vlc:
          await _playVlc(source, title);
          break;
        case PlayerType.iina:
          await _playIina(source, title);
          break;
        case PlayerType.androidMpv:
          await _playAndroidMpv(source, title);
          break;
        case PlayerType.androidVlc:
          await _playAndroidVlc(source, title);
          break;
        case PlayerType.browser:
          await _playBrowser(source);
          break;
      }
    } catch (e) {
      throw Exception('Failed to play with ${playerToUse.name}: $e');
    }
  }

  static Future<void> _playMpv(StreamSource source, String? title) async {
    final args = <String>[source.url];
    if (title != null) args.add('--force-media-title=$title');

    if (source.headers != null && source.headers!.isNotEmpty) {
      final headerList = source.headers!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(',');
      args.add('--http-header-fields=$headerList');

      if (source.headers!.containsKey('Referer')) {
        args.add('--referrer=${source.headers!['Referer']}');
      }
      if (source.headers!.containsKey('User-Agent')) {
        args.add('--user-agent=${source.headers!['User-Agent']}');
      }
    }

    await _runPlayerProcess('mpv', args);
  }

  static Future<void> _playVlc(StreamSource source, String? title) async {
    final args = <String>[source.url];
    if (title != null) args.add('--meta-title=$title');

    if (source.headers != null) {
      if (source.headers!.containsKey('Referer')) {
        args.add('--http-referrer=${source.headers!['Referer']}');
      }
      if (source.headers!.containsKey('User-Agent')) {
        args.add('--http-user-agent=${source.headers!['User-Agent']}');
      }
    }

    await _runPlayerProcess('vlc', args);
  }

  static Future<void> _playIina(StreamSource source, String? title) async {
    final args = <String>[source.url];

    // IINA CLI args are slightly different, but it supports mpv options via --mpv-option
    if (title != null) args.add('--mpv-force-media-title=$title');

    if (source.headers != null && source.headers!.isNotEmpty) {
      final headerList = source.headers!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(',');
      args.add('--mpv-http-header-fields=$headerList');

      if (source.headers!.containsKey('Referer')) {
        args.add('--mpv-referrer=${source.headers!['Referer']}');
      }
      if (source.headers!.containsKey('User-Agent')) {
        args.add('--mpv-user-agent=${source.headers!['User-Agent']}');
      }
    }

    // Check if 'iina' is in path, otherwise try 'open' on macOS
    if (await _hasCommand('iina')) {
      await _runPlayerProcess('iina', args);
    } else if (Platform.isMacOS) {
      // Fallback to opening via 'open' command which handles the .app bundle
      // Note: Passing complex args via 'open' to IINA is tricky.
      // Best effort is just the URL if CLI tool isn't installed.
      // However, we can try 'open -a IINA --args ...'
      final openArgs = ['-a', 'IINA', '--args', ...args];
      await Process.start('open', openArgs, mode: ProcessStartMode.detached);
    } else {
      throw Exception('IINA not found in PATH.');
    }
  }

  static Future<void> _playAndroidMpv(
    StreamSource source,
    String? title,
  ) async {
    // am start --user 0 -a android.intent.action.VIEW -d "$episode" -n is.xyz.mpv/.MPVActivity
    // Passing headers to Android intents is not standard for all players.
    // MPV-Android might support extras, but it's undocumented or varies.
    // We'll stick to basic URL launch.
    await Process.run('am', [
      'start',
      '--user',
      '0',
      '-a',
      'android.intent.action.VIEW',
      '-d',
      source.url,
      '-n',
      'is.xyz.mpv/.MPVActivity',
    ]);
  }

  static Future<void> _playAndroidVlc(
    StreamSource source,
    String? title,
  ) async {
    final args = [
      'start',
      '--user',
      '0',
      '-a',
      'android.intent.action.VIEW',
      '-d',
      source.url,
      '-n',
      'org.videolan.vlc/org.videolan.vlc.gui.video.VideoPlayerActivity',
    ];
    if (title != null) {
      args.addAll(['-e', 'title', title]);
    }
    await Process.run('am', args);
  }

  static Future<void> _playBrowser(StreamSource source) async {
    final url = source.url;
    if (Platform.isWindows) {
      await Process.run('start', [url], runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
    }
  }

  static Future<void> _runPlayerProcess(
    String executable,
    List<String> args,
  ) async {
    await Process.start(executable, args, mode: ProcessStartMode.detached);
  }

  static Future<PlayerType?> _detectPlayer() async {
    if (Platform.isAndroid) {
      // Default to androidMpv as we can't easily check installed apps from shell
      return PlayerType.androidMpv;
    }

    if (await _hasCommand('mpv')) return PlayerType.mpv;
    if (Platform.isMacOS) {
      if (await _hasCommand('iina') ||
          await Directory('/Applications/IINA.app').exists()) {
        return PlayerType.iina;
      }
    }
    if (await _hasCommand('vlc')) return PlayerType.vlc;

    return null;
  }

  static Future<bool> _hasCommand(String command) async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('where', [command]);
        return result.exitCode == 0;
      } else {
        final result = await Process.run('which', [command]);
        return result.exitCode == 0;
      }
    } catch (e) {
      return false;
    }
  }
}
