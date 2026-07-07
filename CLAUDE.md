# BeuriDolei — Claude Context

## What it is
App iOS minimaliste de **challenge planche 30 jours** ("beuri dolei" = "tiens bon" en wolof) : objectif quotidien, timer avec pause/reprise, suivi de série (streak), historique local, rappels quotidiens. MVP volontairement sans compte, sans cloud sync, sans social.

## Stack
- **iOS 17+**, SwiftUI, `SWIFT_VERSION = 5.0` (⚠️ la doc du repo mentionne "Swift 6" mais le build setting réel est 5.0 — mismatch doc/réalité, ne pas supposer les features Swift 6 disponibles)
- **Architecture**: MVVM léger — un seul `ObservableObject` store partagé (pas de ViewModels par vue)
- **Persistence**: `UserDefaults` (JSON via Codable) — pas de Core Data/SwiftData
- **Backend**: aucun, 100% local
- **Packages tiers**: aucun (pas de `Package.swift`, pas de Podfile)
- **HealthKit**: entitlement présent et câblé (sync workout) bien que listé comme non-goal MVP dans le PRD — a été livré quand même

## Key files
| File | Purpose |
|------|---------|
| `BeuriDoleiApp.swift` | `@main`, crée le `ChallengeStore`, force le dark mode, bootstrap permissions |
| `ContentView.swift` | Root `TabView` (Séance / Progression / Réglages) |
| `Store/ChallengeStore.swift` | `@MainActor` ObservableObject — source de vérité unique, calcul de streak, load/save |
| `Models/ChallengeDay.swift` | Programme statique 30 jours (dayIndex + séries) |
| `Models/PlankSession.swift` | Session Codable, logique `isCompleted` |
| `Services/HealthKitManager.swift` | Singleton, sync workout HKHealthStore (optionnel) |
| `Services/NotificationManager.swift` | Singleton, rappels quotidiens + notif de félicitations |
| `Views/HomeView.swift`, `TimerView.swift`, `CompletionView.swift`, `ProgressView.swift`, `SettingsView.swift` | Écrans principaux |

## Directory structure
```
BeuriDolei/BeuriDolei/
├── BeuriDoleiApp.swift
├── ContentView.swift
├── Models/            # ChallengeDay, PlankSession, PlankVariant, UserPreferences
├── Store/              # ChallengeStore (état global)
├── Services/           # HealthKitManager, NotificationManager
├── Views/              # Home, Timer, Completion, Progress, Settings
├── Assets.xcassets/
└── BeuriDolei.entitlements  # HealthKit
```

## Commands
```bash
open BeuriDolei/BeuriDolei.xcodeproj
xcodebuild -project BeuriDolei/BeuriDolei.xcodeproj -scheme BeuriDolei -configuration Debug build
xcodebuild -project BeuriDolei/BeuriDolei.xcodeproj -list
```

## Conventions
- Conventional Commits (`feat:`, `fix:`, `refactor:`)
- Refs Linear dans certains messages de commit (`DAK-xxx`)
- AGENTS.md prescrit une séparation MVVM (Views/ViewModels/Models/Services) — pas encore respectée : les vues consomment `ChallengeStore` directement via `@EnvironmentObject`, pas de dossier `ViewModels/`

## Pitfalls
- **Aucun test target** (`BeuriDoleiTests`/`BeuriDoleiUITests` n'existent pas)
- 3 workflows GitHub Actions présents (`ios.yml`, `swift.yml`, `objective-c-xcode.yml`) mais ce sont des templates génériques non adaptés — `swift.yml` échouera (`swift build`/`swift test` sans `Package.swift`), les autres n'ont rien à tester
- Vérifier le build setting Swift réel avant d'utiliser des features Swift 6 (voir Stack ci-dessus)
- HealthKit est câblé malgré le PRD — vérifier l'entitlement avant de le supposer absent
