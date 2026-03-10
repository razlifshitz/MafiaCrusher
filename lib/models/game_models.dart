enum GameState {
  setup,
  learning,
  testing,
  retry,
  roundComplete,
  continuePrompt,
  finalResults,
  practiceSplit,
}

enum Difficulty {
  easy,
  medium,
  hard,
}

enum MemoryTrainType {
  tableBased, // Current game - shows table and asks who voted for player X
  playerBased, // New feature - asks who did player X vote for in round Y
  practiceSplit, // Practice split: you are "me", see nominated players, vote correctly in 3 sec
}

/// Phase within a single practice split scenario
enum PracticeSplitPhase {
  ready,
  votingToFirst,
  votingToSecond,
  showingResultsFirst,  // Show who voted to first nominee (blue)
  showingResultsSecond, // Show who voted to second nominee (blue)
  feedback,
  results, // All scenarios done, show summary
}

enum PlayerStatus {
  active,
  killed,
  eliminated,
}

class PlayerState {
  final PlayerStatus status;
  final int round;

  PlayerState({required this.status, required this.round});
}

class VoteData {
  final int candidate;
  final List<int> voters;
  int count;

  VoteData({
    required this.candidate,
    required this.voters,
    required this.count,
  });
}

class SplitPhase {
  final int player1;
  final int splitPartner;
  final List<int> voters; // Players who voted to eliminate both
  final int voteCount;

  SplitPhase({
    required this.player1,
    required this.splitPartner,
    required this.voters,
    required this.voteCount,
  });
}

class Round {
  final List<VoteData> votes;
  final List<int> candidates;
  final int activePlayers;
  final SplitPhase? splitPhase; // Optional split phase for round 0

  Round({
    required this.votes,
    required this.candidates,
    required this.activePlayers,
    this.splitPhase,
  });
}

class Score {
  final int roundIndex;
  final int candidateIndex;
  final bool correct;
  final bool isRetry;
  final int? retryFromRound;

  Score({
    required this.roundIndex,
    required this.candidateIndex,
    required this.correct,
    required this.isRetry,
    this.retryFromRound,
  });
}

class PlayerBasedQuestion {
  final int questionIndex;
  final int playerId; // Player being asked about
  final int roundIndex; // Round being asked about
  final bool isSplitPhase; // True if asking about split phase
  final int? splitPlayer1; // For split phase questions
  final int? splitPlayer2; // For split phase questions

  PlayerBasedQuestion({
    required this.questionIndex,
    required this.playerId,
    required this.roundIndex,
    this.isSplitPhase = false,
    this.splitPlayer1,
    this.splitPlayer2,
  });
}

