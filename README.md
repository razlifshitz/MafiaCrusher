# Mafia Voting Practice - Flutter App

A memory training game for Mafia voting rounds, converted from React/JSX to Flutter.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── game_models.dart     # Game state models and enums
├── screens/
│   └── game_screen.dart     # Main game screen with all logic
└── widgets/
    └── circular_player_layout.dart  # Circular player layout widget
```

## Features

- **Progressive Memory Training**: 3 rounds with increasing difficulty
- **Difficulty Levels**: Easy (3 candidates), Medium (5 candidates), Hard (7 candidates)
- **Learning Phase**: Watch votes being cast automatically
- **Testing Phase**: Recall who voted for each candidate
- **Retry System**: Test memory of previous rounds
- **Responsive Design**: Works on mobile and desktop
- **Visual Feedback**: Color-coded players and feedback system

## Getting Started

1. Make sure you have Flutter installed:
   ```bash
   flutter --version
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## How to Play

1. **Setup**: Choose your difficulty level (Easy, Medium, or Hard)
2. **Learning Phase**: Watch as votes are cast - remember who votes for whom
3. **Testing Phase**: For each candidate, select all players who voted for them
4. **Retry Phase**: After completing a round, retry previous rounds to test retention
5. **Night Phase**: Process eliminations and kills between rounds
6. **Results**: View your final score and performance breakdown

## Game Flow

- **Round 1**: 9 active players
- **Round 2**: 7 active players + retry Round 1
- **Round 3**: 5 active players + retry all previous rounds

Each round tests your memory of voting patterns, with progressive difficulty as you advance.

