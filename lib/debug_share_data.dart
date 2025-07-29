import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart' hide Column;
import 'core/di/service_locator.dart';
import 'core/database/app_database.dart';
import 'features/save/presentation/share_extension_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  
  runApp(const DebugShareDataApp());
}

class DebugShareDataApp extends StatelessWidget {
  const DebugShareDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debug Share Data',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DebugShareDataPage(),
    );
  }
}

class DebugShareDataPage extends StatefulWidget {
  const DebugShareDataPage({super.key});

  @override
  State<DebugShareDataPage> createState() => _DebugShareDataPageState();
}

class _DebugShareDataPageState extends State<DebugShareDataPage> {
  List<Map<String, dynamic>> userDefaultsData = [];
  List<PendingSave> pendingSaves = [];
  List<Content> recentContents = [];
  String status = 'Ready';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      status = 'Loading...';
    });

    // Check UserDefaults
    await _checkUserDefaults();
    
    // Check database
    await _checkDatabase();
    
    setState(() {
      status = 'Loaded';
    });
  }

  Future<void> _checkUserDefaults() async {
    try {
      const platform = MethodChannel('contentvault/userdefaults');
      final List<dynamic> sharedData = await platform.invokeMethod('getSharedData');
      
      setState(() {
        userDefaultsData = sharedData.map((item) => Map<String, dynamic>.from(item)).toList();
      });
    } catch (e) {
      print('Error checking UserDefaults: $e');
    }
  }

  Future<void> _checkDatabase() async {
    final database = GetIt.instance<AppDatabase>();
    
    // Get pending saves
    final pending = await database.select(database.pendingSavesTable).get();
    
    // Get recent contents
    final contents = await (database.select(database.contentsTable)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
      ..limit(10))
      .get();
    
    setState(() {
      pendingSaves = pending;
      recentContents = contents;
    });
  }

  Future<void> _clearUserDefaults() async {
    try {
      const platform = MethodChannel('contentvault/userdefaults');
      await platform.invokeMethod('clearSharedData');
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UserDefaults cleared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _processSharedData() async {
    try {
      setState(() {
        status = 'Processing shared data...';
      });
      
      // Get ShareExtensionHandler and reinitialize
      final shareHandler = GetIt.instance<ShareExtensionHandler>();
      shareHandler.initialize();
      
      // Wait a bit for processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Reload data
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processed shared data')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Share Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status and Process button
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Status: $status'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: userDefaultsData.isEmpty ? null : _processSharedData,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Process Shared Data'),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'UserDefaults (${userDefaultsData.length} items)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: userDefaultsData.isEmpty ? null : _clearUserDefaults,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (userDefaultsData.isEmpty)
                    const Text('No data in UserDefaults')
                  else
                    ...userDefaultsData.map((item) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('URL: ${item['path'] ?? 'N/A'}'),
                          Text('Type: ${item['type'] ?? 'N/A'}'),
                        ],
                      ),
                    )),
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
                    'Pending Saves (${pendingSaves.length} items)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (pendingSaves.isEmpty)
                    const Text('No pending saves')
                  else
                    ...pendingSaves.map((save) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('URL: ${save.url}'),
                          Text('Status: ${save.status}'),
                          Text('Created: ${save.createdAt}'),
                        ],
                      ),
                    )),
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
                    'Recent Contents (${recentContents.length} items)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (recentContents.isEmpty)
                    const Text('No contents saved')
                  else
                    ...recentContents.map((content) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Title: ${content.title}'),
                          Text('URL: ${content.url}'),
                          Text('Platform: ${content.sourcePlatform}'),
                          Text('Created: ${content.createdAt}'),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}