import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/monetization_constants.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/monetization_providers.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../data/models/game_state.dart';
import '../../../shared/models/difficulty.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../../../shared/widgets/number_pad.dart';
import '../../settings/presentation/settings_notifier.dart';
import 'game_notifier.dart';
import 'widgets/hint_effect_type.dart';
import 'widgets/sudoku_board.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    super.key,
    this.difficultyName,
    this.savedSlot,
  });

  final String? difficultyName;
  final int? savedSlot;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _initialized = false;
  late final FocusNode _focusNode;

  // --- Hint animation state ---
  int? _hintAnimatingRow;
  int? _hintAnimatingCol;
  HintEffectType? _hintEffectType;
  int _hintAnimationKey = 0;
  int? _pendingHintValue;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final notifier = ref.read(gameNotifierProvider.notifier);
    final settings = ref.read(settingsNotifierProvider);
    Difficulty difficulty = settings.lastDifficulty;
    if (widget.difficultyName != null) {
      difficulty = Difficulty.fromName(widget.difficultyName!);
    }

    if (widget.savedSlot == null && widget.difficultyName == null) {
      final resumed = await notifier.resumeAutosave();
      if (resumed) {
        if (mounted) {
          setState(() => _initialized = true);
        }
        return;
      }
    }

    if (widget.savedSlot != null) {
      final loaded = await notifier.loadSlot(widget.savedSlot!);
      if (!loaded) {
        await notifier.startNewGame(difficulty);
      }
    } else {
      await notifier.startNewGame(difficulty);
    }

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  Future<void> _handleHintRequest(
    BuildContext context,
    GameNotifier notifier,
  ) async {
    final gameState = ref.read(gameNotifierProvider);

    // Pre-check: is the hint valid?
    if (!gameState.hasSelection || gameState.isCompleted) return;
    if (gameState.fixedCells[gameState.selectedRow!][gameState.selectedCol!]) {
      return;
    }

    // Remember the cell position BEFORE reserving the hint.
    final targetRow = gameState.selectedRow!;
    final targetCol = gameState.selectedCol!;

    // Reserve the hint: increment counter only, get the correct value.
    // The number is NOT placed yet — it will appear after the animation.
    final correctValue = await notifier.reserveHint();
    if (correctValue == null && context.mounted) {
      _showGetHintsDialog(context);
      return;
    }

    // Trigger the hint effect animation on the target cell.
    if (mounted) {
      setState(() {
        _hintAnimatingRow = targetRow;
        _hintAnimatingCol = targetCol;
        _hintEffectType = HintEffectType.random();
        _hintAnimationKey++;
        _pendingHintValue = correctValue;
      });
    }
  }

  void _onHintAnimationComplete() {
    if (!mounted) return;

    // Place the number AFTER the animation finishes.
    if (_hintAnimatingRow != null &&
        _hintAnimatingCol != null &&
        _pendingHintValue != null) {
      ref.read(gameNotifierProvider.notifier).placeHintValue(
            _hintAnimatingRow!,
            _hintAnimatingCol!,
            _pendingHintValue!,
          );
    }

    setState(() {
      _hintAnimatingRow = null;
      _hintAnimatingCol = null;
      _hintEffectType = null;
      _pendingHintValue = null;
    });
  }

  Future<void> _showGetHintsDialog(BuildContext context) async {
    if (kIsWeb) {
      // Web version - only show shop option
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1410),
          title: const Text('No Hints Available', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Get more hints by purchasing hint packs or upgrading to Premium (unlimited hints).',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFD4AF37))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                GoRouter.of(context).push(RouteNames.shop);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
              ),
              child: const Text('Go to Shop'),
            ),
          ],
        ),
      );
      return;
    }

      // Mobile version - show ad option or shop option
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1410),
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFE8C35A), Color(0xFFD4AF37)],
            ).createShader(bounds),
            child: const Text(
              'Need More Hints?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose an option to get more hints:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              _HintOptionTile(
                icon: Icons.play_circle_filled,
                title: 'Watch Ad (Free)',
                subtitle: 'Get ${MonetizationConstants.hintsPerRewardedAd} hint',
                color: const Color(0xFF4CAF50),
                onTap: () => Navigator.of(context).pop('ad'),
              ),
              const SizedBox(height: 8),
              _HintOptionTile(
                icon: Icons.shopping_bag,
                title: 'Go to Shop',
                subtitle: 'Buy hint packs or Premium',
                color: const Color(0xFFD4AF37),
                onTap: () => Navigator.of(context).pop('shop'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFD4AF37))),
            ),
          ],
        ),
      );

    if (!mounted) return;

    if (choice == 'ad') {
      // Watch ad for hint
      await _watchAdForHint(context);
    } else if (choice == 'shop') {
      // Go to shop
      if (mounted) {
        GoRouter.of(context).push(RouteNames.shop);
      }
    }
  }

  Future<void> _watchAdForHint(BuildContext context) async {
    // Load ad if not ready
    if (!AdService.instance.isRewardedAdReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading ad... Please try again in a moment.'),
          ),
        );
      }
      await AdService.instance.loadRewardedAd();
      return;
    }

    // Show rewarded ad
    final rewarded = await AdService.instance.showRewardedAd();
    
    if (rewarded && mounted) {
      // Add hint to global balance
      await ref.read(hintBalanceProvider.notifier).addHintsFromAd(
            MonetizationConstants.hintsPerRewardedAd,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎁 ${MonetizationConstants.hintsPerRewardedAd} hint added! Try using hint again.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final notifier = ref.read(gameNotifierProvider.notifier);
    final gameState = ref.read(gameNotifierProvider);

    // Block input when paused (except arrow keys for navigation)
    final bool allowInput = !gameState.isPaused;

    // Arrow keys for navigation (always allowed)
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (gameState.selectedRow != null && gameState.selectedRow! > 0) {
        notifier.selectCell(
            gameState.selectedRow! - 1, gameState.selectedCol ?? 0);
      } else if (gameState.selectedRow == null) {
        notifier.selectCell(8, gameState.selectedCol ?? 0);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (gameState.selectedRow != null && gameState.selectedRow! < 8) {
        notifier.selectCell(
            gameState.selectedRow! + 1, gameState.selectedCol ?? 0);
      } else if (gameState.selectedRow == null) {
        notifier.selectCell(0, gameState.selectedCol ?? 0);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (gameState.selectedCol != null && gameState.selectedCol! > 0) {
        notifier.selectCell(
            gameState.selectedRow ?? 0, gameState.selectedCol! - 1);
      } else if (gameState.selectedCol == null) {
        notifier.selectCell(gameState.selectedRow ?? 0, 8);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (gameState.selectedCol != null && gameState.selectedCol! < 8) {
        notifier.selectCell(
            gameState.selectedRow ?? 0, gameState.selectedCol! + 1);
      } else if (gameState.selectedCol == null) {
        notifier.selectCell(gameState.selectedRow ?? 0, 0);
      }
    }
    // Number keys 1-9 (only when not paused)
    else if (allowInput &&
        (event.logicalKey == LogicalKeyboardKey.digit1 ||
            event.logicalKey == LogicalKeyboardKey.numpad1)) {
      notifier.enterNumber(1);
    } else if (allowInput &&
        (event.logicalKey == LogicalKeyboardKey.digit2 ||
            event.logicalKey == LogicalKeyboardKey.numpad2)) {
      notifier.enterNumber(2);
    } else if (allowInput &&
        (event.logicalKey == LogicalKeyboardKey.digit3 ||
            event.logicalKey == LogicalKeyboardKey.numpad3)) {
      notifier.enterNumber(3);
    } else if (allowInput &&
        (event.logicalKey == LogicalKeyboardKey.digit4 ||
            event.logicalKey == LogicalKeyboardKey.numpad4)) {
      notifier.enterNumber(4);
    } else if (allowInput &&
        (event.logicalKey == LogicalKeyboardKey.digit5 ||
            event.logicalKey == LogicalKeyboardKey.numpad5)) {
      notifier.enterNumber(5);
    } else if (allowInput &&
        (event.logicalKey == LogicalKeyboardKey.digit6 ||
            event.logicalKey == LogicalKeyboardKey.numpad6)) {
      notifier.enterNumber(6);
    } else if (allowInput &&
        (event.logicalKey == LogicalKeyboardKey.digit7 ||
            event.logicalKey == LogicalKeyboardKey.numpad7)) {
      notifier.enterNumber(7);
    } else if (allowInput &&
        (event.logicalKey == LogicalKeyboardKey.digit8 ||
            event.logicalKey == LogicalKeyboardKey.numpad8)) {
      notifier.enterNumber(8);
    } else if (allowInput &&
        (event.logicalKey == LogicalKeyboardKey.digit9 ||
            event.logicalKey == LogicalKeyboardKey.numpad9)) {
      notifier.enterNumber(9);
    } else if (allowInput &&
        (event.logicalKey == LogicalKeyboardKey.backspace ||
            event.logicalKey == LogicalKeyboardKey.delete ||
            event.logicalKey == LogicalKeyboardKey.digit0 ||
            event.logicalKey == LogicalKeyboardKey.numpad0)) {
      // Clear cell on Backspace, Delete, or 0
      notifier.clearCell();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameNotifierProvider);
    final notifier = ref.read(gameNotifierProvider.notifier);
    final media = MediaQuery.of(context);
    final isPremium = ref.watch(premiumStatusProvider).isPremium;

    // Listen for game completion
    ref.listen<GameState>(gameNotifierProvider, (previous, next) {
      if ((previous == null || !previous.isCompleted) && next.isCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            _showCompletionDialog(context, notifier, next);
          }
        });
      }
    });

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: SafeArea(
            child: !_initialized
                ? const Center(
                    child: CircularProgressIndicator.adaptive(),
                  )
                : Column(
                    children: [
                      _GameHeader(
                        difficulty: gameState.difficulty,
                        elapsed: gameState.elapsedSeconds,
                        hintsUsed: gameState.hintsUsed,
                        onBack: () => Navigator.of(context).pop(),
                        onMenu: () =>
                            _showGameMenu(context, notifier, gameState),
                        isPaused: gameState.isPaused,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: media.size.width < 500 ? 16 : 32,
                            vertical: 16,
                          ),
                          child: Column(
                            children: [
                              SudokuBoard(
                                state: gameState,
                                onCellTap: notifier.selectCell,
                                hintAnimatingRow: _hintAnimatingRow,
                                hintAnimatingCol: _hintAnimatingCol,
                                hintEffectType: _hintEffectType,
                                hintAnimationKey: _hintAnimationKey,
                                onHintAnimationComplete:
                                    _onHintAnimationComplete,
                              ),
                              const SizedBox(height: 24),
                              _ActionBar(
                                onNote: notifier.toggleNoteMode,
                                onHint: () =>
                                    _handleHintRequest(context, notifier),
                                onClear: notifier.clearCell,
                                onPause: notifier.togglePause,
                                isNoteMode: gameState.isNoteMode,
                                isPaused: gameState.isPaused,
                                onRestart: () =>
                                    notifier.startNewGame(gameState.difficulty),
                              ),
                              const SizedBox(height: 16),
                              NumberPad(
                                highlightedNumber: gameState.hasSelection
                                    ? gameState.board[gameState.selectedRow!]
                                        [gameState.selectedCol!]
                                    : null,
                                onNumberSelected: notifier.enterNumber,
                                onClear: notifier.clearCell,
                              ),
                              const SizedBox(height: 24),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                child: gameState.isCompleted
                                    ? _CompletionBanner(
                                        elapsed: gameState.elapsedSeconds,
                                        onContinue: () => notifier.startNewGame(
                                          gameState.difficulty,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Banner ad (only for free users and not on web)
                      if (!isPremium && !kIsWeb) ...[
                        const Divider(height: 1),
                        const BannerAdWidget(),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCompletionDialog(
    BuildContext context,
    GameNotifier notifier,
    GameState gameState,
  ) async {
    final nameController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('🎉 Congratulations!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Time: ${TimeFormatter.formatSeconds(gameState.elapsedSeconds)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'Enter your name for leaderboard',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () async {
                await notifier.saveToLeaderboard(nameController.text.trim());
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
  }

  Future<void> _showGameMenu(
    BuildContext context,
    GameNotifier notifier,
    GameState currentState,
  ) async {
    final summaries = notifier.savedGames();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1410),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1A1410),
                Color(0xFF0A0A08),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFE8C35A),
                      Color(0xFFD4AF37),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Game Menu',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var slot = 1; slot <= AppConstants.maxSaveSlots; slot++)
                      _GoldMenuButton(
                        label: 'Save Slot $slot',
                        onPressed: () async {
                          await notifier.saveToSlot(slot);
                          if (context.mounted) Navigator.pop(context);
                        },
                        isFilled: true,
                      ),
                    for (final entry in summaries)
                      _GoldMenuButton(
                        label: 'Load Slot ${entry.slot} • ${entry.difficulty.label}',
                        onPressed: () async {
                          await notifier.loadSlot(entry.slot);
                          if (context.mounted) Navigator.pop(context);
                        },
                        isFilled: false,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.emoji_events, color: Color(0xFFD4AF37)),
                  title: const Text('Leaderboard', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(RouteNames.leaderboard);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag, color: Color(0xFFD4AF37)),
                  title: const Text('Shop', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(RouteNames.shop);
                  },
                ),
                Divider(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await notifier.startNewGame(
                        currentState.difficulty,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFD4AF37),
                    ),
                    child: const Text(
                      'Restart Current Game',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GameHeader extends ConsumerWidget {
  const _GameHeader({
    required this.difficulty,
    required this.elapsed,
    required this.hintsUsed,
    required this.onBack,
    required this.onMenu,
    required this.isPaused,
  });

  final Difficulty difficulty;
  final int elapsed;
  final int hintsUsed;
  final VoidCallback onBack;
  final VoidCallback onMenu;
  final bool isPaused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(premiumStatusProvider).isPremium;
    final hintBalance = ref.watch(hintBalanceProvider);
    final availableHints = isPremium ? '∞' : '${hintBalance.currentHints}';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded),
            color: Colors.white,
            tooltip: 'Back to Menu',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  difficulty.label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: difficulty.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPaused ? 'Paused' : TimeFormatter.formatSeconds(elapsed),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                'Hints',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              Text(
                availableHints,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.more_vert_rounded),
            color: Colors.white,
            tooltip: 'Menu',
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({
    required this.onNote,
    required this.onHint,
    required this.onClear,
    required this.onPause,
    required this.isNoteMode,
    required this.isPaused,
    required this.onRestart,
  });

  final VoidCallback onNote;
  final VoidCallback onHint;
  final VoidCallback onClear;
  final VoidCallback onPause;
  final VoidCallback onRestart;
  final bool isNoteMode;
  final bool isPaused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumStatusProvider).isPremium;
    final hintBalance = ref.watch(hintBalanceProvider);
    final remainingHints = isPremium ? 999 : hintBalance.currentHints;
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _ActionChip(
          label: isNoteMode ? 'Note ON' : 'Note',
          icon: Icons.edit_note_rounded,
          enabled: true,
          onPressed: onNote,
          highlighted: isNoteMode,
        ),
        _ActionChip(
          label: isPremium ? 'Hint (∞)' : 'Hint ($remainingHints)',
          icon: Icons.insights_rounded,
          enabled: true, // Always enabled - will show dialog if no hints
          onPressed: onHint,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'pause':
                onPause();
                break;
              case 'clear':
                onClear();
                break;
              case 'restart':
                onRestart();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'pause',
              child: Row(
                children: [
                  Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause),
                  const SizedBox(width: 12),
                  Text(isPaused ? 'Resume' : 'Pause'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.clear_all_rounded),
                  SizedBox(width: 12),
                  Text('Clear'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'restart',
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded),
                  SizedBox(width: 12),
                  Text('Restart'),
                ],
              ),
            ),
          ],
          child: Chip(
            avatar: const Icon(Icons.more_horiz_rounded, size: 18),
            label: const Text('More...'),
            backgroundColor:
                Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool highlighted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        icon,
        color: enabled
            ? Theme.of(context).colorScheme.onSecondary
            : Theme.of(context).disabledColor,
      ),
      label: Text(label),
      onPressed: enabled ? onPressed : null,
      backgroundColor: highlighted
          ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
          : Theme.of(context).colorScheme.secondary.withOpacity(
                enabled ? 0.8 : 0.2,
              ),
      disabledColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner({
    required this.elapsed,
    required this.onContinue,
  });

  final int elapsed;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'All Done!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completion time: ${TimeFormatter.formatSeconds(elapsed)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('New Puzzle'),
          ),
        ],
      ),
    );
  }
}

class _GoldMenuButton extends StatelessWidget {
  const _GoldMenuButton({
    required this.label,
    required this.onPressed,
    required this.isFilled,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    if (isFilled) {
      // Filled gold gradient button (for Save)
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE8C35A), // goldHighlight
                Color(0xFFD4AF37), // goldPrimary
                Color(0xFFA08428), // goldShadow
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Outlined gold button (for Load)
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.transparent,
            border: Border.all(
              color: const Color(0xFFD4AF37),
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
  }
}

class _HintOptionTile extends StatelessWidget {
  const _HintOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

