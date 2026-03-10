import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_models.dart';

class GameController extends ChangeNotifier {
  GameState _gameState = GameState.setup;
  Difficulty _difficulty = Difficulty.medium;
  MemoryTrainType _memoryTrainType = MemoryTrainType.tableBased;
  List<Round> _allRounds = [];
  int _currentRoundIndex = 0;
  int _learningStep = 0;
  int _testingRoundIndex = 0;
  int _testingCandidateIndex = 0;
  List<int> _selectedPlayers = [];
  bool _showFeedback = false;
  // Player-based mode state
  Map<int, dynamic> _playerBasedAnswers = {}; // Map of questionIndex -> answer (bool for yes/no, int for player number)
  Map<int, dynamic> _playerBasedSelectedAnswers = {}; // Map of questionIndex -> currently selected answer (before submission)
  Map<int, PlayerState> _playerStates = {};
  List<Score> _scores = [];
  int _retryRoundIndex = 0;
  Map<String, int>? _returnToRetry;
  bool _nightPhaseProcessed = false;
  double _voteInterval = 3.5; // Default 3.5 seconds
  bool _isSplitPhase = false; // Track if we're in split phase
  bool _isReplaying = false; // Track if we're replaying (to skip elimination/kill processing in player-based mode)
  Map<String, int>? _replayState; // Store original round indices when replaying (for player-based mode)
  bool _isDevMode = false; // Developer mode flag
  bool _cancelInterval = false; // Cancel interval (dev mode only)
  int? _manualRound0VoteCount; // Manual vote count for round 0 (dev mode only)
  bool _autoFillRandomAnswers = false; // Auto fill random answers (dev mode only)
  bool _skipRound0Questions = false; // Skip round 0 questions in player-based mode

  // Practice split mode state
  int _practiceSplitMePlayer = 1;
  List<int> _practiceSplitNominated = [];
  int? _practiceSplitCorrectVote;
  List<bool> _practiceSplitScores = [];
  int _practiceSplitCurrentScenario = 0;
  static const int _practiceSplitTotalScenarios = 10;
  PracticeSplitPhase _practiceSplitPhase = PracticeSplitPhase.ready;
  int? _practiceSplitUserVote; // which nominee user voted for (first or second) for feedback display
  bool _practiceSplitVotedInFirst = false;
  bool _practiceSplitVotedInSecond = false;
  List<int> _practiceSplitVotersToFirst = [];
  List<int> _practiceSplitVotersToSecond = [];
  bool _practiceSplitOpenVote = true;
  int _practiceSplitVoteSeconds = 5;
  int _practiceSplitResultsSeconds = 5;
  bool _practiceSplitFixedSeat = false; // false = random seat every question (default)
  int _practiceSplitFixedSeatPlayerId = 1; // when fixed seat, which player 1-10

  // Getters
  GameState get gameState => _gameState;
  Difficulty get difficulty => _difficulty;
  MemoryTrainType get memoryTrainType => _memoryTrainType;
  List<Round> get allRounds => _allRounds;
  int get currentRoundIndex => _currentRoundIndex;
  int get learningStep => _learningStep;
  int get testingRoundIndex => _testingRoundIndex;
  int get testingCandidateIndex => _testingCandidateIndex;
  List<int> get selectedPlayers => _selectedPlayers;
  bool get showFeedback => _showFeedback;
  // Player-based mode getters
  Map<int, dynamic> get playerBasedAnswers => _playerBasedAnswers; // Final submitted answers
  Map<int, dynamic> get playerBasedSelectedAnswers => _playerBasedSelectedAnswers; // Currently selected answers (before submission)
  Map<int, PlayerState> get playerStates => _playerStates;
  List<Score> get scores => _scores;
  int get retryRoundIndex => _retryRoundIndex;
  Map<String, int>? get returnToRetry => _returnToRetry;
  double get voteInterval => _voteInterval;
  bool get isSplitPhase => _isSplitPhase;
  bool get isDevMode => _isDevMode;
  bool get cancelInterval => _cancelInterval;
  int? get manualRound0VoteCount => _manualRound0VoteCount;
  bool get autoFillRandomAnswers => _autoFillRandomAnswers;
  bool get skipRound0Questions => _skipRound0Questions;

  // Practice split getters
  int get practiceSplitMePlayer => _practiceSplitMePlayer;
  List<int> get practiceSplitNominated => List.unmodifiable(_practiceSplitNominated);
  int? get practiceSplitCorrectVote => _practiceSplitCorrectVote;
  List<bool> get practiceSplitScores => List.unmodifiable(_practiceSplitScores);
  int get practiceSplitCurrentScenario => _practiceSplitCurrentScenario;
  int get practiceSplitTotalScenarios => _practiceSplitTotalScenarios;
  PracticeSplitPhase get practiceSplitPhase => _practiceSplitPhase;
  int? get practiceSplitUserVote => _practiceSplitUserVote;
  bool get practiceSplitVotedInFirst => _practiceSplitVotedInFirst;
  bool get practiceSplitVotedInSecond => _practiceSplitVotedInSecond;
  List<int> get practiceSplitVotersToFirst => List.unmodifiable(_practiceSplitVotersToFirst);
  List<int> get practiceSplitVotersToSecond => List.unmodifiable(_practiceSplitVotersToSecond);
  bool get practiceSplitOpenVote => _practiceSplitOpenVote;
  int get practiceSplitVoteSeconds => _practiceSplitVoteSeconds;
  int get practiceSplitResultsSeconds => _practiceSplitResultsSeconds;
  bool get practiceSplitFixedSeat => _practiceSplitFixedSeat;
  int get practiceSplitFixedSeatPlayerId => _practiceSplitFixedSeatPlayerId;

  void setPracticeSplitOpenVote(bool value) {
    _practiceSplitOpenVote = value;
    notifyListeners();
  }

  void setPracticeSplitVoteSeconds(int value) {
    _practiceSplitVoteSeconds = value.clamp(1, 15);
    notifyListeners();
  }

  void setPracticeSplitResultsSeconds(int value) {
    _practiceSplitResultsSeconds = value.clamp(1, 15);
    notifyListeners();
  }

  void setPracticeSplitFixedSeat(bool value) {
    _practiceSplitFixedSeat = value;
    notifyListeners();
  }

  void setPracticeSplitFixedSeatPlayerId(int value) {
    _practiceSplitFixedSeatPlayerId = value.clamp(1, 10);
    notifyListeners();
  }

  void setDifficulty(Difficulty difficulty) {
    _difficulty = difficulty;
    notifyListeners();
  }

  void setMemoryTrainType(MemoryTrainType type) {
    _memoryTrainType = type;
    notifyListeners();
  }

  void setGameState(GameState state) {
    _gameState = state;
    notifyListeners();
  }

  void setVoteInterval(double interval) {
    _voteInterval = interval;
    notifyListeners();
  }

  void setDevMode(bool enabled) {
    _isDevMode = enabled;
    // If dev mode is disabled, also disable cancel interval and auto-fill
    if (!enabled) {
      _cancelInterval = false;
      _autoFillRandomAnswers = false;
    }
    notifyListeners();
  }

  void setCancelInterval(bool enabled) {
    if (!_isDevMode) return; // Only allow if dev mode is enabled
    _cancelInterval = enabled;
    notifyListeners();
  }

  void setManualRound0VoteCount(int? count) {
    if (!_isDevMode) return; // Only allow if dev mode is enabled
    _manualRound0VoteCount = count;
    notifyListeners();
  }
  
  void setAutoFillRandomAnswers(bool enabled) {
    if (!_isDevMode) return; // Only allow if dev mode is enabled
    _autoFillRandomAnswers = enabled;
    notifyListeners();
  }
  
  void setSkipRound0Questions(bool enabled) {
    _skipRound0Questions = enabled;
    notifyListeners();
  }

  void setPracticeSplitMePlayer(int playerId) {
    if (playerId < 1 || playerId > 10) return;
    _practiceSplitMePlayer = playerId;
    notifyListeners();
  }

  /// Split rules for 2 players:
  /// - (1, X) with X in 2-6: 2-6 vote to 1, rest (1,7,8,9,10) vote to X. 1 never votes to himself.
  /// - (X, Y) with X in 1-5, Y in 6-10: 1-5 vote to Y, 6-10 vote to X.
  /// - Without 1: (low, high) e.g. 3,4 — "4+4": players high..high+4 vote to low; rest vote to high.
  int? _getCorrectVoteForSplit(int mePlayer, List<int> nominated) {
    if (nominated.length != 2) return null;
    final first = nominated[0];
    final second = nominated[1];
    final low = first < second ? first : second;
    final high = first < second ? second : first;
    final lowIn15 = low >= 1 && low <= 5;
    final highIn15 = high >= 1 && high <= 5;
    final lowIn610 = low >= 6 && low <= 10;
    final highIn610 = high >= 6 && high <= 10;

    // Split without 1: e.g. 3,4 → 4,5,6,7,8 vote to 3; rest vote to 4
    if (low != 1) {
      final votersToLow = <int>[];
      for (int i = 0; i < 5; i++) {
        int p = high + i;
        if (p > 10) p -= 10;
        votersToLow.add(p);
      }
      return votersToLow.contains(mePlayer) ? low : high;
    }

    // Split with 1: (1, X) where X in 2-6 → 2-6 vote to 1, 1 and 7-10 vote to X (1 never votes to himself)
    if (lowIn15 && highIn15) {
      if (mePlayer >= 2 && mePlayer <= 6) return low;   // 2-6 vote to 1
      if (mePlayer >= 7 && mePlayer <= 10) return high; // 7-10 vote to X
      if (mePlayer == 1) return high;                   // 1 votes to X, never to himself
      return low;
    }
    // Split (X, Y) with X in 1-5, Y in 6-10: 1-5 vote to Y, 6-10 vote to X
    if ((lowIn15 && highIn610) || (lowIn610 && highIn15)) {
      final player15 = lowIn15 ? low : high;
      final player610 = lowIn610 ? low : high;
      if (mePlayer >= 1 && mePlayer <= 5) return player610;
      if (mePlayer >= 6 && mePlayer <= 10) return player15;
    }
    return null;
  }

