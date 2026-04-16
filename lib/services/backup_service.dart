/// EduX School Management System
/// Backup Service - Database backup and restore functionality
library;

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';
import '../core/demo/demo_config.dart';
import '../database/database.dart';

/// Backup service for database backup and restore operations
class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  /// Factory constructor using singleton database
  factory BackupService.instance() => BackupService(AppDatabase.instance);

  // ============================================
  // DIRECTORY MANAGEMENT
  // ============================================

  /// Get the application data directory
  Future<Directory> _getAppDataDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final appDir = Directory(p.join(documentsDir.path, 'edux'));
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  /// Get the backup directory
  Future<Directory> getBackupDirectory() async {
    final appDir = await _getAppDataDirectory();
    final backupDir = Directory(p.join(appDir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Get the database file path
  Future<File> getDatabaseFile() async {
    final appDir = await _getAppDataDirectory();
    return File(p.join(appDir.path, DbConstants.dbFileName));
  }

  // ============================================
  // BACKUP CREATION
  // ============================================

  // ============================================
  // BACKUP CREATION
  // ============================================

  /// Create a backup of the database
  /// Returns the created backup metadata
  Future<Backup> createBackup({
    String? description,
    String type = 'manual',
  }) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    final backupDir = await getBackupDirectory();
    final dbFile = await getDatabaseFile();

    if (!await dbFile.exists()) {
      throw Exception('Database file not found');
    }

    // Generate backup filename with timestamp
    final timestamp = DateTime.now();
    final formattedTime = _formatTimestamp(timestamp);
    final fileName = 'edux_backup_$formattedTime.zip';
    final backupPath = p.join(backupDir.path, fileName);

    // Get current stats before backup
    final studentCount = await _getStudentCount();
    final staffCount = await _getStaffCount();

    // Close database connection temporarily
    // Note: In production, we'd use a copied file to avoid locking issues
    // For now, we read the database file directly
    final dbBytes = await dbFile.readAsBytes();

    // Create ZIP archive
    final archive = Archive();

    // Add database file to archive
    archive.addFile(
      ArchiveFile(DbConstants.dbFileName, dbBytes.length, dbBytes),
    );

    // Add metadata file to archive
    final metadata = {
      'version': AppConstants.appVersion,
      'dbVersion': DbConstants.dbVersion,
      'timestamp': timestamp.toIso8601String(),
      'studentCount': studentCount,
      'staffCount': staffCount,
      'description': description ?? '',
    };
    final metadataBytes = metadata.toString().codeUnits;
    archive.addFile(
      ArchiveFile('metadata.json', metadataBytes.length, metadataBytes),
    );

    // Encode archive
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to create backup archive');
    }

    // Write backup file
    final backupFile = File(backupPath);
    await backupFile.writeAsBytes(zipBytes);

    // Save backup metadata to database
    final backupId = await _db
        .into(_db.backups)
        .insert(
          BackupsCompanion.insert(
            fileName: fileName,
            filePath: backupPath,
            fileSize: zipBytes.length,
            type: type,
            description: Value(description),
            dbVersion: DbConstants.dbVersion,
            appVersion: AppConstants.appVersion,
            studentCount: studentCount,
            staffCount: staffCount,
          ),
        );

    final query = _db.select(_db.backups)..where((b) => b.id.equals(backupId));
    return await query.getSingle();
  }

  /// Format timestamp for filename
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}${_pad(timestamp.month)}${_pad(timestamp.day)}'
        '_${_pad(timestamp.hour)}${_pad(timestamp.minute)}${_pad(timestamp.second)}';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  // ============================================
  // BACKUP LISTING
  // ============================================

  /// Get all backups
  Future<List<Backup>> getBackups() async {
    final query = _db.select(_db.backups)
      ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]);
    return await query.get();
  }

  /// Get backup by ID
  Future<Backup?> getBackupById(int id) async {
    final query = _db.select(_db.backups)..where((b) => b.id.equals(id));
    return await query.getSingleOrNull();
  }

  /// Get most recent backup
  Future<Backup?> getMostRecentBackup() async {
    final query = _db.select(_db.backups)
      ..orderBy([(b) => OrderingTerm.desc(b.createdAt)])
      ..limit(1);
    return await query.getSingleOrNull();
  }

  /// Get backup count
  Future<int> getBackupCount() async {
    final backups = await _db.select(_db.backups).get();
    return backups.length;
  }

  // ============================================
  // BACKUP VALIDATION
  // ============================================

  /// Validate a backup file
  Future<BackupValidationResult> validateBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return BackupValidationResult(
          isValid: false,
          error: 'Backup file not found',
        );
      }

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Check for database file
      final dbFile = archive.files.where(
        (f) => f.name == DbConstants.dbFileName,
      );
      if (dbFile.isEmpty) {
        return BackupValidationResult(
          isValid: false,
          error: 'Backup does not contain database file',
        );
      }

      return BackupValidationResult(
        isValid: true,
        fileCount: archive.files.length,
        compressedSize: bytes.length,
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        error: 'Invalid backup file: ${e.toString()}',
      );
    }
  }

  // ============================================
  // BACKUP RESTORE
  // ============================================

  /// Restore from a backup
  /// Note: This will replace the current database!
  Future<void> restoreBackup(int backupId) async {
    if (DemoConfig.isDemo) throw DemoRestrictionException();
    final backup = await getBackupById(backupId);
    if (backup == null) {
      throw Exception('Backup not found');
    }

    await restoreFromFile(backup.filePath);
  }

  /// Restore from a backup file path
  Future<void> restoreFromFile(String filePath) async {
    // Validate backup first
    final validation = await validateBackup(filePath);
    if (!validation.isValid) {
      throw Exception(validation.error ?? 'Invalid backup');
    }

    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Find database file in archive
    final dbArchiveFile = archive.files.firstWhere(
      (f) => f.name == DbConstants.dbFileName,
    );

    // Get target database path
    final dbFile = await getDatabaseFile();

    // Close current database connection
    await _db.close();

    // Create backup of current database before restore
    final currentBackupPath = '${dbFile.path}.pre_restore';
    if (await dbFile.exists()) {
      await dbFile.copy(currentBackupPath);
    }

    try {
      // Write restored database
      await dbFile.writeAsBytes(dbArchiveFile.content as List<int>);

      // Note: The app will need to restart to use the restored database
      // because we can't reinitialize the singleton
    } catch (e) {
      // Restore from pre-restore backup if something went wrong
      final preRestoreFile = File(currentBackupPath);
      if (await preRestoreFile.exists()) {
        await preRestoreFile.copy(dbFile.path);
      }
      rethrow;
    } finally {
      // Clean up pre-restore backup
      final preRestoreFile = File(currentBackupPath);
      if (await preRestoreFile.exists()) {
        await preRestoreFile.delete();
      }
    }
  }

  // ============================================
  // EXPORT/IMPORT
  // ============================================

  /// Export backup to external location
  Future<File> exportBackup(int backupId, String destinationPath) async {
    final backup = await getBackupById(backupId);
    if (backup == null) {
      throw Exception('Backup not found');
    }

    final sourceFile = File(backup.filePath);
    if (!await sourceFile.exists()) {
      throw Exception('Backup file not found on disk');
    }

    final destFile = File(p.join(destinationPath, backup.fileName));
    return await sourceFile.copy(destFile.path);
  }

  /// Import backup from external location
  Future<Backup> importBackup(String sourcePath) async {
    // Validate the external backup
    final validation = await validateBackup(sourcePath);
    if (!validation.isValid) {
      throw Exception(validation.error ?? 'Invalid backup file');
    }

    final sourceFile = File(sourcePath);
    final backupDir = await getBackupDirectory();
    final fileName = p.basename(sourcePath);
    final destPath = p.join(backupDir.path, fileName);

    // Copy to backup directory
    final destFile = await sourceFile.copy(destPath);
    final fileSize = await destFile.length();

    // Add to backup metadata
    // Get stats from archive metadata if available
    final backupId = await _db
        .into(_db.backups)
        .insert(
          BackupsCompanion.insert(
            fileName: fileName,
            filePath: destPath,
            fileSize: fileSize,
            type: 'imported',
            description: const Value('Imported from external source'),
            dbVersion: DbConstants.dbVersion,
            appVersion: AppConstants.appVersion,
            studentCount: 0, // Unknown for imported backups
            staffCount: 0,
          ),
        );

    final query = _db.select(_db.backups)..where((b) => b.id.equals(backupId));
    return await query.getSingle();
  }

  // ============================================
  // BACKUP DELETION
  // ============================================

  /// Delete a backup
  Future<void> deleteBackup(int backupId) async {
    final backup = await getBackupById(backupId);
    if (backup == null) {
      throw Exception('Backup not found');
    }

    // Delete file from disk
    final file = File(backup.filePath);
    if (await file.exists()) {
      await file.delete();
    }

    // Delete metadata from database
    await (_db.delete(_db.backups)..where((b) => b.id.equals(backupId))).go();
  }

  /// Delete old backups (retention policy)
  Future<int> deleteOldBackups({int keepCount = 10}) async {
    final backups = await getBackups();
    if (backups.length <= keepCount) {
      return 0;
    }

    int deletedCount = 0;
    for (int i = keepCount; i < backups.length; i++) {
      await deleteBackup(backups[i].id);
      deletedCount++;
    }

    return deletedCount;
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  Future<int> _getStudentCount() async {
    final students = await (_db.select(
      _db.students,
    )..where((s) => s.status.equals('active'))).get();
    return students.length;
  }

  Future<int> _getStaffCount() async {
    final staff = await (_db.select(
      _db.staff,
    )..where((s) => s.status.equals('active'))).get();
    return staff.length;
  }
}

/// Result of backup validation
class BackupValidationResult {
  final bool isValid;
  final String? error;
  final int? fileCount;
  final int? compressedSize;

  BackupValidationResult({
    required this.isValid,
    this.error,
    this.fileCount,
    this.compressedSize,
  });
}

/// Extension for backup file size formatting
extension BackupExtension on Backup {
  /// Get formatted file size
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// Get type display name
  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'manual':
        return 'Manual';
      case 'auto':
        return 'Automatic';
      case 'imported':
        return 'Imported';
      default:
        return type;
    }
  }
}
