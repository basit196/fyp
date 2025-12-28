import 'package:flutter/material.dart';
import '../models/worker.dart';

class LevelBadge extends StatelessWidget {
  final WorkerLevel level;
  final bool showLabel;
  final double size;

  const LevelBadge({
    super.key,
    required this.level,
    this.showLabel = true,
    this.size = 12,
  });

  Color get levelColor {
    switch (level) {
      case WorkerLevel.newbie:
        return const Color(0xFF10B981); // Green
      case WorkerLevel.professional:
        return const Color(0xFFF59E0B); // Amber
      case WorkerLevel.expert:
        return const Color(0xFFEF4444); // Red/Purple
    }
  }

  String get levelName {
    switch (level) {
      case WorkerLevel.newbie:
        return 'Newbie';
      case WorkerLevel.professional:
        return 'Professional';
      case WorkerLevel.expert:
        return 'Expert';
    }
  }

  IconData get levelIcon {
    switch (level) {
      case WorkerLevel.newbie:
        return Icons.energy_savings_leaf;
      case WorkerLevel.professional:
        return Icons.star;
      case WorkerLevel.expert:
        return Icons.workspace_premium;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!showLabel) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: levelColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          levelIcon,
          size: size,
          color: levelColor,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: levelColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: levelColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            levelIcon,
            size: size,
            color: levelColor,
          ),
          const SizedBox(width: 4),
          Text(
            levelName,
            style: TextStyle(
              fontSize: size - 2,
              fontWeight: FontWeight.bold,
              color: levelColor,
            ),
          ),
        ],
      ),
    );
  }
}

