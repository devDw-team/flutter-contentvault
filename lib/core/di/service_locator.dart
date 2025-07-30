import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../../features/save/presentation/share_extension_handler.dart';
import '../../features/save/domain/services/url_validator.dart';
import '../../features/save/domain/services/platform_parser_selector.dart';
import '../../features/save/domain/services/content_metadata_extractor.dart';
import '../../features/save/domain/services/background_save_processor.dart';
import '../../features/save/domain/services/pending_saves_repository.dart';
import '../../features/save/data/api_clients/youtube_api_client.dart';
import '../../features/save/data/parsers/youtube_parser.dart';
import '../../features/save/data/parsers/twitter_parser.dart';
import '../../features/save/data/parsers/web_parser.dart';
import '../../features/save/data/parsers/threads_parser.dart';
import '../../features/search/domain/services/search_engine.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  
  // Database
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);
  
  // Services
  getIt.registerLazySingleton<UrlValidator>(() => UrlValidator());
  getIt.registerLazySingleton<ContentMetadataExtractor>(() => ContentMetadataExtractor());
  getIt.registerLazySingleton<PendingSavesRepository>(() => PendingSavesRepository(database));
  
  // API Clients
  final youtubeApiKey = sharedPreferences.getString('youtube_api_key') ?? '';
  getIt.registerLazySingleton<YouTubeApiClient>(
    () => YouTubeApiClient(apiKey: youtubeApiKey),
  );
  
  // Parsers
  getIt.registerLazySingleton<YouTubeParser>(
    () => YouTubeParser(
      apiClient: getIt<YouTubeApiClient>(),
      metadataExtractor: getIt<ContentMetadataExtractor>(),
    ),
  );
  
  getIt.registerLazySingleton<TwitterParser>(
    () => TwitterParser(
      metadataExtractor: getIt<ContentMetadataExtractor>(),
    ),
  );
  
  getIt.registerLazySingleton<WebParser>(
    () => WebParser(),
  );
  
  getIt.registerLazySingleton<ThreadsParser>(
    () => ThreadsParser(
      metadataExtractor: getIt<ContentMetadataExtractor>(),
    ),
  );
  
  // Platform Parser Selector (depends on parsers)
  getIt.registerLazySingleton<PlatformParserSelector>(
    () => PlatformParserSelector(
      youtubeParser: getIt<YouTubeParser>(),
      twitterParser: getIt<TwitterParser>(),
      webParser: getIt<WebParser>(),
      threadsParser: getIt<ThreadsParser>(),
    ),
  );
  
  // Background Processor
  getIt.registerLazySingleton<BackgroundSaveProcessor>(
    () => BackgroundSaveProcessor(
      database: getIt<AppDatabase>(),
      metadataExtractor: getIt<ContentMetadataExtractor>(),
      platformSelector: getIt<PlatformParserSelector>(),
      pendingSavesRepository: getIt<PendingSavesRepository>(),
    ),
  );
  
  // Share Extension Handler
  getIt.registerLazySingleton<ShareExtensionHandler>(
    () => ShareExtensionHandler(
      database: getIt<AppDatabase>(),
      urlValidator: getIt<UrlValidator>(),
      platformSelector: getIt<PlatformParserSelector>(),
      pendingSavesRepository: getIt<PendingSavesRepository>(),
      backgroundQueueProcessor: getIt<BackgroundSaveProcessor>(),
    ),
  );
  
  // Search Engine
  getIt.registerLazySingleton<SearchEngine>(
    () => SearchEngine(database: getIt<AppDatabase>()),
  );
  
  // TODO: API clients, repositories 등 추가 등록
} 