/// EduX Teacher App - Database Provider
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

part 'database_provider.g.dart';

/// Provider for AppDatabase instance
@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  return AppDatabase();
}
