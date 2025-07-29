import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../models/pending_save_model.dart';

class PendingSavesRepository {
  final AppDatabase _database;
  
  PendingSavesRepository(this._database);
  
  Future<void> insert(PendingSaveModel save) async {
    await _database.into(_database.pendingSavesTable).insert(
      PendingSavesTableCompanion(
        id: Value(save.id),
        url: Value(save.url),
        title: Value(save.title),
        savedText: Value(save.text),
        images: Value(save.images),
        sourcePlatform: Value(save.sourcePlatform),
        status: Value(save.status),
        errorMessage: Value(save.errorMessage),
        retryCount: Value(save.retryCount),
        createdAt: Value(save.createdAt),
        processedAt: Value(save.processedAt),
      ),
    );
  }

  Future<void> update(String id, PendingSaveModel save) async {
    await (_database.update(_database.pendingSavesTable)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      PendingSavesTableCompanion(
        url: Value(save.url),
        title: Value(save.title),
        savedText: Value(save.text),
        images: Value(save.images),
        sourcePlatform: Value(save.sourcePlatform),
        status: Value(save.status),
        errorMessage: Value(save.errorMessage),
        retryCount: Value(save.retryCount),
        processedAt: Value(save.processedAt),
      ),
    );
  }

  Future<List<PendingSaveModel>> getPendingSaves({int limit = 5}) async {
    final query = _database.select(_database.pendingSavesTable)
      ..where((tbl) => tbl.status.equals('pending'))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)])
      ..limit(limit);
    
    final results = await query.get();
    
    return results.map((row) => PendingSaveModel(
      id: row.id,
      url: row.url,
      title: row.title,
      text: row.savedText,
      images: row.images,
      sourcePlatform: row.sourcePlatform,
      status: row.status,
      errorMessage: row.errorMessage,
      retryCount: row.retryCount,
      createdAt: row.createdAt,
      processedAt: row.processedAt,
    )).toList();
  }

  Future<PendingSaveModel?> getById(String id) async {
    final query = _database.select(_database.pendingSavesTable)
      ..where((tbl) => tbl.id.equals(id));
    
    final result = await query.getSingleOrNull();
    
    if (result == null) return null;
    
    return PendingSaveModel(
      id: result.id,
      url: result.url,
      title: result.title,
      text: result.savedText,
      images: result.images,
      sourcePlatform: result.sourcePlatform,
      status: result.status,
      errorMessage: result.errorMessage,
      retryCount: result.retryCount,
      createdAt: result.createdAt,
      processedAt: result.processedAt,
    );
  }

  Future<void> delete(String id) async {
    await (_database.delete(_database.pendingSavesTable)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<void> cleanupOldCompleted(DateTime cutoffDate) async {
    await (_database.delete(_database.pendingSavesTable)
          ..where((tbl) => 
            tbl.status.equals('completed') & 
            tbl.processedAt.isSmallerThanValue(cutoffDate)))
        .go();
  }
  
  Future<List<PendingSaveModel>> getAllPendingSaves() async {
    final results = await _database.select(_database.pendingSavesTable).get();
    
    return results.map((row) => PendingSaveModel(
      id: row.id,
      url: row.url,
      title: row.title,
      text: row.savedText,
      images: row.images,
      sourcePlatform: row.sourcePlatform,
      status: row.status,
      errorMessage: row.errorMessage,
      retryCount: row.retryCount,
      createdAt: row.createdAt,
      processedAt: row.processedAt,
    )).toList();
  }
}