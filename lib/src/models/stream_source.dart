/// Represents a video source link.
class StreamSource {
  /// The direct URL to the video file or stream manifest.
  final String url;

  /// The quality of the video (e.g., "1080p", "720p", "default", "auto").
  final String quality;

  /// The type of stream: "mp4" (direct file) or "hls" (m3u8 playlist).
  final String type;

  /// Optional headers required to play the video (e.g., Referer, User-Agent).
  final Map<String, String>? headers;

  StreamSource({
    required this.url,
    required this.quality,
    required this.type,
    this.headers,
  });

  @override
  String toString() => '$quality ($type): $url';
}
