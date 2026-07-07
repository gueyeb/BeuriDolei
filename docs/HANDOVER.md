# Handover agents BeuriDolei

Utiliser ce fichier comme mémoire de session partagée entre Humain, Claude Code et Codex.

## Session courante

- Date: 2026-07-08
- Objectif courant: BD-014/015/016 (onboarding, annuler série, partage résultat) + BD-V2-003 (widget) + BD-V2-004 (audit TestFlight) implémentés par Claude Code. **Build jamais vérifié** — environnement Xcode bloqué (voir ci-dessous).
- Feature active: aucune
- Owner: humain — lancer un build dès que l'environnement le permet, avant de considérer ce lot comme `done`.
- Status: BD-001 à BD-013 terminés et vérifiés (build+tests). BD-014/015/016/V2-003/V2-004 codés mais **non compilés** dans cette session à cause d'un problème d'environnement local (voir "Blocage environnement").

## Blocage environnement (2026-07-08)

- Le SDK Xcode local est passé à iOS 26.5 (probable mise à jour macOS silencieuse) mais seul le runtime simulateur iOS 26.3 est installé → `xcodebuild build` échoue à l'étape `CompileAssetCatalogVariant` (`No simulator runtime version ... available to use with iphonesimulator SDK version 23F81a`). Déjà repéré par Codex la veille avec le même symptôme.
- Tentative de téléchargement du runtime iOS 26.5 via `xcodebuild -downloadPlatform iOS` : a d'abord échoué par manque d'espace disque, puis pendant le nettoyage le disque a chuté à moins de 2 Go libres à cause d'un téléchargement automatique de mise à jour macOS (26.5.2) en arrière-plan, aggravé par un process `xcodebuild -downloadAllPlatforms` resté actif par erreur (tué depuis). **Décision humaine** : ne pas continuer à consommer de disque, coder sans vérifier par build.
- Conséquence : tout le travail de cette session (BD-014, BD-015, BD-016, BD-V2-003) a été relu manuellement (pas de faute de syntaxe évidente, imports cohérents, `pbxproj` validé via `plutil -lint` et `xcodebuild -list`) mais **jamais compilé ni exécuté**.
- Action recommandée avant tout autre travail : libérer de l'espace disque (viser 10 Go+ libres), vérifier/mettre en pause la mise à jour macOS en cours si toujours active, télécharger le runtime iOS 26.5 (`xcodebuild -downloadPlatform iOS`), puis lancer `xcodebuild build` + `xcodebuild test` complets sur ce lot avant QA simulateur.
- **Session arrêtée le 2026-07-08 sur décision humaine** à cause du risque disque (~3,3 Go libres en fin de session, mise à jour macOS toujours potentiellement active). Code commité tel quel, non vérifié par build. Prochaine session : commencer par vérifier l'espace disque disponible avant toute commande Xcode.

## Tranche active

