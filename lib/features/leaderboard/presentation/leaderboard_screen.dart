import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../data/models/leaderboard_entry.dart';
import '../../../data/repositories/leaderboard_repository.dart';
import '../../../shared/models/difficulty.dart';
import '../../../shared/widgets/app_background.dart';
import '../../game/presentation/game_notifier.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  final Map<Difficulty, List<LeaderboardEntry>> _entries = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: difficultyOptions.length, vsync: this);
    _controller.addListener(() {
      if (_controller.indexIsChanging) return;
      _loadEntries(difficultyOptions[_controller.index]);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntries(_currentDifficulty);
    });
  }

  Difficulty get _currentDifficulty => difficultyOptions[_controller.index];

  Future<void> _loadEntries(Difficulty difficulty) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final repository = ref.read(leaderboardRepositoryProvider);
    final data = repository.fetch(difficulty);
    if (!mounted) return;
    setState(() {
      _entries[difficulty] = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameNotifierProvider, (previous, next) {
      final wasCompleted = previous?.isCompleted ?? false;
      if (!wasCompleted && next.isCompleted && mounted) {
        _loadEntries(_currentDifficulty);
      }
    });
    ref.watch(gameNotifierProvider); // rebuild when games finish

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                    ),
                    Text(
                      'Leaderboard',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        await ref
                            .read(leaderboardRepositoryProvider)
                            .clear(_currentDifficulty);
                        if (mounted) {
                          _loadEntries(_currentDifficulty);
                        }
                      },
                      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _controller,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: [
                    for (final difficulty in difficultyOptions)
                      Tab(text: difficulty.label),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _LeaderboardList(
                          entries: _entries[_currentDifficulty] ?? const [],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No records yet. Finish a puzzle to claim a spot.',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          tileColor: Colors.black.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.white24,
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            entry.playerName,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            entry.timestamp.toLocal().toIso8601String(),
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: Text(
            TimeFormatter.formatSeconds(entry.seconds),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
