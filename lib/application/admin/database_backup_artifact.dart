import 'dart:io';

final class DatabaseBackupArtifact {
  const DatabaseBackupArtifact({required this.file, required this.directory});

  final File file;
  final Directory directory;

  Future<void> dispose() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
