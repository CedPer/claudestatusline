# ClaudeStatusLine

Une statusline compacte sur deux lignes pour [Claude Code](https://docs.anthropic.com/en/docs/claude-code), avec un fond bleu nuit et des couleurs distinctes par catégorie.

## Aperçu

La statusline est conçue pour afficher :

**Ligne 1**
- Dossier du projet
- Branche Git et état du dépôt : ✓ propre ou ✎ modifications détectées
- Modèle raccourci (Opus, Sonnet ou Haiku)
- Niveau d'effort

**Ligne 2**
- Barre de progression et pourcentage de contexte
- Durée de session
- Utilisation et heure de réinitialisation des fenêtres de quota de 5 heures et de 7 jours, lorsque Claude Code fournit ces données

Les couleurs sont différenciées par catégorie : cyan pour le projet/contexte, violet pour Git et l'effort, vert pour les valeurs positives et pourcentages, jaune pour le modèle et la durée, gris bleuté pour les séparateurs et les informations de réinitialisation. L'arrière-plan est bleu nuit. Les chiffres d'exemple ne sont pas des valeurs fixes.

> **Compatibilité :** les champs JSON disponibles dépendent de la version de Claude Code. Les informations de quota ou de durée qui ne sont pas fournies par la version installée peuvent être absentes ou afficher « — ». Certaines icônes nécessitent une police de terminal compatible avec les glyphes Nerd Font.

## Prérequis

- Claude Code installé.
- Bash.
- Python 3 (utilisé pour lire le JSON fourni à la commande statusline).
- Git pour afficher la branche et détecter les modifications.
- Un terminal prenant en charge les séquences ANSI.

## Installation globale

Cette procédure active la statusline pour les projets et sessions Claude Code locaux de l'utilisateur, grâce aux paramètres utilisateur.

1. Crée le dossier de configuration si nécessaire :

   ```bash
   mkdir -p ~/.claude
   ```

2. Depuis la racine du dépôt cloné, copie le script dans le dossier utilisateur :

   ```bash
   cp statusline.sh ~/.claude/statusline.sh
   chmod +x ~/.claude/statusline.sh
   ```

3. Ouvre `~/.claude/settings.json`. Ajoute la propriété suivante à l'objet JSON existant :

   ```json
   "statusLine": {
     "type": "command",
     "command": "~/.claude/statusline.sh",
     "padding": 0
   }
   ```

   **Important :** si le fichier contient déjà d'autres paramètres, conserve-les et ajoute uniquement la propriété `statusLine`, en respectant les virgules JSON. Ne crée pas une deuxième propriété `statusLine`. Si le fichier n'existe pas, crée-le avec un objet JSON autour de cette propriété, par exemple :

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "~/.claude/statusline.sh",
       "padding": 0
     }
   }
   ```

4. Redémarre Claude Code ou ouvre une nouvelle session pour vérifier le résultat.

## Installation depuis GitHub

```bash
git clone https://github.com/CedPer/claudestatusline.git
cd claudestatusline
mkdir -p ~/.claude
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Ajoute ensuite le bloc `statusLine` ci-dessus dans `~/.claude/settings.json`.

## Vérification et dépannage

- Vérifie les permissions : `ls -l ~/.claude/statusline.sh`
- Vérifie les dépendances : `command -v bash python3 git`
- Lance un test avec un JSON de démonstration :

  ```bash
  printf '%s\n' '{"workspace":{"current_dir":"'"$PWD"'"},"model":{"display_name":"Claude Opus"},"effort":{"level":"high"},"context_window":{"used_percentage":42},"session":{"duration_minutes":12}}' | ~/.claude/statusline.sh
  ```

- Si les quotas n'apparaissent pas, vérifie les champs transmis par ta version de Claude Code : les données de quota ne sont pas disponibles dans tous les payloads.
- Si les icônes sont remplacées par des carrés, utilise une police compatible Nerd Font ou remplace les glyphes par des symboles Unicode plus simples.
- Pour diagnostiquer une erreur, exécute : `bash -x ~/.claude/statusline.sh`.

## Consommation

Le script s'exécute localement et lit le JSON transmis par Claude Code. Il ne fait pas d'appel API et ne demande pas à un modèle de générer la statusline à chaque actualisation. Il utilise un peu de CPU pour lancer Python et Git.

## Configuration de référence

À fusionner dans `~/.claude/settings.json` existant, sans remplacer les autres réglages :

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  }
}
```
