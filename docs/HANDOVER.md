# Handover agents BeuriDolei

Utiliser ce fichier comme mémoire de session partagée entre Humain, Claude Code et Codex.

## Session courante

- Date: 2026-07-07
- Objectif courant: BD-012 (valider/invalider un jour en Progression) livré et QA sur simulateur ; choisir la prochaine phase produit.
- Feature active: aucune
- Owner: humain pour sélectionner la prochaine phase
- Status: BD-001 à BD-012 terminés. BD-012 implémenté directement par Claude Code (hors boucle Codex, à la demande explicite de l'humain), tests unitaires ajoutés (28/28 verts), QA manuelle simulateur OK.

## Tranche active

- Feature ID: aucune
- Objectif: lancer une passe QA sur device réel (permissions système), puis choisir la prochaine phase produit.
- Critères d'acceptation: la prochaine tranche est issue soit d'un défaut constaté en QA, soit d'un benchmark App Store/Play Store, soit d'un candidat V2 assumé.
- Checks de capacité: `xcodebuild test` passe; QA manuelle device réel USB pour notifications/HealthKit/haptics.
- Signal de livraison: décision sur la prochaine phase.
- Fichiers attendus: `docs/FEATURE_BACKLOG.md`, `docs/HANDOVER.md`
- Owner: humain / Claude Code pour QA device réel

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

- Interactions réelles Réglages : activer/désactiver notifications, changer l'heure du rappel, reset du défi (avec confirmation du comportement attendu).
- Tester sur device réel via USB : permissions notifications/HealthKit/haptics — le simulateur ne peut pas les valider fidèlement.
- Vérifier sur iPhone avec Dynamic Island que le cercle Jour/Streak est suffisamment bas et ne chevauche jamais l'îlot ni la status bar.
- Après QA complète, proposer la prochaine tranche produit en s'appuyant sur un benchmark App Store/Play Store des meilleures apps de plank/challenge/habit fitness.

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
