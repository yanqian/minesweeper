# Minesweeper iOS Implementation Tasks

## Status
- [x] Scaffold Xcode SwiftUI project structure
- [x] Implement game models (board, cells, modes, state)
- [x] Implement game logic (mine placement, first-tap safety, flood reveal, win/lose)
- [x] Implement UI (board, header, mode switching, custom mode)
- [x] Implement long-press flagging
- [x] Add metrics tracking and persistence
- [x] Add haptics and success sound feedback
- [x] Add unit tests for board generation and win logic
- [x] Fix Xcode build issues and warnings
- [x] Make stats panel collapsible to enlarge board space
- [x] Add pinch-to-zoom for the board
- [x] Split Custom mode into settings page and full-board game page
- [x] Add played/won stats in the summary panels
- [x] Make timer pause on inactive modes and keep it red for visibility
- [x] Adjust board sizing to fit screen width on smaller devices
- [x] Replace mode indicator with a top bar (mode picker, start button, timer)
- [x] Disable swipe mode switching and auto-scale larger boards to use more height
## Notes
- Implementation PR: https://github.com/yanqian/minesweeper/pull/5
- Tests: `xcodebuild -scheme Minesweeper -sdk iphonesimulator -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' test CODE_SIGNING_ALLOWED=NO`
