import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';

class RoundCompleteScreen extends StatelessWidget {
  final GameController controller;

  const RoundCompleteScreen({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Round ${controller.currentRoundIndex + 1} Complete!',
            style: TextStyle(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 24),
          ...controller.allRounds.asMap().entries.map((entry) {
            final score = controller.calculateRoundScore(entry.key);
            if (score.isEmpty) return SizedBox.shrink();
            final percentage = (score['correct']! / score['total']! * 100).round();
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Round ${entry.key + 1}: ${score['correct']}/${score['total']} ($percentage%)',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 18,
                  color: Colors.white,
                ),
              ),
            );
          }),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: controller.processEliminationAndKill,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2563EB),
              padding: EdgeInsets.symmetric(
                horizontal: 32,
                vertical: isMobile ? 12 : 16,
              ),
            ),
            child: Text(
              'Process Night Phase',
              style: TextStyle(fontSize: isMobile ? 16 : 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

