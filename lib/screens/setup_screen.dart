import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../controllers/game_controller.dart';

class SetupScreen extends StatelessWidget {
  final GameController controller;

  const SetupScreen({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = isMobile ? double.infinity : math.min(500.0, screenWidth * 0.4).toDouble();

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Progressive Memory Training',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Practice remembering votes across multiple rounds:',
            style: TextStyle(color: Colors.grey[300], fontSize: isMobile ? 12 : 14),
          ),
          SizedBox(height: 12),
          _buildBulletPoint('Round 1: 9 players', isMobile),
          _buildBulletPoint('Round 2: 7 players + retry Round 1', isMobile),
          _buildBulletPoint('Round 3: 5 players + retry all rounds', isMobile),
          SizedBox(height: 24),
          Text(
            'Memory Train Type',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          _buildMemoryTrainTypeButton(context, MemoryTrainType.tableBased, '📊 Table Based', isMobile),
          SizedBox(height: 8),
          _buildMemoryTrainTypeButton(context, MemoryTrainType.playerBased, '👤 Player Based', isMobile),
          SizedBox(height: 8),
          _buildMemoryTrainTypeButton(context, MemoryTrainType.practiceSplit, '🎯 Practice Split', isMobile),
          if (controller.memoryTrainType != MemoryTrainType.practiceSplit) ...[
            SizedBox(height: 24),
            Text(
              'Choose Difficulty',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            _buildDifficultyButton(context, Difficulty.easy, '🟢 Easy - 3 candidates', isMobile),
            SizedBox(height: 8),
            _buildDifficultyButton(context, Difficulty.medium, '🟡 Medium - 5 candidates', isMobile),
            SizedBox(height: 8),
            _buildDifficultyButton(context, Difficulty.hard, '🔴 Hard - 7 candidates', isMobile),
            SizedBox(height: 24),
          ],
          if (controller.memoryTrainType == MemoryTrainType.practiceSplit) ...[
            SizedBox(height: 24),
            Text(
              'Round 0 split: vote the correct way in 3 seconds per scenario.',
              style: TextStyle(color: Colors.grey[400], fontSize: isMobile ? 11 : 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
          ],
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (controller.memoryTrainType == MemoryTrainType.practiceSplit) {
                controller.startPracticeSplitGame();
              } else {
                controller.startGame();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2563EB),
              padding: EdgeInsets.symmetric(
                horizontal: 32,
                vertical: isMobile ? 12 : 16,
              ),
            ),
            child: Text(
              'Start Training',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('• ', style: TextStyle(color: Colors.grey[300], fontSize: isMobile ? 12 : 14)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[300], fontSize: isMobile ? 12 : 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryTrainTypeButton(BuildContext context, MemoryTrainType type, String label, bool isMobile) {
    final isSelected = controller.memoryTrainType == type;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => controller.setMemoryTrainType(type),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Color(0xFF2563EB) : Color(0xFF475569),
          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(BuildContext context, Difficulty diff, String label, bool isMobile) {
    final isSelected = controller.difficulty == diff;
    Color color;
    switch (diff) {
      case Difficulty.easy:
        color = Color(0xFF16A34A);
        break;
      case Difficulty.medium:
        color = Color(0xFFCA8A04);
        break;
      case Difficulty.hard:
        color = Color(0xFFDC2626);
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => controller.setDifficulty(diff),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Color(0xFF475569),
          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