  /// Returns list of players (1-10) who vote to [nominee] by split rules. Split players vote for the other nominee, not themselves.
  List<int> _getVotersToNominee(int nominee, List<int> nominated) {
    if (nominated.length != 2) return [];
    final voters = <int>[];
    for (int p = 1; p <= 10; p++) {
      final correctVote = _getCorrectVoteForSplit(p, nominated);
      if (correctVote == nominee) voters.add(p);
    }
    return voters;
  }

  void _computeAndSetVotersForResults() {
    if (_practiceSplitNominated.length != 2) return;
    final first = _practiceSplitNominated[0];
    final second = _practiceSplitNominated[1];
    final me = _practiceSplitMePlayer;
    // Simulated voters only (exclude "me"); never simulate ME's vote
    final toFirst = _getVotersToNominee(first, _practiceSplitNominated).where((p) => p != me).toList();
    final toSecond = _getVotersToNominee(second, _practiceSplitNominated).where((p) => p != me).toList();
    // Add "me" to the list for the phase they actually voted in so results always show the user's vote (even when wrong, e.g. voting for self)
    if (_practiceSplitVotedInFirst) {
      _practiceSplitVotersToFirst = [...toFirst, me]..sort();
    } else {
      _practiceSplitVotersToFirst = toFirst;
    }
    final meVotedInSecond = _practiceSplitVotedInSecond || (!_practiceSplitVotedInFirst && !_practiceSplitVotedInSecond);
    if (meVotedInSecond) {
      _practiceSplitVotersToSecond = [...toSecond, me]..sort();
    } else {
      _practiceSplitVotersToSecond = toSecond;
    }
  }

  void startPracticeSplitGame() {
    _practiceSplitScores = [];
    _practiceSplitCurrentScenario = 0;
    _practiceSplitPhase = PracticeSplitPhase.ready;
    _practiceSplitUserVote = null;
    _practiceSplitVotedInFirst = false;
    _practiceSplitVotedInSecond = false;
    _practiceSplitVotersToFirst = [];
    _practiceSplitVotersToSecond = [];
    _gameState = GameState.practiceSplit;
    _memoryTrainType = MemoryTrainType.practiceSplit;
    if (_practiceSplitFixedSeat) {
      _practiceSplitMePlayer = _practiceSplitFixedSeatPlayerId;
    }
    notifyListeners();
    _generateNextPracticeSplitScenario();
  }

  void _generateNextPracticeSplitScenario() {
    final random = math.Random();
    if (!_practiceSplitFixedSeat) {
      _practiceSplitMePlayer = random.nextInt(10) + 1;
    }
    List<int> nominated;
    if (random.nextDouble() < 0.9) {
      // 90%: split with 1 and another player (2-10)
      final other = random.nextInt(9) + 2; // 2..10
      nominated = [1, other]..sort();
    } else {
      // 10%: split without 1, e.g. 3 and 4 (two from 2-10, distinct)
      final from210 = [2, 3, 4, 5, 6, 7, 8, 9, 10]..shuffle(random);
      nominated = [from210[0], from210[1]]..sort();
    }
    _practiceSplitNominated = nominated;
    _practiceSplitCorrectVote = _getCorrectVoteForSplit(_practiceSplitMePlayer, nominated);
    _practiceSplitUserVote = null;
    _practiceSplitVotedInFirst = false;
    _practiceSplitVotedInSecond = false;
    _practiceSplitPhase = PracticeSplitPhase.ready;
    notifyListeners();
  }

  void handlePracticeSplitReady() {
    if (_gameState != GameState.practiceSplit) return;
    if (_practiceSplitPhase != PracticeSplitPhase.ready) return;
    final voteSec = _practiceSplitVoteSeconds;
    final resultsSec = _practiceSplitResultsSeconds;
    _practiceSplitPhase = PracticeSplitPhase.votingToFirst;
    notifyListeners();
    Future.delayed(Duration(seconds: voteSec), () {
      if (_gameState != GameState.practiceSplit) return;
      if (_practiceSplitPhase != PracticeSplitPhase.votingToFirst) return;
      if (_practiceSplitOpenVote) {
        _computeAndSetVotersForResults();
        _practiceSplitPhase = PracticeSplitPhase.showingResultsFirst;
        notifyListeners();
        Future.delayed(Duration(seconds: resultsSec), () {
          if (_gameState != GameState.practiceSplit) return;
          _practiceSplitPhase = PracticeSplitPhase.votingToSecond;
          notifyListeners();
          _afterVotingToSecond(voteSec, resultsSec);
        });
      } else {
        _practiceSplitPhase = PracticeSplitPhase.votingToSecond;
        notifyListeners();
        _afterVotingToSecond(voteSec, resultsSec);
      }
    });
  }

  void _afterVotingToSecond(int voteSec, int resultsSec) {
    Future.delayed(Duration(seconds: voteSec), () {
      if (_gameState != GameState.practiceSplit) return;
      if (_practiceSplitPhase != PracticeSplitPhase.votingToSecond) return;
      _computeAndSetVotersForResults();
      if (_practiceSplitOpenVote) {
        _practiceSplitPhase = PracticeSplitPhase.showingResultsSecond;
        notifyListeners();
        Future.delayed(Duration(seconds: resultsSec), () {
          if (_gameState != GameState.practiceSplit) return;
          _finishPracticeSplitScenario();
        });
      } else {
        _practiceSplitPhase = PracticeSplitPhase.showingResultsFirst;
        notifyListeners();
        Future.delayed(Duration(seconds: resultsSec), () {
          if (_gameState != GameState.practiceSplit) return;
          _practiceSplitPhase = PracticeSplitPhase.showingResultsSecond;
          notifyListeners();
          Future.delayed(Duration(seconds: resultsSec), () {
            if (_gameState != GameState.practiceSplit) return;
            _finishPracticeSplitScenario();
          });
        });
      }
    });
  }

  void _finishPracticeSplitScenario() {
    final first = _practiceSplitNominated[0];
    final second = _practiceSplitNominated[1];
    // If ME didn't vote to any nominee, it counts as voting for the last candidate (second)
    final effectiveVote = _practiceSplitVotedInFirst ? first : second;
    final correct = effectiveVote == _practiceSplitCorrectVote;
    _practiceSplitUserVote = effectiveVote;
    _practiceSplitScores.add(correct);
    _practiceSplitPhase = PracticeSplitPhase.feedback;
    notifyListeners();
    _scheduleNextPracticeSplit();
  }

  void _scheduleNextPracticeSplit() {
    Future.delayed(Duration(milliseconds: 1500), () {
      if (_gameState != GameState.practiceSplit) return;
      _practiceSplitCurrentScenario++;
      if (_practiceSplitCurrentScenario >= _practiceSplitTotalScenarios) {
        _practiceSplitPhase = PracticeSplitPhase.results;
        notifyListeners();
      } else {
        _generateNextPracticeSplitScenario();
      }
    });
  }

  void handlePracticeSplitCastVote() {
    if (_gameState != GameState.practiceSplit) return;
    if (_practiceSplitPhase == PracticeSplitPhase.votingToFirst) {
      if (!_practiceSplitVotedInFirst && !_practiceSplitVotedInSecond) {
        _practiceSplitVotedInFirst = true;
        notifyListeners();
      }
    } else if (_practiceSplitPhase == PracticeSplitPhase.votingToSecond) {
      if (!_practiceSplitVotedInFirst && !_practiceSplitVotedInSecond) {
        _practiceSplitVotedInSecond = true;
        notifyListeners();
      }
    }
  }

  void handlePracticeSplitVote(int playerId) {
    if (_gameState != GameState.practiceSplit) return;
    if (_practiceSplitNominated.length != 2) return;
    if (_practiceSplitVotedInFirst || _practiceSplitVotedInSecond) return;
    final first = _practiceSplitNominated[0];
    final second = _practiceSplitNominated[1];
    if (_practiceSplitPhase == PracticeSplitPhase.votingToFirst && playerId == first) {
      _practiceSplitVotedInFirst = true;
      notifyListeners();
    } else if (_practiceSplitPhase == PracticeSplitPhase.votingToSecond && playerId == second) {
      _practiceSplitVotedInSecond = true;
      notifyListeners();
    }
  }

