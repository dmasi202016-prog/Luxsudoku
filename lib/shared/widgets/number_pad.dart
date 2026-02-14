import 'package:flutter/material.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.onNumberSelected,
    required this.onClear,
    this.highlightedNumber,
  });

  final ValueChanged<int> onNumberSelected;
  final VoidCallback onClear;
  final int? highlightedNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numbers = List.generate(9, (index) => index + 1);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final number in numbers)
          _NumberChip(
            number: number,
            isHighlighted: highlightedNumber == number,
            onTap: () => onNumberSelected(number),
          ),
        ActionChip(
          backgroundColor: theme.colorScheme.surface.withOpacity(0.8),
          avatar: const Icon(Icons.highlight_remove_rounded),
          label: const Text('Clear'),
          onPressed: onClear,
        ),
      ],
    );
  }
}

class _NumberChip extends StatelessWidget {
  const _NumberChip({
    required this.number,
    required this.onTap,
    required this.isHighlighted,
  });

  final int number;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isHighlighted
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                )
              : null,
          border: Border.all(
            color: isHighlighted
                ? Colors.transparent
                : theme.colorScheme.outlineVariant.withOpacity(0.4),
          ),
          color: isHighlighted
              ? null
              : theme.colorScheme.surface.withOpacity(0.8),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$number',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlighted
                ? Colors.white
                : theme.colorScheme.onSurface.withOpacity(0.9),
          ),
        ),
      ),
    );
  }
}
