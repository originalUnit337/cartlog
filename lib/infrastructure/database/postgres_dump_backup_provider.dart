import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cartlog/application/admin/database_backup_artifact.dart';
import 'package:cartlog/application/admin/database_backup_provider.dart';
import 'package:cartlog/infrastructure/database/database_config.dart';

final class PostgresDumpBackupProvider implements DatabaseBackupProvider {
  PostgresDumpBackupProvider({
    required this.config,
    this.executable = 'pg_dump',
  });

  final DatabaseConfig config;
  final String executable;

  @override
  Future<DatabaseBackupArtifact> createBackup() async {
    final directory = await Directory.systemTemp.createTemp(
      'cartlog-database-backup-',
    );
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      ':',
      '-',
    );
    final suffix = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    final file = File('${directory.path}/cartlog-$timestamp-$suffix.dump');

    try {
      await _restrictPermissions(directory.path, '700');
      final process = await Process.start(
        executable,
        [
          '--format=custom',
          '--no-owner',
          '--no-privileges',
          '--host=${config.host}',
          '--port=${config.port}',
          '--username=${config.username}',
          '--dbname=${config.database}',
          '--file=${file.path}',
        ],
        environment: {
          ...Platform.environment,
          'PGPASSWORD': config.password,
          'PGSSLMODE': _sslModeName,
        },
      );

      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      await process.stdout.drain<void>();
      final exitCode = await process.exitCode;
      final stderr = (await stderrFuture).trim();

      if (exitCode != 0) {
        throw ProcessException(
          executable,
          const [],
          stderr.isEmpty ? 'pg_dump exited with code $exitCode.' : stderr,
          exitCode,
        );
      }
      if (!await file.exists() || await file.length() == 0) {
        throw StateError('pg_dump completed without producing a backup file.');
      }
      await _restrictPermissions(file.path, '600');

      return DatabaseBackupArtifact(file: file, directory: directory);
    } catch (_) {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
      rethrow;
    }
  }

  String get _sslModeName => switch (config.sslMode) {
    .disable => 'disable',
    .require => 'require',
    .verifyFull => 'verify-full',
  };

  Future<void> _restrictPermissions(String path, String mode) async {
    if (Platform.isWindows) return;
    final result = await Process.run('chmod', [mode, path]);
    if (result.exitCode != 0) {
      throw ProcessException('chmod', [mode, path], result.stderr.toString());
    }
  }
}