  void autoFillAnswers() {
    if (!_isDevMode || !_autoFillRandomAnswers) return;
    
    if (_memoryTrainType == MemoryTrainType.playerBased) {
      _autoFillPlayerBasedAnswers();
    } else {
      _autoFillTableBasedAnswers();
    }
  }
  
  void _autoFillPlayerBasedAnswers() {
    final questions = getPlayerBasedQuestions();
    final random = math.Random();
    
    for (final question in questions) {
      if (_playerBasedSelectedAnswers.containsKey(question.questionIndex)) continue;
      
      if (question.isSplitPhase) {
        // Random yes/no
        _playerBasedSelectedAnswers[question.questionIndex] = random.nextBool();
      } else {
        // Random player number (1-10)
        _playerBasedSelectedAnswers[question.questionIndex] = random.nextInt(10) + 1;
      }
    }
    notifyListeners();
  }
  
  void _autoFillTableBasedAnswers() {
    if (_gameState != GameState.testing && _gameState != GameState.retry) return;
    if (_testingRoundIndex < 0 || _testingRoundIndex >= _allRounds.length) return;
    
    final currentRound = _allRounds[_testingRoundIndex];
    if (currentRound.votes.isEmpty && currentRound.splitPhase == null) return;
    
    // Handle split phase
    if (currentRound.splitPhase != null && _isSplitPhase) {
      final splitPhase = currentRound.splitPhase!;
      final random = math.Random();
      
      // Randomly select some voters (not necessarily correct)
      final activePlayers = List.generate(10, (i) => i + 1)
          .where((p) => !_playerStates.containsKey(p))
          .where((p) => p != splitPhase.player1 && p != splitPhase.splitPartner)
          .toList();
      
      if (activePlayers.isEmpty) return;
      
      final numToSelect = random.nextInt(activePlayers.length) + 1;
      activePlayers.shuffle(random);
      _selectedPlayers = activePlayers.take(numToSelect).toList();
      notifyListeners();
      return;
    }
    
    // Regular voting phase
    if (_testingCandidateIndex < 0 || _testingCandidateIndex >= currentRound.votes.length) return;
    
    final currentVote = currentRound.votes[_testingCandidateIndex];
    
    // Get active players (excluding candidate and inactive players)
    final relevantPlayerStates = _gameState == GameState.retry
        ? getPlayerStatesForRound(_testingRoundIndex)
        : _playerStates;
    
    final activePlayers = List.generate(10, (i) => i + 1)
        .where((p) => !relevantPlayerStates.containsKey(p))
        .where((p) => p != currentVote.candidate)
        .toList();
    
    if (activePlayers.isEmpty) return;
    
    final random = math.Random();
    final numToSelect = random.nextInt(activePlayers.length) + 1;
    activePlayers.shuffle(random);
    _selectedPlayers = activePlayers.take(numToSelect).toList();
    notifyListeners();
  }

  // Helper method to get delay duration - returns 0 if cancel interval is enabled
  Duration _getDelay(int milliseconds) {
    if (_cancelInterval) return Duration.zero;
    return Duration(milliseconds: milliseconds);
  }

  void startGame() {
    // Start with all 10 players active for split phase
    // No initial kill - split phase happens before night phase
    final newPlayerStates = <int, PlayerState>{};

    _playerStates = newPlayerStates;
    _allRounds = [];
    _currentRoundIndex = 0;
    _scores = [];
    _nightPhaseProcessed = false;
    _isSplitPhase = false;
    notifyListeners();

    // Generate split phase first (round 0) with all 10 players
    generateSplitPhase(newPlayerStates);
  }

  void generateSplitPhase(Map<int, PlayerState> currentPlayerStates) {
    final random = math.Random();
    final activePlayers = List.generate(10, (i) => i + 1)
        .where((p) => !currentPlayerStates.containsKey(p))
        .toList();

    // Player 1 splits with one of players 2-6
    final possiblePartners = [2, 3, 4, 5, 6].where((p) => activePlayers.contains(p)).toList();
    if (possiblePartners.isEmpty) {
      // Fallback: use any active player except 1
      final fallbackPartners = activePlayers.where((p) => p != 1).toList();
      if (fallbackPartners.isEmpty) {
        // No valid partners, skip split phase
        generateRound(9, currentPlayerStates);
        return;
      }
      possiblePartners.addAll(fallbackPartners);
    }
    final splitPartner = possiblePartners[random.nextInt(possiblePartners.length)];

    // 80% chance: 1-5 votes, 20% chance: 6-8 votes
    // Or use manual vote count if set in dev mode
    final voteCount = _manualRound0VoteCount ?? (random.nextDouble() < 0.8
        ? random.nextInt(5) + 1 // 1-5 votes (80%)
        : random.nextInt(3) + 6); // 6-8 votes (20%)

    // Select voters from active players (excluding player 1 and split partner)
    // This ensures split players never vote to exclude themselves
    final possibleVoters = activePlayers.where((p) => p != 1 && p != splitPartner).toList();
    possibleVoters.shuffle(random);
    final voters = possibleVoters.take(voteCount).toList()..sort();

    final splitPhase = SplitPhase(
      player1: 1,
      splitPartner: splitPartner,
      voters: voters,
      voteCount: voteCount,
    );

    // Create round 0 with split phase
    final newRound = Round(
      votes: [], // No regular votes in split phase
      candidates: [],
      activePlayers: 10,
      splitPhase: splitPhase,
    );

    _allRounds = [newRound];
    _currentRoundIndex = 0;
    _isSplitPhase = true;
    _gameState = GameState.learning;
    _learningStep = 0;
    notifyListeners();

    // Start learning phase for split phase (just show it once, no multiple steps)
    // In player-based mode, we don't test after split phase - we test before the next round
    Future.delayed(_getDelay((_voteInterval * 1000).round()), () {
      if (_gameState == GameState.learning && _isSplitPhase) {
        Future.delayed(_getDelay(1500), () {
          if (_memoryTrainType == MemoryTrainType.playerBased) {
            // In player-based mode, process split phase results and continue to next round
            // (which will ask questions about previous rounds before learning)
            // BUT skip this if we're replaying (to avoid killing/eliminating players again)
            if (_isReplaying) {
              // During replay, just go back to testing without processing eliminations/kills
              // Safety check: ensure we're still in learning state
              if (_gameState == GameState.learning) {
                _isReplaying = false; // Clear replay flag
                _isSplitPhase = false;
                startTesting();
              } else {
                // State changed unexpectedly, clear flag and try to recover
                _isReplaying = false;
                _isSplitPhase = false;
                _gameState = GameState.testing;
                _testingRoundIndex = _currentRoundIndex;
                notifyListeners();
              }
            } else {
              final splitPhase = _allRounds[0].splitPhase!;
              
              if (splitPhase.voteCount >= 6) {
                // Both players eliminated, then one killed
                final newPlayerStates = Map<int, PlayerState>.from(_playerStates);
                newPlayerStates[splitPhase.player1] = PlayerState(
                  status: PlayerStatus.eliminated,
                  round: 0,
                );
                newPlayerStates[splitPhase.splitPartner] = PlayerState(
                  status: PlayerStatus.eliminated,
                  round: 0,
                );
                
                // Kill one more player
                final activePlayers = List.generate(10, (i) => i + 1)
                    .where((p) => !newPlayerStates.containsKey(p))
                    .toList();
                if (activePlayers.isNotEmpty) {
                  final random = math.Random();
                  final killed = activePlayers[random.nextInt(activePlayers.length)];
                  newPlayerStates[killed] = PlayerState(
                    status: PlayerStatus.killed,
                    round: 0,
                  );
                }
                
                _playerStates = newPlayerStates;
                _isSplitPhase = false;
                _nightPhaseProcessed = true;
                notifyListeners();
              } else {
                // Not enough votes, kill one player
                final random = math.Random();
                final activePlayers = List.generate(10, (i) => i + 1)
                    .where((p) => !_playerStates.containsKey(p))
                    .toList();
                
                if (activePlayers.isNotEmpty) {
                  final killed = activePlayers[random.nextInt(activePlayers.length)];
                  final newPlayerStates = Map<int, PlayerState>.from(_playerStates);
                  newPlayerStates[killed] = PlayerState(
                    status: PlayerStatus.killed,
                    round: 0,
                  );
                  _playerStates = newPlayerStates;
                }
                
                _isSplitPhase = false;
                _nightPhaseProcessed = true;
                notifyListeners();
              }
            }
          } else {
            // Table-based mode: start testing after split phase
            startTesting();
          }
        });
      }
    });
  }

