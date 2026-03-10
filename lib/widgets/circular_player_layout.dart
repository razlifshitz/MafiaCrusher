import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_models.dart';

class CircularPlayerLayout extends StatelessWidget {
  final Map<int, PlayerState> playerStates;
  final Function(int) onPlayerClick;
  final GameState gameState;
  final int? currentCandidate;
  final List<int>? currentVoters;
  final List<int>? selectedPlayers;
  final bool showFeedback;
  final int? testingRoundIndex;
  final Map<int, PlayerState> Function(int)? getPlayerStatesForRound;
  final SplitPhase? splitPhase; // For split phase display
  final int? mePlayerId; // Practice split: "me" shown in green with special border
  final List<int>? tappablePlayerIds; // If set, only these players trigger onPlayerClick (e.g. nominated in practice split)
  final List<int>? nominatedPlayerIds; // Practice split: both split players get split color
  final List<int>? highlightedVoterIds; // Practice split results: players who voted to current nominee (blue)

  const CircularPlayerLayout({
    Key? key,
    required this.playerStates,
    required this.onPlayerClick,
    required this.gameState,
    this.currentCandidate,
    this.currentVoters,
    this.selectedPlayers,
    this.showFeedback = false,
    this.testingRoundIndex,
    this.getPlayerStatesForRound,
    this.splitPhase,
    this.mePlayerId,
    this.tappablePlayerIds,
    this.nominatedPlayerIds,
    this.highlightedVoterIds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final containerHeight = isMobile ? 280.0 : 500.0;
    final radius = isMobile ? 110.0 : 180.0;
    final playerSize = isMobile ? 44.0 : 64.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final centerY = containerHeight / 2;

        return Container(
          height: containerHeight,
          child: Stack(
            children: [
              Positioned(
                left: centerX - (isMobile ? 88 : 160),
                top: centerY - (isMobile ? 88 : 160),
                child: Container(
                  width: isMobile ? 176 : 320,
                  height: isMobile ? 176 : 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF78350F),
                        Color(0xFF92400E),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
              ...List.generate(10, (index) {
                final playerId = index + 1;
                final position = _getPlayerPosition(index, radius, centerX, centerY);
                final relevantPlayerStates = _getRelevantPlayerStates();

                final canTap = tappablePlayerIds == null
                    ? (relevantPlayerStates[playerId] == null)
                    : tappablePlayerIds!.contains(playerId);
                return Positioned(
                  left: position.dx - playerSize / 2,
                  top: position.dy - playerSize / 2,
                  child: _buildPlayerCircle(
                    context,
                    playerId,
                    playerSize,
                    relevantPlayerStates,
                    isMobile,
                    canTap: canTap,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Map<int, PlayerState> _getRelevantPlayerStates() {
    if (gameState == GameState.retry && testingRoundIndex != null && getPlayerStatesForRound != null) {
      return getPlayerStatesForRound!(testingRoundIndex!);
    }
    return playerStates;
  }

  // Rotated so vertical line through center splits 1-5 (right) and 6-10 (left); 5 and 6 equidistant from that line.
  static const double _seatRotationDeg = 18.0;

  Offset _getPlayerPosition(int index, double radius, double centerX, double centerY) {
    final angleDeg = index * 36 - 90 + _seatRotationDeg;
    final angle = angleDeg * (math.pi / 180);
    return Offset(
      centerX + (radius * math.cos(angle)),
      centerY + (radius * math.sin(angle)),
    );
  }

  Widget _buildPlayerCircle(
    BuildContext context,
    int playerId,
    double size,
    Map<int, PlayerState> relevantPlayerStates,
    bool isMobile, {
    bool canTap = true,
  }) {
    final playerState = relevantPlayerStates[playerId];
    final isInactive = playerState != null;
    final color = _getPlayerColor(playerId, relevantPlayerStates, isMobile);
    final icon = _getPlayerIcon(playerState);
    final enabled = tappablePlayerIds == null ? !isInactive : canTap;

    final isMe = mePlayerId != null && playerId == mePlayerId;
    final isNominated = nominatedPlayerIds != null && nominatedPlayerIds!.contains(playerId);
    const greenBorder = Color(0xFF22C55E);
    const amberBorder = Color(0xFFF59E0B);
    final borderW = isMobile ? 3.0 : 4.0;

    Widget inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: isMe ? Border.all(color: greenBorder, width: borderW) : (isNominated ? Border.all(color: amberBorder, width: borderW) : null),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '$playerId',
              style: TextStyle(
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          if (icon != null) icon,
        ],
      ),
    );

    if (isMe && isNominated) {
      final innerSize = size - 2 * borderW;
      inner = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: amberBorder, width: borderW),
        ),
        padding: EdgeInsets.all(borderW),
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: greenBorder, width: borderW),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '$playerId',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              if (icon != null) icon,
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: enabled ? () => onPlayerClick(playerId) : null,
      child: inner,
    );
  }

  Color _getPlayerColor(
    int playerId,
    Map<int, PlayerState> relevantPlayerStates,
    bool isMobile,
  ) {
    // Results screen: blue only for actual voters; split nominees never vote for themselves, so they stay default fill + border
    if (highlightedVoterIds != null && highlightedVoterIds!.contains(playerId)) {
      return Color(0xFF3B82F6); // Blue only for players who voted to this nominee
    }
    // Practice split: nominated (split) players use default fill + amber border; ME uses default fill + green border only
    if (nominatedPlayerIds != null && nominatedPlayerIds!.isNotEmpty) {
      final isNominated = nominatedPlayerIds!.contains(playerId);
      if (isNominated) return Color(0xFFE5E7EB); // Default fill; amber border is drawn in _buildPlayerCircle
      // ME: don't return green here — fill is default; green border is drawn in _buildPlayerCircle
    }
    // ME: use default fill (border only) so "me" is identified by green ring, not green fill
    // Practice split fallback: nominated in red when only tappablePlayerIds set
    if (tappablePlayerIds != null && splitPhase == null && tappablePlayerIds!.contains(playerId)) {
      return Color(0xFFEF4444); // Red for nominated
    }
    if (relevantPlayerStates[playerId] != null) {
      return Color(0xFF4B5563).withOpacity(0.5);
    }

    // Handle split phase colors
    if (splitPhase != null) {
      if (playerId == splitPhase!.player1 || playerId == splitPhase!.splitPartner) {
        return Color(0xFFEF4444); // Red for split players (like candidates)
      }
      // During testing/retry with feedback, show feedback colors first
      if ((gameState == GameState.testing || gameState == GameState.retry) && showFeedback) {
        final isCorrectVoter = splitPhase!.voters.contains(playerId);
        final isSelected = selectedPlayers != null && selectedPlayers!.contains(playerId);
        
        if (isCorrectVoter && isSelected) {
          return Color(0xFF22C55E); // Green for correct selection
        }
        if (isCorrectVoter && !isSelected) {
          return Color(0xFFF97316); // Orange for missed (should have been selected)
        }
        if (!isCorrectVoter && isSelected) {
          return Color(0xFFDC2626); // Dark red for wrong selection
        }
      }
      // Show voters in blue during learning phase (before feedback)
      if (splitPhase!.voters.contains(playerId) && gameState == GameState.learning) {
        return Color(0xFF3B82F6); // Blue for voters
      }
      // During testing/retry without feedback, show selected players
      if (gameState == GameState.testing || gameState == GameState.retry) {
        if (selectedPlayers != null && selectedPlayers!.contains(playerId)) {
          return Color(0xFF60A5FA); // Light blue for selected
        }
      }
      return Color(0xFFE5E7EB); // White for others
    }

    if (gameState == GameState.learning) {
      if (playerId == currentCandidate) {
        return Color(0xFFEF4444);
      }
      if (currentVoters != null && currentVoters!.contains(playerId)) {
        return Color(0xFF3B82F6);
      }
    }

    if (gameState == GameState.testing || gameState == GameState.retry) {
      if (playerId == currentCandidate) {
        return Color(0xFFEF4444);
      }
      if (showFeedback) {
        final isCorrectVoter = currentVoters != null && currentVoters!.contains(playerId);
        final isSelected = selectedPlayers != null && selectedPlayers!.contains(playerId);

        if (isCorrectVoter && isSelected) {
          return Color(0xFF22C55E);
        }
        if (isCorrectVoter && !isSelected) {
          return Color(0xFFF97316);
        }
        if (!isCorrectVoter && isSelected) {
          return Color(0xFFDC2626);
        }
      } else {
        if (selectedPlayers != null && selectedPlayers!.contains(playerId)) {
          return Color(0xFF60A5FA);
        }
      }
    }

    return Color(0xFFE5E7EB);
  }

  Widget? _getPlayerIcon(PlayerState? playerState) {
    if (playerState == null) return null;

    if (playerState.status == PlayerStatus.killed) {
      return Positioned(
        top: -4,
        right: -4,
        child: Text(
          '🔫',
          style: TextStyle(fontSize: 20),
        ),
      );
    }
    if (playerState.status == PlayerStatus.eliminated) {
      return Positioned(
        top: -8,
        right: -8,
        child: Text(
          '🔨',
          style: TextStyle(fontSize: 24),
        ),
      );
    }
    return null;
  }
}


