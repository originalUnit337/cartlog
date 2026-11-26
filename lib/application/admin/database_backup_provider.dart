import 'package:cartlog/application/admin/database_backup_artifact.dart';

abstract interface class DatabaseBackupProvider {
  Future<DatabaseBackupArtifact> createBackup();
}
