# Flair

Un explorateur de fichiers pour Vex qui lit, cherche, range et répond grâce à l'IA,
entièrement au clavier.

- **Aperçu** : Espace affiche une page HTML rendue (CSS, JavaScript, rechargement
  automatique à chaque enregistrement, zoom, largeur mobile, `F` pour agrandir), et résume
  par l'IA tout le reste (texte, code, PDF). `flair page.html` ouvre directement l'aperçu.
- **Recherche par le sens** : `I` indexe le dossier avec un modèle d'embeddings local,
  puis `/` trouve « la facture d'électricité de l'an dernier » sans connaître son nom.
  Sans index, la recherche porte sur les noms.
- **Commandes en langage naturel** : `:` puis « range les captures d'écran par mois »
  produit un plan de déplacements et renommages que tu valides avec Ctrl+Entrée.
- **Rangement automatique** : `S` range par type sans IA ; Maj+S demande un rangement
  intelligent à l'IA.
- **Chat avec un dossier** : `C` pose des questions ; avec un index, les fichiers
  pertinents sont lus pour répondre.
- **Dossier GitHub** : dans la barre latérale (ou Ctrl+G), tes dépôts GitHub s'affichent
  comme un dossier. Ceux déjà clonés sur la machine sont reconnus ; Entrée ouvre le clone,
  ou clone le dépôt dans `~/Work` (réglable) puis l'ouvre. Espace résume le README.
- **Git** : statut des fichiers dans la liste, `D` explique les changements en cours et
  propose un message de commit, `G` ouvre le dépôt sur GitHub.

- **Ouvrir** : un clic, un double-clic ou Entrée sur une page HTML l'affiche rendue dans
  flair (réglable : éditeur ou navigateur). Le code s'ouvre dans ton éditeur (VS Code par
  défaut) ; `E` y ouvre n'importe quel fichier ou dossier.
- **Tri automatique** : par défaut, la liste choisit son ordre selon le dossier : les plus
  récents en haut dans Téléchargements, Images, Vidéos, Bureau et les captures, par nom
  ailleurs. Clique sur une colonne pour trier par nom, taille ou date (re-clique pour
  inverser), ou utilise le bouton « Tri » et la touche `O`.

Les fichiers de code portent le vrai logo de leur langage. L'accent est orange par défaut ;
les réglages proposent d'autres couleurs ou de suivre le thème Vex.

## Sécurité des fichiers

Les plans ne peuvent que créer des dossiers et déplacer ou renommer. Ils ne suppriment
rien, n'écrasent rien et ne sortent jamais du dossier courant, même via un lien symbolique.
Rien ne bouge avant validation. Si une étape échoue, tout ce qui a déjà été fait est
défait. Ctrl+Z annule un plan appliqué.

## Moteurs IA

| Tâche | Par défaut | Réglable |
|---|---|---|
| Résumés | local | oui |
| Chat, plans, Git | Claude (`claude-opus-5-5`) | oui |
| Embeddings | local | non |

- **Local** : n'importe quel serveur compatible OpenAI. LM Studio (`http://localhost:1234`,
  onglet Developer → Start Server) ou Ollama (`http://localhost:11434`). Pour la recherche
  par le sens, charge un modèle d'embeddings comme `nomic-embed-text`.
- **Claude** : exporte `ANTHROPIC_API_KEY`, ou saisis la clé dans les réglages (Ctrl+,).
  Elle est alors stockée dans `~/.config/flair/flair.conf`, en mode 0600.

Si un moteur manque, la fenêtre le dit et explique quoi faire.

## Raccourcis

| Touche | Action |
|---|---|
| ↑ ↓ / J K | Se déplacer |
| Entrée / → / L | Ouvrir (HTML : aperçu, code : éditeur) |
| O | Changer le tri |
| E | Ouvrir dans l'éditeur de code |
| Retour / ← / H | Dossier parent |
| ~ | Dossier personnel |
| Ctrl+L | Aller à un chemin |
| . | Fichiers cachés |
| Espace | Aperçu : page HTML rendue, sinon résumé par l'IA |
| F | Agrandir l'aperçu HTML |
| / | Rechercher |
| I | Indexer ce dossier |
| C | Discuter avec ce dossier |
| : ou Ctrl+K | Commande en langage naturel |
| S | Ranger par type |
| Maj+S | Rangement intelligent (IA) |
| Ctrl+Entrée | Appliquer le plan |
| Échap | Fermer, abandonner le plan, arrêter l'IA |
| D | Expliquer les changements Git |
| G | Ouvrir le dépôt sur GitHub |
| Ctrl+G | Dossier GitHub (et retour) |
| R | Recharger les dépôts (dossier GitHub) |
| Ctrl+Maj+G | Cloner un dépôt par son nom |
| Ctrl+Z / Ctrl+Maj+Z | Annuler / rétablir |
| 1 2 3 4 | Aperçu, recherche, chat, plan |
| Ctrl+, | Réglages |
| ? | Aide |
| Q | Quitter |

Le dossier GitHub utilise l'outil `gh` (`gh auth login` une fois).

## Développement

```sh
bin/build      # build/flair
bin/test       # tests Qt Test, hors écran
bin/install    # paquet Arch : lanceur, icône
```
