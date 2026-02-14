import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../shared/models/difficulty.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../game/presentation/game_notifier.dart';
import '../../settings/presentation/settings_notifier.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  Difficulty _selectedDifficulty = Difficulty.veryEasy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsNotifierProvider);
      setState(() {
        _selectedDifficulty = settings.lastDifficulty;
      });
      // Pre-initialize audio on menu screen
      if (settings.soundEnabled) {
        AudioService.instance.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameNotifierProvider, (_, __) {
      if (mounted) {
        setState(() {});
      }
    });
    final savedGames = ref.read(gameNotifierProvider.notifier).savedGames();
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 64,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MenuHeader(
                  onSettings: () => GoRouter.of(context).push(RouteNames.settings),
                  onShop: () => GoRouter.of(context).push(RouteNames.shop),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Savor the silence.\nMaster the grid.',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Choose your vibe. Enter your flow',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Select Difficulty',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: difficultyOptions
                              .map<Widget>(
                                (difficulty) => _GoldChoiceChip(
                                  selected: _selectedDifficulty == difficulty,
                                  label: difficulty.label,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedDifficulty = difficulty;
                                    });
                                    ref
                                        .read(settingsNotifierProvider.notifier)
                                        .updateLastDifficulty(difficulty);
                                  },
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Start ${_selectedDifficulty.label} Game',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () {
                            // Start audio on user interaction (web autoplay policy) - non-blocking
                            final soundEnabled = ref.read(settingsNotifierProvider).soundEnabled;
                            if (soundEnabled) {
                              // Stop any finish sound and restart background music in background
                              AudioService.instance.stopFinishSound();
                              AudioService.instance.playBackground(enabled: true);
                            }
                            // Navigate immediately without waiting for audio
                            GoRouter.of(context).push(
                              '${RouteNames.game}?difficulty=${_selectedDifficulty.name}',
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'View Leaderboard',
                          icon: Icons.emoji_events_rounded,
                          onPressed: () => GoRouter.of(context)
                              .push(RouteNames.leaderboard),
                        ),
                        const SizedBox(height: 32),
                        if (savedGames.isNotEmpty) ...[
                          Text(
                            'Saved Sessions',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: savedGames
                                .map(
                                  (slot) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _SavedGameCard(
                                      slot: slot.slot,
                                      difficulty: slot.difficulty,
                                      elapsedSeconds: slot.elapsedSeconds,
                                      updatedAt: slot.updatedAt,
                                      onLoad: () {
                                        // Start audio on user interaction - non-blocking
                                        final soundEnabled = ref.read(settingsNotifierProvider).soundEnabled;
                                        if (soundEnabled) {
                                          // Stop any finish sound and restart background music in background
                                          AudioService.instance.stopFinishSound();
                                          AudioService.instance.playBackground(enabled: true);
                                        }
                                        // Navigate immediately without waiting for audio
                                        GoRouter.of(context).push(
                                          '${RouteNames.game}?slot=${slot.slot}',
                                        );
                                      },
                                      onDelete: () async {
                                        await ref.read(gameNotifierProvider.notifier).deleteSlot(slot.slot);
                                        if (mounted) {
                                          setState(() {});
                                        }
                                      },
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({
    required this.onSettings,
    required this.onShop,
  });

  final VoidCallback onSettings;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFE8C35A), // goldHighlight
              Color(0xFFD4AF37), // goldPrimary
              Color(0xFFA08428), // goldShadow
            ],
          ).createShader(bounds),
          child: const Icon(Icons.blur_on_rounded, size: 32, color: Colors.white),
        ),
        const SizedBox(width: 12),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFE8C35A), // goldHighlight
              Color(0xFFD4AF37), // goldPrimary
            ],
          ).createShader(bounds),
          child: Text(
            'Luxe Sudoku',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onShop,
          icon: const Icon(Icons.shopping_bag_rounded, color: Colors.amber),
          tooltip: 'Shop',
        ),
        IconButton(
          onPressed: onSettings,
          icon: const Icon(Icons.settings_rounded, color: Colors.white),
          tooltip: 'Settings',
        ),
      ],
    );
  }
}

class _SavedGameCard extends StatelessWidget {
  const _SavedGameCard({
    required this.slot,
    required this.difficulty,
    required this.elapsedSeconds,
    required this.updatedAt,
    required this.onLoad,
    required this.onDelete,
  });

  final int slot;
  final Difficulty difficulty;
  final int elapsedSeconds;
  final DateTime updatedAt;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final formattedTime = TimeFormatter.formatSeconds(elapsedSeconds);
    final daysSinceUpdate = DateTime.now().difference(updatedAt).inDays;
    final lastPlayedText = daysSinceUpdate == 0
        ? 'Today'
        : daysSinceUpdate == 1
            ? 'Yesterday'
            : '$daysSinceUpdate days ago';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.5),
            Colors.black.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: difficulty.accentColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onLoad,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Slot indicator with difficulty color
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: difficulty.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: difficulty.accentColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#$slot',
                          style: TextStyle(
                            color: difficulty.accentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Game info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: difficulty.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: difficulty.accentColor.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              difficulty.label,
                              style: TextStyle(
                                color: difficulty.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last played: $lastPlayedText',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Delete',
                    ),
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: difficulty.accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: onLoad,
                        icon: Icon(
                          Icons.play_arrow_rounded,
                          color: difficulty.accentColor,
                          size: 28,
                        ),
                        tooltip: 'Load Game',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 골드 테마 ChoiceChip with 빛 반사 효과
class _GoldChoiceChip extends StatelessWidget {
  const _GoldChoiceChip({
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final bool selected;
  final String label;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE8C35A), // goldHighlight
                    Color(0xFFD4AF37), // goldPrimary
                    Color(0xFFA08428), // goldShadow
                  ],
                  stops: [0.0, 0.5, 1.0],
                )
              : null,
          color: selected ? null : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: selected 
                ? const Color(0xFFE8C35A).withOpacity(0.5)
                : Colors.white.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFFE8C35A).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(-2, -2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFF0F0F0),
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            fontSize: 16,
            shadows: selected
                ? [
                    Shadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, -1),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
