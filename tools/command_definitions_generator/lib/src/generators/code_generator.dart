import '../models/command_definition_model.dart';

/// Abstract base class for language-specific code generators.
abstract class CodeGenerator {
  /// Target language name (e.g. 'Dart', 'Kotlin', 'Swift', 'C++').
  String get targetLanguage;

  /// Generates a map of relative file path to file content.
  Map<String, String> generate(List<CommandDefinitionModel> commands);

  /// Header comment included in all generated files.
  static const String fileHeader = '// GENERATED FILE - DO NOT EDIT.\n';
}

/// Helper utilities for deterministic string escaping.
class StringEscaper {
  /// Escapes a string for Dart single-quoted literals: `'...'`.
  static String escapeDart(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      switch (rune) {
        case 0x5C: // \
          buffer.write(r'\\');
          break;
        case 0x27: // '
          buffer.write(r"\'");
          break;
        case 0x24: // $
          buffer.write(r'\$');
          break;
        case 0x0A: // \n
          buffer.write(r'\n');
          break;
        case 0x0D: // \r
          buffer.write(r'\r');
          break;
        case 0x09: // \t
          buffer.write(r'\t');
          break;
        default:
          buffer.write(String.fromCharCode(rune));
      }
    }
    return "'$buffer'";
  }

  /// Escapes a string for Kotlin double-quoted literals: `"..."`.
  static String escapeKotlin(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      switch (rune) {
        case 0x5C: // \
          buffer.write(r'\\');
          break;
        case 0x22: // "
          buffer.write(r'\"');
          break;
        case 0x24: // $
          buffer.write(r'\$');
          break;
        case 0x0A: // \n
          buffer.write(r'\n');
          break;
        case 0x0D: // \r
          buffer.write(r'\r');
          break;
        case 0x09: // \t
          buffer.write(r'\t');
          break;
        default:
          buffer.write(String.fromCharCode(rune));
      }
    }
    return '"$buffer"';
  }

  /// Escapes a string for Swift double-quoted literals: `"..."`.
  static String escapeSwift(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      switch (rune) {
        case 0x5C: // \
          buffer.write(r'\\');
          break;
        case 0x22: // "
          buffer.write(r'\"');
          break;
        case 0x0A: // \n
          buffer.write(r'\n');
          break;
        case 0x0D: // \r
          buffer.write(r'\r');
          break;
        case 0x09: // \t
          buffer.write(r'\t');
          break;
        case 0x00: // \0
          buffer.write(r'\0');
          break;
        default:
          buffer.write(String.fromCharCode(rune));
      }
    }
    return '"$buffer"';
  }

  /// Escapes a string for C++ double-quoted literals: `"..."`.
  static String escapeCpp(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      switch (rune) {
        case 0x5C: // \
          buffer.write(r'\\');
          break;
        case 0x22: // "
          buffer.write(r'\"');
          break;
        case 0x3F: // ? to prevent trigraphs
          buffer.write(r'\?');
          break;
        case 0x0A: // \n
          buffer.write(r'\n');
          break;
        case 0x0D: // \r
          buffer.write(r'\r');
          break;
        case 0x09: // \t
          buffer.write(r'\t');
          break;
        default:
          buffer.write(String.fromCharCode(rune));
      }
    }
    return '"$buffer"';
  }
}
