import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../models/game_models.dart';

class ContinuePromptScreen extends StatelessWidget {
  final GameController controller;

  const ContinuePromptScreen({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final eliminated = controller.playerStates.entries
        .where((e) =>
            e.value.status == PlayerStatus.eliminated &&
            e.value.round == controller.currentRoundIndex)
        .map((e) => e.key)
        .toList();
    final killed = controller.playerStates.entries
        .where((e) =>
            e.value.status == PlayerStatus.killed &&
            e.value.round == controller.currentRoundIndex)
        .map((e) => e.key)
        .toList();

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
            'Night Phase Complete',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF475569).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '🔨 Eliminated',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...eliminated.map((id) => Text(
                            'Player $id',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF7F1D1D).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '🔫 Killed',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...killed.map((id) => Text(
                            'Player $id',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text(
            '${10 - controller.playerStates.length} players remaining',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: isMobile ? 14 : 16,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: controller.continueToNextRound,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF16A34A),
              padding: EdgeInsets.symmetric(
                horizontal: 32,
                vertical: isMobile ? 12 : 16,
              ),
            ),
            child: Text(
              'Continue to Next Voting Phase',
              style: TextStyle(fontSize: isMobile ? 16 : 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

