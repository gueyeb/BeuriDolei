# BeuriDolei — Claude Context

## What it is
App iOS minimaliste de **challenge planche 30 jours** ("beuri dolei" = "tiens bon" en wolof) : objectif quotidien, timer avec pause/reprise, suivi de série (streak), historique local, rappels quotidiens. MVP volontairement sans compte, sans cloud sync, sans social.

## Stack
- **iOS 17+**, SwiftUI, `SWIFT_VERSION = 5.0` (⚠️ la doc du repo mentionne "Swift 6" mais le build setting réel est 5.0 — mismatch doc/réalité, ne pas supposer les features Swift 6 disponibles)
- **Architecture**: MVVM léger — un seul `ObservableObject` store partagé (pas de ViewModels par vue)
- **Persistence**: `UserDefaults` (JSON via Codable) — pas de Core Data/SwiftData
- **Backend**: aucun, 100% local
- **Packages tiers**: aucun (pas de `Package.swift`, pas de Podfile)
- **HealthKit**: entitlement write-only (workout sync), pas de lecture de données Santé
- **Widget**: target `BeuriDoleiWidget` (App Extension), partage l'état via l'App Group `group.com.dakhine.BeuriDolei` (`Shared/WidgetSnapshot.swift`) — **ajouté le 2026-07-08, jamais compilé** (voir Pitfalls)
- **Onboarding**: écrans d'intro au premier lancement, flag `UserPreferences.hasCompletedOnboarding`

## Key files
| File | Purpose |
|------|---------|
| `BeuriDoleiApp.swift` | `@main`, crée le `ChallengeStore`, force le dark mode |
| `ContentView.swift` | Gate onboarding puis root `TabView` (Séance / Progression / Réglages), bootstrap permissions après l'onboarding |
| `Views/OnboardingView.swift` | 3 écrans d'intro au premier lancement |
| `Store/ChallengeStore.swift` | `@MainActor` ObservableObject — source de vérité unique, calcul de streak, load/save, pousse un `WidgetSnapshot` + `WidgetCenter.reloadTimelines` à chaque save |
| `Models/ChallengeDay.swift` | Programme statique 30 jours (dayIndex + séries), progressif 20s→5min |
| `Models/PlankSession.swift` | Session Codable, logique `isCompleted` |
| `Services/HealthKitManager.swift` | Singleton, sync workout HKHealthStore (optionnel, write-only) |
| `Services/NotificationManager.swift` | Singleton, rappels quotidiens + notif de félicitations |
| `Views/HomeView.swift`, `TimerView.swift`, `CompletionView.swift`, `ProgressView.swift`, `SettingsView.swift` | Écrans principaux |
| `Views/ShareCardView.swift` | Carte image récap (jour/streak/temps), rendue via `ImageRenderer` et partagée via `ShareLink` depuis `CompletionView` |
| `Shared/WidgetSnapshot.swift` | État minimal (jour/streak/complété) partagé app ↔ widget via App Group |
| `BeuriDoleiWidget/` | Target Widget Extension (jour courant + streak sur l'écran d'accueil) |

## Directory structure
```
BeuriDolei/
├── BeuriDolei/
│   ├── BeuriDoleiApp.swift
│   ├── ContentView.swift
│   ├── Models/            # ChallengeDay, PlankSession, PlankVariant, UserPreferences
│   ├── Store/              # ChallengeStore (état global)
│   ├── Services/           # HealthKitManager, NotificationManager
│   ├── Views/              # Home, Timer, Completion, Progress, Settings, Onboarding, ShareCard
│   ├── Shared/             # WidgetSnapshot.swift (app + widget)
│   ├── Assets.xcassets/
│   ├── PrivacyInfo.xcprivacy
│   └── BeuriDolei.entitlements  # HealthKit + App Group
├── BeuriDoleiWidget/       # Target Widget Extension
└── BeuriDoleiTests/        # XCTest — ChallengeStoreTests
```

## Commands
```bash
open BeuriDolei/BeuriDolei.xcodeproj
xcodebuild -project BeuriDolei/BeuriDolei.xcodeproj -scheme BeuriDolei -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -project BeuriDolei/BeuriDolei.xcodeproj -scheme BeuriDolei -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' test
xcodebuild -project BeuriDolei/BeuriDolei.xcodeproj -list
```

## Conventions
- Conventional Commits (`feat:`, `fix:`, `refactor:`)
- Refs Linear dans certains messages de commit (`DAK-xxx`)
- AGENTS.md prescrit une séparation MVVM (Views/ViewModels/Models/Services) — pas encore respectée : les vues consomment `ChallengeStore` directement via `@EnvironmentObject`, pas de dossier `ViewModels/`
- Modifications de target/`.pbxproj` : passer par la gem Ruby `xcodeproj` plutôt que d'éditer le texte à la main (utilisé pour créer `BeuriDoleiWidget`)
- `docs/HANDOVER.md` = mémoire de session partagée Humain/Claude Code/Codex ; `docs/FEATURE_BACKLOG.md` = statut des features (IDs `BD-xxx`)

## Pitfalls
- **Build non vérifié depuis le 2026-07-08** : le SDK Xcode local est passé en iOS 26.5 sans le runtime simulateur correspondant (seul 26.3 est installé) → `xcodebuild build` échoue à `CompileAssetCatalogVariant`. Onboarding, bouton "recommencer la série", partage image et le target `BeuriDoleiWidget` ont été codés et relus manuellement mais **jamais compilés**. Voir `docs/HANDOVER.md` pour le détail et la procédure de déblocage (libérer du disque, `xcodebuild -downloadPlatform iOS`).
- 1 seul workflow GitHub Actions (`ios.yml`) — les templates génériques ont été supprimés (BD-008)
- Vérifier le build setting Swift réel avant d'utiliser des features Swift 6 (voir Stack ci-dessus)
- HealthKit est write-only — ne pas supposer un accès en lecture aux données Santé
