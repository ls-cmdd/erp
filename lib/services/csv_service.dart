import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CsvService {
  static CsvService get instance => _i;
  static final _i = CsvService._();
  CsvService._();

  /// Export list of maps to CSV, returns file path.
  Future<String> export(List<Map<String, dynamic>> data, String fileName) async {
    if (data.isEmpty) throw Exception('لا توجد بيانات للتصدير');

    final headers = data.first.keys.toList();
    final rows = <List<dynamic>>[headers];
    for (final row in data) {
      rows.add(headers.map((h) => row[h] ?? '').toList());
    }

    // Add BOM for Excel Arabic support
    const bom = '\uFEFF';
    final csvStr = bom + const ListToCsvConverter().convert(rows);

    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory(p.join(dir.path, 'ERP_Exports'));
    if (!exportsDir.existsSync()) exportsDir.createSync(recursive: true);

    final file = File(p.join(exportsDir.path,
        '${fileName}_${DateTime.now().millisecondsSinceEpoch}.csv'));
    await file.writeAsString(csvStr, encoding: const Utf8Codec(allowMalformed: true));
    return file.path;
  }

  /// Build display-friendly headers mapping for Arabic labels
  List<Map<String, dynamic>> mapHeaders(
      List<Map<String, dynamic>> data, Map<String, String> labels) {
    return data.map((row) {
      return {
        for (final e in labels.entries)
          if (row.containsKey(e.key)) e.value: row[e.key]
      };
    }).toList();
  }
}