  void generateRound(int numActivePlayers, Map<int, PlayerState> currentPlayerStates) {
    final activePlayers = List.generate(10, (i) => i + 1)
        .where((p) => !currentPlayerStates.containsKey(p))
        .toList();

    int numCandidates;
    switch (_difficulty) {
      case Difficulty.easy:
        numCandidates = math.min(3, numActivePlayers);
        break;
      case Difficulty.medium:
        numCandidates = math.min(5, numActivePlayers);
        break;
      case Difficulty.hard:
        numCandidates = math.min(7, numActivePlayers);
        break;
    }

    final random = math.Random();
    final candidates = <int>[];
    while (candidates.length < numCandidates) {
      final candidate = activePlayers[random.nextInt(activePlayers.length)];
      if (!candidates.contains(candidate)) {
        candidates.add(candidate);
      }
    }

    final votingData = <VoteData>[];
    for (final candidate in candidates) {
      votingData.add(VoteData(
        candidate: candidate,
        voters: [],
        count: 0,
      ));
    }

    for (final voter in activePlayers) {
      final validCandidates = candidates.where((c) => c != voter).toList();
      if (validCandidates.isNotEmpty) {
        final chosenCandidate = validCandidates[random.nextInt(validCandidates.length)];
        final candidateData = votingData.firstWhere((v) => v.candidate == chosenCandidate);
        candidateData.voters.add(voter);
        candidateData.count++;
      }
    }

    for (final vote in votingData) {
      vote.voters.sort();
    }

    final newRound = Round(
      votes: votingData,
      candidates: candidates,
      activePlayers: numActivePlayers,
    );

    _allRounds = [..._allRounds, newRound];
    
    // If we're in retry mode, skip learning phase and go directly to testing
    if (_gameState == GameState.retry) {
      _gameState = GameState.retry;
      _testingRoundIndex = _currentRoundIndex;
      _testingCandidateIndex = 0;
      _selectedPlayers = [];
      _showFeedback = false;
      notifyListeners();
    } else {
      _gameState = GameState.learning;
      _learningStep = 0;
      notifyListeners();
      _startLearningPhase();
    }
  }

  void _startLearningPhase() {
    try {
      if (_gameState == GameState.learning && _allRounds.isNotEmpty) {
        // Safety check: ensure round index is valid
        if (_currentRoundIndex < 0 || _currentRoundIndex >= _allRounds.length) {
          print('ERROR: Invalid round index in _startLearningPhase: $_currentRoundIndex, rounds length: ${_allRounds.length}');
          return;
        }
        
        final currentRound = _allRounds[_currentRoundIndex];
        
        // Safety check: ensure round is not null
        if (currentRound == null) {
          print('ERROR: Round is null at index $_currentRoundIndex');
          return;
        }
        
        // Skip learning phase for split phase (handled separately)
        if (currentRound.splitPhase != null) {
          return;
        }
        
        // Safety check: ensure votes exist
        if (currentRound.votes.isEmpty) {
          print('WARNING: Round $_currentRoundIndex has no votes in _startLearningPhase');
          return;
        }
        
        // Store votes length in a local variable to avoid accessing it in delayed callback
        final votesLength = currentRound.votes.length;
        
        Future.delayed(_getDelay((_voteInterval * 1000).round()), () {
          try {
            // Re-validate state before proceeding
            if (_gameState != GameState.learning) {
              print('WARNING: Game state changed from learning to ${_gameState} during _startLearningPhase delay');
              return;
            }
            
            // Re-validate round index
            if (_currentRoundIndex < 0 || _currentRoundIndex >= _allRounds.length) {
              print('ERROR: Round index became invalid during _startLearningPhase delay: $_currentRoundIndex');
              return;
            }
            
            // Re-get current round to ensure it's still valid
            final currentRoundCheck = _allRounds[_currentRoundIndex];
            if (currentRoundCheck == null || currentRoundCheck.votes.isEmpty) {
              print('ERROR: Round became invalid during _startLearningPhase delay');
              return;
            }
            
            if (_learningStep < votesLength - 1) {
              _learningStep++;
              notifyListeners();
              _startLearningPhase();
            } else {
              Future.delayed(_getDelay(1500), () {
                try {
                  // Re-validate state again before processing
                  if (_gameState != GameState.learning) {
                    print('WARNING: Game state changed from learning to ${_gameState} during _startLearningPhase completion delay');
                    return;
                  }
                  
                  // In player-based mode, process eliminations/kills and show night phase
                  // BUT skip this if we're replaying (to avoid killing/eliminating players again)
                  // In table-based mode, start testing phase for current round
                  if (_memoryTrainType == MemoryTrainType.playerBased) {
                    if (_isReplaying) {
                      // During replay, just go back to testing without processing eliminations/kills
                      // Safety check: ensure we're still in learning state and have valid round index
                      if (_gameState == GameState.learning && 
                          _currentRoundIndex >= 0 && 
                          _currentRoundIndex < _allRounds.length) {
                        // Restore original round indices before going back to testing
                        if (_replayState != null) {
                          _currentRoundIndex = _replayState!['originalCurrentRoundIndex']!;
                          _testingRoundIndex = _replayState!['originalTestingRoundIndex']!;
                          _replayState = null;
                        }
                        _isReplaying = false; // Clear replay flag
                        startTesting();
                      } else {
                        // State changed unexpectedly, clear flag and try to recover
                        print('WARNING: State changed during replay, recovering...');
                        _isReplaying = false;
                        _replayState = null;
                        _gameState = GameState.testing;
                        if (_currentRoundIndex >= 0 && _currentRoundIndex < _allRounds.length) {
                          _testingRoundIndex = _currentRoundIndex;
                        }
                        notifyListeners();
                      }
                    } else {
                      _processEliminationAndKillInternal();
                    }
                  } else {
                    startTesting();
                  }
                } catch (e, stackTrace) {
                  print('ERROR in _startLearningPhase completion callback: $e');
                  print('Stack trace: $stackTrace');
                  // Try to recover
                  _isReplaying = false;
                  _replayState = null;
                  _gameState = GameState.testing;
                  if (_currentRoundIndex >= 0 && _currentRoundIndex < _allRounds.length) {
                    _testingRoundIndex = _currentRoundIndex;
                  }
                  notifyListeners();
                }
              });
            }
          } catch (e, stackTrace) {
            print('ERROR in _startLearningPhase delay callback: $e');
            print('Stack trace: $stackTrace');
            // Try to recover
            _isReplaying = false;
            _replayState = null;
            _gameState = GameState.testing;
            if (_currentRoundIndex >= 0 && _currentRoundIndex < _allRounds.length) {
              _testingRoundIndex = _currentRoundIndex;
            }
            notifyListeners();
          }
        });
      }
    } catch (e, stackTrace) {
      print('ERROR in _startLearningPhase: $e');
      print('Stack trace: $stackTrace');
      // Try to recover
      _isReplaying = false;
      _replayState = null;
      _gameState = GameState.testing;
      if (_currentRoundIndex >= 0 && _currentRoundIndex < _allRounds.length) {
        _testingRoundIndex = _currentRoundIndex;
      }
      notifyListeners();
    }
  }


  void startTesting() {
    try {
      if (_returnToRetry != null) {
      // When restoring from replay in retry mode:
      // - 'retryRound' is the round we just replayed (and want to continue testing)
      // - 'currentRound' is the last completed round (needed for retry logic)
      final retryRound = _returnToRetry!['retryRound']!;
      final savedCurrentRound = _returnToRetry!['currentRound']!;
      
      // Set testing round to the round we're testing in retry (the one we just replayed)
      _testingRoundIndex = retryRound;
      _retryRoundIndex = retryRound; // Set retryRoundIndex to match the round we're testing
      
      // Restore _currentRoundIndex to the saved value (last completed round)
      // This is needed for retry logic to work correctly
      _currentRoundIndex = savedCurrentRound;
      
      _gameState = GameState.retry;
      _returnToRetry = null;
      
      // Check if starting with split phase round
      if (_testingRoundIndex < _allRounds.length && 
          _allRounds[_testingRoundIndex].splitPhase != null) {
        _isSplitPhase = true;
      } else {
        _isSplitPhase = false;
      }
    } else {
      _gameState = GameState.testing;
      _testingRoundIndex = _currentRoundIndex;
    }
    
    // Safety check: ensure current round index is valid (especially important for player-based mode)
    if (_currentRoundIndex < 0 || _currentRoundIndex >= _allRounds.length) {
      print('ERROR: Invalid current round index in startTesting: $_currentRoundIndex, rounds length: ${_allRounds.length}');
      return;
    }
    
    // Safety check: ensure testing round index is valid
    if (_testingRoundIndex < 0 || _testingRoundIndex >= _allRounds.length) {
      print('ERROR: Invalid testing round index in startTesting: $_testingRoundIndex, rounds length: ${_allRounds.length}');
      return;
    }
    
    // Safety check: if testing split phase, ensure it's actually a split phase
    final testRound = _allRounds[_testingRoundIndex];
    if (testRound.splitPhase != null && !_isSplitPhase) {
      // Set split phase flag if we're testing a split phase round
      _isSplitPhase = true;
    }
    
    _testingCandidateIndex = 0;
    _selectedPlayers = [];
    _showFeedback = false;
    
    // Initialize player-based mode state if needed
    if (_memoryTrainType == MemoryTrainType.playerBased) {
      _playerBasedSelectedAnswers = {}; // Reset selected answers
      _playerBasedAnswers = {}; // Reset submitted answers
    }
    
    notifyListeners();
    
    // Auto-fill random answers if enabled (after a short delay to ensure UI is ready)
    Future.delayed(Duration(milliseconds: 100), () {
      autoFillAnswers();
    });
    } catch (e, stackTrace) {
      print('ERROR in startTesting: $e');
      print('Stack trace: $stackTrace');
      // Try to recover
      _isReplaying = false;
      _gameState = GameState.testing;
      if (_currentRoundIndex >= 0 && _currentRoundIndex < _allRounds.length) {
        _testingRoundIndex = _currentRoundIndex;
      }
      notifyListeners();
    }
  }

