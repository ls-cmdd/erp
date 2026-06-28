import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../db/database.dart';

class BackupService {
  static BackupService get instance => _i;
  static final _i = BackupService._();
  BackupService._();

  Future<String> createBackup() async {
    final dir     = await getApplicationDocumentsDirectory();
    final backDir = Directory(p.join(dir.path, 'ERP_Backups'));
    if (!backDir.existsSync()) backDir.createSync(recursive: true);

    final srcPath = AppDatabase.instance.dbPath;
    final dstPath = p.join(backDir.path,
        'erp_backup_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.db');

    await File(srcPath).copy(dstPath);
    return dstPath;
  }

  Future<void> restoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type           : FileType.any,
      allowMultiple  : false,
      dialogTitle    : 'اختر ملف النسخة الاحتياطية',
    );
    if (result == null || result.files.isEmpty) return;

    final srcPath = result.files.first.path!;
    if (!srcPath.endsWith('.db')) throw Exception('الملف غير صالح');

    await AppDatabase.instance.close();
    final dstPath = AppDatabase.instance.dbPath;
    await File(srcPath).copy(dstPath);
    await AppDatabase.instance.initialize();
  }

  Future<List<FileSystemEntity>> listBackups() async {
    final dir     = await getApplicationDocumentsDirectory();
    final backDir = Directory(p.join(dir.path, 'ERP_Backups'));
    if (!backDir.existsSync()) return [];
    return backDir
        .listSync()
        .where((f) => f.path.endsWith('.db'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
  }

  Future<void> exportData(String csvPath, String name) async {
    // open folder in file manager
    if (Platform.isWindows) {
      await Process.run('explorer.exe', ['/select,', csvPath]);
    } else if (Platform.isMacOS) {
      await Process.run('open', ['-R', csvPath]);
    } else {
      await Process.run('xdg-open', [p.dirname(csvPath)]);
    }
  }
}
