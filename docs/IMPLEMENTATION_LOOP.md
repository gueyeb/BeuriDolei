# Boucle d'implémentation BeuriDolei

Ce fichier définit la boucle de travail partagée pour implémenter les features BeuriDolei avec Codex et Claude Code.

## Objectif

Garder l'intention produit, l'état d'implémentation, la vérification et les passages de relais visibles dans le repo. Le PRD reste la source de vérité produit. Cette boucle est la source de vérité d'exécution.

## Modèle de travail

Répartition par défaut :
- Claude Code : implémentation large, refactors, features multi-fichiers, premier câblage UI.
- Codex : implémentation ciblée, code review, debugging, corrections build/tests, vérification, nettoyage du handover.
- Humain : décisions produit, changements de priorité, arbitrage des compromis.

Dans cette session, Codex n'a pas d'outil natif pour appeler Claude Code directement. Si Claude Code dispose d'un plugin Codex, utilise-le depuis Claude quand c'est utile. Depuis Codex, la coordination doit passer par les fichiers du repo, les diffs Git, les sorties terminal et des notes de handover explicites.

## Boucle feature

Utiliser cette boucle pour chaque feature non triviale.

1. Sélectionner
   - Choisir une feature dans `docs/FEATURE_BACKLOG.md`.
   - Confirmer le statut, la priorité et les critères d'acceptation.
   - Si le besoin est flou, mettre à jour le backlog avant de coder.

2. Découper
   - Transformer la feature en plus petite tranche utile.
   - Définir les checks de capacité, les checks de régression et le signal de livraison.
   - Noter la tranche active dans `docs/HANDOVER.md`.

3. Implémenter
   - Garder les changements dans le périmètre de la tranche choisie.
   - Préférer les patterns existants : SwiftUI, `ChallengeStore`, persistance locale, pas de backend.
   - Ajouter des tests quand la logique est non triviale et qu'une cible de test pratique existe.

4. Vérifier
   - Lancer les checks disponibles dans cet ordre :
     1. build ou compilation
     2. type check ou analyse statique
     3. lint ou validation de style
     4. tests ciblés, puis tests plus larges si nécessaire
     5. audit ciblé des logs de debug, secrets, fichiers générés ou docs obsolètes
   - Pour ce repo, le check par défaut est :
     `xcodebuild -project BeuriDolei/BeuriDolei.xcodeproj -scheme BeuriDolei -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' build`

5. Relire
   - Vérifier que le diff ne dépasse pas le périmètre.
   - Vérifier que `PRD.md`, `docs/FEATURE_BACKLOG.md` et `docs/HANDOVER.md` reflètent encore la réalité.
   - Si Claude et Codex ont touché les mêmes fichiers, inspecter attentivement avant commit.

6. Passer le relais
   - Mettre à jour `docs/HANDOVER.md` avec les changements, résultats de vérification, questions ouvertes et prochaine action.
   - Mettre à jour le statut dans le backlog.
   - Utiliser Conventional Commit au moment du commit.

## Protocole de handover

Chaque handover doit contenir :
- Objectif courant.
- Fichiers modifiés.
- Ce qui a été vérifié et la commande exacte.
- Échecs connus ou checks sautés.
- Décisions produit ou techniques prises.
- Prochaine action recommandée.

Éviter les handoffs qui disent seulement "continuer" ou "fix build". Le prochain agent doit pouvoir reprendre sans relire tout le chat.

## Règles de synchronisation PRD

Mettre à jour `PRD.md` quand :
- le périmètre produit change
- les frontières MVP/V2 changent
- les critères d'acceptation changent
- une feature livrée contredit le PRD

Ne pas mettre à jour `PRD.md` pour :
- notes temporaires d'implémentation
- échecs de build locaux
- contexte agent-à-agent
- état de tâche court terme

Utiliser `docs/HANDOVER.md` pour le contexte d'exécution transitoire.

## Definition of Ready

Une feature est prête à implémenter quand elle a :
- un résultat visible ou vérifiable
- des critères d'acceptation
- des zones de code attendues
- un plan de vérification
- un owner ou prochain agent

## Definition of Done

Une feature est terminée quand :
- les critères d'acceptation passent
- le build réussit, ou l'échec est documenté avec sa cause
- les docs pertinentes sont à jour
- le handover indique la prochaine action
- aucun changement hors périmètre n'a été introduit
