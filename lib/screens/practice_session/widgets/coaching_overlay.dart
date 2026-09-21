import 'package:flutter/material.dart';
import 'package:interprep/common/constants/styles.dart';

class CoachingOverlay extends StatefulWidget {
  final List<String> warnings;
  final List<String> suggestions;
  final double confidenceScore;
  final bool isVisible;

  const CoachingOverlay({
    super.key,
    required this.warnings,
    required this.suggestions,
    required this.confidenceScore,
    this.isVisible = true,
  });

  @override
  State<CoachingOverlay> createState() => _CoachingOverlayState();
}

class _CoachingOverlayState extends State<CoachingOverlay> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Styles.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Styles.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Coaching',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  _buildConfidenceIndicator(),
                ],
              ),
            ),
            // Warnings
            if (widget.warnings.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Warnings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...widget.warnings.map((warning) => Padding(
                          padding: const EdgeInsets.only(left: 20, bottom: 4),
                          child: Text(
                            _getWarningMessage(warning),
                            style: const TextStyle(fontSize: 11),
                          ),
                        )),
                  ],
                ),
              ),
            ],
            // Suggestions
            if (widget.suggestions.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  widget.warnings.isNotEmpty ? 0 : 12,
                  12,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tips_and_updates, color: Colors.blue, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Suggestions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...widget.suggestions.take(3).map((suggestion) => Padding(
                          padding: const EdgeInsets.only(left: 20, bottom: 4),
                          child: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 11),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    final color = widget.confidenceScore > 0.7
        ? Colors.green
        : widget.confidenceScore > 0.4
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${(widget.confidenceScore * 100).toInt()}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getWarningMessage(String warning) {
    switch (warning) {
      case 'pitch_low':
        return 'Pitch too low';
      case 'pitch_high':
        return 'Pitch too high';
      case 'pace_slow':
        return 'Speaking too slowly';
      case 'pace_fast':
        return 'Speaking too fast';
      default:
        return warning;
    }
  }
}

