# Backlog feature BeuriDolei

Ce backlog suit les tranches d'implémentation. Garder la stratégie produit dans `PRD.md`; garder l'exécution quotidienne ici.

## Légende des statuts

- `todo` : pas commencé
- `active` : en cours d'implémentation
- `blocked` : en attente d'une décision ou d'une contrainte externe
- `review` : implémenté, à relire ou vérifier
- `done` : livré ou accepté localement

## État actuel

Le code contient déjà la structure app, les modèles, le store, le timer, la progression, les réglages, les notifications et des fichiers HealthKit. Décision produit prise le 2026-07-06 : HealthKit reste MVP (sync workout, écriture seule). `PRD.md` mis à jour (déplacé des non-objectifs/V2 vers Périmètre MVP §5 et roadmap MVP).

## MVP Backlog

| ID | Statut | Feature | Critères d'acceptation | Notes |
| --- | --- | --- | --- | --- |
| BD-001 | done | Modèle challenge 30 jours | 30 jours existent, chaque jour a une cible, le jour courant est dérivé de façon cohérente | Livré 2026-07-06 : programme et dérivation du jour courant couverts par XCTest, suite finale 23 tests OK |
| BD-002 | done | Flux timer de séance | Les états démarrer, pause, reprise, abandon et complétion fonctionnent sans ambiguïté UI | Livré 2026-07-06 : transitions timer extraites et testées, suite finale 23 tests OK |
| BD-003 | done | Streak et historique | Les séances incomplètes n'incrémentent pas le streak; un jour complété n'est pas compté deux fois; l'historique survit à la relance | Livré 2026-07-06 : couverture XCTest durcie, suite finale 23 tests OK |
| BD-004 | done | Rappels quotidiens | Le rappel peut être activé, modifié, désactivé; une notification de complétion est envoyée après succès | Livré 2026-07-06 : scheduler injecté et testé, 23 tests OK |
| BD-005 | done | Écran progression | Les jours passés, courant et futurs sont distinguables | Livré 2026-07-06 : résolution des états de cellule extraite et testée, suite finale 23 tests OK |
| BD-006 | done | Cible de tests | Ajouter une cible XCTest focalisée sur store, streak, dates, persistance et complétion de session | Livré 2026-07-06 : cible `BeuriDoleiTests`, 23 tests `ChallengeStoreTests`, `xcodebuild test` OK sur iPhone 17 |
| BD-007 | done | Réconciliation PRD/code | Décider si HealthKit est MVP, V2 ou expérimental; mettre à jour PRD et settings | Décidé 2026-07-06 : HealthKit reste MVP. `PRD.md` mis à jour |
| BD-008 | done | Nettoyage CI | Supprimer ou corriger les GitHub Actions génériques qui ne correspondent pas au projet Xcode | Livré 2026-07-06 : workflow unique `iOS CI`, suppression des templates Swift/Object-C non applicables |
| BD-009 | done | HealthKit écriture seule | Les permissions et entitlements HealthKit correspondent au PRD MVP : écriture workout uniquement, aucune lecture de données Santé | Livré 2026-07-06 : suppression de l'accès `health-records`, autorisation HealthKit `read: []`, build + 23 tests OK |
| BD-010 | done | Logo, icônes et exercice MVP | L'app n'utilise plus de pictos ambigus d'abdos/haltères; le MVP propose une planche classique avec guide visuel; AppIcon, LaunchMark et BrandMark sont cohérents | Livré 2026-07-06 : remplacement des SF Symbols `figure.*`, suppression du sélecteur de variantes, ajout `PlankVariantIcon`, source SVG versionnée, build + 23 tests OK |
| BD-011 | done | Fix QA retour accueil et marque | Après complétion, le bouton retour ramène à l'accueil; le header respecte la safe area; l'icône app ne ressemble plus à une posture au sol; splash et marque utilisent une palette cohérente | Livré 2026-07-06 : dismissal explicite depuis `HomeView`, header supprimé pour éviter la Dynamic Island, AppIcon éclair + anneau, LaunchMark/BrandMark transparents sur fond chaud sombre; build + 23 tests OK |
| BD-012 | done | Valider/invalider un jour en Progression | Depuis l'écran Progression, taper un jour affiche ce qui est prévu (exercice/durée/séries); un jour atteignable non complété peut être validé manuellement; un jour complété peut être invalidé (avec confirmation) | Livré 2026-07-07 par Claude Code (hors boucle Codex) : `ChallengeStore.validateDay`/`invalidateDay`, `DayDetailSheet` remplace `SessionDetailSheet`, build + 28 tests OK, QA manuelle simulateur des 3 états (à venir/atteignable/complété) |
| BD-013 | done | Splash icon cache fix | Le splash screen affiche l'éclair, pas l'ancien monogramme B, même après cache LaunchScreen iOS | Livré 2026-07-08 : nouvel asset `LaunchBolt` référencé par `LaunchScreen.storyboard` pour casser le cache de `LaunchMark`; assets vérifiés localement, build Xcode bloqué par configuration locale iOS 26.5 |
| BD-014 | done | Onboarding première ouverture | Un nouvel utilisateur voit 1-3 écrans d'intro (objectif, fonctionnement, permissions) avant le Jour 1; ne réapparaît plus ensuite | Livré 2026-07-08 : `OnboardingView` (TabView paginé) + `UserPreferences.hasCompletedOnboarding`, gate dans `ContentView`; permissions bootstrap déplacé après l'onboarding. Build non vérifié (voir Vérification) |
| BD-015 | done | Annuler la série en cours | Pendant le timer, un bouton permet de recommencer la série active à zéro sans perdre les séries déjà validées ni abandonner la séance | Livré 2026-07-08 : `TimerSessionState.restartCurrentSerie()` + bouton "arrow.counterclockwise" dans `TimerView`, 1 nouveau test unitaire. Build non vérifié (voir Vérification) |
| BD-016 | done | Partage/export résultat de séance | Depuis l'écran de complétion, un bouton génère une image récap (jour, temps tenu, streak) partageable via la feuille de partage iOS | Livré 2026-07-08 : `ShareCardView` + `ImageRenderer` + `ShareLink` dans `CompletionView`. Build non vérifié (voir Vérification) |

