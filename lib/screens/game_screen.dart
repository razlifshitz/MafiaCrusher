import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../controllers/game_controller.dart';
import 'setup_screen.dart';
import 'game_play_screen.dart';
import 'round_complete_screen.dart';
import 'continue_prompt_screen.dart';
import 'final_results_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController controller;

  @override
  void initState() {
    super.initState();
    controller = GameController();
    controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
            ],
          ),
        ),
        child: SafeArea(
          child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildToolbar(true),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(12),
            child: _buildCurrentScreen(),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        _buildToolbar(false),
        Expanded(
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 1200),
              padding: EdgeInsets.all(32),
              child: _buildCurrentScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 8 : 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎭 Mafia Voting Practice',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (!isMobile)
                Text(
                  'Improve your memory for Mafia voting rounds',
                  style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                ),
            ],
          ),
          Row(
            children: [
              _buildSettingsButton(isMobile),
              if (controller.gameState != GameState.setup) ...[
                SizedBox(width: 8),
                _buildNavigationButtons(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(bool isMobile) {
    return IconButton(
      onPressed: () => _showSettingsDialog(context),
      icon: Icon(Icons.settings, color: Colors.white),
      tooltip: 'Settings',
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => controller.setGameState(GameState.setup),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF475569),
          ),
          child: Text(
            '← Back to Main Menu',
            style: TextStyle(color: Colors.white),
          ),
        ),
        SizedBox(width: 16),
        if (controller.gameState == GameState.learning ||
            controller.gameState == GameState.testing ||
            controller.gameState == GameState.retry)
          ElevatedButton(
            onPressed: controller.replayVotingPhase,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF475569),
            ),
            child: Text(
              '🔄 Replay Voting Phase',
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context) {
    double initialInterval = controller.voteInterval;
    bool initialDevMode = controller.isDevMode;
    bool initialCancelInterval = controller.cancelInterval;
    bool initialAutoFillRandomAnswers = controller.autoFillRandomAnswers;
    bool initialSkipRound0Questions = controller.skipRound0Questions;
    int? initialManualRound0VoteCount = controller.manualRound0VoteCount;
    bool initialPracticeSplitOpenVote = controller.practiceSplitOpenVote;
    int initialPracticeSplitVoteSeconds = controller.practiceSplitVoteSeconds;
    int initialPracticeSplitResultsSeconds = controller.practiceSplitResultsSeconds;
    bool initialPracticeSplitFixedSeat = controller.practiceSplitFixedSeat;
    int initialPracticeSplitFixedSeatPlayerId = controller.practiceSplitFixedSeatPlayerId;
    final TextEditingController voteCountController = TextEditingController(
      text: initialManualRound0VoteCount?.toString() ?? '',
    );
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double currentInterval = initialInterval;
        bool currentDevMode = initialDevMode;
        bool currentCancelInterval = initialCancelInterval;
        bool currentAutoFillRandomAnswers = initialAutoFillRandomAnswers;
        bool currentSkipRound0Questions = initialSkipRound0Questions;
        int? currentManualRound0VoteCount = initialManualRound0VoteCount;
        bool currentPracticeSplitOpenVote = initialPracticeSplitOpenVote;
        int currentPracticeSplitVoteSeconds = initialPracticeSplitVoteSeconds;
        int currentPracticeSplitResultsSeconds = initialPracticeSplitResultsSeconds;
        bool currentPracticeSplitFixedSeat = initialPracticeSplitFixedSeat;
        int currentPracticeSplitFixedSeatPlayerId = initialPracticeSplitFixedSeatPlayerId;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFF1E293B),
              title: Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vote Display Interval',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: currentInterval,
                            min: 2.0,
                            max: 5.0,
                            divisions: 6, // 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0
                            label: '${currentInterval.toStringAsFixed(1)}s',
                            activeColor: Color(0xFF16A34A),
                            inactiveColor: Color(0xFF475569),
                            onChanged: (value) {
                              setState(() {
                                currentInterval = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFF475569),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${currentInterval.toStringAsFixed(1)}s',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Time between each vote during learning phase',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 24),
                    Divider(color: Colors.grey[700], height: 1),
                    SizedBox(height: 16),
                    CheckboxListTile(
                      title: Text(
                        "Don't Ask About Round 0",
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Skip round 0 questions in player-based mode',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      value: currentSkipRound0Questions,
                      activeColor: Color(0xFF16A34A),
                      onChanged: (value) {
                        setState(() {
                          currentSkipRound0Questions = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    SizedBox(height: 16),
                    Divider(color: Colors.grey[700], height: 1),
                    SizedBox(height: 16),
                    Text(
                      'Practice Split',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    CheckboxListTile(
                      title: Text(
                        'Open vote',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Show vote results after each nominee (off = show both after voting ends)',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      value: currentPracticeSplitOpenVote,
                      activeColor: Color(0xFF16A34A),
                      onChanged: (value) {
                        setState(() {
                          currentPracticeSplitOpenVote = value ?? true;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Voting time (seconds)',
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                    Slider(
                      value: currentPracticeSplitVoteSeconds.toDouble(),
                      min: 1,
                      max: 15,
                      divisions: 14,
                      label: '${currentPracticeSplitVoteSeconds}s',
                      activeColor: Color(0xFF16A34A),
                      onChanged: (value) {
                        setState(() {
                          currentPracticeSplitVoteSeconds = value.round();
                        });
                      },
                    ),
                    Text(
                      'Results display (seconds)',
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                    Slider(
                      value: currentPracticeSplitResultsSeconds.toDouble(),
                      min: 1,
                      max: 15,
                      divisions: 14,
                      label: '${currentPracticeSplitResultsSeconds}s',
                      activeColor: Color(0xFF16A34A),
                      onChanged: (value) {
                        setState(() {
                          currentPracticeSplitResultsSeconds = value.round();
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    CheckboxListTile(
                      title: Text(
                        'Fixed seat',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Use same seat every question (off = random seat each question)',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      value: currentPracticeSplitFixedSeat,
                      activeColor: Color(0xFF16A34A),
                      onChanged: (value) {
                        setState(() {
                          currentPracticeSplitFixedSeat = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (currentPracticeSplitFixedSeat) ...[
                      SizedBox(height: 8),
                      Text(
                        'Your seat (player number 1–10)',
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                      ),
                      SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(10, (i) {
                          final playerId = i + 1;
                          final isSelected = currentPracticeSplitFixedSeatPlayerId == playerId;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                currentPracticeSplitFixedSeatPlayerId = playerId;
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFF22C55E) : Color(0xFF475569),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$playerId',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                    SizedBox(height: 16),
                    Divider(color: Colors.grey[700], height: 1),
                    SizedBox(height: 16),
                    CheckboxListTile(
                      title: Text(
                        'Developer Mode',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Enable developer features',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      value: currentDevMode,
                      activeColor: Color(0xFF16A34A),
                      onChanged: (value) {
                        setState(() {
                          currentDevMode = value ?? false;
                          if (!currentDevMode) {
                            currentCancelInterval = false;
                            currentAutoFillRandomAnswers = false;
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (currentDevMode) ...[
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.only(left: 40),
                        child: CheckboxListTile(
                          title: Text(
                            'Cancel Interval',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Skip all delays to jump through screens faster',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          value: currentCancelInterval,
                          activeColor: Color(0xFF16A34A),
                          onChanged: (value) {
                            setState(() {
                              currentCancelInterval = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.only(left: 40),
                        child: CheckboxListTile(
                          title: Text(
                            'Auto Fill Random Answers',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Automatically fill random answers in testing phase',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          value: currentAutoFillRandomAnswers,
                          activeColor: Color(0xFF16A34A),
                          onChanged: (value) {
                            setState(() {
                              currentAutoFillRandomAnswers = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.only(left: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Round 0 Vote Count',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Override random vote count for split phase (1-9)',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: voteCountController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Auto (random)',
                                      hintStyle: TextStyle(color: Colors.grey[500]),
                                      filled: true,
                                      fillColor: Color(0xFF475569),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value.isEmpty) {
                                          currentManualRound0VoteCount = null;
                                        } else {
                                          final count = int.tryParse(value);
                                          if (count != null && count >= 1 && count <= 9) {
                                            currentManualRound0VoteCount = count;
                                          } else {
                                            currentManualRound0VoteCount = null;
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                                  onPressed: () {
                                    setState(() {
                                      voteCountController.clear();
                                      currentManualRound0VoteCount = null;
                                    });
                                  },
                                  tooltip: 'Clear',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    voteCountController.dispose();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    controller.setVoteInterval(currentInterval);
                    controller.setDevMode(currentDevMode);
                    controller.setCancelInterval(currentCancelInterval);
                    controller.setAutoFillRandomAnswers(currentAutoFillRandomAnswers);
                    controller.setSkipRound0Questions(currentSkipRound0Questions);
                    controller.setManualRound0VoteCount(currentManualRound0VoteCount);
                    controller.setPracticeSplitOpenVote(currentPracticeSplitOpenVote);
                    controller.setPracticeSplitVoteSeconds(currentPracticeSplitVoteSeconds);
                    controller.setPracticeSplitResultsSeconds(currentPracticeSplitResultsSeconds);
                    controller.setPracticeSplitFixedSeat(currentPracticeSplitFixedSeat);
                    controller.setPracticeSplitFixedSeatPlayerId(currentPracticeSplitFixedSeatPlayerId);
                    voteCountController.dispose();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF16A34A),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCurrentScreen() {
    switch (controller.gameState) {
      case GameState.setup:
        return SetupScreen(controller: controller);
      case GameState.learning:
      case GameState.testing:
      case GameState.retry:
        return GamePlayScreen(controller: controller);
      case GameState.roundComplete:
      case GameState.continuePrompt:
        // These screens are now integrated into GamePlayScreen
        return GamePlayScreen(controller: controller);
      case GameState.practiceSplit:
        return GamePlayScreen(controller: controller);
      case GameState.finalResults:
        return FinalResultsScreen(controller: controller);
    }
  }
}
