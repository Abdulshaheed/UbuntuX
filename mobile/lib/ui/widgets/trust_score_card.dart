import 'package:flutter/material.dart';
import 'package:mobile/core/config/app_theme.dart';

class TrustScoreCard extends StatelessWidget {
  final int score;
  final String riskLevel;
  final Map<String, String> factors;

  const TrustScoreCard({
    super.key, 
    required this.score,
    this.riskLevel = "Medium",
    this.factors = const {},
  });

  Color _getRiskColor() {
    switch (riskLevel) {
      case 'Low':
        return Colors.greenAccent;
      case 'High':
        return Colors.redAccent;
      case 'Medium':
      default:
        return Colors.orangeAccent;
    }
  }

  void _showExplanation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: UbuntuXTheme.deepNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sentinel Analysis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: UbuntuXTheme.offWhite),
            ),
            const SizedBox(height: 8),
            Text(
              'Factors influencing your trust score:',
              style: TextStyle(color: UbuntuXTheme.silverGray),
            ),
            const SizedBox(height: 24),
            ...factors.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: _getRiskColor(), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(entry.value, style: TextStyle(color: UbuntuXTheme.silverGray, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            UbuntuXTheme.deepNavy,
            riskColor.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: riskColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Trust Sentinel',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: UbuntuXTheme.offWhite.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$riskLevel Risk',
                  style: TextStyle(color: riskColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: UbuntuXTheme.offWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                    ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '/ 100',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: UbuntuXTheme.silverGray,
                      ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showExplanation(context),
                icon: Icon(Icons.info_outline_rounded, size: 16, color: riskColor),
                label: Text(
                  'Why this?',
                  style: TextStyle(color: riskColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: UbuntuXTheme.darkBlue.withOpacity(0.3),
              color: riskColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on real-time saving patterns.',
            style: TextStyle(color: UbuntuXTheme.silverGray.withOpacity(0.5), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
