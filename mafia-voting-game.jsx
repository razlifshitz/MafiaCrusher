import React, { useState, useEffect } from 'react';

const MafiaVotingGame = () => {
  const [isMobile, setIsMobile] = useState(false);
  const [gameState, setGameState] = useState('setup');
  const [difficulty, setDifficulty] = useState('medium');
  const [allRounds, setAllRounds] = useState([]);
  const [currentRoundIndex, setCurrentRoundIndex] = useState(0);
  const [learningStep, setLearningStep] = useState(0);
  const [testingRoundIndex, setTestingRoundIndex] = useState(0);
  const [testingCandidateIndex, setTestingCandidateIndex] = useState(0);
  const [selectedPlayers, setSelectedPlayers] = useState([]);
  const [showFeedback, setShowFeedback] = useState(false);
  const [playerStates, setPlayerStates] = useState({});
  const [scores, setScores] = useState([]);
  const [retryRoundIndex, setRetryRoundIndex] = useState(0);
  const [returnToRetry, setReturnToRetry] = useState(null);

  // Detect screen size
  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };
    
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  const startGame = () => {
    const initialKilled = Math.floor(Math.random() * 10) + 1;
    const newPlayerStates = { [initialKilled]: { status: 'killed', round: -1 } };
    
    setPlayerStates(newPlayerStates);
    setAllRounds([]);
    setCurrentRoundIndex(0);
    setScores([]);
    
    generateRound(9, newPlayerStates);
  };

  const generateRound = (numActivePlayers, currentPlayerStates) => {
    const activePlayers = Array.from({ length: 10 }, (_, i) => i + 1)
      .filter(p => !currentPlayerStates[p]);
    
    let numCandidates;
    if (difficulty === 'easy') {
      numCandidates = Math.min(3, numActivePlayers);
    } else if (difficulty === 'medium') {
      numCandidates = Math.min(5, numActivePlayers);
    } else {
      numCandidates = Math.min(7, numActivePlayers);
    }
    
    const candidates = [];
    while (candidates.length < numCandidates) {
      const candidate = activePlayers[Math.floor(Math.random() * activePlayers.length)];
      if (!candidates.includes(candidate)) {
        candidates.push(candidate);
      }
    }
    
    const votingData = candidates.map(candidate => ({
      candidate,
      voters: [],
      count: 0
    }));
    
    activePlayers.forEach(voter => {
      const validCandidates = candidates.filter(c => c !== voter);
      const chosenCandidate = validCandidates[Math.floor(Math.random() * validCandidates.length)];
      const candidateData = votingData.find(v => v.candidate === chosenCandidate);
      candidateData.voters.push(voter);
      candidateData.count++;
    });
    
    votingData.forEach(v => v.voters.sort((a, b) => a - b));
    
    const newRound = {
      votes: votingData,
      candidates: candidates,
      activePlayers: numActivePlayers
    };
    
    setAllRounds(prev => [...prev, newRound]);
    setGameState('learning');
    setLearningStep(0);
  };

  useEffect(() => {
    if (gameState === 'learning' && allRounds.length > 0) {
      const currentRound = allRounds[currentRoundIndex];
      const timer = setTimeout(() => {
        if (learningStep < currentRound.votes.length - 1) {
          setLearningStep(prev => prev + 1);
        } else {
          setTimeout(() => startTesting(), 1500);
        }
      }, 3500);
      return () => clearTimeout(timer);
    }
  }, [gameState, learningStep, allRounds, currentRoundIndex]);

  const startTesting = () => {
    if (returnToRetry) {
      setCurrentRoundIndex(returnToRetry.currentRound);
      setRetryRoundIndex(returnToRetry.retryRound);
      setTestingRoundIndex(returnToRetry.retryRound);
      setGameState('retry');
      setReturnToRetry(null);
    } else {
      setGameState('testing');
      setTestingRoundIndex(currentRoundIndex);
    }
    setTestingCandidateIndex(0);
    setSelectedPlayers([]);
    setShowFeedback(false);
  };

  const handlePlayerClick = (playerId) => {
    if (gameState !== 'testing' && gameState !== 'retry') return;
    if (showFeedback) return;
    
    const relevantPlayerStates = gameState === 'retry' 
      ? getPlayerStatesForRound(testingRoundIndex)
      : playerStates;
    
    if (relevantPlayerStates[playerId]) return;
    
    setSelectedPlayers(prev => 
      prev.includes(playerId) 
        ? prev.filter(p => p !== playerId)
        : [...prev, playerId]
    );
  };

  const checkAnswer = () => {
    const currentRound = allRounds[testingRoundIndex];
    const correctVoters = currentRound.votes[testingCandidateIndex].voters;
    const isCorrect = 
      selectedPlayers.length === correctVoters.length &&
      selectedPlayers.every(p => correctVoters.includes(p));
    
    const newScore = {
      roundIndex: testingRoundIndex,
      candidateIndex: testingCandidateIndex,
      correct: isCorrect,
      isRetry: gameState === 'retry',
      retryFromRound: gameState === 'retry' ? currentRoundIndex : null
    };
    
    setScores(prev => [...prev, newScore]);
    setShowFeedback(true);
    
    setTimeout(() => {
      if (testingCandidateIndex < currentRound.votes.length - 1) {
        setTestingCandidateIndex(prev => prev + 1);
        setSelectedPlayers([]);
        setShowFeedback(false);
      } else {
        if (gameState === 'testing' && testingRoundIndex === currentRoundIndex) {
          if (currentRoundIndex > 0) {
            setGameState('retry');
            setRetryRoundIndex(0);
            setTestingRoundIndex(0);
            setTestingCandidateIndex(0);
            setSelectedPlayers([]);
            setShowFeedback(false);
          } else {
            setGameState('round-complete');
          }
        } else if (gameState === 'retry') {
          if (retryRoundIndex < currentRoundIndex) {
            setRetryRoundIndex(prev => prev + 1);
            setTestingRoundIndex(prev => prev + 1);
            setTestingCandidateIndex(0);
            setSelectedPlayers([]);
            setShowFeedback(false);
          } else {
            if (currentRoundIndex === 2) {
              setGameState('final-results');
            } else {
              setGameState('round-complete');
            }
          }
        }
      }
    }, 2000);
  };

  const processEliminationAndKill = () => {
    const currentRound = allRounds[currentRoundIndex];
    let maxVotes = 0;
    let eliminated = null;
    currentRound.votes.forEach(v => {
      if (v.count > maxVotes) {
        maxVotes = v.count;
        eliminated = v.candidate;
      }
    });
    
    const newPlayerStates = { ...playerStates };
    if (eliminated) {
      newPlayerStates[eliminated] = { status: 'eliminated', round: currentRoundIndex };
    }
    
    const activePlayers = Array.from({ length: 10 }, (_, i) => i + 1)
      .filter(p => !newPlayerStates[p]);
    
    if (activePlayers.length > 0) {
      const killed = activePlayers[Math.floor(Math.random() * activePlayers.length)];
      newPlayerStates[killed] = { status: 'killed', round: currentRoundIndex };
    }
    
    setPlayerStates(newPlayerStates);
    
    const remainingPlayers = Object.keys(newPlayerStates).length;
    const nextRoundPlayers = 10 - remainingPlayers;
    
    if (nextRoundPlayers >= 5) {
      setGameState('continue-prompt');
    } else {
      setGameState('final-results');
    }
  };

  const continueToNextRound = () => {
    const activePlayers = Array.from({ length: 10 }, (_, i) => i + 1)
      .filter(p => !playerStates[p]);
    
    setCurrentRoundIndex(prev => prev + 1);
    generateRound(activePlayers.length, playerStates);
  };

  const getPlayerPosition = (index) => {
    const angle = (index * 36 - 90) * (Math.PI / 180);
    const radius = isMobile ? 110 : 180;
    return {
      x: Math.cos(angle) * radius,
      y: Math.sin(angle) * radius
    };
  };

  const getPlayerStatesForRound = (roundIdx) => {
    const statesAtRound = {};
    Object.entries(playerStates).forEach(([playerId, data]) => {
      if (data.round < roundIdx) {
        statesAtRound[playerId] = data;
      }
    });
    return statesAtRound;
  };

  const getPlayerColor = (playerId) => {
    const relevantPlayerStates = gameState === 'retry' 
      ? getPlayerStatesForRound(testingRoundIndex)
      : playerStates;
    
    if (relevantPlayerStates[playerId]) {
      return 'bg-gray-600 text-gray-400 opacity-50';
    }
    
    if (gameState === 'learning') {
      const currentRound = allRounds[currentRoundIndex];
      const currentVote = currentRound.votes[learningStep];
      if (playerId === currentVote.candidate) return 'bg-red-500 text-black scale-110';
      if (currentVote.voters.includes(playerId)) return 'bg-blue-500 text-black';
    }
    
    if (gameState === 'testing' || gameState === 'retry') {
      const currentRound = allRounds[testingRoundIndex];
      const currentVote = currentRound.votes[testingCandidateIndex];
      if (playerId === currentVote.candidate) return 'bg-red-500 text-black scale-110';
      if (showFeedback) {
        if (currentVote.voters.includes(playerId) && selectedPlayers.includes(playerId)) {
          return 'bg-green-500 text-black';
        }
        if (currentVote.voters.includes(playerId) && !selectedPlayers.includes(playerId)) {
          return 'bg-orange-500 text-black';
        }
        if (!currentVote.voters.includes(playerId) && selectedPlayers.includes(playerId)) {
          return 'bg-red-600 text-black';
        }
      } else {
        if (selectedPlayers.includes(playerId)) return 'bg-blue-400 text-black';
      }
    }
    
    return 'bg-gray-200 hover:bg-gray-300 text-black';
  };

  const getPlayerIcon = (playerId) => {
    const relevantPlayerStates = gameState === 'retry' 
      ? getPlayerStatesForRound(testingRoundIndex)
      : playerStates;
    
    if (!relevantPlayerStates[playerId]) return null;
    
    if (relevantPlayerStates[playerId].status === 'killed') {
      return <div className="absolute -top-1 -right-1 text-xl">🔫</div>;
    }
    if (relevantPlayerStates[playerId].status === 'eliminated') {
      return <div className="absolute -top-2 -right-2 text-3xl">🔨</div>;
    }
    return null;
  };

  const calculateRoundScore = (roundIdx) => {
    const roundScores = scores.filter(s => s.roundIndex === roundIdx && !s.isRetry);
    if (roundScores.length === 0) return null;
    const correct = roundScores.filter(s => s.correct).length;
    return { correct, total: roundScores.length };
  };

  const calculateRetryScore = (roundIdx, retryFromRound) => {
    const retryScores = scores.filter(s => s.roundIndex === roundIdx && s.isRetry && s.retryFromRound === retryFromRound);
    if (retryScores.length === 0) return null;
    const correct = retryScores.filter(s => s.correct).length;
    return { correct, total: retryScores.length };
  };

  const getTotalScore = () => {
    const correct = scores.filter(s => s.correct).length;
    return { correct, total: scores.length };
  };

  const renderScoreList = () => {
    const scoreDisplay = [];
    for (let roundIdx = 0; roundIdx <= currentRoundIndex; roundIdx++) {
      const round = allRounds[roundIdx];
      if (!round) continue;
      
      const originalScore = calculateRoundScore(roundIdx);
      if (originalScore) {
        scoreDisplay.push(
          <div key={`original-${roundIdx}`} className={isMobile ? "text-xs text-gray-300" : "text-sm text-gray-300"}>
            {isMobile ? `R${roundIdx + 1}` : `Round ${roundIdx + 1}`} ({round.activePlayers}p): {originalScore.correct}/{originalScore.total}
          </div>
        );
      }
      
      if (roundIdx > 0 && roundIdx <= currentRoundIndex) {
        for (let retryIdx = 0; retryIdx < roundIdx; retryIdx++) {
          const retryScore = calculateRetryScore(retryIdx, roundIdx);
          if (retryScore) {
            const retryRound = allRounds[retryIdx];
            scoreDisplay.push(
              <div key={`retry-${roundIdx}-${retryIdx}`} className={isMobile ? "text-xs text-gray-400 ml-2" : "text-sm text-gray-400 ml-2"}>
                🔄 {isMobile ? `R${retryIdx + 1}` : `Retry R${retryIdx + 1}`} ({retryRound.activePlayers}p): {retryScore.correct}/{retryScore.total}
              </div>
            );
          }
        }
        const selfRetry = calculateRetryScore(roundIdx, roundIdx);
        if (selfRetry) {
          scoreDisplay.push(
            <div key={`retry-${roundIdx}-${roundIdx}`} className={isMobile ? "text-xs text-gray-400 ml-2" : "text-sm text-gray-400 ml-2"}>
              🔄 {isMobile ? `R${roundIdx + 1}` : `Retry R${roundIdx + 1}`} ({round.activePlayers}p): {selfRetry.correct}/{selfRetry.total}
            </div>
          );
        }
      }
    }
    return scoreDisplay;
  };

  // MOBILE RENDER
  if (isMobile) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-800 text-white p-3">
        <div className="max-w-2xl mx-auto">
          <h1 className="text-2xl font-bold text-center mb-1">🎭 Mafia Voting Practice</h1>
          <p className="text-center text-gray-300 text-xs mb-3">Improve your memory for Mafia voting rounds</p>

          {gameState !== 'setup' && (
            <div className="flex flex-col gap-2 mb-3">
              <button
                onClick={() => setGameState('setup')}
                className="bg-slate-700 hover:bg-slate-600 px-4 py-2 rounded-lg font-semibold transition text-sm"
              >
                ← Back to Main Menu
              </button>
              {(gameState === 'learning' || gameState === 'testing' || gameState === 'retry') && (
                <button
                  onClick={() => {
                    if (gameState === 'learning') {
                      setLearningStep(0);
                    } else if (gameState === 'testing') {
                      setGameState('learning');
                      setLearningStep(0);
                    } else if (gameState === 'retry') {
                      setReturnToRetry({ currentRound: currentRoundIndex, retryRound: testingRoundIndex });
                      setCurrentRoundIndex(testingRoundIndex);
                      setGameState('learning');
                      setLearningStep(0);
                    }
                  }}
                  className="bg-purple-600 hover:bg-purple-700 px-4 py-2 rounded-lg font-semibold transition text-sm"
                >
                  🔄 Replay Voting Phase
                </button>
              )}
            </div>
          )}

          {gameState === 'setup' && (
            <div className="bg-slate-800 p-4 rounded-lg">
              <h2 className="text-xl mb-3">Progressive Memory Training</h2>
              <p className="text-gray-300 text-sm mb-3">Practice remembering votes across multiple rounds:</p>
              <ul className="text-gray-300 text-sm space-y-1 mb-4">
                <li>• Round 1: 9 players</li>
                <li>• Round 2: 7 players + retry Round 1</li>
                <li>• Round 3: 5 players + retry all rounds</li>
              </ul>
              
              <h3 className="text-lg mb-2">Choose Difficulty</h3>
              <div className="space-y-2 mb-4">
                <button
                  onClick={() => setDifficulty('easy')}
                  className={`w-full p-3 rounded-lg transition text-sm ${difficulty === 'easy' ? 'bg-green-600' : 'bg-slate-700'}`}
                >
                  🟢 Easy - 3 candidates
                </button>
                <button
                  onClick={() => setDifficulty('medium')}
                  className={`w-full p-3 rounded-lg transition text-sm ${difficulty === 'medium' ? 'bg-yellow-600' : 'bg-slate-700'}`}
                >
                  🟡 Medium - 5 candidates
                </button>
                <button
                  onClick={() => setDifficulty('hard')}
                  className={`w-full p-3 rounded-lg transition text-sm ${difficulty === 'hard' ? 'bg-red-600' : 'bg-slate-700'}`}
                >
                  🔴 Hard - 7 candidates
                </button>
              </div>
              
              <button onClick={startGame} className="w-full bg-blue-600 hover:bg-blue-700 py-3 rounded-lg text-lg font-semibold">
                Start Training
              </button>
            </div>
          )}

          {(gameState === 'learning' || gameState === 'testing' || gameState === 'retry') && (
            <>
              <div className="bg-slate-800 p-3 rounded-lg mb-3">
                <h3 className="text-lg font-bold mb-2">
                  {gameState === 'learning' ? '📋 Candidates' : '❓ Testing'}
                </h3>
                {gameState === 'learning' && (
                  <div className="text-xs text-gray-400 mb-2">
                    Round {currentRoundIndex + 1} - {allRounds[currentRoundIndex]?.activePlayers} players
                  </div>
                )}
                {(gameState === 'testing' || gameState === 'retry') && (
                  <div className="text-xs text-gray-400 mb-2">
                    {gameState === 'retry' ? '🔄 Retry: ' : ''}Round {testingRoundIndex + 1}
                  </div>
                )}
                <div className="space-y-1.5">
                  {gameState === 'learning' && allRounds[currentRoundIndex]?.candidates.map(candidate => (
                    <div key={candidate} className={`p-2 rounded text-sm ${allRounds[currentRoundIndex].votes[learningStep]?.candidate === candidate ? 'bg-red-600' : 'bg-slate-700'}`}>
                      Player {candidate}
                    </div>
                  ))}
                  {(gameState === 'testing' || gameState === 'retry') && allRounds[testingRoundIndex]?.candidates.map(candidate => (
                    <div key={candidate} className={`p-2 rounded text-sm ${allRounds[testingRoundIndex].votes[testingCandidateIndex]?.candidate === candidate ? 'bg-red-600' : 'bg-slate-700'}`}>
                      Player {candidate}
                    </div>
                  ))}
                </div>

                {(gameState === 'testing' || gameState === 'retry') && (
                  <div className="mt-3 pt-3 border-t border-slate-700">
                    <h4 className="font-bold mb-1.5 text-sm">Current Scores:</h4>
                    <div className="space-y-0.5">{renderScoreList()}</div>
                  </div>
                )}
              </div>

              <div className="bg-slate-800 p-3 rounded-lg mb-3">
                {gameState === 'learning' && (
                  <>
                    <h2 className="text-lg font-bold text-center">
                      Receiving votes to Player {allRounds[currentRoundIndex]?.votes[learningStep]?.candidate}
                    </h2>
                    <p className="text-gray-400 text-sm text-center mt-1">Watch and remember...</p>
                    <div className="text-xs text-gray-500 text-center mt-1">
                      Vote {learningStep + 1} / {allRounds[currentRoundIndex]?.votes.length}
                    </div>
                  </>
                )}

                {(gameState === 'testing' || gameState === 'retry') && (
                  <>
                    {gameState === 'retry' && (
                      <div className="mb-2">
                        <h2 className="text-xl font-bold text-yellow-400 text-center">
                          🔄 RETRY: {allRounds[testingRoundIndex]?.activePlayers}P Round
                        </h2>
                      </div>
                    )}
                    <h2 className="text-lg font-bold text-center mb-1">
                      Who voted for Player {allRounds[testingRoundIndex]?.votes[testingCandidateIndex]?.candidate}?
                    </h2>
                    <p className="text-gray-400 text-sm text-center">Click all players who voted</p>
                    {!showFeedback && (
                      <button onClick={checkAnswer} className="mt-2 w-full bg-green-600 hover:bg-green-700 py-2 rounded-lg font-semibold text-sm">
                        Submit Answer
                      </button>
                    )}
                    {showFeedback && (
                      <div className="mt-2 text-center">
                        <p className="text-lg text-gray-400">
                          {selectedPlayers.length === allRounds[testingRoundIndex].votes[testingCandidateIndex].voters.length &&
                          selectedPlayers.every(p => allRounds[testingRoundIndex].votes[testingCandidateIndex].voters.includes(p))
                            ? '✅ Correct!'
                            : '❌ Incorrect'}
                        </p>
                        <p className="text-xs text-gray-400 mt-1">
                          Correct: {allRounds[testingRoundIndex].votes[testingCandidateIndex].voters.join(', ') || 'No one'}
                        </p>
                      </div>
                    )}
                  </>
                )}
              </div>

              <div className="relative" style={{ height: '280px' }}>
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="w-44 h-44 rounded-full bg-gradient-to-br from-amber-900 to-amber-800 shadow-2xl" />
                  {Array.from({ length: 10 }, (_, i) => i + 1).map(playerId => {
                    const pos = getPlayerPosition(playerId - 1);
                    return (
                      <div
                        key={playerId}
                        onClick={() => handlePlayerClick(playerId)}
                        className={`absolute w-11 h-11 rounded-full flex items-center justify-center text-base font-bold shadow-lg transition-all duration-300 ${
                          (playerStates[playerId] || (gameState === 'retry' && getPlayerStatesForRound(testingRoundIndex)[playerId])) ? 'cursor-not-allowed' : 'cursor-pointer'
                        } ${getPlayerColor(playerId)}`}
                        style={{
                          left: `calc(50% + ${pos.x}px - 1.375rem)`,
                          top: `calc(50% + ${pos.y}px - 1.375rem)`
                        }}
                      >
                        {playerId}
                        {getPlayerIcon(playerId)}
                      </div>
                    );
                  })}
                </div>
              </div>

              <div className="mt-3 flex flex-wrap justify-center gap-3 text-xs">
                <div className="flex items-center gap-1">
                  <div className="w-3 h-3 bg-red-500 rounded-full" />
                  <span>Candidate</span>
                </div>
                <div className="flex items-center gap-1">
                  <div className="w-3 h-3 bg-blue-500 rounded-full" />
                  <span>Voted</span>
                </div>
                <div className="flex items-center gap-1">
                  <span>🔫</span>
                  <span>Killed</span>
                </div>
                <div className="flex items-center gap-1">
                  <span>🔨</span>
                  <span>Elim.</span>
                </div>
              </div>
            </>
          )}

          {gameState === 'round-complete' && (
            <div className="bg-slate-800 p-4 rounded-lg">
              <h2 className="text-2xl font-bold text-center mb-3">Round {currentRoundIndex + 1} Complete!</h2>
              <div className="mb-4 text-sm">
                {allRounds.map((round, idx) => {
                  const score = calculateRoundScore(idx);
                  if (!score) return null;
                  return (
                    <div key={idx} className="mb-1">
                      Round {idx + 1}: {score.correct}/{score.total} ({Math.round(score.correct/score.total*100)}%)
                    </div>
                  );
                })}
              </div>
              <button onClick={processEliminationAndKill} className="w-full text-white bg-blue-600 hover:bg-blue-700 py-3 rounded-lg text-lg font-semibold">
                Process Night Phase
              </button>
            </div>
          )}

          {gameState === 'continue-prompt' && (
            <div className="bg-slate-800 p-4 rounded-lg">
              <h2 className="text-xl font-bold text-center mb-3">Night Phase Complete</h2>
              <div className="grid grid-cols-2 gap-3 mb-4">
                <div className="bg-red-900/30 p-3 rounded-lg">
                  <h3 className="text-sm font-bold mb-1">🔨 Eliminated</h3>
                  {Object.entries(playerStates)
                    .filter(([_, data]) => data.status === 'eliminated' && data.round === currentRoundIndex)
                    .map(([id, _]) => (<div key={id} className="text-lg font-bold">Player {id}</div>))}
                </div>
                <div className="bg-slate-700/30 p-3 rounded-lg">
                  <h3 className="text-sm font-bold mb-1">🔫 Killed</h3>
                  {Object.entries(playerStates)
                    .filter(([_, data]) => data.status === 'killed' && data.round === currentRoundIndex)
                    .map(([id, _]) => (<div key={id} className="text-lg font-bold">Player {id}</div>))}
                </div>
              </div>
              <p className="text-gray-300 text-sm text-center mb-4">
                {10 - Object.keys(playerStates).length} players remaining
              </p>
              <button onClick={continueToNextRound} className="w-full text-white bg-green-600 hover:bg-green-700 py-3 rounded-lg text-lg font-semibold">
                Continue to Next Voting Phase
              </button>
            </div>
          )}

          {gameState === 'final-results' && (
            <div className="bg-slate-800 p-4 rounded-lg">
              <h2 className="text-2xl font-bold text-center mb-3">🎯 Training Complete!</h2>
              <div className="text-5xl font-bold text-center mb-2">
                {getTotalScore().correct} / {getTotalScore().total}
              </div>
              <div className="text-2xl text-gray-400 text-center mb-4">
                {Math.round((getTotalScore().correct / getTotalScore().total) * 100)}%
              </div>
              <div className="space-y-3 mb-4 text-sm">
                {allRounds[0] && (
                  <div className="bg-slate-700 p-3 rounded-lg">
                    <div className="font-bold mb-1">Round 1 - 9 Players</div>
                    {(() => {
                      const originalScore = calculateRoundScore(0);
                      return originalScore ? <div className="ml-2">Original: {originalScore.correct}/{originalScore.total} ({Math.round(originalScore.correct/originalScore.total*100)}%)</div> : null;
                    })()}
                  </div>
                )}
                {allRounds[1] && (
                  <div className="bg-slate-700 p-3 rounded-lg">
                    <div className="font-bold mb-1">Round 2 - 7 Players</div>
                    <div className="ml-2 space-y-0.5 text-xs">
                      {(() => {
                        const originalScore = calculateRoundScore(1);
                        return originalScore ? <div className="text-sm">Original: {originalScore.correct}/{originalScore.total} ({Math.round(originalScore.correct/originalScore.total*100)}%)</div> : null;
                      })()}
                      {(() => {
                        const retry9 = calculateRetryScore(0, 1);
                        return retry9 ? <div className="text-gray-300">🔄 Retry 9P: {retry9.correct}/{retry9.total} ({Math.round(retry9.correct/retry9.total*100)}%)</div> : null;
                      })()}
                      {(() => {
                        const retry7 = calculateRetryScore(1, 1);
                        return retry7 ? <div className="text-gray-300">🔄 Retry 7P: {retry7.correct}/{retry7.total} ({Math.round(retry7.correct/retry7.total*100)}%)</div> : null;
                      })()}
                    </div>
                  </div>
                )}
                {allRounds[2] && (
                  <div className="bg-slate-700 p-3 rounded-lg">
                    <div className="font-bold mb-1">Round 3 - 5 Players</div>
                    <div className="ml-2 space-y-0.5 text-xs">
                      {(() => {
                        const originalScore = calculateRoundScore(2);
                        return originalScore ? <div className="text-sm">Original: {originalScore.correct}/{originalScore.total} ({Math.round(originalScore.correct/originalScore.total*100)}%)</div> : null;
                      })()}
                      {(() => {
                        const retry9 = calculateRetryScore(0, 2);
                        return retry9 ? <div className="text-gray-300">🔄 Retry 9P: {retry9.correct}/{retry9.total} ({Math.round(retry9.correct/retry9.total*100)}%)</div> : null;
                      })()}
                      {(() => {
                        const retry7 = calculateRetryScore(1, 2);
                        return retry7 ? <div className="text-gray-300">🔄 Retry 7P: {retry7.correct}/{retry7.total} ({Math.round(retry7.correct/retry7.total*100)}%)</div> : null;
                      })()}
                      {(() => {
                        const retry5 = calculateRetryScore(2, 2);
                        return retry5 ? <div className="text-gray-300">🔄 Retry 5P: {retry5.correct}/{retry5.total} ({Math.round(retry5.correct/retry5.total*100)}%)</div> : null;
                      })()}
                    </div>
                  </div>
                )}
              </div>
              <div className="text-lg text-center mb-4">
                {getTotalScore().correct === getTotalScore().total
                  ? '🌟 Perfect!'
                  : getTotalScore().correct / getTotalScore().total >= 0.8
                  ? '🎉 Excellent!'
                  : getTotalScore().correct / getTotalScore().total >= 0.6
                  ? '👍 Good job!'
                  : '💪 Keep training!'}
              </div>
              <button onClick={() => setGameState('setup')} className="w-full bg-blue-600 hover:bg-blue-700 py-3 rounded-lg text-lg font-semibold">
                Train Again
              </button>
            </div>
          )}
        </div>
      </div>
    );
  }

  // DESKTOP RENDER
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-800 text-white p-8">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-4xl font-bold text-center mb-2">🎭 Mafia Voting Practice</h1>
        <p className="text-center text-gray-300 mb-8">Improve your memory for Mafia voting rounds</p>

        {gameState !== 'setup' && (
          <div className="flex justify-center gap-4 mb-4">
            <button
              onClick={() => setGameState('setup')}
              className="bg-slate-700 hover:bg-slate-600 px-6 py-2 rounded-lg font-semibold transition"
            >
              ← Back to Main Menu
            </button>
            {(gameState === 'learning' || gameState === 'testing' || gameState === 'retry') && (
              <button
                onClick={() => {
                  if (gameState === 'learning') {
                    setLearningStep(0);
                  } else if (gameState === 'testing') {
                    setGameState('learning');
                    setLearningStep(0);
                  } else if (gameState === 'retry') {
                    setReturnToRetry({ currentRound: currentRoundIndex, retryRound: testingRoundIndex });
                    setCurrentRoundIndex(testingRoundIndex);
                    setGameState('learning');
                    setLearningStep(0);
                  }
                }}
                className="bg-purple-600 hover:bg-purple-700 px-6 py-2 rounded-lg font-semibold transition"
              >
                🔄 Replay Voting Phase
              </button>
            )}
          </div>
        )}

        {gameState === 'setup' && (
          <div className="text-center space-y-6">
            <div className="bg-slate-800 p-8 rounded-lg max-w-md mx-auto">
              <h2 className="text-2xl mb-4">Progressive Memory Training</h2>
              <p className="text-gray-300 mb-4">Practice remembering votes across multiple rounds:</p>
              <ul className="text-left text-gray-300 space-y-2 mb-6">
                <li>• Round 1: 9 players</li>
                <li>• Round 2: 7 players + retry Round 1</li>
                <li>• Round 3: 5 players + retry all rounds</li>
              </ul>
              
              <div className="mb-6">
                <h3 className="text-xl mb-3">Choose Difficulty</h3>
                <div className="space-y-3">
                  <button
                    onClick={() => setDifficulty('easy')}
                    className={`w-full p-4 rounded-lg transition ${difficulty === 'easy' ? 'bg-green-600' : 'bg-slate-700 hover:bg-slate-600'}`}
                  >
                    🟢 Easy - 3 candidates
                  </button>
                  <button
                    onClick={() => setDifficulty('medium')}
                    className={`w-full p-4 rounded-lg transition ${difficulty === 'medium' ? 'bg-yellow-600' : 'bg-slate-700 hover:bg-slate-600'}`}
                  >
                    🟡 Medium - 5 candidates
                  </button>
                  <button
                    onClick={() => setDifficulty('hard')}
                    className={`w-full p-4 rounded-lg transition ${difficulty === 'hard' ? 'bg-red-600' : 'bg-slate-700 hover:bg-slate-600'}`}
                  >
                    🔴 Hard - 7 candidates
                  </button>
                </div>
              </div>
              
              <button onClick={startGame} className="bg-blue-600 hover:bg-blue-700 px-8 py-4 rounded-lg text-xl font-semibold transition">
                Start Training
              </button>
            </div>
          </div>
        )}

        {(gameState === 'learning' || gameState === 'testing' || gameState === 'retry') && (
          <div className="flex gap-8">
            <div className="w-64 bg-slate-800 p-6 rounded-lg h-fit">
              <h3 className="text-xl font-bold mb-4">
                {gameState === 'learning' ? '📋 Candidates' : '❓ Testing'}
              </h3>
              {gameState === 'learning' && (
                <div className="text-sm text-gray-400 mb-4">
                  Round {currentRoundIndex + 1} - {allRounds[currentRoundIndex]?.activePlayers} players
                </div>
              )}
              {(gameState === 'testing' || gameState === 'retry') && (
                <div className="text-sm text-gray-400 mb-4">
                  {gameState === 'retry' ? '🔄 Retry: ' : ''}Round {testingRoundIndex + 1}
                </div>
              )}
              <div className="space-y-2">
                {gameState === 'learning' && allRounds[currentRoundIndex]?.candidates.map(candidate => (
                  <div key={candidate} className={`p-3 rounded ${allRounds[currentRoundIndex].votes[learningStep]?.candidate === candidate ? 'bg-red-600' : 'bg-slate-700'}`}>
                    Player {candidate}
                  </div>
                ))}
                {(gameState === 'testing' || gameState === 'retry') && allRounds[testingRoundIndex]?.candidates.map(candidate => (
                  <div key={candidate} className={`p-3 rounded ${allRounds[testingRoundIndex].votes[testingCandidateIndex]?.candidate === candidate ? 'bg-red-600' : 'bg-slate-700'}`}>
                    Player {candidate}
                  </div>
                ))}
              </div>

              {(gameState === 'testing' || gameState === 'retry') && (
                <div className="mt-6 pt-6 border-t border-slate-700">
                  <h4 className="font-bold mb-2">Current Scores:</h4>
                  <div className="space-y-1">{renderScoreList()}</div>
                </div>
              )}
            </div>

            <div className="flex-1">
              {gameState === 'learning' && (
                <div className="text-center mb-6 bg-slate-800 p-4 rounded-lg">
                  <h2 className="text-2xl font-bold">
                    Receiving votes to Player {allRounds[currentRoundIndex]?.votes[learningStep]?.candidate}
                  </h2>
                  <p className="text-gray-400 mt-2">Watch and remember...</p>
                  <div className="mt-2 text-sm text-gray-500">
                    Vote {learningStep + 1} / {allRounds[currentRoundIndex]?.votes.length}
                  </div>
                </div>
              )}

              {(gameState === 'testing' || gameState === 'retry') && (
                <div className="text-center mb-6 bg-slate-800 p-4 rounded-lg">
                  {gameState === 'retry' && (
                    <div className="mb-4">
                      <h2 className="text-3xl font-bold text-yellow-400">
                        🔄 RETRY MODE: {allRounds[testingRoundIndex]?.activePlayers} Players Round
                      </h2>
                    </div>
                  )}
                  <h2 className="text-2xl font-bold mb-2">
                    Who voted for Player {allRounds[testingRoundIndex]?.votes[testingCandidateIndex]?.candidate}?
                  </h2>
                  <p className="text-gray-400">Click on all players who voted</p>
                  {!showFeedback && (
                    <button onClick={checkAnswer} className="mt-4 bg-green-600 hover:bg-green-700 px-6 py-2 rounded-lg font-semibold transition">
                      Submit Answer
                    </button>
                  )}
                  {showFeedback && (
                    <div className="mt-4">
                      <p className="text-xl text-gray-400">
                        {selectedPlayers.length === allRounds[testingRoundIndex].votes[testingCandidateIndex].voters.length &&
                        selectedPlayers.every(p => allRounds[testingRoundIndex].votes[testingCandidateIndex].voters.includes(p))
                          ? '✅ Correct!'
                          : '❌ Incorrect'}
                      </p>
                      <p className="text-sm text-gray-400 mt-2">
                        Correct: {allRounds[testingRoundIndex].votes[testingCandidateIndex].voters.join(', ') || 'No one'}
                      </p>
                    </div>
                  )}
                </div>
              )}

              <div className="relative" style={{ height: '500px' }}>
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="w-80 h-80 rounded-full bg-gradient-to-br from-amber-900 to-amber-800 shadow-2xl" />
                  {Array.from({ length: 10 }, (_, i) => i + 1).map(playerId => {
                    const pos = getPlayerPosition(playerId - 1);
                    return (
                      <div
                        key={playerId}
                        onClick={() => handlePlayerClick(playerId)}
                        className={`absolute w-16 h-16 rounded-full flex items-center justify-center text-xl font-bold shadow-lg transition-all duration-300 ${
                          (playerStates[playerId] || (gameState === 'retry' && getPlayerStatesForRound(testingRoundIndex)[playerId])) ? 'cursor-not-allowed' : 'cursor-pointer'
                        } ${getPlayerColor(playerId)}`}
                        style={{
                          left: `calc(50% + ${pos.x}px - 2rem)`,
                          top: `calc(50% + ${pos.y}px - 2rem)`
                        }}
                      >
                        {playerId}
                        {getPlayerIcon(playerId)}
                      </div>
                    );
                  })}
                </div>
              </div>

              <div className="mt-6 flex justify-center gap-6 text-sm flex-wrap">
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 bg-red-500 rounded-full" />
                  <span>Candidate</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 bg-blue-500 rounded-full" />
                  <span>Voted</span>
                </div>
                <div className="flex items-center gap-2">
                  <span>🔫</span>
                  <span>Killed at night</span>
                </div>
                <div className="flex items-center gap-2">
                  <span>🔨</span>
                  <span>Eliminated by vote</span>
                </div>
              </div>
            </div>
          </div>
        )}

        {gameState === 'round-complete' && (
          <div className="text-center space-y-6">
            <div className="bg-slate-800 p-8 rounded-lg max-w-2xl mx-auto">
              <h2 className="text-3xl font-bold mb-6">Round {currentRoundIndex + 1} Complete!</h2>
              <div className="mb-6">
                {allRounds.map((round, idx) => {
                  const score = calculateRoundScore(idx);
                  if (!score) return null;
                  return (
                    <div key={idx} className="text-lg mb-2">
                      Round {idx + 1}: {score.correct}/{score.total} ({Math.round(score.correct/score.total*100)}%)
                    </div>
                  );
                })}
              </div>
              <button onClick={processEliminationAndKill} className="bg-blue-600 text-white hover:bg-blue-700 px-8 py-4 rounded-lg text-xl font-semibold transition">
                Process Night Phase
              </button>
            </div>
          </div>
        )}

        {gameState === 'continue-prompt' && (
          <div className="text-center space-y-6">
            <div className="bg-slate-800 p-8 rounded-lg max-w-md mx-auto">
              <h2 className="text-2xl font-bold mb-4">Night Phase Complete</h2>
              <div className="grid grid-cols-2 gap-4 mb-6">
                <div className="bg-red-900/30 p-4 rounded-lg">
                  <h3 className="text-lg mb-2">🔨 Eliminated</h3>
                  {Object.entries(playerStates)
                    .filter(([_, data]) => data.status === 'eliminated' && data.round === currentRoundIndex)
                    .map(([id, _]) => (<div key={id} className="text-xl font-bold">Player {id}</div>))}
                </div>
                <div className="bg-slate-700/30 p-4 rounded-lg">
                  <h3 className="text-lg mb-2">🔫 Killed</h3>
                  {Object.entries(playerStates)
                    .filter(([_, data]) => data.status === 'killed' && data.round === currentRoundIndex)
                    .map(([id, _]) => (<div key={id} className="text-xl font-bold">Player {id}</div>))}
                </div>
              </div>
              <p className="text-gray-300 mb-6">{10 - Object.keys(playerStates).length} players remaining</p>
              <button onClick={continueToNextRound} className="bg-green-600 text-white hover:bg-green-700 px-8 py-4 rounded-lg text-xl font-semibold transition">
                Continue to Next Voting Phase
              </button>
            </div>
          </div>
        )}

        {gameState === 'final-results' && (
          <div className="text-center space-y-6">
            <div className="bg-slate-800 p-8 rounded-lg max-w-3xl mx-auto">
              <h2 className="text-4xl font-bold mb-6">🎯 Training Complete!</h2>
              <div className="text-6xl font-bold mb-4">{getTotalScore().correct} / {getTotalScore().total}</div>
              <div className="text-3xl text-gray-400 mb-8">{Math.round((getTotalScore().correct / getTotalScore().total) * 100)}% Accuracy</div>
              <div className="space-y-6 mb-8 text-left">
                {allRounds[0] && (
                  <div className="bg-slate-700 p-5 rounded-lg">
                    <div className="text-xl font-bold mb-3">Round 1 - 9 Players</div>
                    {(() => {
                      const originalScore = calculateRoundScore(0);
                      return originalScore ? (
                        <div className="ml-4 text-lg">
                          Original Test: {originalScore.correct}/{originalScore.total} ({Math.round(originalScore.correct/originalScore.total*100)}%)
                        </div>
                      ) : null;
                    })()}
                  </div>
                )}
                {allRounds[1] && (
                  <div className="bg-slate-700 p-5 rounded-lg">
                    <div className="text-xl font-bold mb-3">Round 2 - 7 Players</div>
                    <div className="ml-4 space-y-2">
                      {(() => {
                        const originalScore = calculateRoundScore(1);
                        return originalScore ? (
                          <div className="text-lg">
                            Original Test: {originalScore.correct}/{originalScore.total} ({Math.round(originalScore.correct/originalScore.total*100)}%)
                          </div>
                        ) : null;
                      })()}
                      {(() => {
                        const retry9 = calculateRetryScore(0, 1);
                        return retry9 ? (
                          <div className="text-gray-300">
                            🔄 Retry 9 Players: {retry9.correct}/{retry9.total} ({Math.round(retry9.correct/retry9.total*100)}%)
                          </div>
                        ) : null;
                      })()}
                      {(() => {
                        const retry7 = calculateRetryScore(1, 1);
                        return retry7 ? (
                          <div className="text-gray-300">
                            🔄 Retry 7 Players: {retry7.correct}/{retry7.total} ({Math.round(retry7.correct/retry7.total*100)}%)
                          </div>
                        ) : null;
                      })()}
                    </div>
                  </div>
                )}
                {allRounds[2] && (
                  <div className="bg-slate-700 p-5 rounded-lg">
                    <div className="text-xl font-bold mb-3">Round 3 - 5 Players</div>
                    <div className="ml-4 space-y-2">
                      {(() => {
                        const originalScore = calculateRoundScore(2);
                        return originalScore ? (
                          <div className="text-lg">
                            Original Test: {originalScore.correct}/{originalScore.total} ({Math.round(originalScore.correct/originalScore.total*100)}%)
                          </div>
                        ) : null;
                      })()}
                      {(() => {
                        const retry9 = calculateRetryScore(0, 2);
                        return retry9 ? (
                          <div className="text-gray-300">
                            🔄 Retry 9 Players: {retry9.correct}/{retry9.total} ({Math.round(retry9.correct/retry9.total*100)}%)
                          </div>
                        ) : null;
                      })()}
                      {(() => {
                        const retry7 = calculateRetryScore(1, 2);
                        return retry7 ? (
                          <div className="text-gray-300">
                            🔄 Retry 7 Players: {retry7.correct}/{retry7.total} ({Math.round(retry7.correct/retry7.total*100)}%)
                          </div>
                        ) : null;
                      })()}
                      {(() => {
                        const retry5 = calculateRetryScore(2, 2);
                        return retry5 ? (
                          <div className="text-gray-300">
                            🔄 Retry 5 Players: {retry5.correct}/{retry5.total} ({Math.round(retry5.correct/retry5.total*100)}%)
                          </div>
                        ) : null;
                      })()}
                    </div>
                  </div>
                )}
              </div>
              <div className="text-2xl mb-6">
                {getTotalScore().correct === getTotalScore().total
                  ? '🌟 Perfect Score! Incredible memory!'
                  : getTotalScore().correct / getTotalScore().total >= 0.8
                  ? '🎉 Excellent! Your memory is sharp!'
                  : getTotalScore().correct / getTotalScore().total >= 0.6
                  ? '👍 Good job! Keep practicing!'
                  : '💪 Keep training, you\'ll improve!'}
              </div>
              <button onClick={() => setGameState('setup')} className="bg-blue-600 hover:bg-blue-700 px-8 py-4 rounded-lg text-xl font-semibold transition">
                Train Again
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default MafiaVotingGame;