  void handlePlayerClick(int playerId) {
    if (_gameState != GameState.testing && _gameState != GameState.retry) return;
    if (_showFeedback) return;
    
    // In player-based mode, handle differently - but this shouldn't be called for player-based mode
    // Player-based mode uses handlePlayerBasedAnswer instead
    if (_memoryTrainType == MemoryTrainType.playerBased) {
      return;
    }

    final relevantPlayerStates = _gameState == GameState.retry
        ? getPlayerStatesForRound(_testingRoundIndex)
        : _playerStates;

    if (relevantPlayerStates.containsKey(playerId)) return;

    if (_selectedPlayers.contains(playerId)) {
      _selectedPlayers.remove(playerId);
    } else {
      _selectedPlayers.add(playerId);
    }
    notifyListeners();
  }
  
  void handlePlayerBasedAnswer(int questionIndex, dynamic answer) {
    if (_gameState != GameState.testing && _gameState != GameState.retry) return;
    if (_showFeedback) return;
    if (_memoryTrainType != MemoryTrainType.playerBased) return;
    
    _playerBasedSelectedAnswers[questionIndex] = answer;
    notifyListeners();
  }

  // Get list of player-based questions for all previous rounds (before current round)
  // Only includes questions for currently living (active) players at the START of current round
  List<PlayerBasedQuestion> getPlayerBasedQuestions() {
    final questions = <PlayerBasedQuestion>[];
    int questionIndex = 0;
    
    // Safety check: ensure we have rounds
    if (_allRounds.isEmpty) {
      print('ERROR: No rounds available in getPlayerBasedQuestions');
      return questions;
    }
    
    // Safety check: ensure current round index is valid
    if (_currentRoundIndex < 0) {
      print('ERROR: Invalid current round index: $_currentRoundIndex');
      return questions;
    }
    
    // Get currently active (living) players at the START of current round
    // These are players who haven't been eliminated/killed yet (before current round's eliminations)
    final activePlayers = List.generate(10, (i) => i + 1)
        .where((p) {
          if (!_playerStates.containsKey(p)) {
            // Player is still alive
            return true;
          } else {
            // Player was eliminated/killed - check if it was in a future round
            final eliminationRound = _playerStates[p]!.round;
            return eliminationRound >= _currentRoundIndex;
          }
        })
        .toList();
    
    print('DEBUG: getPlayerBasedQuestions - currentRoundIndex: $_currentRoundIndex, activePlayers: $activePlayers');
    
    // Add questions for all PREVIOUS rounds (up to but NOT including current round)
    for (int roundIdx = 0; roundIdx < _currentRoundIndex && roundIdx < _allRounds.length; roundIdx++) {
      // Skip round 0 if setting is enabled
      if (_skipRound0Questions && roundIdx == 0) {
        continue;
      }
      
      // Safety check: ensure round exists
      if (roundIdx < 0 || roundIdx >= _allRounds.length) {
        print('ERROR: Round index out of bounds: $roundIdx, rounds length: ${_allRounds.length}');
        continue;
      }
      
      final round = _allRounds[roundIdx];
      
      // Safety check: ensure round is not null
      if (round == null) {
        print('ERROR: Round at index $roundIdx is null');
        continue;
      }
      
      // For each currently active player, add a question for this round
      // (only if they were active at the START of this round)
      for (final playerId in activePlayers) {
        // Check if player was active at the START of this round
        // A player was active at round N if they were not eliminated/killed BEFORE round N
        // (i.e., their elimination/kill round is > roundIdx, or they're still alive)
        // Note: If a player was eliminated/killed IN round N, they were still active at the START of round N
        // So we check: player is still alive OR eliminated/killed in a later round (round > roundIdx)
        bool wasActiveAtRound;
        if (!_playerStates.containsKey(playerId)) {
          // Player is still alive - they were active at the start of this round
          wasActiveAtRound = true;
        } else {
          // Player was eliminated/killed - check if it was AFTER this round
          // If eliminated/killed in round N, they were active at the START of round N
          // So if round == roundIdx, they were active; if round > roundIdx, they were active
          final eliminationRound = _playerStates[playerId]!.round;
          wasActiveAtRound = eliminationRound >= roundIdx; // >= because eliminated IN round N means active at START of round N
        }

        if (!wasActiveAtRound) continue; // Skip if player wasn't active at the start of this round

        if (round.splitPhase != null) {
          // Split phase question: "Did player X vote to exclude both player T,S in round 0?"
          // Safety check: ensure split phase data is valid
          try {
            questions.add(PlayerBasedQuestion(
              questionIndex: questionIndex++,
              playerId: playerId,
              roundIndex: roundIdx,
              isSplitPhase: true,
              splitPlayer1: round.splitPhase!.player1,
              splitPlayer2: round.splitPhase!.splitPartner,
            ));
          } catch (e, stackTrace) {
            print('ERROR: Failed to create split phase question for round $roundIdx, player $playerId: $e');
            print('Stack trace: $stackTrace');
            continue;
          }
        } else {
          // Regular round question: "Who did player X vote for in round Y?"
          // Safety check: ensure round has votes
          if (round.votes.isEmpty) {
            print('WARNING: Round $roundIdx has no votes, skipping question for player $playerId');
            continue;
          }
          try {
            questions.add(PlayerBasedQuestion(
              questionIndex: questionIndex++,
              playerId: playerId,
              roundIndex: roundIdx,
              isSplitPhase: false,
            ));
          } catch (e) {
            print('ERROR: Failed to create regular question for round $roundIdx, player $playerId: $e');
            continue;
          }
        }
      }
    }
    
    return questions;
  }
  
  // Get questions grouped by player
  Map<int, List<PlayerBasedQuestion>> getPlayerBasedQuestionsByPlayer() {
    final questions = getPlayerBasedQuestions();
    final grouped = <int, List<PlayerBasedQuestion>>{};
    
    for (final question in questions) {
      if (!grouped.containsKey(question.playerId)) {
        grouped[question.playerId] = [];
      }
      grouped[question.playerId]!.add(question);
    }
    
    // Sort questions within each player by round index
    for (final playerId in grouped.keys) {
      grouped[playerId]!.sort((a, b) => a.roundIndex.compareTo(b.roundIndex));
    }
    
    return grouped;
  }
  
