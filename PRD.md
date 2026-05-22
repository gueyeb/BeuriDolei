# PRD — BeuriDolei

> Application iOS de défi planche (plank challenge)
> Date : Mai 2026 | Statut : cadrage MVP
> Linear : [BeuriDolei](https://linear.app/dakhine/project/beuridolei)

---

## Contexte & Positionnement

BeuriDolei ("tenir bon" en Wolof) est une app iOS de défi planche pensée pour une pratique quotidienne simple et durable. Le problème à résoudre n'est pas le manque de contenus fitness, mais le manque d'un outil minimaliste pour lancer un chrono, suivre une progression de 30 jours, et garder un streak sans bruit produit.

Le produit doit rester :
- simple a ouvrir et utiliser en moins de 5 secondes
- discret, sans abonnement ni mécanique sociale
- motivant par la continuité, pas par la gamification agressive

---

## Objectif Produit

Permettre a un utilisateur iPhone de suivre un programme planche 30 jours, compléter sa séance du jour, et visualiser sa régularité avec un minimum de friction.

### Signal de réussite MVP
- l'utilisateur comprend immédiatement la cible du jour
- il peut lancer, pauser, reprendre et terminer sa séance sans ambiguïté
- la journée est marquée comme complétée si la cible est atteinte
- le streak et l'historique restent cohérents d'un jour a l'autre

---

## Persona

**Utilisateur principal — Babacar**
- pratique déjà une activité physique régulière
- veut renforcer son core sans suivre un programme complexe
- ne cherche pas un coach virtuel ni des vidéos
- utilise un iPhone et apprécie les apps sobres, nettes, locales

---

## Périmètre MVP

### 1. Programme 30 jours
- programme prédéfini de 30 jours avec durée cible croissante
- un seul objectif actif par jour
- possibilité de voir les jours passés, le jour courant, et les jours a venir

### 2. Timer de séance
- mode principal : compte a rebours basé sur la cible du jour
- pause, reprise, abandon, validation de fin
- feedback haptique léger toutes les 10 secondes et a la complétion

### 3. Progression & Streak
- une journée est complétée si `elapsed >= target`
- streak journalier calculé sur jours consécutifs complétés
- historique local des séances avec date, durée réalisée, cible, statut

### 4. Rappels
- rappel quotidien configurable
- notification de félicitation après séance complète

---

## Non-objectifs MVP

- compte utilisateur ou sync cloud
- social, leaderboard, partage public
- coach vocal, vidéo, ou bibliothèque d'exercices
- variantes de planche et programmes personnalisés
- intégration HealthKit

Ces éléments restent en V2+ pour protéger la vitesse d'exécution du MVP.

---

## Flux Utilisateur Principal

1. L'utilisateur ouvre l'app.
2. Il voit le jour courant, la cible du jour, son streak et l'action principale.
3. Il lance le timer.
4. Il peut pauser ou reprendre.
5. Si la cible est atteinte, l'app marque la journée comme complétée.
6. Il voit un état de réussite simple et son historique mis a jour.

---

## Ecrans MVP

### Home
- jour courant du challenge
- durée cible du jour
- bouton principal `Commencer`
- résumé streak et dernière séance

### Session / Timer
- chrono en cours
- état `running`, `paused`, `completed`, `abandoned`
- actions pause, reprendre, arrêter

### Progression
- vue calendrier ou liste des 30 jours
- statuts : complété, manqué, a venir

### Settings
- heure de rappel
- activation haptics
- reset local du challenge

---

## Modèle de Données

- `ChallengeDay`
  - `dayIndex`
  - `targetDurationSeconds`
  - `completionDate`
  - `status`
- `PlankSession`
  - `startedAt`
  - `endedAt`
  - `elapsedSeconds`
  - `targetSeconds`
  - `isCompleted`
- `UserPreferences`
  - `reminderTime`
  - `hapticsEnabled`

Persistance locale via `UserDefaults` pour le MVP. Si le modèle grossit, migration vers un store plus structuré a prévoir.

---

## Stack & Contraintes Techniques

- **Plateforme :** iOS 17+ (SwiftUI, Swift 6)
- **Architecture :** MVVM
- **Source de vérité :** `ChallengeStore`
- **Persistance :** `UserDefaults`
- **Notifications :** `UserNotifications`
- **Haptics :** `UIImpactFeedbackGenerator`
- **Bundle ID :** `com.dakhine.BeuriDolei`

Le repo actuel contient surtout le squelette SwiftUI. Les prochaines itérations doivent créer explicitement `Models/`, `ViewModels/`, `Views/`, et `Services/`.

---

## Critères d'Acceptation MVP

- la cible du jour est toujours visible sur l'écran d'accueil
- une séance incomplète n'incrémente pas le streak
- une journée ne peut pas être comptée deux fois
- le streak est recalculé correctement après relance de l'app
- l'historique affiche au minimum date, cible, durée réelle, statut
- le rappel quotidien peut être activé, modifié, puis désactivé

---

## Roadmap

### MVP
- modèle de données du challenge
- timer fonctionnel
- home, progression, réglages
- streak + historique local
- rappels quotidiens

### V2
- HealthKit
- variantes de planche
- défis personnalisés
- widget iOS

### V3
- distribution TestFlight
- polish App Store

---

## Décisions Produit

- **Local-first :** pas de compte au lancement
- **Minimalisme :** peu d'écrans, peu de texte, action principale évidente
- **Discipline > engagement artificiel :** pas de badges, pièces, ou manipulations attentionnelles

---

## Liens

- Repo : `/Users/bgueye/Projects/BeuriDolei`
- Note vault : `/Users/bgueye/ObsidianVault_Dakhine-HQ/03_PROJECTS/BeuriDolei-PRD.md`
- Référence produit proche : `ZikrCompanion`
