# Minesweeper iOS App

## Summary
Design doc for the Minesweeper iOS app with menu-based mode switching, custom mode configuration, gameplay interactions, and metrics tracking. Primary task: https://github.com/yanqian/minesweeper/issues/1

## Goals
- Deliver a modern Swift/SwiftUI Minesweeper app with clear, responsive gameplay.
- Start in Easy mode and allow mode changes via a top bar menu.
- Support Easy, Medium, Hard, and Custom modes with safe custom bounds.
- Track and persist success rate, duration, and other core metrics per mode and overall.
- Provide win/lose results with haptic failure feedback and success sound.

## Non-Goals
- Multiplayer or online leaderboards.
- Cloud sync or cross-device persistence.
- Theming or skin marketplace.

## Background / Context
The user wants a native iOS Minesweeper experience implemented in modern Swift and SwiftUI. The UX should center on a clean top bar for mode selection, quick flagging with long-press, and persistent player stats.

## Proposed Design

### UX Flow
- App launches into Easy mode.
- Use the top bar to pick mode (Easy/Medium/Hard/Custom).
- Tap a cell to reveal. Long-press to flag or unflag.
- Use `Start` to begin a new game for the current mode.
- When the game ends, show a result modal with win/lose messaging and a restart action.
- On loss, play a system haptic error (vibration). On win, play a short success sound.

### Mode Navigation
- Use a top bar with a mode picker (menu), `Start` button, and timer.
- Order modes as [Easy, Medium, Hard, Custom]. Default mode is Easy.
- Swipe-based mode switching is disabled.

### Custom Mode
- Custom screen exposes steppers for rows, columns, and mine count.
- Safe bounds (initial proposal):
  - Rows: 8 to 24
  - Columns: 8 to 30
  - Mines: 10% to 30% of total cells, with an absolute minimum of 10
- Changes apply on confirm and start a new game instance.
- Custom settings live on a dedicated page; the game board is shown on a separate page with a Settings button to return.

### Gameplay Model
- `GameMode`: `.easy`, `.medium`, `.hard`, `.custom(config)`
- `Cell`: `isMine`, `isRevealed`, `isFlagged`, `adjacentMines`
- `Board`: rows, cols, mines, cells array
- `GameState`: board, status (`playing`, `won`, `lost`), startTime, endTime

### Mine Placement and Reveal Rules
- Place mines randomly at game start, avoiding the first tapped cell to ensure the first reveal is safe.
- Compute adjacent mine counts after placement.
- On reveal:
  - If mine: end game as loss.
  - If zero adjacent mines: flood-fill reveal all connected zero cells and their borders.
  - If flagged: ignore reveal.

### Metrics
Track per mode and overall:
- `gamesPlayed`
- `gamesWon`
- `successRate` (derived)
- `totalTimeSeconds`
- `bestTimeSeconds`
- `averageTimeSeconds` (derived)
- `lastPlayedAt`
UI shows `gamesPlayed` and `gamesWon` in the stats panel.

Store metrics in a `StatsStore` using `Codable` persisted to JSON in Application Support or UserDefaults. Application Support is preferred for clarity and size stability.

### Architecture
- SwiftUI + MVVM
- `GameViewModel` manages `GameState`, starts new games, and handles input.
- `StatsStore` is an `ObservableObject` and shared via environment.
- `SoundManager` handles success audio using `AVAudioPlayer`.
- `Haptics` helper uses `UINotificationFeedbackGenerator` for failure.

## Data / API Changes
- Local persistence only. No network APIs.
- App storage file: `stats.json` with versioned schema for future upgrades.

## Security / Privacy
- No personal data collected. Metrics are stored locally on device.

## Rollout Plan
- Phase 1: Core gameplay and mode switching.
- Phase 2: Custom mode and settings bounds.
- Phase 3: Metrics persistence and result feedback polish.

## Test Plan
- Unit tests for board generation, mine placement, and flood-fill reveal.
- Unit tests for metrics aggregation per mode and overall.
- UI tests for swipe navigation and result modal flows.
- Manual tests on device for haptics and sound behavior.

## Open Questions
None.
