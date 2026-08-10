#!/usr/bin/env bash
# Prépare l'écran virtuel côté Mac (BetterDisplay) avant de lancer tesla-display.
set -uo pipefail

APP="/Applications/BetterDisplay.app"
CLI_CANDIDATES=(
  "/usr/local/bin/betterdisplaycli"
  "/opt/homebrew/bin/betterdisplaycli"
  "$APP/Contents/MacOS/betterdisplaycli"
)

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "❌ Script réservé à macOS." >&2
  exit 1
fi

echo "── Écran virtuel pour la Tesla ─────────────────────────────"
echo

if [[ ! -d "$APP" ]]; then
  echo "BetterDisplay n'est pas installé."
  echo
  if command -v brew >/dev/null 2>&1; then
    read -r -p "L'installer maintenant avec Homebrew ? [o/N] " answer
    case "$answer" in
      o|O|y|Y) brew install --cask betterdisplay ;;
      *) echo "→ Installation manuelle : https://github.com/waydabber/BetterDisplay/releases" ;;
    esac
  else
    echo "→ Téléchargez-le ici : https://github.com/waydabber/BetterDisplay/releases"
    echo "  (la version gratuite suffit pour créer un écran virtuel)"
  fi
  echo
fi

CLI=""
for candidate in "${CLI_CANDIDATES[@]}"; do
  if [[ -x "$candidate" ]]; then CLI="$candidate"; break; fi
done

if [[ -n "$CLI" ]]; then
  echo "✅ CLI BetterDisplay détectée : $CLI"
  echo
  echo "Écrans actuellement connus de BetterDisplay :"
  "$CLI" get --identifiers 2>/dev/null || echo "  (commande indisponible sur cette version)"
  echo
  echo "La syntaxe de création d'écran virtuel varie selon la version de BetterDisplay."
  echo "Consultez l'aide intégrée puis créez l'écran :"
  echo
  echo "   $CLI create --help"
  echo
else
  echo "ℹ️  CLI BetterDisplay absente (facultatif)."
  echo "   Elle s'installe depuis l'app : menu BetterDisplay ▸ Settings ▸ Application ▸ Install CLI."
  echo
fi

cat <<'GUIDE'
Création manuelle de l'écran virtuel (2 minutes, à faire une seule fois) :

  1. Ouvrir BetterDisplay → une icône d'écran apparaît dans la barre des menus.
  2. Cliquer dessus → section « Virtual Displays » → « Create New Virtual Display ».
  3. Choisir « Display » (pas « Dummy ») et valider.
  4. Résolution recommandée selon la Tesla :
       • Model 3 / Model Y ............... 1920 × 1200  (16:10, écran 15")
       • Model S / X 2021+ ............... 1920 × 1136  (écran 17" paysage)
       • Model S / X jusqu'à 2020 ........ 1200 × 1600  (écran 17" portrait)
  5. Réglages système ▸ Moniteurs : placer l'écran virtuel à droite du principal
     et vérifier qu'il est en mode « Étendre » (et non « Recopie »).

Ensuite, depuis tools/tesla-display :

     ./run.sh --list          # repérer l'index de l'écran virtuel
     ./run.sh --display 2     # le diffuser vers la Tesla
GUIDE
