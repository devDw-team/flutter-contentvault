import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'core/database/app_database.dart';
import 'features/save/domain/services/pending_saves_repository.dart';

class TestPage extends ConsumerStatefulWidget {
  const TestPage({super.key});

  @override
  ConsumerState<TestPage> createState() => _TestPageState();
}

class _TestPageState extends ConsumerState<TestPage> {
  List<PendingSave> pendingSaves = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadPendingSaves();
  }

  Future<void> _loadPendingSaves() async {
    try {
      final database = GetIt.instance<AppDatabase>();
      final results = await database.select(database.pendingSavesTable).get();
      
      setState(() {
        pendingSaves = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Saves Debug'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text('Error: $error'))
              : pendingSaves.isEmpty
                  ? const Center(child: Text('No pending saves found'))
                  : ListView.builder(
                      itemCount: pendingSaves.length,
                      itemBuilder: (context, index) {
                        final save = pendingSaves[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${save.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('URL: ${save.url}'),
                                Text('Title: ${save.title ?? 'N/A'}'),
                                Text('Status: ${save.status}'),
                                Text('Platform: ${save.sourcePlatform}'),
                                Text('Created: ${save.createdAt}'),
                                Text('Processed: ${save.processedAt ?? 'Not processed'}'),
                                if (save.errorMessage != null)
                                  Text('Error: ${save.errorMessage}', style: const TextStyle(color: Colors.red)),
                                Text('Retry Count: ${save.retryCount}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPendingSaves,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}