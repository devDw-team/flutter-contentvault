import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../save/domain/services/pending_saves_repository.dart';
import '../save/presentation/share_extension_handler.dart';
import '../save/domain/services/background_save_processor.dart';

class DebugPage extends ConsumerStatefulWidget {
  const DebugPage({super.key});

  @override
  ConsumerState<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends ConsumerState<DebugPage> {
  String _sharedDataStatus = 'Checking...';
  String _pendingSavesStatus = 'Checking...';
  String _contentsStatus = 'Checking...';
  List<Map<String, dynamic>> _sharedData = [];
  List<Content> _recentContents = [];

  @override
  void initState() {
    super.initState();
    _checkData();
  }

  Future<void> _checkData() async {
    try {
      // Check UserDefaults
      const platform = MethodChannel('contentvault/userdefaults');
      final List<dynamic> sharedData = await platform.invokeMethod('getSharedData');
      
      setState(() {
        _sharedData = sharedData.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        _sharedDataStatus = 'Found ${sharedData.length} items in UserDefaults';
      });

      // Check database
      final database = GetIt.instance<AppDatabase>();
      final pendingSavesRepo = GetIt.instance<PendingSavesRepository>();
      
      // Count pending saves
      final pendingSaves = await pendingSavesRepo.getPendingSaves();
      setState(() {
        _pendingSavesStatus = 'Pending saves: ${pendingSaves.length}';
      });

      // Count contents and get recent ones
      final contents = await database.select(database.contentsTable).get();
      final recentContents = await (database.select(database.contentsTable)
        ..orderBy([(t) => drift.OrderingTerm(expression: t.createdAt, mode: drift.OrderingMode.desc)])
        ..limit(5))
        .get();
      
      setState(() {
        _contentsStatus = 'Contents: ${contents.length}';
        _recentContents = recentContents;
      });

    } catch (e) {
      setState(() {
        _sharedDataStatus = 'Error: $e';
      });
    }
  }

  Future<void> _clearSharedData() async {
    try {
      const platform = MethodChannel('contentvault/userdefaults');
      await platform.invokeMethod('clearSharedData');
      _checkData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing data: $e')),
      );
    }
  }

  Future<void> _processSharedData() async {
    try {
      setState(() {
        _sharedDataStatus = 'Processing...';
      });

      final shareHandler = GetIt.instance<ShareExtensionHandler>();
      await shareHandler.processInitialSharedData();
      
      await Future.delayed(const Duration(seconds: 2));
      _checkData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing completed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing: $e')),
      );
    }
  }

  Future<void> _runBackgroundProcessor() async {
    try {
      final processor = GetIt.instance<BackgroundSaveProcessor>();
      await processor.processQueue();
      
      await Future.delayed(const Duration(seconds: 1));
      _checkData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Background processing completed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error in background processing: $e')),
      );
    }
  }

  Future<void> _testDirectSave() async {
    try {
      final database = GetIt.instance<AppDatabase>();
      final uuid = const Uuid();
      final testId = uuid.v4();
      
      // Insert test content directly
      await database.into(database.contentsTable).insert(
        ContentsTableCompanion.insert(
          id: testId,
          title: 'Test Content ${DateTime.now()}',
          url: 'https://test.com/${DateTime.now().millisecondsSinceEpoch}',
          contentType: 'test',
          sourcePlatform: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test content saved directly')),
      );
      
      await Future.delayed(const Duration(seconds: 1));
      _checkData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Direct save error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkData,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UserDefaults Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_sharedDataStatus),
                  const SizedBox(height: 16),
                  if (_sharedData.isNotEmpty) ...[
                    const Text('Shared URLs:'),
                    const SizedBox(height: 8),
                    ..._sharedData.map((item) => Card(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('URL: ${item['path'] ?? 'N/A'}'),
                            Text('Type: ${item['type'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    )),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _processSharedData,
                          child: const Text('Process Shared Data'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _clearSharedData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                          child: const Text('Clear'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Database Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_pendingSavesStatus),
                  Text(_contentsStatus),
                  if (_recentContents.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Recent Contents:'),
                    const SizedBox(height: 8),
                    ..._recentContents.map((content) => Card(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              content.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Type: ${content.contentType} | Platform: ${content.sourcePlatform}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getPlatformColor(content.sourcePlatform),
                              ),
                            ),
                            Text(
                              content.url,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _runBackgroundProcessor,
                          child: const Text('Run Background'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _testDirectSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                          ),
                          child: const Text('Test Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      case 'threads':
        return Colors.black;
      case 'article':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF2196F3);
    }
  }
}