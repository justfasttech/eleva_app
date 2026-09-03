import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class FaithTree extends StatelessWidget {
  final double faithPoints;

  const FaithTree({super.key, required this.faithPoints});

  int get level => (faithPoints / 5).floor().clamp(0, 14);
  double get percentage => faithPoints.clamp(0.0, 70.0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Árvore da fé',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ElevaColors.gold,
            ),
          ),
        ),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/trees/$level.png',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.park_rounded,
                        size: 80,
                        color: ElevaColors.gold.withValues(alpha: 0.4),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 10,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ElevaColors.gold, ElevaColors.goldLight],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
