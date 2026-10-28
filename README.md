# ClaudeStatusLine

Une statusline compacte sur deux lignes pour [Claude Code](https://docs.anthropic.com/en/docs/claude-code), avec un fond bleu nuit et des couleurs distinctes par catégorie.

## Aperçu

![Aperçu de la statusline Claude Code](docs/statusline-preview.svg)

*Illustration indicative : les valeurs sont des exemples. Les informations de quota dépendent des données exposées par la version de Claude Code utilisée.*

**Ligne 1**
- Dossier du projet
- Branche Git et état du dépôt : ✓ propre ou ✎ modifications détectées
- Modèle raccourci (Opus, Sonnet ou Haiku)
- Niveau d'effort

**Ligne 2**
- Barre de progression et pourcentage de contexte
- Durée de session
- Utilisation et réinitialisation des fenêtres de quota de 5 heures et de 7 jours, si ces données sont disponibles

La palette utilise le cyan pour le projet et le contexte, le violet pour Git et l'effort, le vert pour les indicateurs et pourcentages, le jaune pour le modèle et la durée, et le gris bleuté pour les séparateurs et les informations de réinitialisation. L'arrière-plan est bleu nuit.

> **Compatibilité :** les champs JSON disponibles varient selon la version de Claude Code. Les informations de quota ou de durée absentes des données reçues peuvent ne pas s'afficher. Certaines icônes nécessitent une police de terminal compatible avec les glyphes Nerd Font.

## Prérequis

- Claude Code installé.
- Bash.
- Python 3 pour lire le JSON transmis à la statusline.
- Git pour afficher la branche et détecter les modifications.
- Un terminal prenant en charge les séquences ANSI.

## Installation globale

Cette installation configure la statusline au niveau utilisateur, pour les projets et sessions Claude Code locaux.

1. Crée le dossier de configuration si nécessaire :

   ```bash
   mkdir -p ~/.claude
   ```

2. Depuis la racine du dépôt cloné, copie le script :

   ```bash
   cp statusline.sh ~/.claude/statusline.sh
   chmod +x ~/.claude/statusline.sh
   ```

3. Ouvre `~/.claude/settings.json` et ajoute la propriété suivante à l'objet JSON existant :

   ```json
   "statusLine": {
     "type": "command",
     "command": "~/.claude/statusline.sh",
     "padding": 0
   }
   ```

   **Important :** conserve les autres réglages et respecte les virgules JSON. Ne crée pas une deuxième propriété `statusLine`. Si le fichier n'existe pas encore, crée-le avec un objet JSON complet :

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
- Teste le script avec des données de démonstration :

  ```bash
  printf '%s\\n' '{"workspace":{"current_dir":"'"$PWD"'"},"model":{"display_name":"Claude Opus"},"effort":{"level":"high"},"context_window":{"used_percentage":42},"session":{"duration_minutes":12}}' | ~/.claude/statusline.sh
  ```

- Si les quotas ne s'affichent pas, les données correspondantes ne sont peut-être pas fournies par ta version de Claude Code.
- Si les icônes apparaissent sous forme de carrés, installe une police compatible Nerd Font ou remplace les glyphes par des symboles Unicode simples.
- Pour diagnostiquer une erreur : `bash -x ~/.claude/statusline.sh`.

## Consommation

Le script s'exécute localement et lit le JSON transmis par Claude Code. Il ne fait pas d'appel API et ne demande pas à un modèle de générer la statusline à chaque actualisation. Il consomme une petite quantité de CPU pour lancer Python et Git.

## Configuration de référence

À fusionner dans le fichier `~/.claude/settings.json` existant, sans remplacer les autres paramètres :

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  }
}
```
