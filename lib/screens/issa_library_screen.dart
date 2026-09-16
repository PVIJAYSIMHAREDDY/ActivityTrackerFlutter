import 'package:flutter/material.dart';
import '../services/issa_library.dart';

class IssaLibraryScreen extends StatefulWidget {
  final String initialQuery;
  final Future<IssaLibrary>? library;
  const IssaLibraryScreen({super.key, this.initialQuery = '', this.library});
  @override
  State<IssaLibraryScreen> createState() => _IssaLibraryScreenState();
}

class _IssaLibraryScreenState extends State<IssaLibraryScreen> {
  late final TextEditingController _query;
  late Future<IssaLibrary> _library;
  String? _bookId;
  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery);
    _library = widget.library ?? IssaLibrary.load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ISSA learning library')),
    body: FutureBuilder<IssaLibrary>(
      future: _library,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('The textbook library could not load.'),
                TextButton(
                  onPressed: () => setState(() {
                    _library = widget.library ?? IssaLibrary.load();
                  }),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final library = snapshot.data;
        if (library == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = library.search(_query.text, bookId: _bookId, limit: 20);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Learn the why behind your plan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${library.books.length} textbooks · ${library.searchablePages} searchable pages · Available offline',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Search your supplied course material by topic. Results are source excerpts, not personalized advice. Page numbers refer to the PDF; diagrams and scanned text are not interpreted.',
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Search textbook topics',
                    hintText: 'For example: periodization, protein, motivation',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Search',
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => setState(() {}),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: '',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Course'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All six courses'),
                    ),
                    for (final book in library.books)
                      DropdownMenuItem(
                        value: book.id,
                        child: Text(
                          book.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _bookId = value == '' ? null : value),
                ),
                const SizedBox(height: 16),
                if (_query.text.trim().isEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final topic in [
                        'Periodization',
                        'Hypertrophy',
                        'Protein',
                        'Hydration',
                        'Motivation',
                        'Movement',
                        'Assessment',
                        'Recovery',
                      ])
                        ActionChip(
                          label: Text(topic),
                          onPressed: () => setState(() => _query.text = topic),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  for (final book in library.books)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.menu_book_outlined),
                        title: Text(book.title),
                        subtitle: Text('${book.pages.length} PDF pages'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => IssaReaderScreen(book: book),
                          ),
                        ),
                      ),
                    ),
                ] else if (results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No matching pages. Try one or two topic words, or select another course.',
                    ),
                  )
                else ...[
                  Text('Top ${results.length} matching pages'),
                  for (final result in results)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.citation,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(result.excerpt),
                            TextButton.icon(
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Read source page'),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => IssaReaderScreen(
                                    book: result.book,
                                    initialPage: result.page,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

class IssaReaderScreen extends StatefulWidget {
  final IssaBook book;
  final int initialPage;
  const IssaReaderScreen({super.key, required this.book, this.initialPage = 1});
  @override
  State<IssaReaderScreen> createState() => _IssaReaderScreenState();
}

class _IssaReaderScreenState extends State<IssaReaderScreen> {
  late int _page;
  late final TextEditingController _pageInput;
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(1, widget.book.pages.length);
    _pageInput = TextEditingController(text: '$_page');
  }

  void _go(int page) {
    setState(() {
      _page = page.clamp(1, widget.book.pages.length);
      _pageInput.text = '$_page';
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _pageInput.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.book.title)),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous page',
                onPressed: _page > 1 ? () => _go(_page - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _pageInput,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.go,
                  decoration: const InputDecoration(labelText: 'PDF page'),
                  onSubmitted: (value) => _go(int.tryParse(value) ?? _page),
                ),
              ),
              Text(' / ${widget.book.pages.length}'),
              IconButton(
                tooltip: 'Next page',
                onPressed: _page < widget.book.pages.length
                    ? () => _go(_page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SelectableText(
                  widget.book.pages[_page - 1].isEmpty
                      ? 'No extractable text on this page. Refer to the original PDF for illustrations or scanned content.'
                      : widget.book.pages[_page - 1],
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
