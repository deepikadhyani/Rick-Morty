# Rick & Morty iOS App

Built with SwiftUI + Clean Architecture against the [Rick & Morty REST API](https://rickandmortyapi.com/api).

---

## Architecture

Three layers — Presentation, Domain, Data. Domain is pure Swift with zero framework imports. Everything else points inward.

```
Rick&Morty/
├── Domain/           # Pure Swift. No UIKit, no Foundation networking.
│   ├── Models/       # Character, Episode
│   ├── Interfaces/   # CharacterRepositoryProtocol
│   └── UseCases/     # FetchCharactersUseCase, FetchEpisodesUseCase
├── Data/             # Implements domain contracts
│   ├── DTOs/         # API response shapes + toDomain() mappers
│   ├── Network/      # NetworkService (URLSession wrapped behind a protocol)
│   └── Repositories/ # CharacterRepository
└── Presentation/
    ├── CharacterList/
    └── CharacterDetail/
```

All dependencies are constructor-injected. `Rick_MortyApp.swift` is the composition root — the full graph is built once there and nothing is a singleton.

ViewModels expose a single `state` enum (`loading / loaded / empty / error`). Views just switch on it — no logic lives there.

---

## Features

- Character list with infinite scroll (threshold-based, loads next page 5 items before the end)
- Debounced search by name — 500ms, cancels in-flight requests when query changes
- Status badge colour-coded per character (Alive / Dead / Unknown)
- Detail screen with full character info + episode list sorted chronologically
- Dark Mode — all colours are semantic so it works out of the box

---

## Tests

Three suites in `Rick_MortyTests.swift`:

- **FetchCharactersUseCaseTests** — input sanitization, parameter forwarding, error propagation
- **NetworkServiceTests** — uses `MockURLProtocol` injected via `URLSessionConfiguration` to test decode success, bad status codes, and malformed JSON without hitting the real network
- **CharacterListViewModelTests** — state transitions, pagination, search reset, double-fetch guard

Run with `Cmd+U`.

---

## A few decisions worth noting

**404 = empty, not an error.** The API returns 404 when a search has no results instead of a 200 with an empty array. The repository catches this and returns `[]` so the UI shows the empty state rather than an error screen.

**Episode batch request.** Characters can appear in 20+ episodes. Instead of making N serial requests, the repository uses the batch endpoint (`/episode/1,2,3`). One catch — the API returns a single object when you request one ID and an array for multiple, so both shapes are handled.

**`SDWebImageSwiftUI` for images.** Gives disk + memory caching without having to build it. Could be replaced with a custom `AsyncImage` wrapper but it wasn't worth the time for this scope.

**Debounce with `Task.sleep`.** No Combine — kept the whole codebase on one concurrency model. Cancels the previous task on each keystroke, waits 500ms, then fires.

---

## What I'd add next

- Offline support — cache last successful response to disk, serve it when there's no connectivity
- UI + snapshot tests — logic is covered but the views aren't tested at all
- Skeleton loaders — the `ProgressView` works but placeholder rows would feel better
- Favourites — heart toggle persisted with SwiftData

---

## Requirements

iOS 16+ / Xcode 15+ / Swift 5.9+

No setup needed — open the `.xcodeproj` and run.