  // Get correct answer for a player-based question
  dynamic getPlayerBasedAnswer(PlayerBasedQuestion question) {
    try {
      if (question.roundIndex < 0 || question.roundIndex >= _allRounds.length) {
        print('ERROR: Invalid round index in getPlayerBasedAnswer: ${question.roundIndex}, rounds length: ${_allRounds.length}');
        return null;
      }
      
      final round = _allRounds[question.roundIndex];
      if (round == null) {
        print('ERROR: Round is null at index ${question.roundIndex}');
        return null;
      }
      
      if (question.isSplitPhase || round.splitPhase != null) {
        // For split phase: return true if player voted to eliminate both, false otherwise
        if (round.splitPhase == null) {
          print('ERROR: Split phase question but round has no split phase. Round index: ${question.roundIndex}');
          return false;
        }
        final voters = round.splitPhase!.voters;
        if (voters == null) {
          print('ERROR: Split phase voters is null for round ${question.roundIndex}');
          return false;
        }
        return voters.contains(question.playerId);
      } else {
        // For regular round: find which candidate the player voted for
        if (round.votes.isEmpty) {
          print('ERROR: Regular round question but round has no votes. Round index: ${question.roundIndex}');
          return null;
        }
        for (final vote in round.votes) {
          if (vote.voters.contains(question.playerId)) {
            return vote.candidate;
          }
        }
        return null; // Player didn't vote (shouldn't happen, but handle it)
      }
    } catch (e, stackTrace) {
      print('ERROR in getPlayerBasedAnswer for question ${question.questionIndex}: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  void _checkPlayerBasedAnswer() {
    final questions = getPlayerBasedQuestions();
    if (questions.isEmpty) return;
    
    // Check all answers at once
    bool allAnswered = true;
    for (final question in questions) {
      if (!_playerBasedSelectedAnswers.containsKey(question.questionIndex)) {
        allAnswered = false;
        break;
      }
    }
    
    if (!allAnswered) {
      // Not all questions answered yet
      return;
    }
    
    // Check all answers and record scores
    for (final question in questions) {
      final selectedAnswer = _playerBasedSelectedAnswers[question.questionIndex];
      final correctAnswer = getPlayerBasedAnswer(question);
      final isCorrect = selectedAnswer == correctAnswer;
      
      // Record score
      final newScore = Score(
        roundIndex: question.roundIndex,
        candidateIndex: question.questionIndex,
        correct: isCorrect,
        isRetry: _gameState == GameState.retry,
        retryFromRound: _gameState == GameState.retry ? _currentRoundIndex : null,
      );
      _scores = [..._scores, newScore];
      
      // Store correctness for feedback (true = correct, false = wrong)
      _playerBasedAnswers[question.questionIndex] = isCorrect;
    }
    
    // Don't overwrite _playerBasedAnswers - it should contain correctness booleans, not the answers
    _showFeedback = true;
    notifyListeners();
    
    // No automatic timer - user will click continue button when ready
  }
  
  void continueAfterPlayerBasedFeedback() {
    _showFeedback = false;
    _playerBasedSelectedAnswers = {}; // Clear selected answers
    
    // All questions answered - now start learning phase for current round
    // In player-based mode, we ask about previous rounds BEFORE learning the current round
    if (_gameState == GameState.testing) {
      // After completing testing about previous rounds, start learning phase for current round
      final activePlayers = List.generate(10, (i) => i + 1)
          .where((p) => !_playerStates.containsKey(p))
          .toList();
      
      final nextRoundPlayers = activePlayers.length;
      
      // Check if next round would be 3 players - if so, finish game (no 3p learning phase)
      if (nextRoundPlayers == 3) {
        // Last round - finish game after questions
        _gameState = GameState.finalResults;
        notifyListeners();
      } else {
        // Note: _currentRoundIndex is already set correctly by continueToNextRound()
        // We just need to start the learning phase for the current round
        _gameState = GameState.learning;
        _learningStep = 0;
        notifyListeners();
        generateRound(activePlayers.length, _playerStates);
      }
    }
  }

  void checkAnswer() {
    // Handle player-based mode
    if (_memoryTrainType == MemoryTrainType.playerBased) {
      _checkPlayerBasedAnswer();
      return;
    }
    
    // Safety check: ensure round index is valid
    if (_testingRoundIndex < 0 || _testingRoundIndex >= _allRounds.length) {
      print('ERROR: Invalid testing round index: $_testingRoundIndex, rounds length: ${_allRounds.length}');
      return;
    }
    
    final currentRound = _allRounds[_testingRoundIndex];
    
    // Handle split phase differently
    if (currentRound.splitPhase != null && _isSplitPhase) {
      final splitPhase = currentRound.splitPhase!;
      final correctVoters = splitPhase.voters;
      final isCorrect = _selectedPlayers.length == correctVoters.length &&
          _selectedPlayers.every((p) => correctVoters.contains(p));

      final newScore = Score(
        roundIndex: _testingRoundIndex,
        candidateIndex: 0, // Split phase uses index 0
        correct: isCorrect,
        isRetry: _gameState == GameState.retry,
        retryFromRound: _gameState == GameState.retry ? _currentRoundIndex : null,
      );

      _scores = [..._scores, newScore];
      _showFeedback = true;
      notifyListeners();

      Future.delayed(_getDelay(2000), () {
        // Auto-fill random answers if enabled (for next candidate/round)
        autoFillAnswers();
        
        // In retry mode, don't process split phase completion - trigger retry logic to move to next round
        if (_gameState == GameState.retry) {
          // Trigger the retry logic to move to next round
          // This simulates completing the split phase test in retry mode
          if (_retryRoundIndex < _currentRoundIndex) {
            // Move to next round after split phase
            _retryRoundIndex++;
            _testingRoundIndex++;
            _isSplitPhase = false; // Clear split phase flag
            _testingCandidateIndex = 0;
            _selectedPlayers = [];
            _showFeedback = false;
            notifyListeners();
          } else {
            // Finished all retry rounds up to current, process elimination and kill
            _isSplitPhase = false;
            _processEliminationAndKillInternal();
            
            // Check if we should show night phase results
            if (showNightPhaseResults) {
              notifyListeners();
            } else {
              final nextRoundPlayers = 10 - _playerStates.length;
              if (nextRoundPlayers < 5) {
                _gameState = GameState.finalResults;
                notifyListeners();
              }
            }
          }
          return;
        }
        
        // Handle split phase completion (only in normal mode)
        if (splitPhase.voteCount >= 6) {
          // Both players eliminated, then one killed, show night phase then jump to 7 players
          final newPlayerStates = Map<int, PlayerState>.from(_playerStates);
          newPlayerStates[splitPhase.player1] = PlayerState(
            status: PlayerStatus.eliminated,
            round: 0,
          );
          newPlayerStates[splitPhase.splitPartner] = PlayerState(
            status: PlayerStatus.eliminated,
            round: 0,
          );
          
          // Kill one more player
          final activePlayers = List.generate(10, (i) => i + 1)
              .where((p) => !newPlayerStates.containsKey(p))
              .toList();
          if (activePlayers.isNotEmpty) {
            final random = math.Random();
            final killed = activePlayers[random.nextInt(activePlayers.length)];
            newPlayerStates[killed] = PlayerState(
              status: PlayerStatus.killed,
              round: 0,
            );
          }
          
          _playerStates = newPlayerStates;
          _isSplitPhase = false;
          // Keep currentRoundIndex at 0 to show eliminated/killed from round 0
          _nightPhaseProcessed = true; // Show night phase results
          // Keep game state as testing so UI can show night phase
          notifyListeners();
        } else {
          // Not enough votes (voteCount < 6), 2 players were NOT eliminated
          // Kill one player, then show night phase before jumping to 9 players round
          final random = math.Random();
          final activePlayers = List.generate(10, (i) => i + 1)
              .where((p) => !_playerStates.containsKey(p))
              .toList();
          
          if (activePlayers.isNotEmpty) {
            final killed = activePlayers[random.nextInt(activePlayers.length)];
            final newPlayerStates = Map<int, PlayerState>.from(_playerStates);
            newPlayerStates[killed] = PlayerState(
              status: PlayerStatus.killed,
              round: 0,
            );
            _playerStates = newPlayerStates;
          }
          
          _isSplitPhase = false;
          // Keep currentRoundIndex at 0 to show eliminated/killed from round 0
          _nightPhaseProcessed = true; // Show night phase results
          // Keep game state as testing so UI can show night phase
          notifyListeners();
        }
      });
      return;
    }
    
    // Regular voting phase
    // Safety check: ensure votes exist and index is valid
    if (currentRound.votes.isEmpty || 
        _testingCandidateIndex < 0 || 
        _testingCandidateIndex >= currentRound.votes.length) {
      return;
    }
    
    final correctVoters = currentRound.votes[_testingCandidateIndex].voters;
    final isCorrect = _selectedPlayers.length == correctVoters.length &&
        _selectedPlayers.every((p) => correctVoters.contains(p));

    final newScore = Score(
      roundIndex: _testingRoundIndex,
      candidateIndex: _testingCandidateIndex,
      correct: isCorrect,
      isRetry: _gameState == GameState.retry,
      retryFromRound: _gameState == GameState.retry ? _currentRoundIndex : null,
    );

    _scores = [..._scores, newScore];
    _showFeedback = true;
    notifyListeners();

    Future.delayed(_getDelay(2000), () {
      // Safety check: ensure round index is valid
      if (_testingRoundIndex < 0 || _testingRoundIndex >= _allRounds.length) {
        return;
      }
      
      final currentRound = _allRounds[_testingRoundIndex];
      
      // Safety check: ensure votes exist
      if (currentRound.votes.isEmpty) {
        return;
      }
      
      if (_testingCandidateIndex < currentRound.votes.length - 1) {
        _testingCandidateIndex++;
        _selectedPlayers = [];
        _showFeedback = false;
        notifyListeners();
        // Auto-fill random answers if enabled (for next candidate)
        Future.delayed(Duration(milliseconds: 100), () {
          autoFillAnswers();
        });
      } else {
        if (_gameState == GameState.testing && _testingRoundIndex == _currentRoundIndex) {
          // After completing testing for a round, enter retry mode
          // Check if current round is split phase (round 0) - skip retry for split phase
          final isCurrentRoundSplitPhase = _currentRoundIndex < _allRounds.length &&
              _allRounds[_currentRoundIndex].splitPhase != null;
          
          // Enter retry mode for all rounds except split phase (round 0)
          if (!isCurrentRoundSplitPhase) {
            _gameState = GameState.retry;
            // Start retry from round 0 (split phase) first, then continue with all rounds up to current
            // In retry mode, skip learning phase and go directly to testing
            _retryRoundIndex = 0;
            _testingRoundIndex = 0;
            _testingCandidateIndex = 0;
            _selectedPlayers = [];
            _showFeedback = false;
            // Check if round 0 is split phase
            if (_allRounds.isNotEmpty && _allRounds[0].splitPhase != null) {
              _isSplitPhase = true;
            }
            notifyListeners();
          } else {
            // Split phase - process elimination and kill, then continue
            _processEliminationAndKillInternal();
            
            // Check if we should show night phase results
            // The UI will check showNightPhaseResults to display the night phase
            // We keep the game state as testing so the UI can render the night phase
            notifyListeners();
            
            // If we shouldn't show night phase, go directly to final results
            if (!showNightPhaseResults) {
              final nextRoundPlayers = 10 - _playerStates.length;
              // In player-based mode, allow 3-player round after 5-player round
              final minPlayers = _memoryTrainType == MemoryTrainType.playerBased ? 3 : 5;
              if (nextRoundPlayers < minPlayers) {
                _gameState = GameState.finalResults;
                notifyListeners();
              }
            }
          }
        } else if (_gameState == GameState.retry) {
          // Safety check: ensure retry round index is valid
          if (_retryRoundIndex < 0 || _retryRoundIndex >= _allRounds.length) {
            return;
          }
          
          final retryRound = _allRounds[_retryRoundIndex];
          
          // Handle split phase rounds in retry
          if (retryRound.splitPhase != null) {
            // This is a split phase round - move to next round
            // Only retry rounds up to current round
            if (_retryRoundIndex < _currentRoundIndex) {
              // Move to next round after split phase
              _retryRoundIndex++;
              _testingRoundIndex++;
              _isSplitPhase = false; // Clear split phase flag
              _testingCandidateIndex = 0;
              _selectedPlayers = [];
              _showFeedback = false;
              notifyListeners();
            } else {
              // Finished all retry rounds up to current, process elimination and kill
              _isSplitPhase = false;
              _processEliminationAndKillInternal();
              
              // Check if we should show night phase results
              if (showNightPhaseResults) {
                notifyListeners();
              } else {
                final nextRoundPlayers = 10 - _playerStates.length;
                // In player-based mode, allow 3-player round after 5-player round
                final minPlayers = _memoryTrainType == MemoryTrainType.playerBased ? 3 : 5;
                if (nextRoundPlayers < minPlayers) {
                  _gameState = GameState.finalResults;
                  notifyListeners();
                }
              }
            }
            return;
          }
          
          // Regular round retry logic - iterate through all rounds up to current round
          // Only retry rounds that have been completed (up to _currentRoundIndex)
          if (_retryRoundIndex < _currentRoundIndex) {
            // Move to next round
            _retryRoundIndex++;
            _testingRoundIndex++;
            _testingCandidateIndex = 0;
            _selectedPlayers = [];
            _showFeedback = false;
            notifyListeners();
          } else {
            // Finished all retry rounds up to current, process elimination and kill for the current round
            // Then show night phase or go to final results
            _processEliminationAndKillInternal();
            
            // Check if we should show night phase results
            if (showNightPhaseResults) {
              // Show night phase results - keep in retry state so UI can render it
              notifyListeners();
            } else {
              // If we shouldn't show night phase, go directly to final results
              final nextRoundPlayers = 10 - _playerStates.length;
              // In player-based mode, allow 3-player round after 5-player round
              final minPlayers = _memoryTrainType == MemoryTrainType.playerBased ? 3 : 5;
              if (nextRoundPlayers < minPlayers) {
                _gameState = GameState.finalResults;
                notifyListeners();
              }
            }
          }
        }
      }
    });
  }

  void _processEliminationAndKillInternal() {
    // Safety check: ensure round index is valid
    if (_currentRoundIndex < 0 || _currentRoundIndex >= _allRounds.length) {
      print('ERROR: Invalid current round index: $_currentRoundIndex, rounds length: ${_allRounds.length}');
      return;
    }
    
    final currentRound = _allRounds[_currentRoundIndex];
    
    // Skip if this is a split phase round (no regular votes)
    if (currentRound.splitPhase != null) {
      return;
    }
    
    // Safety check: ensure votes exist
    if (currentRound.votes.isEmpty) {
      print('ERROR: Current round has no votes. Round index: $_currentRoundIndex, Split phase: ${currentRound.splitPhase != null}');
      return;
    }
    
    int maxVotes = 0;
    int? eliminated;
    for (final vote in currentRound.votes) {
      if (vote.count > maxVotes) {
        maxVotes = vote.count;
        eliminated = vote.candidate;
      }
    }

    final newPlayerStates = Map<int, PlayerState>.from(_playerStates);
    // Only eliminate if there's a clear winner (max votes > 0)
    if (eliminated != null && maxVotes > 0) {
      newPlayerStates[eliminated] = PlayerState(
        status: PlayerStatus.eliminated,
        round: _currentRoundIndex,
      );
    }

    final activePlayers = List.generate(10, (i) => i + 1)
        .where((p) => !newPlayerStates.containsKey(p))
        .toList();

    if (activePlayers.isNotEmpty) {
      final random = math.Random();
      final killed = activePlayers[random.nextInt(activePlayers.length)];
      newPlayerStates[killed] = PlayerState(
        status: PlayerStatus.killed,
        round: _currentRoundIndex,
      );
    }

    _playerStates = newPlayerStates;
    _nightPhaseProcessed = true;
    notifyListeners();
  }

  void processEliminationAndKill() {
    _processEliminationAndKillInternal();
  }

  void continueToNextRound() {
    print('DEBUG: continueToNextRound - START, currentRoundIndex: $_currentRoundIndex, allRounds.length: ${_allRounds.length}');
    final activePlayers = List.generate(10, (i) => i + 1)
        .where((p) => !_playerStates.containsKey(p))
        .toList();

    final remainingPlayers = _playerStates.length;
    final nextRoundPlayers = 10 - remainingPlayers;

    _nightPhaseProcessed = false;
    
    // In player-based mode, allow 3-player round after 5-player round
    final minPlayers = _memoryTrainType == MemoryTrainType.playerBased ? 3 : 5;
    if (nextRoundPlayers >= minPlayers) {
      // If we're at round 0 (split phase), move to round 1, otherwise increment
      print('DEBUG: continueToNextRound - BEFORE increment, currentRoundIndex: $_currentRoundIndex');
      if (_currentRoundIndex == 0) {
        _currentRoundIndex = 1;
      } else {
        _currentRoundIndex++;
      }
      print('DEBUG: continueToNextRound - AFTER increment, currentRoundIndex: $_currentRoundIndex');
      
      // In player-based mode, start with testing phase (ask about previous rounds)
      // before learning the current round
      if (_memoryTrainType == MemoryTrainType.playerBased) {
        // Check if next round would be 3 players - if so, ask questions and finish game (no 3p learning phase)
        if (nextRoundPlayers == 3) {
          // Last round - ask questions about all previous rounds, then finish game
          try {
            print('DEBUG: continueToNextRound - next round would be 3 players, asking final questions');
            print('DEBUG: continueToNextRound - currentRoundIndex: $_currentRoundIndex, allRounds.length: ${_allRounds.length}');
            final questions = getPlayerBasedQuestions();
            if (questions.isNotEmpty) {
              // Start testing phase to ask about previous rounds
              _gameState = GameState.testing;
              // In player-based mode, we're asking about previous rounds (0 to _currentRoundIndex - 1)
              // Set _testingRoundIndex to the highest round we're asking about (which is _currentRoundIndex - 1)
              // or 0 if _currentRoundIndex is 1 (asking about round 0 before round 1)
              _testingRoundIndex = _currentRoundIndex > 0 ? _currentRoundIndex - 1 : 0;
              _testingCandidateIndex = 0;
              _selectedPlayers = [];
              _showFeedback = false;
              _playerBasedSelectedAnswers = {}; // Reset selected answers
              _playerBasedAnswers = {}; // Reset submitted answers
              notifyListeners();
              // Auto-fill random answers if enabled
              Future.delayed(Duration(milliseconds: 100), () {
                autoFillAnswers();
              });
            } else {
              // No questions to ask, go directly to final results
              _gameState = GameState.finalResults;
              notifyListeners();
            }
          } catch (e, stackTrace) {
            print('ERROR in continueToNextRound (player-based, final round): $e');
            print('Stack trace: $stackTrace');
            // Fallback: go directly to final results
            _gameState = GameState.finalResults;
            notifyListeners();
          }
        } else {
          // Not the last round - ask questions about previous rounds, then start learning phase for current round
          try {
            print('DEBUG: continueToNextRound - currentRoundIndex: $_currentRoundIndex, allRounds.length: ${_allRounds.length}');
            final questions = getPlayerBasedQuestions();
            if (questions.isNotEmpty) {
              // Start testing phase to ask about previous rounds
              _gameState = GameState.testing;
              // In player-based mode, we're asking about previous rounds (0 to _currentRoundIndex - 1)
              // Set _testingRoundIndex to the highest round we're asking about (which is _currentRoundIndex - 1)
              // or 0 if _currentRoundIndex is 1 (asking about round 0 before round 1)
              _testingRoundIndex = _currentRoundIndex > 0 ? _currentRoundIndex - 1 : 0;
              _testingCandidateIndex = 0;
              _selectedPlayers = [];
              _showFeedback = false;
              _playerBasedSelectedAnswers = {}; // Reset selected answers
              _playerBasedAnswers = {}; // Reset submitted answers
              notifyListeners();
              // Auto-fill random answers if enabled
              Future.delayed(Duration(milliseconds: 100), () {
                autoFillAnswers();
              });
            } else {
              // No questions to ask, go directly to learning phase
              _gameState = GameState.learning;
              _learningStep = 0;
              notifyListeners();
              generateRound(activePlayers.length, _playerStates);
            }
          } catch (e, stackTrace) {
            print('ERROR in continueToNextRound (player-based): $e');
            print('Stack trace: $stackTrace');
            // Fallback: go directly to learning phase
            _gameState = GameState.learning;
            _learningStep = 0;
            notifyListeners();
            generateRound(activePlayers.length, _playerStates);
          }
        }
      } else {
        // Table-based mode: go directly to learning phase
        _gameState = GameState.learning;
        _learningStep = 0;
        notifyListeners();
        generateRound(activePlayers.length, _playerStates);
      }
    } else {
      _gameState = GameState.finalResults;
      notifyListeners();
    }
  }

  bool get showNightPhaseResults {
    // Show results after elimination/kill has been processed for current round
    if (!_nightPhaseProcessed) return false;
    
    // Get eliminated and killed players from current round
    final eliminatedPlayers = _playerStates.entries
        .where((e) => e.value.status == PlayerStatus.eliminated && e.value.round == _currentRoundIndex)
        .map((e) => e.key)
        .toList();
    
    final killedPlayers = _playerStates.entries
        .where((e) => e.value.status == PlayerStatus.killed && e.value.round == _currentRoundIndex)
        .map((e) => e.key)
        .toList();
    
    final nextRoundPlayers = 10 - _playerStates.length;
    
    // In player-based mode, allow 3-player round after 5-player round
    // In table-based mode, skip night phase if next round would have less than 5 players
    final minPlayers = _memoryTrainType == MemoryTrainType.playerBased ? 3 : 5;
    if (nextRoundPlayers < minPlayers) return false;
    
    final eliminated = eliminatedPlayers.isNotEmpty;
    final killed = killedPlayers.isNotEmpty;
    return eliminated || killed;
  }

  List<int> get eliminatedPlayers {
    return _playerStates.entries
        .where((e) =>
            e.value.status == PlayerStatus.eliminated &&
            e.value.round == _currentRoundIndex)
        .map((e) => e.key)
        .toList();
  }

  List<int> get killedPlayers {
    return _playerStates.entries
        .where((e) =>
            e.value.status == PlayerStatus.killed &&
            e.value.round == _currentRoundIndex)
        .map((e) => e.key)
        .toList();
  }

  Map<int, PlayerState> getPlayerStatesForRound(int roundIdx) {
    final statesAtRound = <int, PlayerState>{};
    _playerStates.forEach((playerId, data) {
      // Only include players killed/eliminated BEFORE this round's night phase
      // For round 0, this means no players should be included (since rounds start at 0)
      // For round 1, include players with round < 1 (i.e., round 0)
      // The check should be strict < to exclude eliminations/kills from the current round's night phase
      // Players killed/eliminated in round N's night phase have round: N, so they should NOT appear when replaying round N
      if (data.round < roundIdx) {
        statesAtRound[playerId] = data;
      }
    });
    return statesAtRound;
  }

  Map<String, int> calculateRoundScore(int roundIdx) {
    final roundScores = _scores
        .where((s) => s.roundIndex == roundIdx && !s.isRetry)
        .toList();
    if (roundScores.isEmpty) return {};
    final correct = roundScores.where((s) => s.correct).length;
    return {'correct': correct, 'total': roundScores.length};
  }

  Map<String, int> calculateRetryScore(int roundIdx, int retryFromRound) {
    final retryScores = _scores
        .where((s) =>
            s.roundIndex == roundIdx &&
            s.isRetry &&
            s.retryFromRound == retryFromRound)
        .toList();
    if (retryScores.isEmpty) return {};
    final correct = retryScores.where((s) => s.correct).length;
    return {'correct': correct, 'total': retryScores.length};
  }

  Map<String, int> getTotalScore() {
    final correct = _scores.where((s) => s.correct).length;
    return {'correct': correct, 'total': _scores.length};
  }

  void replayVotingPhase() {
    if (_gameState == GameState.learning) {
      _learningStep = 0;
      notifyListeners();
      // Check if current round is split phase
      if (_currentRoundIndex < _allRounds.length && 
          _allRounds[_currentRoundIndex].splitPhase != null) {
        // For split phase, just restart the learning phase display
        _isSplitPhase = true;
        notifyListeners();
        // After a delay, move to testing
      Future.delayed(_getDelay((_voteInterval * 1000).round()), () {
        if (_gameState == GameState.learning && _isSplitPhase) {
          Future.delayed(_getDelay(1500), () {
            startTesting();
          });
        }
      });
      } else {
        _startLearningPhase();
      }
    } else if (_gameState == GameState.testing) {
      try {
        // In player-based mode, we're testing questions about previous rounds
        // So we need to replay the round at _testingRoundIndex, not _currentRoundIndex
        // In table-based mode, _testingRoundIndex == _currentRoundIndex
        final roundToReplay = _memoryTrainType == MemoryTrainType.playerBased 
            ? _testingRoundIndex 
            : _currentRoundIndex;
        
        // Safety check: ensure round index is valid
        if (roundToReplay < 0 || roundToReplay >= _allRounds.length) {
          print('ERROR: Invalid round index in replayVotingPhase: $roundToReplay, rounds length: ${_allRounds.length}');
          return;
        }
        
        // Save the original current round index and testing round index (needed for player-based mode to restore after replay)
        if (_memoryTrainType == MemoryTrainType.playerBased) {
          _replayState = {
            'originalCurrentRoundIndex': _currentRoundIndex,
            'originalTestingRoundIndex': _testingRoundIndex,
          };
        }
        
        // In player-based mode, set replay flag to skip elimination/kill processing
        if (_memoryTrainType == MemoryTrainType.playerBased) {
          _isReplaying = true;
          // Clear player-based state when replaying
          _playerBasedSelectedAnswers = {};
          _playerBasedAnswers = {};
          _showFeedback = false;
        }
        
        // Set current round index to the round we're replaying
        _currentRoundIndex = roundToReplay;
        _gameState = GameState.learning;
        _learningStep = 0;
        notifyListeners();
        
        // Check if current round is split phase
        final currentRound = _allRounds[_currentRoundIndex];
        if (currentRound != null && currentRound.splitPhase != null) {
          // For split phase, just restart the learning phase display
          _isSplitPhase = true;
          notifyListeners();
          // After a delay, move to testing
          Future.delayed(_getDelay((_voteInterval * 1000).round()), () {
            try {
              if (_gameState == GameState.learning && _isSplitPhase) {
                Future.delayed(_getDelay(1500), () {
                  try {
                    // Restore original round indices before going back to testing
                    if (_replayState != null) {
                      _currentRoundIndex = _replayState!['originalCurrentRoundIndex']!;
                      _testingRoundIndex = _replayState!['originalTestingRoundIndex']!;
                      _replayState = null;
                    }
                    _isReplaying = false;
                    startTesting();
                  } catch (e, stackTrace) {
                    print('ERROR in replayVotingPhase split phase completion: $e');
                    print('Stack trace: $stackTrace');
                    // Recover
                    _isReplaying = false;
                    _replayState = null;
                    _isSplitPhase = false;
                    _gameState = GameState.testing;
                    notifyListeners();
                  }
                });
              }
            } catch (e, stackTrace) {
              print('ERROR in replayVotingPhase split phase delay: $e');
              print('Stack trace: $stackTrace');
              // Recover
              _isReplaying = false;
              _replayState = null;
              _isSplitPhase = false;
              _gameState = GameState.testing;
              notifyListeners();
            }
          });
        } else {
          _startLearningPhase();
        }
      } catch (e, stackTrace) {
        print('ERROR in replayVotingPhase (testing state): $e');
        print('Stack trace: $stackTrace');
        // Recover
        _isReplaying = false;
        _replayState = null;
        _gameState = GameState.testing;
        notifyListeners();
      }
    } else if (_gameState == GameState.retry) {
      // In retry mode, replay the round that the user is currently trying to solve
      // This is the round at _testingRoundIndex (the round currently being tested in retry mode)
      // Save the current retry state to restore after replay
      final savedRetryRoundIndex = _retryRoundIndex;
      final savedCurrentRoundIndex = _currentRoundIndex;
      final roundToReplay = _testingRoundIndex; // The round currently being tested in retry
      
      // Remove scores from the current retry attempt for this round
      // This ensures the left toolbar score resets correctly after replay
      _scores = _scores.where((score) {
        // Keep all non-retry scores
        if (!score.isRetry) return true;
        // Remove retry scores for the round being replayed that are from the current retry attempt
        if (score.roundIndex == roundToReplay && 
            score.retryFromRound == savedCurrentRoundIndex) {
          return false;
        }
        return true;
      }).toList();
      
      // IMPORTANT: Set current round to the round being tested in retry mode
      // This ensures _startLearningPhase() will replay the correct round
      _currentRoundIndex = roundToReplay;
      _gameState = GameState.learning;
      _learningStep = 0;
      _testingCandidateIndex = 0; // Reset candidate index for fresh start
      _selectedPlayers = []; // Clear selected players
      _showFeedback = false; // Clear feedback
      
      // Set returnToRetry BEFORE starting learning phase so UI can use it to get correct player states
      // This is needed for both split phase and regular rounds
      _returnToRetry = {
        'currentRound': savedCurrentRoundIndex,
        'retryRound': roundToReplay, // Continue testing the same round we replayed
      };
      notifyListeners();
      
      // Check if current round is split phase
      if (_currentRoundIndex < _allRounds.length && 
          _allRounds[_currentRoundIndex].splitPhase != null) {
        // For split phase, just restart the learning phase display
        _isSplitPhase = true;
        notifyListeners();
        // After a delay, move to testing
        Future.delayed(_getDelay((_voteInterval * 1000).round()), () {
          if (_gameState == GameState.learning && _isSplitPhase) {
            Future.delayed(_getDelay(1500), () {
              // _returnToRetry is already set above, just call startTesting
              startTesting();
            });
          }
        });
      } else {
        // _startLearningPhase() will use _currentRoundIndex which we just set to roundToReplay
        _startLearningPhase();
      }
    }
  }
}

