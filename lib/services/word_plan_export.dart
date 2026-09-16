import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'adaptive_plan_service.dart';

class WordPlanExport {
  static Uint8List create(AdaptivePlan plan, String type) {
    if (!['full', 'workout', 'nutrition'].contains(type)) {
      throw ArgumentError.value(type);
    }
    String escape(String s) => s
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
    const headings = [
      'Daily nutrition targets',
      'Weekly meal plan',
      'Weekly shopping list',
      'Weekly workout plan',
      'Weekly coaching review',
      'Source notes',
    ];
    final lines = plan.lines(type).expand((line) => line.split('\n')).toList();
    final paragraphs = List.generate(lines.length, (i) {
      final line = lines[i];
      final heading = i == 0 || headings.contains(line);
      final format = heading
          ? '<w:rPr><w:b/><w:color w:val="173B52"/><w:sz w:val="${i == 0 ? 36 : 28}"/></w:rPr>'
          : '<w:rPr><w:sz w:val="22"/></w:rPr>';
      return '<w:p><w:pPr><w:spacing w:after="140"/>${heading ? "<w:keepNext/>" : ""}</w:pPr><w:r>$format<w:t xml:space="preserve">${escape(line)}</w:t></w:r></w:p>';
    }).join();
    final archive = Archive();
    void add(String name, String value) {
      final bytes = utf8.encode(value);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    add(
      '[Content_Types].xml',
      '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>',
    );
    add(
      '_rels/.rels',
      '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>',
    );
    add(
      'word/document.xml',
      '<?xml version="1.0" encoding="UTF-8"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>$paragraphs<w:sectPr/></w:body></w:document>',
    );
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static Future<String> save(AdaptivePlan plan, String type) async {
    final name = 'activity_tracker_${type}_plan.docx';
    final file = XFile.fromData(
      create(plan, type),
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      name: name,
    );
    if (kIsWeb) {
      await file.saveTo(name);
      return 'Word document download started.';
    }
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$name';
    await file.saveTo(path);
    await OpenFile.open(path);
    return 'Word document saved: $path';
  }
}
