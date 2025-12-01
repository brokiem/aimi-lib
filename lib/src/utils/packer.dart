class DeanEdwardsPacker {
  static String unpack(String args) {
    // Dean Edwards Packer unpacker
    // args format: 'payload',radix,count,'keywords'.split('|'),0,{}

    // 1. Extract keywords
    var splitIndex = args.lastIndexOf(".split('|')");
    if (splitIndex == -1) {
      // Try with double quotes
      splitIndex = args.lastIndexOf('.split("|")');
    }
    if (splitIndex == -1) return '';

    // Find the quote before keywords
    final keywordsEndQuoteIndex = splitIndex - 1;
    final quoteChar = args[keywordsEndQuoteIndex];

    // Find the start quote of keywords (handling escaped quotes)
    int keywordsStartQuoteIndex = -1;
    for (int i = keywordsEndQuoteIndex - 1; i >= 0; i--) {
      if (args[i] == quoteChar && (i == 0 || args[i - 1] != '\\')) {
        keywordsStartQuoteIndex = i;
        break;
      }
    }
    if (keywordsStartQuoteIndex == -1) return '';

    final keywordsStr = args.substring(
      keywordsStartQuoteIndex + 1,
      keywordsEndQuoteIndex,
    );
    final keywords = keywordsStr.split('|');

    // 2. Extract payload, radix, count
    // The part before keywords is: 'payload',radix,count,
    final beforeKeywords = args.substring(0, keywordsStartQuoteIndex).trim();
    if (!beforeKeywords.endsWith(',')) return '';

    // Helper to find last comma ignoring quotes would be better, but assuming standard format:
    // Find comma before count
    int commaAfterCount = beforeKeywords.length - 1;
    int commaBeforeCount = beforeKeywords.lastIndexOf(',', commaAfterCount - 1);
    if (commaBeforeCount == -1) return '';

    // Find comma before radix
    int commaBeforeRadix = beforeKeywords.lastIndexOf(
      ',',
      commaBeforeCount - 1,
    );
    if (commaBeforeRadix == -1) return '';

    final countStr = beforeKeywords
        .substring(commaBeforeCount + 1, commaAfterCount)
        .trim();
    final radixStr = beforeKeywords
        .substring(commaBeforeRadix + 1, commaBeforeCount)
        .trim();
    final payloadRaw = beforeKeywords.substring(0, commaBeforeRadix).trim();

    // Payload might be quoted
    String payload = payloadRaw;
    if ((payload.startsWith("'") && payload.endsWith("'")) ||
        (payload.startsWith('"') && payload.endsWith('"'))) {
      payload = payload.substring(1, payload.length - 1);
    }

    final radix = int.tryParse(radixStr) ?? 10;
    final count = int.tryParse(countStr) ?? 0;

    if (keywords.length != count && count != 0) {
      // Sometimes count is just a placeholder or keywords length is different?
      // But usually they match. Proceed anyway.
    }

    // Unescape payload
    payload = payload
        .replaceAll(r"\'", "'")
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', r'\');

    if (keywords.isEmpty) return payload;

    // 3. Unpack
    final Map<String, String> dict = {};
    for (int i = 0; i < count; i++) {
      String key = _toBase(i, radix);
      String val = (i < keywords.length && keywords[i].isNotEmpty)
          ? keywords[i]
          : key;
      dict[key] = val;
    }

    return payload.replaceAllMapped(RegExp(r'\b\w+\b'), (match) {
      final word = match.group(0)!;
      return dict[word] ?? word;
    });
  }

  static String _toBase(int d, int a) {
    const chars =
        '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (d < a) return chars[d];
    return _toBase(d ~/ a, a) + chars[d % a];
  }
}
