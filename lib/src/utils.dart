import 'dart:math';

class Decryptor {
  static final Map<String, String> _map = {
    '79': 'A', '7a': 'B', '7b': 'C', '7c': 'D', '7d': 'E', '7e': 'F', '7f': 'G',
    '70': 'H', '71': 'I', '72': 'J', '73': 'K', '74': 'L', '75': 'M', '76': 'N', '77': 'O',
    '68': 'P', '69': 'Q', '6a': 'R', '6b': 'S', '6c': 'T', '6d': 'U', '6e': 'V', '6f': 'W',
    '60': 'X', '61': 'Y', '62': 'Z',
    '59': 'a', '5a': 'b', '5b': 'c', '5c': 'd', '5d': 'e', '5e': 'f', '5f': 'g',
    '50': 'h', '51': 'i', '52': 'j', '53': 'k', '54': 'l', '55': 'm', '56': 'n', '57': 'o',
    '48': 'p', '49': 'q', '4a': 'r', '4b': 's', '4c': 't', '4d': 'u', '4e': 'v', '4f': 'w',
    '40': 'x', '41': 'y', '42': 'z',
    '08': '0', '09': '1', '0a': '2', '0b': '3', '0c': '4', '0d': '5', '0e': '6', '0f': '7',
    '00': '8', '01': '9',
    '15': '-', '16': '.', '67': '_', '46': '~', '02': ':', '17': '/', '07': '?', '1b': '#',
    '63': '[', '65': ']', '78': '@', '19': '!', '1c': '\$', '1e': '&', '10': '(', '11': ')',
    '12': '*', '13': '+', '14': ',', '03': ';', '05': '=', '1d': '%'
  };

  static String decrypt(String input) {
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i += 2) {
      if (i + 1 < input.length) {
        final pair = input.substring(i, i + 2);
        buffer.write(_map[pair] ?? pair);
      } else {
        buffer.write(input[i]);
      }
    }
    var result = buffer.toString();
    return result.replaceAll('/clock', '/clock.json');
  }
}

class DeanEdwardsPacker {
  static String unpack(String args) {
    // Dean Edwards Packer unpacker
    // args format: 'payload',radix,count,'keywords'.split('|'),0,{}

    // 1. Extract keywords
    var splitIndex = args.lastIndexOf(".split('|')");
    if (splitIndex == -1) {
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

    final keywordsStr =
        args.substring(keywordsStartQuoteIndex + 1, keywordsEndQuoteIndex);
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

    final countStr =
        beforeKeywords.substring(commaBeforeCount + 1, commaAfterCount);
    final count = int.tryParse(countStr) ?? 0;

    // Find comma before radix
    int commaBeforeRadix =
        beforeKeywords.lastIndexOf(',', commaBeforeCount - 1);
    if (commaBeforeRadix == -1) return '';

    final radixStr =
        beforeKeywords.substring(commaBeforeRadix + 1, commaBeforeCount);
    final radix = int.tryParse(radixStr) ?? 0;

    // Payload is everything before radix
    String payload = beforeKeywords.substring(0, commaBeforeRadix).trim();

    // Remove wrapping quotes from payload
    if ((payload.startsWith("'") && payload.endsWith("'")) ||
        (payload.startsWith('"') && payload.endsWith('"'))) {
      payload = payload.substring(1, payload.length - 1);
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

class StringUtils {
  static String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }
}
