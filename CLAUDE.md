# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ContentVault is a multi-platform content archive Flutter app for saving, organizing, and searching content from YouTube, X/Twitter, and web articles with AI-powered organization.

## Key Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run code generation (required after modifying database tables or generated files)
flutter packages pub run build_runner build

# Run the app
flutter run

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Build for production
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
```

## Architecture

### State Management
- Uses **Riverpod 2.0** with riverpod_annotation for code generation
- Providers are organized by feature in `lib/features/*/providers/`
- Follow AsyncValue pattern for async operations

### Database
- **Drift** (SQLite) for local storage
- Database definition: `lib/core/database/app_database.dart`
- Tables in `lib/core/database/tables/`
- Run `flutter packages pub run build_runner build` after modifying tables

### Navigation
- **go_router** for declarative routing
- Routes defined in `lib/core/router/app_router.dart`
- Uses ShellRoute for persistent bottom navigation

### Dependency Injection
- **get_it** for service locator pattern
- Setup in `lib/core/di/service_locator.dart`
- Register singletons for database, SharedPreferences, API clients

### Project Structure
```
lib/
├── core/           # Core functionality (database, DI, routing, theme)
├── features/       # Feature modules (home, save, search, library, ai, settings)
├── shared/         # Shared widgets and utilities
└── main.dart       # App entry point
```

Each feature follows this structure:
- `data/` - Repository implementations
- `domain/` - Entities and repository interfaces
- `presentation/` - UI pages and widgets
- `providers/` - Riverpod providers

## Key Development Patterns

### Error Handling
- Use custom exceptions (AppException)
- Handle errors with AsyncValue in providers
- Show user-friendly error messages in UI

### Widget Development
- Prefer const constructors
- Use composition over inheritance
- Extract complex widgets into separate files
- Follow Material 3 design guidelines

### Testing
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for full features
- Aim for 80% code coverage

## Important Notes

1. **Code Generation**: Always run `flutter packages pub run build_runner build` after modifying:
   - Drift database tables
   - Riverpod providers with annotations
   - JSON serializable models

2. **Imports**: Check existing imports before adding new packages - the project uses specific versions

3. **Styling**: Follow existing patterns in the codebase, especially for theme usage and widget composition

4. **Git Commits**: Use conventional commits (feat:, fix:, docs:, etc.)

For detailed coding conventions and rules, refer to `.cursor/rules/contentvault.mdc`.