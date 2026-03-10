import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';
import '../controllers/game_controller.dart';
import '../widgets/circular_player_layout.dart';

class GamePlayScreen extends StatelessWidget {
  final GameController controller;

  const GamePlayScreen({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      // Safety check: ensure controller is not null
      if (controller == null) {
        print('ERROR: Controller is null in GamePlayScreen.build');
        return Center(child: Text('Error: Controller is null', style: TextStyle(color: Colors.red)));
      }
      
      final isMobile = MediaQuery.of(context).size.width < 768;

      // Practice split mode
      if (controller.gameState == GameState.practiceSplit) {
        return _buildPracticeSplitLayout(context, isMobile);
      }
      
      // If showing night phase results, show that instead
      if (controller.showNightPhaseResults) {
      return isMobile
          ? SingleChildScrollView(
              child: Column(
                children: [
                  _buildScoreOnlyPanel(context, isMobile),
                  SizedBox(height: 12),
                  _buildNightPhaseResults(context, isMobile),
                  SizedBox(height: 12),
                  _buildCircularLayout(context, null),
                  SizedBox(height: 4),
                  _buildLegend(isMobile),
                ],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 256, child: _buildScoreOnlyPanel(context, isMobile)),
                SizedBox(width: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildNightPhaseResults(context, isMobile),
                        SizedBox(height: 12),
                        _buildCircularLayout(context, null),
                        SizedBox(height: 4),
                        _buildLegend(isMobile),
                      ],
                    ),
                  ),
                ),
              ],
            );
    }
    
    // Safety check: ensure rounds exist
    if (controller.allRounds.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    
    final roundIndex = controller.gameState == GameState.learning
        ? controller.currentRoundIndex
        : controller.testingRoundIndex;
    
    if (roundIndex >= controller.allRounds.length) {
      return Center(child: CircularProgressIndicator());
    }
    
    final currentRound = controller.allRounds[roundIndex];
    
    // Handle player-based mode
    if (controller.memoryTrainType == MemoryTrainType.playerBased &&
        (controller.gameState == GameState.testing || controller.gameState == GameState.retry)) {
      try {
        return _buildPlayerBasedLayout(context, isMobile);
      } catch (e, stackTrace) {
        print('ERROR in GamePlayScreen.build when calling _buildPlayerBasedLayout: $e');
        print('Stack trace: $stackTrace');
        return Center(
          child: Text(
            'Error building player-based layout: $e',
            style: TextStyle(color: Colors.red),
          ),
        );
      }
    }
    
    // Handle split phase
    if (currentRound.splitPhase != null && controller.isSplitPhase) {
      return _buildSplitPhaseLayout(context, isMobile, currentRound);
    }
    
    // Safety check: ensure votes exist (skip if split phase round)
    if (currentRound.splitPhase != null || currentRound.votes.isEmpty) {
      print('ERROR: Round $roundIndex has split phase or empty votes. Split phase: ${currentRound.splitPhase != null}, Votes length: ${currentRound.votes.length}');
      return Center(child: CircularProgressIndicator());
    }
    
    // Safety check: ensure votes exist
    final voteIndex = controller.gameState == GameState.learning
        ? controller.learningStep
        : controller.testingCandidateIndex;
    
    if (voteIndex < 0 || voteIndex >= currentRound.votes.length) {
      return Center(child: CircularProgressIndicator());
    }
    
    final currentVote = currentRound.votes[voteIndex];

    return isMobile
        ? SingleChildScrollView(
            child: Column(
              children: [
                _buildCandidatesPanel(context, isMobile, currentRound, currentVote),
                SizedBox(height: 12),
                _buildGameInfoPanel(context, isMobile, currentRound, currentVote),
                SizedBox(height: 12),
                _buildCircularLayout(context, currentVote),
                SizedBox(height: 4),
                _buildLegend(isMobile),
              ],
            ),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 256, child: _buildCandidatesPanel(context, isMobile, currentRound, currentVote)),
              SizedBox(width: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildGameInfoPanel(context, isMobile, currentRound, currentVote),
                      SizedBox(height: 12),
                      _buildCircularLayout(context, currentVote),
                      SizedBox(height: 4),
                      _buildLegend(isMobile),
                    ],
                  ),
                ),
              ),
            ],
          );
    } catch (e, stackTrace) {
      print('ERROR in GamePlayScreen.build: $e');
      print('Stack trace: $stackTrace');
      return Center(
        child: Text(
          'Error in build: $e',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  }

  Widget _buildCandidatesPanel(BuildContext context, bool isMobile, Round? currentRound, VoteData? currentVote) {
    if (currentRound == null || currentVote == null) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        decoration: BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 Candidates',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    // Safety check: skip if split phase round or no candidates
    if (currentRound.splitPhase != null || currentRound.candidates.isEmpty) {
      return SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.gameState == GameState.learning ? '📋 Candidates' : '❓ Testing',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            controller.gameState == GameState.learning
                ? 'Round ${controller.currentRoundIndex + 1} - ${currentRound.activePlayers} players'
                : '${controller.gameState == GameState.retry ? '🔄 Retry: ' : ''}Round ${controller.testingRoundIndex + 1} - ${currentRound.activePlayers} players',
            style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.grey[400]),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: currentRound.candidates.map((candidate) {
                final isCurrent = candidate == currentVote.candidate;
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 8 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent ? Color(0xFFDC2626) : Color(0xFF475569),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Player $candidate',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: Colors.white,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Always show current scores section
          Divider(color: Colors.grey[700], height: 24),
          Text(
            'Current Scores:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 12 : 14,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          ..._buildScoreList(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildGameInfoPanel(BuildContext context, bool isMobile, Round? currentRound, VoteData? currentVote) {
    if (currentRound == null || currentVote == null) {
      return SizedBox.shrink();
    }
    // Fixed height to accommodate all states: learning, testing, retry, and feedback
    final fixedHeight = isMobile ? 160.0 : 180.0;
    
    return Container(
      constraints: BoxConstraints(
        minWidth: isMobile ? 0 : 500,
        maxWidth: isMobile ? double.infinity : 500,
      ),
      height: fixedHeight,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.gameState == GameState.retry)
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '🔄 RETRY MODE: ${currentRound.activePlayers} Players Round',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFBBF24),
                  ),
                ),
              ),
            if (controller.gameState == GameState.learning) ...[
              Text(
                'Receiving votes to Player ${currentVote.candidate}',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Watch and remember...',
                style: TextStyle(color: Colors.grey[400], fontSize: isMobile ? 11 : 13),
              ),
              SizedBox(height: 4),
              Text(
                currentRound.votes.isNotEmpty 
                    ? 'Vote ${controller.learningStep + 1} / ${currentRound.votes.length}'
                    : 'Vote ${controller.learningStep + 1} / 0',
                style: TextStyle(color: Colors.grey[500], fontSize: isMobile ? 10 : 11),
              ),
            ],
            if (controller.gameState == GameState.testing || controller.gameState == GameState.retry) ...[
              Text(
                'Who voted for Player ${currentVote.candidate}?',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Click on all players who voted',
                style: TextStyle(color: Colors.grey[400], fontSize: isMobile ? 11 : 13),
              ),
              SizedBox(height: 8),
              if (!controller.showFeedback)
                ElevatedButton(
                  onPressed: controller.checkAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF16A34A),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: isMobile ? 8 : 10,
                    ),
                  ),
                  child: Text(
                    'Submit Answer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
              if (controller.showFeedback) ...[
                Text(
                  controller.selectedPlayers.length == currentVote.voters.length &&
                          controller.selectedPlayers.every((p) => currentVote.voters.contains(p))
                      ? '✅ Correct!'
                      : '❌ Incorrect',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Correct: ${currentVote.voters.isEmpty ? 'No one' : currentVote.voters.join(', ')}',
                    style: TextStyle(color: Colors.grey[400], fontSize: isMobile ? 10 : 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                    softWrap: true,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNightPhaseResults(BuildContext context, bool isMobile) {
    final eliminated = controller.eliminatedPlayers;
    final killed = controller.killedPlayers;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 10 : 12,
      ),
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
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Color(0xFF7F1D1D).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '🔨 Eliminated',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      if (eliminated.isNotEmpty)
                        Text(
                          eliminated.map((id) => 'Player $id').join(' & '),
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      if (eliminated.isEmpty)
                        Text(
                          'No one',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Color(0xFF475569).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '🔫 Killed',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      ...killed.map((id) => Text(
                            'Player $id',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )),
                      if (killed.isEmpty)
                        Text(
                          'None',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '${10 - controller.playerStates.length} players remaining',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              controller.continueToNextRound();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF16A34A),
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: isMobile ? 10 : 12,
              ),
            ),
            child: Text(
              'Continue to Next Voting Phase',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularLayout(BuildContext context, VoteData? currentVote, {
    SplitPhase? splitPhase,
    int? mePlayerId,
    List<int>? tappablePlayerIds,
    List<int>? nominatedPlayerIds,
    List<int>? highlightedVoterIds,
    Function(int)? onPlayerClickOverride,
  }) {
    // When showing night phase results, always use current player states (with eliminated/killed)
    // Otherwise, use round-specific states for retry mode or when replaying
    // Practice split uses empty player states (all 10 active)
    Map<int, PlayerState> relevantPlayerStates;
    if (controller.gameState == GameState.practiceSplit) {
      relevantPlayerStates = {};
    } else if (controller.showNightPhaseResults) {
      relevantPlayerStates = controller.playerStates;
    } else if (controller.gameState == GameState.retry) {
      relevantPlayerStates = controller.getPlayerStatesForRound(controller.testingRoundIndex);
    } else if (controller.gameState == GameState.learning && controller.returnToRetry != null) {
      relevantPlayerStates = controller.getPlayerStatesForRound(controller.currentRoundIndex);
    } else {
      relevantPlayerStates = controller.playerStates;
    }

    return CircularPlayerLayout(
      playerStates: relevantPlayerStates,
      onPlayerClick: onPlayerClickOverride ?? controller.handlePlayerClick,
      gameState: controller.showNightPhaseResults ? GameState.learning : controller.gameState,
      currentCandidate: currentVote?.candidate,
      currentVoters: currentVote != null && (controller.gameState == GameState.learning || controller.showFeedback)
          ? currentVote.voters
          : null,
      selectedPlayers: controller.selectedPlayers,
      showFeedback: controller.showFeedback,
      testingRoundIndex: (controller.gameState == GameState.retry || 
                          (controller.gameState == GameState.learning && controller.returnToRetry != null))
          ? (controller.gameState == GameState.retry 
              ? controller.testingRoundIndex 
              : controller.currentRoundIndex)
          : null,
      getPlayerStatesForRound: controller.getPlayerStatesForRound,
      splitPhase: splitPhase,
      mePlayerId: mePlayerId,
      tappablePlayerIds: tappablePlayerIds,
      nominatedPlayerIds: nominatedPlayerIds,
      highlightedVoterIds: highlightedVoterIds,
    );
  }

  Widget _buildPracticeSplitLayout(BuildContext context, bool isMobile) {
    final phase = controller.practiceSplitPhase;
    final nominated = controller.practiceSplitNominated;
    final nominatedText = nominated.isEmpty ? '' : nominated.join(' and ');
    final scores = controller.practiceSplitScores;
    final goodCount = scores.where((c) => c).length;
    final scenario = controller.practiceSplitCurrentScenario + 1;
    final total = controller.practiceSplitTotalScenarios;

    Widget panel;
    if (phase == PracticeSplitPhase.results) {
      panel = _buildPracticeSplitResultsPanel(context, isMobile, goodCount, total);
    } else {
      panel = Container(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        decoration: BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Practice Split',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You are player ${controller.practiceSplitMePlayer} (green). Scenario $scenario/$total.',
              style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.grey[400]),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Split: $nominatedText',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 12),
            if (phase == PracticeSplitPhase.ready)
              Text(
                'First votes to player ${nominated.isNotEmpty ? nominated[0] : ''} (${controller.practiceSplitVoteSeconds}s), then to player ${nominated.length >= 2 ? nominated[1] : ''} (${controller.practiceSplitVoteSeconds}s). Tap Ready below when set.',
                style: TextStyle(color: Colors.grey[300], fontSize: isMobile ? 12 : 14),
              ),
            if (phase == PracticeSplitPhase.votingToFirst || phase == PracticeSplitPhase.votingToSecond)
              Text(
                'One vote only for the whole round.',
                style: TextStyle(color: Colors.grey[400], fontSize: isMobile ? 11 : 12),
              ),
            if (phase == PracticeSplitPhase.showingResultsFirst || phase == PracticeSplitPhase.showingResultsSecond)
              Text(
                'Vote results (${controller.practiceSplitResultsSeconds}s)',
                style: TextStyle(color: Colors.grey[400], fontSize: isMobile ? 12 : 14),
              ),
            if (phase == PracticeSplitPhase.feedback) ...[
              Text(
                controller.practiceSplitScores.isNotEmpty && controller.practiceSplitScores.last
                    ? 'Correct!'
                    : 'Mistake! You should vote to player ${controller.practiceSplitCorrectVote}.',
                style: TextStyle(
                  color: controller.practiceSplitScores.isNotEmpty && controller.practiceSplitScores.last
                      ? Color(0xFF22C55E)
                      : Color(0xFFDC2626),
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (controller.practiceSplitUserVote == null && !controller.practiceSplitVotedInFirst && !controller.practiceSplitVotedInSecond)
                Text(
                  'No vote in time.',
                  style: TextStyle(color: Color(0xFFF97316), fontSize: isMobile ? 12 : 14),
                ),
            ],
            SizedBox(height: 16),
            Text('Score: $goodCount/${scores.length} correct', style: TextStyle(color: Colors.grey[300], fontSize: isMobile ? 12 : 14)),
          ],
        ),
      );
    }

    final votedThisScenario = controller.practiceSplitVotedInFirst || controller.practiceSplitVotedInSecond;
    final currentNomineeTappable = !votedThisScenario && (phase == PracticeSplitPhase.votingToFirst && nominated.isNotEmpty)
        ? [nominated[0]]
        : !votedThisScenario && (phase == PracticeSplitPhase.votingToSecond && nominated.length >= 2)
            ? [nominated[1]]
            : null;
    final isShowingResults = phase == PracticeSplitPhase.showingResultsFirst || phase == PracticeSplitPhase.showingResultsSecond;
    final resultsPlayerNumber = isShowingResults
        ? (phase == PracticeSplitPhase.showingResultsFirst && nominated.isNotEmpty
            ? nominated[0]
            : (nominated.length >= 2 ? nominated[1] : null))
        : null;
    final highlightedVoterIds = isShowingResults
        ? (phase == PracticeSplitPhase.showingResultsFirst
            ? controller.practiceSplitVotersToFirst
            : controller.practiceSplitVotersToSecond)
        : null;
    final circularLayout = _buildCircularLayout(
      context,
      null,
      mePlayerId: controller.practiceSplitMePlayer,
      tappablePlayerIds: currentNomineeTappable,
      nominatedPlayerIds: nominated.isEmpty ? null : nominated,
      highlightedVoterIds: highlightedVoterIds,
      onPlayerClickOverride: (phase == PracticeSplitPhase.votingToFirst || phase == PracticeSplitPhase.votingToSecond)
          ? controller.handlePracticeSplitVote
          : null,
    );
    final actionButton = _buildPracticeSplitActionButton(context, isMobile, phase, votedThisScenario);

    final isVoting = phase == PracticeSplitPhase.votingToFirst || phase == PracticeSplitPhase.votingToSecond;
    final votingPlayerNumber = isVoting
        ? (phase == PracticeSplitPhase.votingToFirst && nominated.isNotEmpty
            ? nominated[0]
            : (nominated.length >= 2 ? nominated[1] : null))
        : null;

    Widget content;
    if (phase == PracticeSplitPhase.results) {
      content = isMobile
          ? SingleChildScrollView(
              child: Column(
                children: [
                  panel,
                  SizedBox(height: 12),
                  circularLayout,
                  SizedBox(height: 4),
                  _buildLegend(isMobile, practiceSplit: true, showVotedLegend: isShowingResults),
                ],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 280, child: panel),
                SizedBox(width: 32),
                Expanded(
                  child: Column(
                    children: [
                      circularLayout,
                      SizedBox(height: 4),
                      _buildLegend(isMobile, practiceSplit: true, showVotedLegend: isShowingResults),
                    ],
                  ),
                ),
              ],
            );
    } else {
      content = isMobile
          ? SingleChildScrollView(
              child: Column(
                children: [
                  panel,
                  SizedBox(height: 12),
                  if (isVoting && votingPlayerNumber != null) ...[
                    _buildPracticeSplitVotingCountdown(context),
                    SizedBox(height: 8),
                    _buildPracticeSplitVotingHeadline(context, isMobile, votingPlayerNumber),
                    SizedBox(height: 12),
                  ],
                  if (isShowingResults && resultsPlayerNumber != null) ...[
                    _buildPracticeSplitResultsHeadline(context, isMobile, resultsPlayerNumber),
                    SizedBox(height: 12),
                  ],
                  circularLayout,
                  SizedBox(height: 4),
                  _buildLegend(isMobile, practiceSplit: true, showVotedLegend: isShowingResults),
                  if (actionButton != null) ...[SizedBox(height: 12), actionButton],
                ],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 280, child: panel),
                SizedBox(width: 32),
                Expanded(
                  child: Column(
                    children: [
                      if (isVoting && votingPlayerNumber != null) ...[
                        _buildPracticeSplitVotingCountdown(context),
                        SizedBox(height: 8),
                        _buildPracticeSplitVotingHeadline(context, isMobile, votingPlayerNumber),
                        SizedBox(height: 12),
                      ],
                      if (isShowingResults && resultsPlayerNumber != null) ...[
                        _buildPracticeSplitResultsHeadline(context, isMobile, resultsPlayerNumber),
                        SizedBox(height: 12),
                      ],
                      circularLayout,
                      SizedBox(height: 4),
                      _buildLegend(isMobile, practiceSplit: true, showVotedLegend: isShowingResults),
                      if (actionButton != null) ...[SizedBox(height: 12), actionButton],
                    ],
                  ),
                ),
              ],
            );
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
          if (controller.practiceSplitPhase == PracticeSplitPhase.ready) {
            controller.handlePracticeSplitReady();
          } else {
            controller.handlePracticeSplitCastVote();
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: content,
    );
  }

  Widget _buildPracticeSplitVotingCountdown(BuildContext context) {
    final seconds = controller.practiceSplitVoteSeconds;
    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          key: ValueKey(controller.practiceSplitPhase),
          tween: Tween(begin: 1.0, end: 0.0),
          duration: Duration(seconds: seconds),
          builder: (context, value, _) {
            return Container(
              height: 4,
              width: double.infinity,
              color: Color(0xFF475569),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * value,
                  color: Color(0xFF22C55E),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPracticeSplitVotingHeadline(BuildContext context, bool isMobile, int playerNumber) {
    return Center(
      child: Text(
        'Getting votes to player $playerNumber',
        style: TextStyle(
          fontSize: isMobile ? 24 : 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPracticeSplitResultsHeadline(BuildContext context, bool isMobile, int playerNumber) {
    return Center(
      child: Text(
        'Voted to player $playerNumber',
        style: TextStyle(
          fontSize: isMobile ? 24 : 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3B82F6),
        ),
      ),
    );
  }

  Widget? _buildPracticeSplitActionButton(BuildContext context, bool isMobile, PracticeSplitPhase phase, bool votedThisScenario) {
    if (phase == PracticeSplitPhase.ready) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: controller.handlePracticeSplitReady,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2563EB),
            padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Ready', style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      );
    }
    if (phase == PracticeSplitPhase.votingToFirst || phase == PracticeSplitPhase.votingToSecond) {
      final disabled = votedThisScenario;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: disabled ? null : controller.handlePracticeSplitCastVote,
          style: ElevatedButton.styleFrom(
            backgroundColor: disabled ? Color(0xFF475569) : Color(0xFF16A34A),
            disabledBackgroundColor: Color(0xFF475569),
            padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(disabled ? 'Voted' : 'VOTE', style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      );
    }
    return null;
  }

  Widget _buildPracticeSplitResultsPanel(BuildContext context, bool isMobile, int goodCount, int total) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Practice Split – Results', style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 12),
          Text(
            '$goodCount / $total correct',
            style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.setGameState(GameState.setup),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF475569)),
            child: Text('Back to Main Menu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitPhaseLayout(BuildContext context, bool isMobile, Round currentRound) {
    final splitPhase = currentRound.splitPhase!;
    
    return isMobile
        ? SingleChildScrollView(
            child: Column(
              children: [
                _buildSplitPhaseCandidatesPanel(context, isMobile, currentRound, splitPhase),
                SizedBox(height: 12),
                _buildSplitPhaseInfoPanel(context, isMobile, splitPhase),
                SizedBox(height: 12),
                _buildCircularLayout(context, null, splitPhase: splitPhase),
                SizedBox(height: 4),
                _buildLegend(isMobile),
              ],
            ),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 256, child: _buildSplitPhaseCandidatesPanel(context, isMobile, currentRound, splitPhase)),
              SizedBox(width: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSplitPhaseInfoPanel(context, isMobile, splitPhase),
                      SizedBox(height: 12),
                      _buildCircularLayout(context, null, splitPhase: splitPhase),
                      SizedBox(height: 4),
                      _buildLegend(isMobile),
                    ],
                  ),
                ),
              ),
            ],
          );
  }

  Widget _buildSplitPhaseCandidatesPanel(BuildContext context, bool isMobile, Round currentRound, SplitPhase splitPhase) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.gameState == GameState.learning ? '📋 Candidates' : '❓ Testing',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            controller.gameState == GameState.learning
                ? 'Round ${controller.currentRoundIndex + 1} - ${currentRound.activePlayers} players'
                : '${controller.gameState == GameState.retry ? '🔄 Retry: ' : ''}Round ${controller.testingRoundIndex + 1} - ${currentRound.activePlayers} players',
            style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.grey[400]),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 8 : 12,
              ),
              decoration: BoxDecoration(
                color: Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Split Players: Player ${splitPhase.player1} & Player ${splitPhase.splitPartner}',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Always show current scores section
          Divider(color: Colors.grey[700], height: 24),
          Text(
            'Current Scores:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 12 : 14,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          ..._buildScoreList(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildSplitPhaseInfoPanel(BuildContext context, bool isMobile, SplitPhase splitPhase) {
    final fixedHeight = isMobile ? 160.0 : 180.0;
    
    // Get the current round to get active players count
    final roundIndex = controller.gameState == GameState.learning
        ? controller.currentRoundIndex
        : controller.testingRoundIndex;
    final currentRound = roundIndex < controller.allRounds.length 
        ? controller.allRounds[roundIndex]
        : null;
    final activePlayers = currentRound?.activePlayers ?? 10;
    
    return Container(
      constraints: BoxConstraints(
        minWidth: isMobile ? 0 : 500,
        maxWidth: isMobile ? double.infinity : 500,
      ),
      height: fixedHeight,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.gameState == GameState.retry)
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '🔄 RETRY MODE: $activePlayers Players Round',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFBBF24),
                  ),
                ),
              ),
            if (controller.gameState == GameState.learning) ...[
              Text(
                'Player 1 split with Player ${splitPhase.splitPartner}',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Watch and remember who voted to eliminate both...',
                style: TextStyle(color: Colors.grey[400], fontSize: isMobile ? 11 : 13),
              ),
            ],
            if (controller.gameState == GameState.testing || controller.gameState == GameState.retry) ...[
              Text(
                'Who voted to eliminate both Player ${splitPhase.player1} and Player ${splitPhase.splitPartner}?',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Click on all players who voted',
                style: TextStyle(color: Colors.grey[400], fontSize: isMobile ? 10 : 12),
              ),
              SizedBox(height: 8),
              if (!controller.showFeedback)
                ElevatedButton(
                  onPressed: controller.checkAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF16A34A),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: isMobile ? 8 : 10,
                    ),
                  ),
                  child: Text(
                    'Submit Answer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
              if (controller.showFeedback) ...[
                Text(
                  controller.selectedPlayers.length == splitPhase.voters.length &&
                          controller.selectedPlayers.every((p) => splitPhase.voters.contains(p))
                      ? '✅ Correct!'
                      : '❌ Incorrect',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Correct: ${splitPhase.voters.isEmpty ? 'No one' : splitPhase.voters.join(', ')}',
                    style: TextStyle(color: Colors.grey[400], fontSize: isMobile ? 10 : 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                    softWrap: true,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(bool isMobile, {bool practiceSplit = false, bool showVotedLegend = false}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: practiceSplit
              ? [
                  _buildLegendItem('You (border)', Color(0xFF22C55E), isMobile),
                  _buildLegendItem('Split (border)', Color(0xFFF59E0B), isMobile),
                  if (showVotedLegend) _buildLegendItem('Voted', Color(0xFF3B82F6), isMobile),
                ]
              : [
                  _buildLegendItem('Candidate', Color(0xFFEF4444), isMobile),
                  _buildLegendItem('Voted', Color(0xFF3B82F6), isMobile),
                  _buildLegendItem('🔫 Killed', null, isMobile),
                  _buildLegendItem('🔨 Eliminated', null, isMobile),
                ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color? color, bool isMobile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (color != null)
          Container(
            width: isMobile ? 12 : 16,
            height: isMobile ? 12 : 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          )
        else
          Text(label.startsWith('🔫') ? '🔫' : '🔨',
              style: TextStyle(fontSize: isMobile ? 12 : 16)),
        SizedBox(width: 4),
        Flexible(
          child: Text(
            label.replaceAll(RegExp(r'[🔫🔨]'), '').trim(),
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey[300],
            ),
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreOnlyPanel(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Scores:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 12 : 14,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          ..._buildScoreList(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildPlayerBasedLayout(BuildContext context, bool isMobile) {
    try {
      // If showing night phase results, show that instead of player-based questions
      if (controller.showNightPhaseResults) {
        return isMobile
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    _buildScoreOnlyPanel(context, isMobile),
                    SizedBox(height: 12),
                    _buildNightPhaseResults(context, isMobile),
                    SizedBox(height: 12),
                    _buildCircularLayout(context, null),
                    SizedBox(height: 4),
                    _buildLegend(isMobile),
                  ],
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 256, child: _buildScoreOnlyPanel(context, isMobile)),
                  SizedBox(width: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildNightPhaseResults(context, isMobile),
                          SizedBox(height: 12),
                          _buildCircularLayout(context, null),
                          SizedBox(height: 4),
                          _buildLegend(isMobile),
                        ],
                      ),
                    ),
                  ),
                ],
              );
      }
      
      // Safety check: ensure controller is valid
      if (controller == null) {
        print('ERROR: Controller is null in _buildPlayerBasedLayout');
        return Center(child: Text('Error: Controller is null', style: TextStyle(color: Colors.red)));
      }
      
      List<PlayerBasedQuestion> questions;
      try {
        questions = controller.getPlayerBasedQuestions();
      } catch (e, stackTrace) {
        print('ERROR: Failed to get player-based questions: $e');
        print('Stack trace: $stackTrace');
        return Center(
          child: Text(
            'Error loading questions: $e',
            style: TextStyle(color: Colors.red),
          ),
        );
      }
      
      if (questions.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }
      
      // Get current round info for the toolbar
      final roundIndex = controller.gameState == GameState.learning
          ? controller.currentRoundIndex
          : controller.testingRoundIndex;
      
      final currentRound = roundIndex >= 0 && roundIndex < controller.allRounds.length 
          ? controller.allRounds[roundIndex]
          : null;
    
      try {
        final toolbar = _buildPlayerBasedToolbar(context, isMobile, currentRound);
        final questionsPanel = _buildPlayerBasedQuestionsPanel(context, isMobile, questions);
        final circularLayout = _buildCircularLayout(context, null);
        final legend = _buildLegend(isMobile);
        return isMobile
            ? SingleChildScrollView(
                child: Column(
                    children: [
                      toolbar,
                      SizedBox(height: 12),
                      questionsPanel,
                      SizedBox(height: 12),
                      circularLayout,
                      SizedBox(height: 4),
                      legend,
                    ],
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 256, child: toolbar),
                  SizedBox(width: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          questionsPanel,
                          SizedBox(height: 12),
                          circularLayout,
                          SizedBox(height: 4),
                          legend,
                        ],
                      ),
                    ),
                  ),
                ],
              );
      } catch (e, stackTrace) {
        print('ERROR in _buildPlayerBasedLayout when assembling widgets: $e');
        print('Stack trace: $stackTrace');
        return Center(
          child: Text(
            'Error assembling layout: $e',
            style: TextStyle(color: Colors.red),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('ERROR in _buildPlayerBasedLayout: $e');
      print('Stack trace: $stackTrace');
      return Center(
        child: Text(
          'Error loading questions: $e',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  }
  
  Widget _buildPlayerBasedToolbar(BuildContext context, bool isMobile, Round? currentRound) {
    // In player-based mode, when testing, we're asking about previous rounds before current round
    // So we need to get the active players count at the START of current round
    final roundIndex = controller.currentRoundIndex;
    final activePlayers = 10 - controller.playerStates.length;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '❓ Testing',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Round ${roundIndex + 1} - $activePlayers players',
            style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.grey[400]),
          ),
          // Show split phase info if it's round 0
          if (currentRound?.splitPhase != null) ...[
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Split Players: Player ${currentRound!.splitPhase!.player1} & Player ${currentRound.splitPhase!.splitPartner}',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          // Show Table button
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showTableDialog(context, isMobile),
            icon: Icon(Icons.table_chart, size: isMobile ? 16 : 18, color: Colors.white),
            label: Text(
              'Show Table',
              style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF475569),
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isMobile ? 10 : 12,
              ),
            ),
          ),
          // Always show current scores section
          Divider(color: Colors.grey[700], height: 24),
          Text(
            'Current Scores:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 12 : 14,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          ..._buildScoreList(context, isMobile),
        ],
      ),
    );
  }
  
  void _showTableDialog(BuildContext context, bool isMobile) {
    // Get current round info
    final roundIndex = controller.gameState == GameState.learning
        ? controller.currentRoundIndex
        : controller.testingRoundIndex;
    final currentRound = roundIndex < controller.allRounds.length 
        ? controller.allRounds[roundIndex]
        : null;
    
    // Get relevant player states
    Map<int, PlayerState> relevantPlayerStates;
    if (controller.showNightPhaseResults) {
      relevantPlayerStates = controller.playerStates;
    } else if (controller.gameState == GameState.retry) {
      relevantPlayerStates = controller.getPlayerStatesForRound(controller.testingRoundIndex);
    } else if (controller.gameState == GameState.learning && controller.returnToRetry != null) {
      relevantPlayerStates = controller.getPlayerStatesForRound(controller.currentRoundIndex);
    } else {
      relevantPlayerStates = controller.playerStates;
    }
    
    // Get split phase if applicable
    final splitPhase = currentRound?.splitPhase;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? MediaQuery.of(context).size.width * 0.9 : 600,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Player Table',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularPlayerLayout(
                        playerStates: relevantPlayerStates,
                        onPlayerClick: (_) {}, // No interaction in dialog
                        gameState: controller.showNightPhaseResults ? GameState.learning : controller.gameState,
                        currentCandidate: null,
                        currentVoters: null,
                        selectedPlayers: null,
                        showFeedback: false,
                        testingRoundIndex: controller.testingRoundIndex,
                        getPlayerStatesForRound: controller.getPlayerStatesForRound,
                        splitPhase: splitPhase,
                      ),
                      SizedBox(height: 16),
                      _buildLegend(isMobile),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlayerBasedQuestionsPanel(BuildContext context, bool isMobile, List<PlayerBasedQuestion> questions) {
    try {
      // Safety check: ensure questions list is not null or empty
      if (questions.isEmpty) {
        print('WARNING: _buildPlayerBasedQuestionsPanel called with empty questions list');
        return Container(
          padding: EdgeInsets.all(16),
          child: Text(
            'No questions available',
            style: TextStyle(color: Colors.grey[400]),
          ),
        );
      }
      
      // Group questions by player using the passed questions list
      final questionsByPlayer = <int, List<PlayerBasedQuestion>>{};
      for (final question in questions) {
        // Safety check: ensure question is not null
        if (question == null) {
          print('WARNING: Null question found in questions list');
          continue;
        }
        if (!questionsByPlayer.containsKey(question.playerId)) {
          questionsByPlayer[question.playerId] = [];
        }
        questionsByPlayer[question.playerId]!.add(question);
      }
      
      // Safety check: ensure we have questions grouped
      if (questionsByPlayer.isEmpty) {
        print('WARNING: No questions grouped by player');
        return Container(
          padding: EdgeInsets.all(16),
          child: Text(
            'No questions available',
            style: TextStyle(color: Colors.grey[400]),
          ),
        );
      }
      
      // Sort questions within each player by round index
      for (final playerId in questionsByPlayer.keys) {
        questionsByPlayer[playerId]!.sort((a, b) => a.roundIndex.compareTo(b.roundIndex));
      }
      final allQuestions = questions;
    
    return Container(
      constraints: BoxConstraints(
        minWidth: isMobile ? 0 : 500,
        maxWidth: isMobile ? double.infinity : 500,
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // No retry mode in player-based training - we always ask about all rounds
          Text(
            'Answer all questions:',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          // Show questions grouped by player
          ...() {
            try {
              final playerIds = questionsByPlayer.keys.toList();
              playerIds.sort();
              return playerIds.map((playerId) {
                final playerQuestions = questionsByPlayer[playerId];
                if (playerQuestions == null || playerQuestions.isEmpty) {
                  print('WARNING: No questions for player $playerId');
                  return SizedBox.shrink();
                }
                return _buildPlayerBox(context, isMobile, playerId, playerQuestions, allQuestions);
              });
            } catch (e, stackTrace) {
              print('ERROR in questions grouping: $e');
              print('Stack trace: $stackTrace');
              return [Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Error grouping questions: $e',
                  style: TextStyle(color: Colors.red),
                ),
              )];
            }
          }(),
          SizedBox(height: 16),
          // Submit button or Continue button
          if (!controller.showFeedback)
            ElevatedButton(
              onPressed: _areAllQuestionsAnswered(allQuestions)
                  ? controller.checkAnswer
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF16A34A),
                padding: EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: isMobile ? 12 : 16,
                ),
              ),
              child: Text(
                'Submit All Answers',
                style: TextStyle(color: Colors.white, fontSize: isMobile ? 14 : 16),
              ),
            )
          else
            ElevatedButton(
              onPressed: controller.continueAfterPlayerBasedFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                padding: EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: isMobile ? 12 : 16,
                ),
              ),
              child: Text(
                'Continue',
                style: TextStyle(color: Colors.white, fontSize: isMobile ? 14 : 16),
              ),
            ),
        ],
      ),
    );
    } catch (e, stackTrace) {
      print('ERROR in _buildPlayerBasedQuestionsPanel: $e');
      print('Stack trace: $stackTrace');
      return Container(
        padding: EdgeInsets.all(16),
        child: Text(
          'Error loading questions panel: $e',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  }
  
  Widget _buildPlayerBox(BuildContext context, bool isMobile, int playerId, List<PlayerBasedQuestion> playerQuestions, List<PlayerBasedQuestion> allQuestions) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Color(0xFF475569).withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFF64748B),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Player $playerId',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          ...playerQuestions.map((question) {
            final questionIndex = allQuestions.indexOf(question);
            if (questionIndex < 0) {
              print('ERROR: Question not found in allQuestions. Question: ${question.questionIndex}, player: ${question.playerId}, round: ${question.roundIndex}');
              return Container(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Error: Question not found',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _buildPlayerBasedQuestionRow(context, isMobile, question, questionIndex),
            );
          }),
        ],
      ),
    );
  }
  
  bool _areAllQuestionsAnswered(List<PlayerBasedQuestion> questions) {
    for (final question in questions) {
      if (!controller.playerBasedSelectedAnswers.containsKey(question.questionIndex)) {
        return false;
      }
    }
    return true;
  }
  
  Widget _buildPlayerBasedQuestionRow(BuildContext context, bool isMobile, PlayerBasedQuestion question, int index) {
    // Safety check: ensure round exists
    if (question.roundIndex < 0 || question.roundIndex >= controller.allRounds.length) {
      print('ERROR: Invalid round index in _buildPlayerBasedQuestionRow: ${question.roundIndex}, rounds length: ${controller.allRounds.length}');
      return Container(
        padding: EdgeInsets.all(8),
        child: Text(
          'Error: Invalid round index',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
    
    final round = controller.allRounds[question.roundIndex];
    if (round == null) {
      print('ERROR: Round is null at index ${question.roundIndex}');
      return Container(
        padding: EdgeInsets.all(8),
        child: Text(
          'Error: Round is null',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
    
    dynamic correctAnswer;
    try {
      correctAnswer = controller.getPlayerBasedAnswer(question);
    } catch (e, stackTrace) {
      print('ERROR: Failed to get answer for question ${question.questionIndex}: $e');
      print('Stack trace: $stackTrace');
      correctAnswer = null;
    }
    
    final selectedAnswer = controller.playerBasedSelectedAnswers[question.questionIndex];
    final isCorrectValue = controller.playerBasedAnswers[question.questionIndex];
    final showFeedback = controller.showFeedback && isCorrectValue != null;
    // isCorrectValue is a boolean: true if the answer was correct, false if wrong
    final isCorrect = isCorrectValue == true;
    
    // Safety check: if correctAnswer is null, handle gracefully
    if (correctAnswer == null && showFeedback) {
      print('WARNING: correctAnswer is null for question ${question.questionIndex}');
    }
    
    // Get round info for display
    final roundPlayerCount = round.activePlayers;
    
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: showFeedback
            ? Border.all(
                color: isCorrect ? Color(0xFF22C55E) : Color(0xFFEF4444),
                width: 2,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          _buildQuestionText(question, isMobile, roundPlayerCount),
          SizedBox(height: 12),
          // Answer buttons below the question (always visible)
          if (question.isSplitPhase) ...[
            // Yes/No buttons in a row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: controller.showFeedback
                        ? null
                        : () => controller.handlePlayerBasedAnswer(question.questionIndex, true),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: _getButtonColor(
                          selectedAnswer == true,
                          showFeedback,
                          isCorrect,
                          correctAnswer != null && correctAnswer == true,
                          true, // isYesButton
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Yes',
                        style: TextStyle(color: Colors.white, fontSize: isMobile ? 11 : 12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: controller.showFeedback
                        ? null
                        : () => controller.handlePlayerBasedAnswer(question.questionIndex, false),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: _getButtonColor(
                          selectedAnswer == false,
                          showFeedback,
                          isCorrect,
                          correctAnswer != null && correctAnswer == false,
                          false, // isYesButton
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'No',
                        style: TextStyle(color: Colors.white, fontSize: isMobile ? 11 : 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Player selector in a single row - fill available width
            Row(
              children: List.generate(10, (i) {
                final playerNum = i + 1;
                final isSelected = selectedAnswer == playerNum;
                final isCorrectAnswer = correctAnswer == playerNum;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 9 ? 4 : 0),
                    child: GestureDetector(
                      onTap: controller.showFeedback
                          ? null
                          : () => controller.handlePlayerBasedAnswer(question.questionIndex, playerNum),
                      child: Container(
                        height: isMobile ? 32 : 36,
                        decoration: BoxDecoration(
                          color: _getButtonColor(
                            isSelected,
                            showFeedback,
                            isCorrect,
                            isCorrectAnswer,
                            false, // not Yes/No button
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$playerNum',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
  
  Color _getButtonColor(bool isSelected, bool showFeedback, bool isCorrect, bool isCorrectAnswer, bool isYesButton) {
    if (!showFeedback) {
      // Before feedback: blue if selected, grey if not
      return isSelected ? Color(0xFF2563EB) : Color(0xFF475569);
    } else {
      // After feedback - prioritize correct answer highlighting
      if (isCorrectAnswer) {
        // This button is the correct answer: always green
        return Color(0xFF16A34A);
      } else if (isSelected) {
        // This button was selected but is not the correct answer: red
        return Color(0xFFEF4444);
      } else {
        // Not selected, not correct: grey
        return Color(0xFF475569);
      }
    }
  }
  
  Widget _buildQuestionText(PlayerBasedQuestion question, bool isMobile, int roundPlayerCount) {
    if (question.isSplitPhase) {
      // For split phase, mention which players were voted to exclude
      final player1 = question.splitPlayer1 ?? 0;
      final player2 = question.splitPlayer2 ?? 0;
      return RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: Colors.white,
          ),
          children: [
            TextSpan(text: 'Did '),
            TextSpan(
              text: 'Player ${question.playerId}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' vote to exclude '),
            TextSpan(
              text: 'Players $player1 & $player2',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: '?'),
          ],
        ),
      );
    } else {
      return RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: Colors.white,
          ),
          children: [
            TextSpan(text: 'Who did '),
            TextSpan(
              text: 'Player ${question.playerId}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' vote for in round ${question.roundIndex + 1} (${roundPlayerCount}p)?'),
          ],
        ),
      );
    }
  }

  List<Widget> _buildScoreList(BuildContext context, bool isMobile) {
    final scoreDisplay = <Widget>[];
    for (int roundIdx = 0; roundIdx <= controller.currentRoundIndex; roundIdx++) {
      if (roundIdx >= controller.allRounds.length) continue;
      final round = controller.allRounds[roundIdx];
      final originalScore = controller.calculateRoundScore(roundIdx);
      if (originalScore.isNotEmpty) {
        scoreDisplay.add(
          Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              '${isMobile ? 'R${roundIdx + 1}' : 'Round ${roundIdx + 1}'} (${round.activePlayers}p): ${originalScore['correct']}/${originalScore['total']}',
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: Colors.grey[300],
              ),
            ),
          ),
        );
      }

      if (roundIdx > 0 && roundIdx <= controller.currentRoundIndex) {
        for (int retryIdx = 0; retryIdx < roundIdx; retryIdx++) {
          final retryScore = controller.calculateRetryScore(retryIdx, roundIdx);
          if (retryScore.isNotEmpty) {
            final retryRound = controller.allRounds[retryIdx];
            scoreDisplay.add(
              Padding(
                padding: EdgeInsets.only(bottom: 4, left: 8),
                child: Text(
                  '🔄 ${isMobile ? 'R${retryIdx + 1}' : 'Retry R${retryIdx + 1}'} (${retryRound.activePlayers}p): ${retryScore['correct']}/${retryScore['total']}',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            );
          }
        }
        final selfRetry = controller.calculateRetryScore(roundIdx, roundIdx);
        if (selfRetry.isNotEmpty) {
          scoreDisplay.add(
            Padding(
              padding: EdgeInsets.only(bottom: 4, left: 8),
              child: Text(
                '🔄 ${isMobile ? 'R${roundIdx + 1}' : 'Retry R${roundIdx + 1}'} (${round.activePlayers}p): ${selfRetry['correct']}/${selfRetry['total']}',
                style: TextStyle(
                  fontSize: isMobile ? 10 : 12,
                  color: Colors.grey[400],
                ),
              ),
            ),
          );
        }
      }
    }
    return scoreDisplay;
  }
}

