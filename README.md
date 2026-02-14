# Luxe Sudoku - Flutter Cross-Platform Game

A beautiful, cross-platform Sudoku game built with Flutter, featuring a glamorous interface and sophisticated gameplay.

## Features

- **Cross-platform**: Runs on Web, iOS, and Android
- **Three difficulty levels**: Easy, Medium, Hard
- **Smart gameplay**: Hint system, Undo/Redo, conflict detection
- **Save system**: Up to 5 save slots plus auto-save
- **Leaderboard**: Track your best times per difficulty
- **Responsive design**: Adapts to all screen sizes
- **Dark/Light themes**: System-aware theme support
- **Glamorous UI**: Beautiful gradients and elegant animations

## Tech Stack

- **Framework**: Flutter 3.24.x+
- **Language**: Dart 3.5.x+
- **State Management**: Riverpod 2.6.x
- **Routing**: go_router 14.6.x
- **Local Storage**: Hive 2.2.x + SharedPreferences 2.3.x
- **UI**: Material 3, Google Fonts

## Getting Started

### Prerequisites

- Flutter SDK 3.24.0 or higher
- Dart SDK 3.5.0 or higher

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd sudoku_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:

   **For Web:**
   ```bash
   flutter run -d chrome
   ```

   **For iOS:**
   ```bash
   flutter run -d ios
   ```

   **For Android:**
   ```bash
   flutter run -d android
   ```

### Building for Production

**Web:**
```bash
flutter build web --release
```
Output: `build/web/`

**iOS:**
```bash
flutter build ios --release
```

**Android APK:**
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**Android App Bundle:**
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

## Project Structure

```
lib/
├── main.dart               # App entry point
├── app.dart                # Root app widget
├── core/                   # Global utilities
│   ├── constants/          # App constants
│   ├── theme/              # Theme configuration
│   ├── utils/              # Helper utilities
│   ├── router/             # Navigation
│   └── providers/          # Global providers
├── shared/                 # Shared widgets & models
│   ├── widgets/            # Reusable widgets
│   └── models/             # Shared models
├── data/                   # Data layer
│   ├── models/             # Data models (Hive)
│   ├── repositories/       # Data repositories
│   └── services/           # Storage services
└── features/               # Feature modules
    ├── menu/               # Main menu
    ├── game/               # Game screen
    ├── settings/           # Settings
    └── leaderboard/        # Leaderboard
```

## How to Play

1. **Start a new game**: Select difficulty (Easy, Medium, Hard) from the main menu
2. **Fill the grid**: Tap a cell and select a number (1-9)
3. **Use hints**: Click the Hint button when stuck (limited per difficulty)
4. **Undo mistakes**: Use Undo/Redo buttons to backtrack
5. **Save progress**: Use the menu to save to one of 5 slots
6. **Complete the puzzle**: Fill all cells correctly to win!

## Game Rules

- Each row must contain numbers 1-9 without repetition
- Each column must contain numbers 1-9 without repetition
- Each 3×3 sub-grid must contain numbers 1-9 without repetition
- Conflicts are highlighted in red

## Testing

Run unit tests:
```bash
flutter test
```

Run specific test:
```bash
flutter test test/features/game/domain/sudoku_validator_test.dart
```

## Performance

- Puzzle generation: < 1 second
- App startup: < 3 seconds
- 60 FPS rendering on all platforms
- Optimized memory usage with Hive storage

## Browser Compatibility (Web)

- Chrome/Edge: Latest 2 versions ✅
- Firefox: Latest 2 versions ✅
- Safari: Latest 2 versions ✅

## Mobile Requirements

- **iOS**: iOS 12.0+
- **Android**: Android 8.0 (API 26)+

## License

This project is built for demonstration purposes.

## Credits

- Background images: Unsplash
- Icons: Material Icons
- Fonts: Google Fonts (Montserrat)
