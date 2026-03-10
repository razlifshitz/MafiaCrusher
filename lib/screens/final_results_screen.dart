import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../models/game_models.dart';

class FinalResultsScreen extends StatelessWidget {
  final GameController controller;

  const FinalResultsScreen({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final totalScore = controller.getTotalScore();
    final percentage = totalScore['total']! > 0
        ? (totalScore['correct']! / totalScore['total']! * 100).round()
        : 0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🎯 Training Complete!',
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${totalScore['correct']} / ${totalScore['total']}',
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: isMobile ? 14 : 18,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 12),
          ..._buildDetailedResults(isMobile),
          SizedBox(height: 12),
          _buildPerformanceMessage(totalScore, isMobile),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => controller.setGameState(GameState.setup),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2563EB),
              padding: EdgeInsets.symmetric(
                horizontal: 32,
                vertical: isMobile ? 12 : 16,
              ),
            ),
            child: Text(
              'Train Again',
              style: TextStyle(fontSize: isMobile ? 14 : 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetailedResults(bool isMobile) {
    final results = <Widget>[];
    for (int roundIdx = 0; roundIdx < controller.allRounds.length; roundIdx++) {
      final round = controller.allRounds[roundIdx];
      final originalScore = controller.calculateRoundScore(roundIdx);
      final roundResults = <Widget>[];

      if (originalScore.isNotEmpty) {
        final origPercentage =
            (originalScore['correct']! / originalScore['total']! * 100).round();
        roundResults.add(
          Text(
            'Original Test: ${originalScore['correct']}/${originalScore['total']} ($origPercentage%)',
            style: TextStyle(
              fontSize: isMobile ? 9 : 11,
              color: Colors.white,
            ),
          ),
        );
      }

      if (roundIdx > 0) {
        for (int retryIdx = 0; retryIdx < roundIdx; retryIdx++) {
          final retryScore = controller.calculateRetryScore(retryIdx, roundIdx);
          if (retryScore.isNotEmpty) {
            final retryPercentage =
                (retryScore['correct']! / retryScore['total']! * 100).round();
            roundResults.add(
              Padding(
                padding: EdgeInsets.only(top: 1),
                child: Text(
                  '🔄 Retry ${controller.allRounds[retryIdx].activePlayers} Players: ${retryScore['correct']}/${retryScore['total']} ($retryPercentage%)',
                  style: TextStyle(
                    fontSize: isMobile ? 8 : 10,
                    color: Colors.grey[300],
                  ),
                ),
              ),
            );
          }
        }
        final selfRetry = controller.calculateRetryScore(roundIdx, roundIdx);
        if (selfRetry.isNotEmpty) {
          final selfRetryPercentage =
              (selfRetry['correct']! / selfRetry['total']! * 100).round();
          roundResults.add(
            Padding(
              padding: EdgeInsets.only(top: 1),
              child: Text(
                '🔄 Retry ${round.activePlayers} Players: ${selfRetry['correct']}/${selfRetry['total']} ($selfRetryPercentage%)',
                style: TextStyle(
                  fontSize: isMobile ? 8 : 10,
                  color: Colors.grey[300],
                ),
              ),
            ),
          );
        }
      }

      if (roundResults.isNotEmpty) {
        results.add(
          Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: Color(0xFF475569),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Round ${roundIdx + 1} - ${round.activePlayers} Players',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                ...roundResults,
              ],
            ),
          ),
        );
      }
    }
    return results;
  }

  Widget _buildPerformanceMessage(Map<String, int> totalScore, bool isMobile) {
    final ratio = totalScore['total']! > 0
        ? totalScore['correct']! / totalScore['total']!
        : 0.0;
    String message;
    if (ratio == 1.0) {
      message = '🌟 Perfect Score! Incredible memory!';
    } else if (ratio >= 0.8) {
      message = '🎉 Excellent! Your memory is sharp!';
    } else if (ratio >= 0.6) {
      message = '👍 Good job! Keep practicing!';
    } else {
      message = '💪 Keep training, you\'ll improve!';
    }

    return Text(
      message,
      style: TextStyle(
        fontSize: isMobile ? 12 : 14,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
}