- Feature ID: BD-014, BD-015, BD-016, BD-V2-003, BD-V2-004
- Objectif: vérifier par build + tests le lot livré ce jour, puis QA manuelle simulateur (onboarding, bouton "recommencer la série", partage image, widget en Aujourd'hui).
- Critères d'acceptation: `xcodebuild build` et `xcodebuild test` passent sans erreur; onboarding s'affiche une seule fois; le widget affiche jour/streak et se met à jour après une séance.
- Checks de capacité: build iOS Simulator OK; `xcodebuild test` OK; ajout du widget à l'écran d'accueil simulateur pour vérifier le rendu réel.
- Signal de livraison: build+tests verts, QA visuelle des 4 features.
- Fichiers attendus: `docs/FEATURE_BACKLOG.md`, `docs/HANDOVER.md`
- Owner: humain / Claude Code (prochaine session, une fois l'environnement débloqué)

## Dernier handover

### Résumé

BD-012 implémenté par Claude Code directement (feature demandée par l'humain hors boucle Codex) : possibilité de valider/invalider manuellement un jour depuis Progression, et voir ce qui est prévu pour n'importe quel jour (pas seulement les jours complétés).

- `ChallengeStore.validateDay(_:)` : marque un jour comme complété manuellement (utilise la série cible complète du jour, daté à aujourd'hui). No-op si le jour est déjà complété ou si l'index est hors bornes.
- `ChallengeStore.invalidateDay(_:)` : supprime la/les session(s) enregistrée(s) pour ce jour, recalcule le streak. No-op si le jour n'était pas complété.
- `ProgressView.swift` : `SessionDetailSheet` (lecture seule, jours complétés uniquement) remplacé par `DayDetailSheet` qui gère les 4 états — affiche toujours la section "Prévu" (exercice/durée/séries cibles depuis `ChallengeDay.programme`), ajoute "Réalisé" si une session existe, puis un bouton contextuel : "Invalider ce jour" (destructif, avec confirmation) si complété, "Valider ce jour" si atteignable (`dayIndex <= currentDayIndex`), ou message "Jour à venir" sinon. Tap sur n'importe quelle cellule de la grille (plus seulement les complétées) ouvre ce sheet.
- Réponse à la question sur la progression des durées : oui, `ChallengeDay.swift` a bien un programme progressif — 20s/série (Jour 1, ~1min) jusqu'à 300s/série (Jour 30, ~15min), par paliers hebdomadaires (initiation/consolidation/progression/performance). Rien à changer là-dessus, déjà bien conçu.

QA manuelle complète sur simulateur : jour futur → "Prévu" + "Jour à venir" (pas de bouton) ✓; jour courant non complété → "Valider ce jour" → passe en vert avec check, stats mises à jour (streak/temps/%) ✓; jour complété → "Prévu" + "Réalisé" + "Invalider ce jour" → confirmation → repasse à l'état non complété, stats recalculées ✓.

Détail mineur repéré (pré-existant, pas introduit par ce travail) : la date dans "Réalisé" utilise `.formatted(date:time:)` qui suit la locale système du simulateur (affiche "at" au lieu de "à" en anglais) plutôt qu'une locale FR forcée. **Corrigé** : `DayDetailSheet` force `Locale(identifier: "fr_FR")` sur ce formatter (seule occurrence de date formatée dans l'app, vérifié par grep). QA simulateur : "7 juil. 2026 à 22:27" ✓. Décision volontaire : locale forcée en dur plutôt que vraie i18n — l'app reste 100% français jusqu'à la finalisation, l'internationalisation (si besoin) sera une tranche séparée.

### Fichiers modifiés

- `BeuriDolei/BeuriDolei/Store/ChallengeStore.swift` (+ `validateDay`, `invalidateDay`)
- `BeuriDolei/BeuriDolei/Views/ProgressView.swift` (`SessionDetailSheet` → `DayDetailSheet`, tap sur toutes les cellules, wrapper `DaySelection`, locale FR forcée sur la date "Réalisé")
- `BeuriDolei/BeuriDoleiTests/ChallengeStoreTests.swift` (+5 tests : validateDay x3, invalidateDay x2)
- `BeuriDolei/BeuriDolei/LaunchScreen.storyboard` (`LaunchMark` → `LaunchBolt` pour casser le cache iOS du splash)
- `BeuriDolei/BeuriDolei/Assets.xcassets/LaunchBolt.imageset/`
- `docs/FEATURE_BACKLOG.md`
- `docs/HANDOVER.md`

### Vérification

- Build: `xcodebuild -project BeuriDolei/BeuriDolei.xcodeproj -scheme BeuriDolei -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' build` → OK.
- Tests: `xcodebuild test [...]` → OK, 28/28 tests passés (23 existants + 5 nouveaux).
- QA manuelle simulateur : voir Résumé ci-dessus, cycle complet valider/invalider vérifié visuellement à chaque étape.
- Splash: `LaunchScreen.storyboard` pointe sur `LaunchBolt`, un nouvel asset éclair, pour éviter que le cache LaunchScreen continue d'afficher l'ancien monogramme B de `LaunchMark`.
- Home Dynamic Island: le cercle Jour/Streak est abaissé avec une marge haute fixe dans la safe area; aucun contenu Home ne doit entrer dans la zone Dynamic Island/status bar.
- Note vérification Codex 2026-07-08 : `git diff --check` OK. Build simulateur non concluant côté environnement (`ibtool`: "iOS 26.5 Platform Not Installed" malgré SDK listé; simulateur booté en iOS 26.3). Build destination Mac non concluant à cause du provisioning profile qui n'inclut pas le Mac.

### Décisions

- `validateDay` date toujours la session à "maintenant" (pas de vrai backdating avec date arbitraire) — couvre le cas d'usage principal ("le timer n'a pas loggé ma séance") sans complexifier le calcul de streak/grace-day qui dépend de vraies dates calendaires. Un vrai backdating serait une feature séparée si demandée.
- Le bouton valider n'apparaît que pour `dayIndex <= currentDayIndex` (jours atteignables) — on peut volontairement compléter un jour futur en validant les jours précédents un par un, mais pas sauter directement à un jour lointain par erreur de tap.
- Confirmation dialog obligatoire avant invalidation (destructive, supprime des données) ; validation directe sans confirmation (non-destructive, réversible via invalidation).

### Questions ouvertes

- Aucune bloquante.

### Prochaine action recommandée

Humain : décider de la prochaine amélioration (QA device réel en attente depuis BD-011, ou nouvelle feature).

Recommandation roadmap retenue : QA device réel USB → réglages interactifs → onboarding première ouverture → widget iOS. Garder partage/export J30 et durées personnalisées après premiers retours utilisateur réels.

## À confier à Codex

- Aucun point immédiat. BD-012 est fait et testé par Claude Code ; à prendre en compte dans `docs/FEATURE_BACKLOG.md` si Codex reprend la main sur une prochaine tranche.

## À confier à Claude Code (prochaine session QA)

- **Priorité absolue** : build + tests du lot BD-014/015/016/V2-003 (jamais vérifié, voir "Blocage environnement" ci-dessus) avant toute autre tâche.
- Interactions réelles Réglages : activer/désactiver notifications, changer l'heure du rappel, reset du défi (avec confirmation du comportement attendu).
- Tester sur device réel via USB : permissions notifications/HealthKit/haptics — le simulateur ne peut pas les valider fidèlement.
- Vérifier sur iPhone avec Dynamic Island que le cercle Jour/Streak est suffisamment bas et ne chevauche jamais l'îlot ni la status bar.
- QA du widget : ajouter "BeuriDolei" à l'écran Aujourd'hui/accueil simulateur, vérifier jour+streak, vérifier la mise à jour après une séance complétée.
- Après QA complète, proposer la prochaine tranche produit en s'appuyant sur un benchmark App Store/Play Store des meilleures apps de plank/challenge/habit fitness.

## Fichiers modifiés (2026-07-08, non compilés)

- `BeuriDolei/BeuriDolei/Models/UserPreferences.swift` (+ `hasCompletedOnboarding`)
- `BeuriDolei/BeuriDolei/Views/OnboardingView.swift` (nouveau)
- `BeuriDolei/BeuriDolei/ContentView.swift` (gate onboarding, bootstrap permissions déplacé)
- `BeuriDolei/BeuriDolei/BeuriDoleiApp.swift` (retrait de l'ancien `.onAppear` de bootstrap)
- `BeuriDolei/BeuriDolei/Views/TimerView.swift` (+ bouton "recommencer la série", `TimerSessionState.restartCurrentSerie()`)
- `BeuriDolei/BeuriDoleiTests/ChallengeStoreTests.swift` (+1 test `restartCurrentSerie`)
- `BeuriDolei/BeuriDolei/Views/ShareCardView.swift` (nouveau)
- `BeuriDolei/BeuriDolei/Views/CompletionView.swift` (+ bouton partager)
- `BeuriDolei/BeuriDolei/Shared/WidgetSnapshot.swift` (nouveau, partagé app+widget)
- `BeuriDolei/BeuriDolei/Store/ChallengeStore.swift` (+ `syncWidgetSnapshot()`, import WidgetKit)
- `BeuriDolei/BeuriDoleiWidget/` (nouveau target : `BeuriDoleiWidgetBundle.swift`, `BeuriDoleiWidget.swift`, `Info.plist`, `BeuriDoleiWidget.entitlements`, `PrivacyInfo.xcprivacy`)
- `BeuriDolei/BeuriDolei/BeuriDolei.entitlements` (+ App Group `group.com.dakhine.BeuriDolei`)
- `BeuriDolei/BeuriDolei/PrivacyInfo.xcprivacy` (nouveau, app principale)
- `BeuriDolei/BeuriDolei.xcodeproj/project.pbxproj` (nouveau target `BeuriDoleiWidget` créé via gem Ruby `xcodeproj`, pas d'édition manuelle de texte)

## Template handover

Copier cette section en fin de session.

```md
## Handoff - YYYY-MM-DD HH:MM

### Résumé

- 

### Fichiers modifiés

- 

### Vérification

- Command:
- Result:
- Skipped:

### Décisions

- 

### Questions ouvertes

- 

### Prochaine action recommandée

- 
```
