#!/usr/bin/env bash
# =============================================================================
#  PARE-FEU DU VPS (ufw) - Thomas Loiseau Visuals
#
#  Par defaut ce script n'applique RIEN : il affiche ce qu'il ferait.
#  Pour appliquer reellement :   bash 05-pare-feu-ufw.sh --appliquer
#
#  DANGER CONNU : activer un pare-feu par SSH peut vous couper l'acces a
#  votre propre serveur. Ce script detecte donc votre port SSH et l'autorise
#  AVANT d'activer quoi que ce soit, et refuse d'avancer s'il n'est pas sur.
# =============================================================================
set -uo pipefail

APPLIQUER=0
[ "${1:-}" = "--appliquer" ] && APPLIQUER=1

titre() { printf '\n\033[1;36m=== %s ===\033[0m\n' "$1"; }
ok()    { printf '  \033[0;32m✔\033[0m %s\n' "$1"; }
ko()    { printf '  \033[0;31m✘\033[0m %s\n' "$1"; }
info()  { printf '  \033[0;36m·\033[0m %s\n' "$1"; }
faire() {
  if [ "$APPLIQUER" = "1" ]; then
    printf '  \033[1;33m→\033[0m %s\n' "$*"; "$@"
  else
    printf '  \033[0;90m(simulation)\033[0m %s\n' "$*"
  fi
}

[ "$(id -u)" -ne 0 ] && { ko "A lancer en root (ou avec sudo)."; exit 1; }

titre "1. Detection de votre port SSH"
PORT_SSH=$(ss -tnp 2>/dev/null | awk '/ESTAB/ && /sshd/ {split($4,a,":"); print a[length(a)]; exit}')
if [ -z "${PORT_SSH:-}" ]; then
  PORT_SSH=$(grep -riE '^[[:space:]]*Port[[:space:]]+[0-9]+' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/ 2>/dev/null \
             | grep -oE '[0-9]+$' | head -1)
fi
if [ -z "${PORT_SSH:-}" ]; then
  PORT_SSH=22
  info "Port SSH non detecte : on retient 22 par defaut."
else
  ok "Port SSH detecte : $PORT_SSH"
fi

printf '  \033[1;33mVerifiez ce numero.\033[0m Si votre SSH ecoute ailleurs, arretez ce script\n'
printf '  (Ctrl+C) et relancez-le apres avoir corrige, sinon vous perdrez l acces.\n'

titre "2. Installation de ufw si absent"
if command -v ufw >/dev/null 2>&1; then
  ok "ufw deja present"
else
  faire apt-get update -y
  faire apt-get install -y ufw
fi

titre "3. Regles prevues"
info "Autoriser SSH (port $PORT_SSH)    : pour ne pas vous enfermer dehors"
info "Autoriser 80/tcp et 443/tcp       : sites web et certificats HTTPS"
info "Autoriser 443/udp                 : HTTP/3, utilise par Traefik"
info "Tout le reste en entree           : refuse"

faire ufw --force reset
faire ufw default deny incoming
faire ufw default allow outgoing
faire ufw allow "${PORT_SSH}/tcp" comment 'SSH'
faire ufw allow 80/tcp   comment 'HTTP - Traefik'
faire ufw allow 443/tcp  comment 'HTTPS - Traefik'
faire ufw allow 443/udp  comment 'HTTP/3 - Traefik'

titre "4. Activation"
if [ "$APPLIQUER" = "1" ]; then
  printf '  Activer le pare-feu maintenant ? Tapez exactement OUI puis Entree : '
  read -r REPONSE
  if [ "$REPONSE" = "OUI" ]; then
    ufw --force enable
    ok "Pare-feu actif"
    ufw status verbose | sed 's/^/  /'
  else
    info "Annule. Les regles sont enregistrees mais le pare-feu reste inactif."
    info "Pour l'activer plus tard :  ufw enable"
  fi
else
  info "Mode simulation : rien n'a ete applique."
  info "Pour appliquer :  bash 05-pare-feu-ufw.sh --appliquer"
fi

titre "A SAVOIR ABSOLUMENT : ufw ne filtre pas les ports publies par Docker"
cat <<'TEXTE'
  Docker ecrit ses propres regles iptables, evaluees AVANT celles de ufw.
  Consequence : un port publie par un conteneur (par exemple le 3000 de
  Dokploy) reste accessible depuis internet MEME si ufw affiche "deny 3000".
  C'est une source classique de fausse impression de securite.

  Pour reellement fermer le port 3000 de Dokploy, il faut retirer sa
  publication, pas le bloquer au pare-feu :
        bash 10-fermer-port-3000.sh
TEXTE