## Candidats V2

| ID | Statut | Feature | Critères d'acceptation | Notes |
| --- | --- | --- | --- | --- |
| BD-V2-001 | todo | Durées personnalisées | L'utilisateur peut choisir ou éditer les cibles sans corrompre l'historique courant | Nécessite un plan de migration persistance |
| BD-V2-002 | todo | Variantes de planche | L'utilisateur peut choisir une variante et la voir enregistrée dans l'historique | Modèle présent; scope produit à décider |
| BD-V2-003 | review | Widgets | L'utilisateur peut voir la cible du jour et le streak depuis un widget iOS | Cible `BeuriDoleiWidget` (App Extension) créée 2026-07-08 via `xcodeproj` gem : `WidgetSnapshot` partagé (App Group `group.com.dakhine.BeuriDolei`), `ChallengeStore` pousse un snapshot + `WidgetCenter.reloadTimelines` à chaque `save()`. **Build jamais vérifié** (contrainte disque/runtime, voir Vérification) — à valider avant de passer en `done` |
| BD-V2-004 | review | Préparation TestFlight | L'app a config release, notes privacy, icônes, screenshots et chemin signing | Audit 2026-07-08 : icônes complètes (18/18), `DEVELOPMENT_TEAM` déjà configuré, `CODE_SIGN_STYLE = Automatic`, `PrivacyInfo.xcprivacy` ajouté (app + widget, raison UserDefaults `1C8F.1`), `ITSAppUsesNonExemptEncryption = NO` ajouté. Reste manuel : App Store Connect record, captures d'écran, TestFlight build upload — nécessite le compte développeur de l'humain |

## Ordre recommandé avant mise en prod

1. **Vérifier le build** (BD-014/015/016/V2-003) dès que l'environnement Xcode/disque le permet — aucun de ces changements n'a été compilé, seulement relu manuellement.
2. QA device réel USB : valider notifications, HealthKit et haptics hors simulateur.
3. Réglages interactifs : tester notifications on/off, changement d'heure de rappel et reset du défi.
4. App Store Connect + captures d'écran + upload TestFlight (nécessite le compte développeur).

## Template feature

Copier cette forme de ligne pour ajouter une feature :

| ID | Statut | Feature | Critères d'acceptation | Notes |
| --- | --- | --- | --- | --- |
| BD-XXX | todo | Nom court | Comportement observable qui doit passer | Contraintes, owner ou liens |

## Template tranche

Utiliser ceci dans `docs/HANDOVER.md` quand une feature devient active :

```md
### Tranche active

- Feature ID:
- Objectif:
- Critères d'acceptation:
- Checks de capacité:
- Checks de régression:
- Signal de livraison:
- Fichiers attendus:
- Owner:
```
