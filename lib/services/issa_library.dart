import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IssaBook {
  final String id, title, file;
  final List<String> pages;
  const IssaBook(this.id, this.title, this.file, this.pages);
}

class IssaPassage {
  final IssaBook book;
  final int page;
  final String excerpt;
  final double score;
  const IssaPassage(this.book, this.page, this.excerpt, this.score);
  String get citation => '${book.title} · PDF page $page';
}

/// Source retrieval, not clinical recommendations or a generative model.
class IssaLibrary {
  final List<IssaBook> books;
  final Map<String, Map<int, int>> _index = {};
  final List<({IssaBook book, int page, int length})> _pages = [];
  static Future<IssaLibrary>? _loading;
  static const _stop = {
    'a',
    'an',
    'and',
    'are',
    'as',
    'at',
    'be',
    'by',
    'can',
    'do',
    'does',
    'for',
    'from',
    'how',
    'i',
    'in',
    'is',
    'it',
    'me',
    'my',
    'of',
    'on',
    'or',
    'the',
    'this',
    'to',
    'what',
    'when',
    'which',
    'with',
    'you',
    'your',
    'about',
    'explain',
    'tell',
    'should',
    'would',
    'could',
    'issa',
  };
  static List<String> _terms(String text) => RegExp(r'[a-z0-9]+')
      .allMatches(text.toLowerCase())
      .map((m) => m[0]!)
      .where((t) => t.length > 1 && !_stop.contains(t))
      .toList();

  IssaLibrary(this.books) {
    for (final book in books) {
      for (var p = 0; p < book.pages.length; p++) {
        final terms = _terms(book.pages[p]);
        if (terms.isEmpty) continue;
        final id = _pages.length;
        _pages.add((book: book, page: p + 1, length: terms.length));
        for (final term in terms) {
          final postings = _index.putIfAbsent(term, () => {});
          postings[id] = (postings[id] ?? 0) + 1;
        }
      }
    }
  }
  static IssaLibrary fromJson(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    if (data['version'] != 1) throw const FormatException('Library version');
    return IssaLibrary([
      for (final b in data['books'] as List)
        IssaBook(
          b['id'] as String,
          b['title'] as String,
          b['file'] as String,
          List<String>.from(b['pages'] as List),
        ),
    ]);
  }

  static Future<IssaLibrary> load() => _loading ??= _load();
  static Future<IssaLibrary> _load() async {
    try {
      return await compute(
        fromJson,
        await rootBundle.loadString('assets/coaching/issa_library.json'),
      );
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  int get searchablePages => _pages.length;
  List<IssaPassage> search(String query, {String? bookId, int limit = 8}) {
    final terms = _terms(query).toSet();
    if (terms.isEmpty || limit <= 0) return [];
    final scores = <int, double>{};
    final matches = <int, int>{};
    for (final term in terms) {
      final postings = _index[term] ?? const <int, int>{};
      final rarity = math.log(1 + (_pages.length + 1) / (postings.length + 1));
      for (final entry in postings.entries) {
        final page = _pages[entry.key];
        if (bookId != null && page.book.id != bookId) continue;
        final frequency = entry.value;
        final score =
            rarity *
            frequency *
            2.2 /
            (frequency + 1.2 * (0.25 + 0.75 * page.length / 300));
        scores.update(
          entry.key,
          (value) => value + score,
          ifAbsent: () => score,
        );
        matches.update(entry.key, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final ranked =
        scores.keys.where((id) => matches[id] == terms.length).toList()
          ..sort((a, b) {
            final difference = scores[b]!.compareTo(scores[a]!);
            return difference != 0 ? difference : a.compareTo(b);
          });
    return ranked.take(limit).map((id) {
      final page = _pages[id];
      final text = page.book.pages[page.page - 1].replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      final lower = text.toLowerCase();
      var first = text.length;
      for (final term in terms) {
        final at = lower.indexOf(term);
        if (at >= 0 && at < first) first = at;
      }
      var start = math.max(0, first - 100);
      if (start > 0) {
        final boundary = text.indexOf(' ', start);
        if (boundary >= 0) start = boundary + 1;
      }
      final end = math.min(text.length, start + 650);
      return IssaPassage(
        page.book,
        page.page,
        '${start > 0 ? '…' : ''}${text.substring(start, end)}${end < text.length ? '…' : ''}',
        scores[id]!,
      );
    }).toList();
  }
}
