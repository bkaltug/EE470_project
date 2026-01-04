import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PredictionCard extends StatelessWidget {
  final PredictionResult result;

  const PredictionCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final confidence = result.confidence;
    final confidencePercentage = (confidence * 100).toStringAsFixed(1);

    // Determine confidence level color
    Color confidenceColor;
    String confidenceLabel;
    IconData confidenceIcon;

    if (confidence >= 0.8) {
      confidenceColor = Colors.green;
      confidenceLabel = 'High Confidence';
      confidenceIcon = Icons.verified_rounded;
    } else if (confidence >= 0.5) {
      confidenceColor = Colors.orange;
      confidenceLabel = 'Medium Confidence';
      confidenceIcon = Icons.info_outline_rounded;
    } else {
      confidenceColor = Colors.red;
      confidenceLabel = 'Low Confidence';
      confidenceIcon = Icons.warning_amber_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.6),
            colorScheme.secondaryContainer.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Success Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 36,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          // Result Label
          Text(
            'Detected Sign',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          // Sign Name
          Text(
            result.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 20),

          // Confidence Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: confidenceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: confidenceColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(confidenceIcon, size: 20, color: confidenceColor),
                const SizedBox(width: 8),
                Text(
                  '$confidencePercentage%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: confidenceColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  confidenceLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: confidenceColor),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Confidence Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 8,
              backgroundColor: colorScheme.outline.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
            ),
          ),

          const SizedBox(height: 12),

        ],
      ),
    );
  }
}
